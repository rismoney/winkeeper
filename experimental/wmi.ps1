#Register-WmiEvent -Query "select * from __InstanceOperationEvent within 3 where TargetInstance ISA 'ds_grouppolicycontainer'" -Namespace root\directory\ldap -SourceIdentifier ds_displayname -Action {write-host "gpo
#changed!" }


$myfilter = New-WmiEventFilter -Name WatchGPO -Query "select * from __InstanceOperationEvent within 3 where TargetInstance ISA 'ds_grouppolicycontainer'" -EventNamespace "root\directory\ldap"
$myConsumer = New-WMIEventConsumer -ConsumerType CommandLine -Name WatchGPO -CommandLineTemplate "C:\\windows\\system32\\windowspowershell\\v1.0\\powershell.exe -File c:\@inf\test.ps1"
#-<<<ParameterNAme1>>> %TargetInstance.<<<WmiPropertyName>>>%"
New-WmiFiltertoConsumerBinding -Filter $Myfilter -Consumer $myconsumer
