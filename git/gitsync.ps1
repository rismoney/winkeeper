function gitsync{
  Param(
    [Parameter(Mandatory=$true)] 
    [bool]$push,
    [Parameter(Mandatory=$true)] 
    [string]$msg
  )

  pushd $winkeeper_local
  Invoke-Expression "git checkout $git_branch"
  Invoke-Expression "git add -A -v"
  Invoke-Expression "git commit -m `"Auto generated commit for $msg by winkeeper`""
  
  if ($push) {
    Invoke-Expression "git push origin $git_branch"
  }
  
  popd
}