function gitinit {

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$username,

   [Parameter(Mandatory=$True,Position=2)]
   [string]$useremail,
   
   [Parameter(Mandatory=$True,Position=3)]
   [string]$remote
)


  if(!(test-path $winkeeper_local )){
    New-Item -ItemType directory -Path "$winkeeper_local"
  }

  pushd $winkeeper_local

  Invoke-Expression "git config --global user.name  $user_name"
  Invoke-Expression "git config --global user.email $user_email"
  Invoke-Expression "git config --global push.default simple"

  if(!(test-path "$winkeeper_local\.git" )){
    Invoke-Expression "git init"
    $readme | out-file README.md
    Invoke-Expression "touch .gitignore"
    Invoke-Expression "git checkout -b master"
    Invoke-Expression "git add -A -v"
    Invoke-Expression "git commit -m `"Initial Commit Message for Winkeeper repo`""
    write-host "configuring $remote"
    Invoke-Expression "git remote add origin $remote"
    Invoke-Expression "git push -u origin master"
  }
  popd
}