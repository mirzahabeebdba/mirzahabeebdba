A PowerShell script to enumerate the SQL instances across multiple servers.

##
# Read in a list of Server Names from a file. 
# For each server, query the services to find the SQL server instance names.
# List all the SQL instances found to a log file.

##

$servers = get-content "C:\batch\servers.txt"
$logfile = "C:\batch\sql-instances.txt"
$logerrs = "C:\batch\sql-failures.txt"

Echo "Server, Instance" >> $logfile

ForEach ($server in $servers) { 
   $instances = Get-WmiObject -ComputerName $server win32_service | where {$_.name -like "MSSQL*"}

   if (!$?) {
      Echo "$server - No SQL instance found" >> $logerrs
      Echo "$server - No SQL instance found"
   }
   Else {
      ForEach ($instance in $instances) {
         if (($instance.name -eq "MSSQLSERVER") -or ($instance.name -like "MSSQL$*")) {
            Echo "$server, $($instance.name)" >> $logfile
            Echo "$server, $($instance.name)"
         }
      }  
   }
}
# SS64.com/sql/syntax-instances.html