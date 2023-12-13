#---------------------------------------------------------------------------------------------------------------------------*
#  Purpose        : Script for Creating Flexible server sync to Azure MySQL Single Server
#  Schedule       : Ad-Hoc / On-Demand
#  Date           : 05-DEC-2023
#  Author         : Madan Agrawal
#  Version        : 1.1
#   
#  INPUT          : NONE
#  VARIABLE       : NONE
#  PARENT         : NONE
#  CHILD          : NONE
#---------------------------------------------------------------------------------------------------------------------------*
#---------------------------------------------------------------------------------------------------------------------------*
#
#  IMPORTANT NOTE : The script has to be run on Non-Mission-Critical systems ONLY and not on any production server...
#
#---------------------------------------------------------------------------------------------------------------------------*
#---------------------------------------------------------------------------------------------------------------------------*
# Usage:
# Powershell.exe -File .\CMF-MySQL_Azure_SingleServer_to_Flexible.ps1
#
<#
    Change Log
    ----------
•	Customer consent to install ImportExcel PS Module and Azure CLI
•

        
#>
Set-ExecutionPolicy Bypass -Scope currentuser
CLS
 [System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
if( -not ($Library = [System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")) )
        {
            Throw "This function requires the ADO.NET driver for MySQL:`n`thttp://dev.mysql.com/downloads/connector/net/"
        }
        


#---------------------------------------------------------PROGRAM BEGINS HERE----------------------------------------------------------

write-host "                                                                            " -BackgroundColor DarkMagenta
Write-Host "     Welcome to CMF - MySQL_Azure_SingleServer_to_Flexible_Automation       " -ForegroundColor white -BackgroundColor DarkMagenta
write-host "                     (OSS DB Migration Factory)                             " -BackgroundColor DarkMagenta
write-host "                                                                            " -BackgroundColor DarkMagenta
Write-Host " "

$folder = $PSScriptRoot

Write-Host "`n======================================================================================="
Start-Transcript -path  $folder\Logs\CMF_MySQL_Azure_SingleServer_to_Flexible_Automation_Transcript.txt -Append
Write-Host "`n======================================================================================="

function exitCode
{
    Write-Host "-Ending Execution"
    Stop-Transcript
    exit
}

function createFolder([string]$newFolder) 
{
   if(Test-Path $newFolder)
    {
        Write-Host "-Folder'$newFolder' Exist..."
    }
    else
    {
        New-Item $newFolder -ItemType Directory
        Write-Host "-$newFolder folder created..."
    }
}

#Function to convert json value to hashtable

    function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
          )

        process {
        if ($null -eq $InputObject) 
        {
            return $null
         }
        
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
                )

         Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) 
        {
            $hash = @{}
            
            foreach ($property in $InputObject.PSObject.Properties) 
            {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            
             $hash
        } 
        else 
        {
            $InputObject
        }
        }
    }

    #Functions to fetch the json paths
    function CMF-Read-Hashtable ([Hashtable]$InputHashTable){
    	foreach ($h in $InputHashTable.GetEnumerator() ){
		if ($h.Value -is [Array]){
			CMF-Read-Nested-Array $h.Name $h.Value
		}elseif ($h.Value -is [Hashtable]){
			CMF-Read-Nested-Hashtable $h.Name $h.Value
		}else{
           
			$global:row.Add($h.Name, $h.Value)
		}
	}
	$global:alldata += $global:row
	$global:row =@{}
    }

    function CMF-Read-Nested-Hashtable ([String]$prefix,[Hashtable]$InputNestedHashTable){
	foreach ($h in $InputNestedHashTable.GetEnumerator()){
		if ($h.Value -is [Array]){
			CMF-Read-Nested-Array $h.Name $h.Value
		}elseif ($h.Value -is [Hashtable]){
            $newPrefix=-join($prefix,".",$h.Name)
			CMF-Read-Nested-Hashtable $newPrefix $h.Value
		}else{
			$global:row.Add(-join($prefix,".",$h.Name), $h.Value)
		}
	    }
    }

    function CMF-Read-Array ([Array]$InputArray){
    foreach ($a in $InputArray){
		if($a -is [Hashtable]){
			CMF-Read-Hashtable $a
		}elseif ($a.Value -is [Array]){
		    CMF-Read-Nested-Array $a.Name $a.Value 
		}elseif ($a -is [Array]){
			CMF-Process-Nested-Array $null $a	
		}elseif($a.Value -is [Hashtable]){
			CMF-Read-Nested-Hashtable $a.Name $a.Value
		}else{
			Write-Host "Process-Array :$($a.Value.pstypenames)"
		}
	    }
    }

    function CMF-Read-Nested-Array ([String]$prefix,[Array]$InputArray){
    foreach ($a in $InputArray){
		if($a -is [Hashtable]){
		    CMF-Read-Nested-Hashtable $prefix $a
		}elseif ($a.Value -is [Array]){
			CMF-Read-Nested-Array $prefix $a.Value 
		}elseif ($a -is [Array]){
			CMF-Read-Nested-Array $prefix $a
		}elseif($a.Value -is [Hashtable]){
			CMF-Read-Nested-Hashtable $a.Name $a.Value
		}else{
			$global:row.Add(-join($prefix,".",$h.Name), $h.Value)
		}
	    }
    }


function ExecMySqlQuery{
 param(
 [Parameter (Mandatory = $true)] [string] $MySqlQuery
 )


    $MYSQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $MYSQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
    $MYSQLDataSet = New-Object System.Data.DataSet
    $MYSQLCommand.Connection=$Connection
    $MYSQLCommand.CommandText="$MySqlQuery;"
    $MYSQLDataAdapter.SelectCommand=$MYSQLCommand
    $NumberOfDataSets=$MYSQLDataAdapter.Fill($MYSQLDataSet, "data")

    $Qout = [PSCustomObject] @{
    File = $MYSQLDataSet.tables[0].File
    Position   = $MYSQLDataSet.tables[0].Position
    Message  = $MYSQLDataSet.tables[0].message
   exception=$MYSQLDataSet.tables[0].exception
    }
    return $Qout
}




createFolder $folder\Downloads\
createFolder $folder\Logs\
createFolder $folder\Output\
createFolder $folder\Output\Single\


#Check for ImportExcel module
Write-Host "======================================================================================="
Write-Host "`nChecking for ImportExcel Module"
if((Get-Module -ListAvailable).Name -notcontains "ImportExcel")
{
    Write-Host "Excel PS module not found.."  -BackgroundColor Red
    Write-Host "=======================================================================================" 
    $response = read-host "Do you want to continue download and install Excel PS Module? 'Y' or 'N' : "

    if($response.ToUpper() -eq "Y")
    {
    Write-Host "Downloading ImportExcel PS Module..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    try { Install-Module -Name ImportExcel} 
            catch {

               Write-Host "======================================================================================="  
               Write-Host "Error while downloading Importexcel package , Please make sure computer is connected to internet "  -ForegroundColor Red  
               Write-Host "Or "  -ForegroundColor Red 
               Write-Host "Please install it manually "  -ForegroundColor Red   
               Write-Host "======================================================================================="  
               Write-Host "Please see the error below & execution has been stopped          " 
            throw  $_.Exception.Response.StatusCode.Value__
            }
    
    Write-Host "Downloaded."
    }
    else
    {
        Write-Host "Excel PS module is required for the execution. Exiting..."
        exitCode
    }
    <#Expand-Archive "$folder\Downloads\ImportExcel.zip" "$folder\Downloads\"
    move "$folder\Downloads\ImportExcel-7.8.0" "C:\Program Files\WindowsPowerShell\Modules\ImportExcel"
    Import-Module ImportExcel#>
}


# Read the input config Excel and validate
$inputfile = $PSScriptRoot+"\CMF-MySQL_Single_Server_Input_file.xlsx" 
Write-Host "Input file is $inputfile." -ForegroundColor Green
Write-Host "===================================================================="  


if (-not(Test-Path -Path $inputfile -PathType Leaf)) {
    try {    
         Write-Host "======================================================================================="  
         Write-Host "Unable to read the input file [$inputfile]. Check file & its permission...  "  -BackgroundColor Red
         Write-Host "======================================================================================="  
         Write-Host "Please see the error below Execution has been stopped          "  
         throw $_.Exception.Message                      
    }
    catch {
         throw $_.Exception.Message
    }
 }
else
{
     try {
         $ConfigList = Import-Excel -Path $inputfile -WorksheetName Azure_Subscription 

         }

         catch {
         Write-Host "=================================================================================="  
         Write-Host "The file [$inputfile] does not have the woksheet named Azure_Subscription or Server_List"  -BackgroundColor Red 
         Write-Host "=================================================================================="  
         #Write-Host "Please see the error below & Azure MySQL to Flexible has been stopped          "  
         #throw $_.Exception.Message
         exitcode
        }

           try {
         $ServerList = Import-Excel -Path $inputfile -WorksheetName Server_List 
        $Approved_Rows = $ServerList | Where-Object { $_.Approval_Status.toupper() -eq "YES" }
        $ServerList=$Approved_Rows
         }

         catch {
         Write-Host "=================================================================================="  
         Write-Host "The file [$inputfile] does not have the woksheet named Azure_Subscription or Server_List"  -BackgroundColor Red 
         Write-Host "=================================================================================="  
         #Write-Host "Please see the error below & Azure MySQL to Flexible has been stopped          "  
         #throw $_.Exception.Message
         exitcode
        }

 }    
 
 $ColumnList=$ConfigList | Get-Member -MemberType NoteProperty | %{"$($_.Name)"}
     if (($ColumnList.Contains("Tenant")) -and
        ($ColumnList.Contains("Subscription_ID"))){

        Write-Host "Excel validation is done successfully " 
        }
     else {Write-Host "There are mismatches in the Excel column . Kindly check and retrigger the automation "  -BackgroundColor Red
           exitCode}

$tenant=$ConfigList[0].'Tenant'
if ([string]::IsNullOrWhitespace($tenant)){
Write-Host "'Tenant' is not valid in the Azure_Subscription worksheet. Kindly check and retrigger the automation  "  -BackgroundColor Red 
exitCode
}

$Subscription=$ConfigList[0].'Subscription_ID'
if ([string]::IsNullOrWhitespace($Subscription)){
Write-Host "'Subscription_ID' is not valid in the Azure_Subscription worksheet. Kindly check and retrigger the automation  "  -BackgroundColor Red 
exitCode
}


Unblock-File $folder/Validation_Scripts/Check_PowerShell_Version.ps1
Unblock-File $folder/Validation_Scripts/azurecli.ps1


      
# Check PowerShell version
$Validation=@()
$Outfiledata=@()
$Outputexcel=@()
$DBListData=@()
$AdAdminData=@()

$alldata =@()
$row=@{}
$FWData=@()
$ServerConfigData=@()
$Validation+=& "$folder/Validation_Scripts/Check_PowerShell_Version.ps1"
$Validation+=& "$folder/Validation_Scripts/azurecli.ps1"

Write-Host "======================================================================================="  
Write-Host "Below are the Validation Results"  -ForegroundColor Green  
Write-Host "======================================================================================="  
Write-Host ($Validation | select Validation_Type,Status,Comments | Format-Table | Out-String)

If($Validation.Status.Contains("FAILED"))
{
 Write-Host "There are errors during validation . Terminating the execution ."  -ForegroundColor Red
 exitcode  
}


    
   # if($Outfiledata -ne $null){
   # $Outfiledata | select Host_Name,Resource_Group,Port,VCore,User_ID,Password,Auth_Type,DB_Name,Tenant,Subscription_ID,Approval_Status | Export-Excel $PSScriptRoot\CMF-MySQL_Single_Server_Input_file.xlsx -Append -WorksheetName "Server_List"
   # }

  #  Write-host "tenant" $tenant
   # Write-host "Subscription" $Subscription

$loginoutput=az login --tenant $tenant --only-show-errors

  #Write-host "loginoutput" $loginoutput
  if ($ServerList -eq $null) 
{
    Write-Error "Either no approved servers on list or Error connecting to Tenant: $tenant and Subscription: $Subscription"
    exitcode
}
else
{
    $Serverdata=@()
    $db_data=@()
    $DBList=@()
    $ServerConf=@()
    $confdata=@()
    $ADAdmin=@()
    $Admin=@()
    $Firewall=@()
    $Replica=@()
    $dbdata=@()

    #AZ Connect to provided subscription
    az account set --subscription $Subscription
     
    #Server list fetch for Single Server
    #$Single_list_Out = az mysql server list | Out-File $folder\Output\Single\Single_Server_List.json 
    
    #$ser_details = az mysql server list|ConvertFrom-Json
      
    #$ser_list = az mysql server list |ConvertFrom-Json | ConvertTo-HashTable
    <#if($ser_list -is [Hashtable])
    {
        CMF-Read-Hashtable $ser_list
    }else
    {
	    CMF-Read-Array $ser_list
    }
    
    $Serverdata+=$alldata
    $alldata=@()#>
   
    
  foreach ($mysql in $ServerList)
  {

    $hostname=$mysql.Host_Name

    if($hostname -eq $null){
        Write-host "`n`nHost_Name for source single mysql server column for approved row can't be blank. Please supply single server name and re-run the script again!!!" -ForegroundColor Red
        exitcode
        } 

    $port=$mysql.Port

    if($port -eq $null){
        $port='3306'
        } 

  $mysqlFlexi=$mysql.Destination.toLower()

  
  $RG=$mysql.Resource_Group  
  
  $Az_import="az mysql flexible-server import create --data-source-type ""mysql_single"" --data-source ""$hostname"" --resource-group ""$RG"" --name ""$mysqlFlexi"""

  $tier=$mysql.Tier

   
  if ($tier -ne $null)     { $Az_import=$Az_import+" --tier "+"$tier"  } 
 
  $sku=$mysql."sku-name"

  if ($sku -ne $null)     { $Az_import=$Az_import+" --sku-name "+"""$sku"""  } 

  $storage=$mysql."storage-size"

  if ($storage -ne $null) { $Az_import=$Az_import+" --storage-size "+$storage } 
 
  $admin_user=$mysql."admin-user"
 
       if ($admin_user -eq $null) 
        {
        $uid=$mysql.User_ID
        }
        else
        {
            $Az_import=$Az_import+" --admin-user "+$admin_user
            $uid=$admin_user
        } 
 
  $admin_pass=$mysql."admin-password"

 
       if ($admin_pass -eq $null)
         {
         $pass=$mysql.Password
         }
     else
         {
         $Az_import=$Az_import+" --admin-password "+$admin_pass
         $pass=$admin_pass
         } 
 
 
  $SingleServerInfo="$PSScriptRoot/Output/$hostname.mysql.database.azure.com.json"
  $FlexServerInfo="$PSScriptRoot/Output/$mysqlFlexi.mysql.database.azure.com.json"  
    
     az mysql server show --ids "/subscriptions/$Subscription/resourceGroups/$RG/providers/Microsoft.DBforMySQL/servers/$hostname" > $SingleServerInfo
     $ServerData= get-content "$SingleServerInfo" | ConvertFrom-Json
     
     
     write-host "-----------------------------------------------------------------------------------------------------------"
     write-host "Processing Source Single server [$hostname]              "
     write-host "-----------------------------------------------------------------------------------------------------------"
     write-host "tier:" $ServerData[0].sku.tier
     write-host "Compute Generation:" $ServerData[0].sku.family
     write-host "vCore:" $ServerData[0].sku.capacity
     write-host "storage:" $ServerData[0].storageProfile.storageMb
     write-host "Location:" $ServerData[0].location
     write-host "sslEnforcement:" $ServerData[0].sslEnforcement
     write-host "-----------------------------------------------------------------------------------------------------------"
        
  $sslEnforcement=$ServerData[0].sslEnforcement
  
   
  if($mysqlFlexi -eq $null){
        Write-host "Destination column for approved row can't be blank. Please supply Flexible server name and re-run the script again!!!" -ForegroundColor Red
        exitcode
        } 
   
   Write-host "Cloning host [$hostname] to Flexi server [$mysqlFlexi]" -ForegroundColor Green  

 
Write-host "`nStart Time::"$(Get-Date -format 's')


   # Create Flexible server :Invoke-Expression  $Az_import
  
$Az_import += '; $Success=$?'
Invoke-Expression $Az_import


# Record the end time
Write-host "End Time::"$(Get-Date -format 's')

start-sleep 10

#write-host "if loop: $Success"

if($Success -match "True")
{

  $connectionstr="server=$mysqlFlexi.mysql.database.azure.com;uid=$uid@$mysqlFlexi;pwd=$pass;database=mysql;Allow User Variables=True;"
  
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  
  $connection.ConnectionString = $connectionstr


 $tries = 0
    while ($tries -lt 4) 
    {
        try{    

          $Connection.Open()
           Write-host "`nconnected successfully to host [$mysqlFlexi]" -ForegroundColor Green  
           
                      az mysql flexible-server show --ids "/subscriptions/$Subscription/resourceGroups/$RG/providers/Microsoft.DBforMySQL/flexibleServers/$mysqlFlexi" > $FlexServerInfo
   
           BREAK
           } catch {
                              
                    if($tries -ne 3)
                    {    
                    Write-host "Host [$mysqlFlexi] is not ready to accept connection.retrying connection after 10s..." -ForegroundColor Yellow 
                    
                    } 
                    else
                    {
                    Write-host "Failed to connect [$mysqlFlexi]" -ForegroundColor Red 
                    Write-Error $_
                    }
                start-sleep 10
                $tries++
         }
    }


Write-host "Executing ""call mysql.az_show_binlog_file_and_pos_for_mysql_import""" -ForegroundColor Blue

$MyData=ExecMySqlQuery("call mysql.az_show_binlog_file_and_pos_for_mysql_import;")

$binlog=$MyData.File
$binLogFile=$binlog.substring($binlog.IndexOf("/")+1)
$Position=$MyData.position

Write-host "`nFile:"$binLogFile
Write-host "Position:"$Position

If ($sslEnforcement -eq "Enabled")
  {
  $cert=Get-Content $folder/Validation_Scripts/DigiCertGlobalRootG2.crt.pem -Raw
  $command="call mysql.az_replication_change_master('$hostname.mysql.database.azure.com', '$uid@$hostname', '$pass', $port, '$binLogFile', $Position, '$cert')"
  Write-host "`nExecuting... " -ForegroundColor Blue
  Write-host "call mysql.az_replication_change_master('$hostname.mysql.database.azure.com', '$uid@$hostname', '*****', $port, '$binLogFile', $Position, '*****')" -ForegroundColor Blue

  }
  else
  {
    $command="call mysql.az_replication_change_master('$hostname.mysql.database.azure.com', '$uid@$hostname', '$pass', $port, '$binLogFile', $Position, '')"
    Write-host "`nExecuting... " -ForegroundColor Blue
    Write-host "call mysql.az_replication_change_master('$hostname.mysql.database.azure.com', '$uid@$hostname', '*****', $port, '$binLogFile', $Position, '')" -ForegroundColor Blue
  }

$MyData=ExecMySqlQuery("$command;")

If (!$MyData.exception)
{
Write-host "Call mysql.az_replication_change_master executed successfully!!" -ForegroundColor Green
Write-host $MyData.message -ForegroundColor Green
}
else
{
Write-host "`nFailed to execute ""Call mysql.az_replication_change_master""`n" -ForegroundColor Red
write-host "Error Message:"$MyData.message -ForegroundColor Red
}


Write-host "`nExecuting ""call mysql.az_replication_start""`n" -ForegroundColor Blue

$command="call mysql.az_replication_start"
$MyData=ExecMySqlQuery("$command;")


If (!$MyData.exception)
{
Write-host "call mysql.az_replication_start executed successfully!!" -ForegroundColor Green
Write-host $MyData.message -ForegroundColor Green
}
else
{
Write-host "`nFailed to execute ""call mysql.az_replication_start""`n" -ForegroundColor Red
write-host "Error Message:"$MyData.message -ForegroundColor Red
}


$Connection.Close()
}

}
    Stop-Transcript
}