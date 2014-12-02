
function export-groups {

  if(!(Test-Path -Path "$winkeeper_local\ad" )){
    New-Item -ItemType directory -Path "$winkeeper_local\ad"
  }

  $groups_parent_dir = join-path $winkeeper_local "ad"
  $groups_file = join-path $groups_parent_dir $groups_filename

  $defaultNamingContext = (get-adrootdse).defaultnamingcontext

  $parent = @{Name='Parent'; Expression={ Get-ADParent $_.DistinguishedName } }

  $array = @()

  $GroupExclusions = @("DnsAdmins","DnsUpdateProxy")
  $ParentExclusions = @("CN=Builtin")

  $Groups = Get-ADGroup -Filter * -SearchBase $defaultNamingContext -Properties * | Where-Object {!($_.IsCriticalSystemObject) } | select-object Name,SamAccountName,DistinguishedName,$parent,Description,DisplayName,GroupCategory,GroupScope,ManagedBy
  # Note how we are using Select-Object cmdlet to add the Parent property to the existing "Group" object.
  # We could also use the Add-Member cmdlet. But for what we need the Select-Object cmdlet is simpler.

  # Filtering out groups that have their IsCriticalSystemObject property set will remove the following groups:
  # - Administrators
  # - Users
  # - Guests
  # - Print Operators
  # - Backup Operators
  # - Replicator
  # - Remote Desktop Users
  # - Network Configuration Operators
  # - Performance Monitor Users
  # - Performance Log Users
  # - Distributed COM Users
  # - IIS_IUSRS
  # - Cryptographic Operators
  # - Event Log Readers
  # - Certificate Service DCOM Access
  # - Domain Computers
  # - Domain Controllers
  # - Schema Admins
  # - Enterprise Admins
  # - Cert Publishers
  # - Domain Admins
  # - Domain Users
  # - Domain Guests
  # - Group Policy Creator Owners
  # - RAS and IAS Servers
  # - Server Operators
  # - Account Operators
  # - Pre-Windows 2000 Compatible Access
  # - Incoming Forest Trust Builders
  # - Windows Authorization Access Group
  # - Terminal Server License Servers
  # - Allowed RODC Password Replication Group
  # - Denied RODC Password Replication Group
  # - Read-only Domain Controllers
  # - Enterprise Read-only Domain Controllerss
  # This is typically all groups from under the Builtin container, and some groups from the Users container
  # with the exclusion of the DnsAdmins and DnsUpdateProxy groups.

  ForEach ($Group in $Groups) {

    write-host -ForegroundColor Green "Exporting $($Group.SamAccountName)"

    If ($($Group.Name).Contains("CNF:") -eq $False) {

      $OUPath = $Group.Parent -replace (",$defaultNamingContext","")
      $OUPath = $OUPath -replace (",","|")

      If ($GroupExclusions -notcontains $Group.Name -AND $ParentExclusions -notcontains $OUPath) {

        If ($Group.ManagedBy -ne $NULL -AND $Group.ManagedBy -ne "") {
          $ManagedBy = $Group.ManagedBy
          $ManagedBy = Get-ADObject -Filter {distinguishedName -eq $ManagedBy} | % {$_.Name}
        }

        # Get Members
        $Members = ""
        # When using the Get-ADGroupMember cmdlet to get group members it will
        # fail to get the group members if the group contains a member that is
        # a foreign security principal (i.e. members from another Domain) where
        # the SID cannot be resolved. To work around this we use the member
        # property of the Get-ADGroup cmdlet instead, which will ignore any
        # foreign security principals.
        $GetMembers = (Get-ADGroup -identity $Group.DistinguishedName -properties member).member | Get-ADObject -Properties Name,sAMAccountName | Select Name,SamAccountName | ForEach {
        #$GetMembers = Get-ADGroupMember -identity $Group.DistinguishedName |Select Name,SamAccountName | ForEach {
          $Member = $_.Name
          If ($Member.Contains("CNF:") -eq $False) {
            $Member = $_.SamAccountName 
            If ($Members -ne "" ) {
              If ($Member -ne "" -OR $Member -ne $NULL) {
                $Members += "|" + $Member
              }
            } else {
              $Members += $_.SamAccountName
            }
          } else {
            # Skipping this group as this is a duplication created by a replication collision
          }
        }

        $output = New-Object PSObject
        $output | Add-Member NoteProperty GroupName $Group.Name
        $output | Add-Member NoteProperty Description $Group.Description
        $output | Add-Member NoteProperty DisplayName $Group.DisplayName
        $output | Add-Member NoteProperty Scope $Group.GroupScope
        $output | Add-Member NoteProperty Category $Group.GroupCategory
        $output | Add-Member NoteProperty OUPath $OUPath
        $output | Add-Member NoteProperty ManagedBy $ManagedBy
        $output | Add-Member NoteProperty Members $Members
        $array += $output

      }

    } else {
      write-host -ForegroundColor Red "- Skipping as this is a duplication created by a replication collision."
    }
  }

  $array | export-csv -notype "$groups_file" -Delimiter ','

  # Remove the quotes
  #(get-content "$groups_file") |% {$_ -replace '"',""} | out-file "$groups_file" -Fo -En ascii

}