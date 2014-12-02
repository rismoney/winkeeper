function GetThePrimaryGroup{
  param($Username)
  # The current Domain
  $DomainNC = ([ADSI]"LDAP://RootDSE").DefaultNamingContext
  $BaseOU = [ADSI]"LDAP://$DomainNC"
  $LdapFilter = "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$Username))"

  # Find the user
  $Searcher = New-Object DirectoryServices.DirectorySearcher($BaseOU, $LdapFilter)
  $Searcher.PageSize = 1000
  $Searcher.FindAll() | %{
    $User = $_.GetDirectoryEntry()
    $groupID = $user.primaryGroupID
    $arrSID = $user.objectSid.Value
    $SID = New-Object System.Security.Principal.SecurityIdentifier ($arrSID,0)
    $groupSID = $SID.AccountDomainSid.Value + "-" + $user.primaryGroupID.ToString()
    $group = [adsi]("LDAP://<SID=$groupSID>")
    $group.name
  }
}