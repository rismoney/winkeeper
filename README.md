winkeeper
=========

version control all the windows things


Using Winkeeper:

** Recommended to use a private gitrepo as sensitive data may be in your configurations.

1. Install msysgit or similar git tooling on server
1. clone this repo
1. configure config.ps1 with your intended repo settings
1. Set up a gitrepo on github, empty repo, no files. self service - no README.
1. Establish a deploy key with ssh if using on server
1. run winkeeper init

Usage:
run the with the following options gpo, ou, groups, users, all
example:
```powershell
.\winkeeper.ps1 all
```

Additional usage options
```powershell
.\winkeeper.ps1 gpo -push $false # will not push to an upstream repo (keep repo on server)
