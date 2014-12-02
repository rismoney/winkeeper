$user_name = "Rich Siegel"
$user_email = "rismoney@gmail.com"
$README = "This repo is managed by winkeeper!"

#remote git repo
$winkeeper_remote = "git@github.com:org/winzoo.git"

# local git repository path
$winkeeper_local = "C:\@inf\winkeeper\winkept"

$git_path = 'C:\Program Files (x86)\Git\bin\git.exe'
$git_branch = "master"


$gpo_reference_filename = "gpo_references.txt"
$gpo_wmi_filename = "gpo_wmi.txt"
$ou_filename = "ou.txt"
$groups_filename = "groups.csv"
$users_filename = "users.csv"


# user settings
  $UserExclusions = @("")
  $ParentExclusions = @("")
  $IncludeDisabledUsers = $True
  $IncludeUsersWithEmptyEmployeeID = $True
  $EmployeeIDLength = 6
# more to come
