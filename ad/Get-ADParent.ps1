function Get-ADParent ([string] $dn) {
  $parts = $dn -split '(?<![\\]),'
  $parts[1..$($parts.Count-1)] -join ','
}