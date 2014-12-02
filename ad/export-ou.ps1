function export-ou {

  if(!(Test-Path -Path "$winkeeper_local\ad" )){
      New-Item -ItemType directory -Path "$winkeeper_local\ad"
  }

  $ou_parent_dir = join-path $winkeeper_local "ad"
  $ou_file = join-path $ou_parent_Dir $ou_filename

  $array = @()
  
  $defaultNamingContext = (get-adrootdse).defaultnamingcontext
  $AD_OU_LIST = Get-ADOrganizationalUnit -Filter * -SearchBase $defaultNamingContext -Properties Description,ProtectedFromAccidentalDeletion

  ForEach ($OU in $AD_OU_LIST) {

    $OUPath = $OU.DistinguishedName -replace (",$defaultNamingContext","")
    $OUPath = $OUPath -replace ("OU=","")
    $OUPath = $OUPath -replace (",","|")
    ForEach ($item in $OUPath) {
      If ($Item -ne "Domain Controllers") {

        $tmpOUPath = $Item.Split("|")
        If($tmpOUPath.Count -eq 1)
        {
          $OU_Name = $tmpOUPath[0]
        }
        Else
        {
          # Reverse the Path
          [array]::Reverse($tmpOUPath)
          $OU_Name= $tmpOUPath[0]
          $i = 0
          ForEach ($subOU in $tmpOUPath)
          {
            $i = $i + 1
            If ($i -eq 1)
            {
              $OU_Name = $subOU
            }
            else
            {
              $OU_Name = $OU_Name + "|" + $subOU
            }
          }
        }

        $output = New-Object PSObject
        $output | Add-Member NoteProperty Path $OU_Name
        $output | Add-Member NoteProperty Description ($OU.Description)
        $output | Add-Member NoteProperty Protect ($OU.ProtectedFromAccidentalDeletion.ToString().ToLower())
        $array += $output
        write-output "Processing: $output"
      }
    }
  }

  $array | export-csv -notype "$ou_file" -Delimiter ";"

  # Remove the quotes
  (get-content "$ou_file") |% {$_ -replace '"',""} | out-file "$ou_file" -Fo -En ascii

}