function export-gpo {

  # start with a clean directory to cheat to ensure deletion tracking
  if (Test-Path -Path "$winkeeper_local\gpos" ) {
    remove-item -recurse -force "$winkeeper_local\gpos"
  }

  New-Item -ItemType directory -Path "$winkeeper_local\gpos"

  $gpo_parent_dir = join-path $winkeeper_local "gpos"  

  $gpos=(get-gpo -all |select displayname)
  foreach ($gpo in $gpos) {
    $gponame = $gpo.displayname
    $gporeport = join-path "$gpo_parent_dir" "$gponame.xml"
    write-output "processing gpo $gporeport"
    Get-GPOReport $gponame -ReportType xml -Path $gporeport

    $encoding="UTF-8" # most encoding should work
    $files = get-ChildItem "$gpo_parent_dir\*.xml"
    foreach ( $file in $files ) {
      [xml] $xmlDoc = get-content $file
      $xmlDoc.xml = $($xmlDoc.CreateXmlDeclaration("1.0",$encoding,"")).Value
      #eliminate diff churn
      $xmlDoc.gpo.ReadTime="***REMOVED***"
      $xmlDoc.save($file.FullName)      
    }

  }
}