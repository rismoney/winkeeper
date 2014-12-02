<#
.SYNOPSIS
    winkeeper is like etckeeper for windows
.DESCRIPTION
    stores all your windows configs in a gitrepo
    takes a single command: [init|gpo|ou|groups|users|sync|all]
    to turn off push -p $false
.PARAMETER command
    only takes a single command: [init|gpo|ou|groups|users|sync|all]
.PARAMETER h
    help aka get-help aka -h
.PARAMETER p
    push $true $false default $true
.EXAMPLE
    winkeeper.ps1 init
.EXAMPLE
    winkeeper.ps1 all
#>

Param(
  [Parameter(Mandatory=$false,HelpMessage="valid commands are init,gpo,ou,groups,users,sync,all")] 
  [ValidateSet("init","gpo","ou","groups","users","sync","all","help")] 
  [String]$Command,
  [parameter(Mandatory=$false)]
  [alias("p")]
  [bool]$push=$true,
  [parameter(Mandatory=$false)]
  [alias("h")]
  [switch]$help
)

if ($help) {
get-help .\winkeeper.ps1
break;
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$config_dir = join-path $here "\config"
$gpo_dir = join-path $here "\gpo"
$ad_dir = join-path $here "\ad"
$git_dir = join-path $here "\git"

Resolve-Path $config_dir\config.ps1 | % { . $_.ProviderPath }

Resolve-Path $gpo_dir\*.ps1 |
  ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
  % { . $_.ProviderPath }

Resolve-Path $ad_dir\*.ps1 |
  ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
  % { . $_.ProviderPath }

Resolve-Path $git_dir\*.ps1 |
  ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
  % { . $_.ProviderPath }
  
$modules = @('ActiveDirectory','GroupPolicy')

foreach ($module in $modules) {
  Import-Module $module -ea SilentlyContinue
}

function winkeeper_all {
  gitinit -username $user_name -useremail $user_email -remote $winkeeper_remote
  export-gpo
  export-gpolinks
  export-gpowmi
  export-ou
  export-groups
  export-users
  gitsync -push $push -msg "all modules"
}

if ($command) {write-output "executing $command"}

switch -wildcard ($command) {
  "init"            {gitinit -username $user_name -useremail $user_email -remote $winkeeper_remote}
  "gpo"             {export-gpo;export-gpolinks;export-gpowmi;gitsync -push $push -msg "gpos"}
  "ou"              {export-ou;gitsync -push $push -msg "OUs"}
  "groups"          {export-groups;gitsync -push $push -msg "groups"}
  "users"           {export-users;gitsync -push $push -msg "users"}
  "sync"            {gitsync -push $push -msg "all modules"}
  "all"             {winkeeper_all}
  default           {Write-Host 'Please run winkeeper -h'}
}