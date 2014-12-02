
$defaultNamingContext = (get-adrootdse).defaultnamingcontext
$DistinguishedName = (Get-ADDomain).DistinguishedName
$DomainName = (Get-ADDomain).NetBIOSName
$DNSRoot = (Get-ADDomain).DNSRoot


$searchBase =  $defaultNamingContext


function export-users {


  if(!(Test-Path -Path "$winkeeper_local\ad" )){
    New-Item -ItemType directory -Path "$winkeeper_local\ad"
  }

  $users_parent_dir = join-path $winkeeper_local "ad"
  $users_file = join-path $users_parent_dir $users_filename

  $parent = @{Name='Parent'; Expression={ Get-ADParent $_.DistinguishedName } }

  $array = @()

  If ($IncludeDisabledUsers -eq $False -AND $IncludeUsersWithEmptyEmployeeID -eq $False) {
    $filter = "(&(!useraccountcontrol:1.2.840.113556.1.4.803:=2)(employeeID=*))"
  } elseif ($IncludeDisabledUsers -eq $False -AND $IncludeUsersWithEmptyEmployeeID -eq $True) {
    $filter = "(!useraccountcontrol:1.2.840.113556.1.4.803:=2)"
  } elseif ($IncludeDisabledUsers -eq $True -AND $IncludeUsersWithEmptyEmployeeID -eq $False) {
    $filter = "(employeeID=*)"
  } else {
    $filter = ""
  }

  If ($filter -eq "") {
    $Users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties * | Where-Object {!($_.IsCriticalSystemObject) } | select-object Name,SamAccountName,DistinguishedName,$parent,GivenName,Initials,SurName,EmailAddress,UserPrincipalName,Description,DisplayName,Manager,EmployeeID,EmployeeType,CannotChangePassword,PasswordNeverExpires,userAccountControl,MemberOf
  } else {
    $Users = Get-ADUser -LDAPFilter $filter -SearchBase $SearchBase -Properties * | Where-Object {!($_.IsCriticalSystemObject) } | select-object Name,SamAccountName,DistinguishedName,$parent,GivenName,Initials,SurName,EmailAddress,UserPrincipalName,Description,DisplayName,Manager,EmployeeID,EmployeeType,CannotChangePassword,PasswordNeverExpires,userAccountControl,MemberOf
  }

  # Note how we are using Select-Object cmdlet to add the Parent property to the existing "User" object.
  # We could also use the Add-Member cmdlet. But for what we need the Select-Object cmdlet is simpler.

  # Filtering out user that have their IsCriticalSystemObject property set will remove the following users:
  # - Administrator
  # - Guest
  # - krbtgt

  ForEach ($User in $Users) {

    write-host -ForegroundColor Green "Exporting $($User.SamAccountName)"

    If ($($User.Name).Contains("CNF:") -eq $False) {

      # Refer to KB305144 for a list of UserAccountControl Flags
      $Enabled = $True
      Switch ($User.userAccountControl)
      {
        {($User.userAccountControl -bor 0x0002) -eq $User.userAccountControl} {
          $Enabled = $False
        }
      }

      $IsValidEmployeeIDChars = $False
      If (($User.EmployeeID | Measure-Object -Character).Characters -eq $EmployeeIDLength) {
        $IsValidEmployeeIDChars = $True
      }

      $OUPath = $User.Parent -replace (",$defaultNamingContext","")
      $OUPath = $OUPath -replace (",","|")

      $Memberof = $User.MemberOf 
      $Members = ""
      # Not that you need to use quotes around the identity that you pass to the get-adgroup cmdlet,
      # especially if using a sAMAccountName, as the cmdlet searches the default naming context or
      # partition to find the object. If two or more objects are found, the cmdlet returns a
      # non-terminating error. By using quotes we want are ensuring an exact match.
      $Memberof | %{get-adgroup "$_" |  % {$_.Name}} | ForEach {
      $Member = $_
        If ($Member.Contains("CNF:") -eq $False) {
          If ($Members -ne "" ) {
            $Members += "|" + $Member
          } else {
            $Members += $Member
          }
        } else {
          # Skipping this group as this is a duplication created by a replication collision
        }
      }

      $PrimaryGroup = GetThePrimaryGroup $User.SamAccountName

      Try {
        #$UserPrincipalName = $User.UserPrincipalName -replace ("@$DNSRoot","")
        $UserPrincipalName = $User.UserPrincipalName.Split("@")
        $UserPrincipalName = $UserPrincipalName[0]
        }
      Catch {
        $UserPrincipalName = $User.SamAccountName
        }

      Try {
        #$EmailAddress = $User.EmailAddress -replace ("@$DNSRoot","")
        $EmailAddress = $User.EmailAddress.Split("@")
        $EmailAddress = $EmailAddress[0]
        }
      Catch {
        $EmailAddress = ""
        }

      If ($UserExclusions -notcontains $User.Name -AND $ParentExclusions -notcontains $OUPath) {
        $output = New-Object PSObject
        $output | Add-Member NoteProperty Name $User.Name
        $output | Add-Member NoteProperty SamAccountName $User.SamAccountName
        $output | Add-Member NoteProperty FirstName $User.GivenName
        $output | Add-Member NoteProperty LastName $User.SurName
        $output | Add-Member NoteProperty UserPrincipalName $UserPrincipalName
        $output | Add-Member NoteProperty EmailAddress  $EmailAddress
        $output | Add-Member NoteProperty Description $User.Description
        $output | Add-Member NoteProperty DisplayName $User.DisplayName
        $output | Add-Member NoteProperty OUPath $OUPath
        $output | Add-Member NoteProperty userAccountControl $User.userAccountControl
        $output | Add-Member NoteProperty CannotChangePassword $User.CannotChangePassword
        $output | Add-Member NoteProperty PasswordNeverExpires $User.PasswordNeverExpires
        $output | Add-Member NoteProperty EmployeeID $User.EmployeeID
        $output | Add-Member NoteProperty EmployeeType $User.EmployeeType
        $output | Add-Member NoteProperty PrimaryGroup $PrimaryGroup
        $output | Add-Member NoteProperty MemberOf $Members
        $array += $output
      }

    } else {
      write-host -ForegroundColor Red "- Skipping as user account as this is a duplication created by a replication collision."
    }
  }

  $array | export-csv -notype "$users_file" -Delimiter ','

  # Remove the quotes
  #(get-content "$users_file") |% {$_ -replace '"',""} | out-file "$users_file" -Fo -En ascii

}