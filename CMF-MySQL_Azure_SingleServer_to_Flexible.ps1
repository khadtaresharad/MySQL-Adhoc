﻿#---------------------------------------------------------------------------------------------------------------------------*
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
    #$NumberOfDataSets=$MYSQLDataAdapter.Fill($MYSQLDataSet, "data")
    $MYSQLDataAdapter.Fill($MYSQLDataSet, "data")
    $Qout = [PSCustomObject] @{
    File = $MYSQLDataSet.tables[0].File
    Position   = $MYSQLDataSet.tables[0].Position
    Message  = $MYSQLDataSet.tables[0].message
   exception=$MYSQLDataSet.tables[0].exception
   Value=$MYSQLDataSet.tables[0].Value
    }
    return $Qout
}



$Outdate = '{0}' -f ([system.string]::format('{0:yyyyMMddHHmmss}',(Get-Date)))
createFolder $folder\Downloads\
createFolder $folder\Logs\
createFolder $folder\Output\
createFolder $folder\Output\Single\

Write-Host "======================================================================================="
#Check for mysql-connector
Write-Host "Check for mysql-connector"
 [System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
if( -not ($Library = [System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")) )
        {
            Write-Host "`nmysql-connector-net Missing !`n" -ForegroundColor red
            Write-Host "`nDownload from http://dev.mysql.com/downloads/connector/net/`n" -ForegroundColor red
            Throw "This function requires the ADO.NET driver for MySQL:`n`thttp://dev.mysql.com/downloads/connector/net/"
        }

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
           $Output_data =@()
         $ServerList = Import-Excel -Path $inputfile -WorksheetName Server_List 
        $Approved_Rows = $ServerList | Where-Object { $_.Approval_Status.toupper() -eq "YES" }
        $None_Approved = $ServerList | Where-Object { $_.Approval_Status.toupper() -eq "NO" }
            $Output_data += New-Object psobject -Property @{Host_Name=$None_Approved.Host_Name;Status="Not Approved";Error_msg="NA"}
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

 if ($ServerList -eq $null) 
{
    Write-Error "Either no approved servers on list or Error connecting to Tenant: $tenant and Subscription: $Subscription"
    exitcode
}
#AZ login to corresponsing Tenant and subscription

$loginoutput=az login --tenant $tenant --only-show-errors
if (!$loginoutput) 
{
    Write-Error "Error connecting to Tenant: $tenant and Subscription: $Subscription"
    exitcode
}

else
{
    $Serverdata=@()
     

    #AZ Connect to provided subscription
    az account set --subscription $Subscription
     
       
    
  foreach ($mysql in $ServerList)
  {

    $hostname=$mysql.Host_Name
    $MysqlUID=$mysql.User_ID
    $MysqlPwd=$mysql.Password

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
 
 
  $SingleServerInfo="$PSScriptRoot\Output\$hostname.mysql.database.azure.com_$Outdate.json"
  $FlexServerInfo="$PSScriptRoot\Output\$mysqlFlexi.mysql.database.azure.com_$Outdate.json"  
  
  $SingleServerErr="$PSScriptRoot\Logs\$hostname.Error_log_$Outdate.log"
   
   
    
     write-host "-----------------------------------------------------------------------------------------------------------"
     write-host "Processing Source Single server [$hostname]              "
     write-host "-----------------------------------------------------------------------------------------------------------"
    #write-host "tier:" $ServerData[0].sku.tier
    #write-host "Compute Generation:" $ServerData[0].sku.family
    #write-host "vCore:" $ServerData[0].sku.capacity
    #write-host "storage:" $ServerData[0].storageProfile.storageMb
    #write-host "Location:" $ServerData[0].location
    #write-host "sslEnforcement:" $ServerData[0].sslEnforcement
    #write-host "-----------------------------------------------------------------------------------------------------------"
   
       if (($mysqlFlexi.length -gt 63) -or ($mysqlFlexi.length -lt 3) -or ($mysqlFlexi -match "[^a-z0-9-]"))
       {
       Write-host "`nError - The Flexible server name can contain only lowercase letters, numbers, and the hyphen (-) character. Minimum 3 characters and maximum 63`n"  -ForegroundColor Red
       Set-Content -Path $SingleServerErr -Value "Error - The Flexible server name can contain only lowercase letters, numbers, and the hyphen (-) character. Minimum 3 characters and maximum 63"
       continue
       }
     $connectionSingle="server=$hostname.mysql.database.azure.com;uid=$MysqlUID@$hostname;pwd=$MysqlPwd;database=mysql;Allow User Variables=True;"
     #write-host $connectionSingle
     $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  
     $connection.ConnectionString = $connectionSingle
     
            
        try{    

          $Connection.Open()
           Write-host "`nconnected successfully to host [$hostname]" -ForegroundColor Green  
                              
        
           } catch {
                              
                     
                    Write-host "Not able to connect Source MYSQL [$hostname].`nPlease refer log file @ $SingleServerErr`n" -ForegroundColor Red
                    Write-Error $_
                    Set-Content -Path $SingleServerErr -Value $_.Exception.Message
                    $Output_data += New-Object psobject -Property @{Host_Name=$hostname;Status="Failed";Error_msg="$_"}
                    continue; 
                    
            }
     $MyData=ExecMySqlQuery("SHOW VARIABLES LIKE 'log_bin'")
     
     $connection.close()
     $log_bin=$MyData.Value 
     
     #exitcode
     az mysql server show --ids "/subscriptions/$Subscription/resourceGroups/$RG/providers/Microsoft.DBforMySQL/servers/$hostname" > $SingleServerInfo
     $ServerData= get-content "$SingleServerInfo" | ConvertFrom-Json
     
    #Checking Binary logging on Source single mySQL server, Needed to configure replication

    Write-host "Checking Binary logging on [$hostname]"
     If ($log_bin -match "ON")
     {
      Write-host "`nBinary logging is already enabled on the source MySql [$hostname]`n" -ForegroundColor YELLOW 
     }    
     Else
     {
      Write-host "`nReplication cant be configured. Binary logging is disabled on the source MySql [$hostname].`nKindly verify that binary logging is enabled by running ""SHOW VARIABLES LIKE 'log_bin';""" -ForegroundColor Red 
     Write-host "Refer: https://learn.microsoft.com/en-us/azure/mysql/single-server/how-to-data-in-replication`n" -ForegroundColor Blue
     "Replication cant be configured. Binary logging is disabled on the source MySql [$hostname]. Kindly verify that binary logging is enabled by running ""SHOW VARIABLES LIKE 'log_bin';""" >> $SingleServerErr
     continue;
     }
    $sslEnforcement=$ServerData[0].sslEnforcement
  
   
  if($mysqlFlexi -eq $null){
        Write-host "Destination column for approved row can't be blank. Please supply Flexible server name and re-run the script again!!!" -ForegroundColor Red
        exitcode
        } 
   
    Write-host "Cloning host [$hostname] to Flexi server [$mysqlFlexi]" -ForegroundColor Green  
   
    Write-host "`n----------Start Time::$(Get-Date -format 's')-----------`n"


   # Create Flexible server :Invoke-Expression  $Az_import
  
$Az_import += '; $Success=$?'

Invoke-Expression $Az_import 

# Record the end time
 Write-host "`n----------End Time::$(Get-Date -format 's')-----------`n"

#start-sleep 10

#write-host "if loop: $Success"

if($Success -match "True")
{
   az mysql flexible-server show --ids "/subscriptions/$Subscription/resourceGroups/$RG/providers/Microsoft.DBforMySQL/flexibleServers/$mysqlFlexi" > $FlexServerInfo
   
    Write-host "`n Refer ""$FlexServerInfo"" to get the property of provisioned mysql flexible host [$mysqlFlexi]`n"

     

  $connectionFlexi="server=$mysqlFlexi.mysql.database.azure.com;uid=$uid@$mysqlFlexi;pwd=$pass;database=mysql;Allow User Variables=True;"
  
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  
  $connection.ConnectionString = $connectionFlexi


 $tries = 0
    while ($tries -lt 4) 
    {
        try{    
            
          $Connection.Open()
           Write-host "`nconnected successfully to host [$mysqlFlexi]" -ForegroundColor Green  
           
                     
           BREAK
           } catch {
                              
                    if($tries -ne 3)
                    {    
                    Write-host "Host [$mysqlFlexi] is not ready to accept connection.retrying connection after 10s..." -ForegroundColor Yellow 
                    
                    } 
                    else
                    {
                    Write-host "Failed to connect [$mysqlFlexi], Please refer log file @ $SingleServerErr" -ForegroundColor Red 
                    Write-Error $_
                    Set-Content -Path $SingleServerErr -Value $_.Exception.Message
                    $FlexConnFailed=1
                    $Output_data += New-Object psobject -Property @{Host_Name=$hostname;Status="Failed";Error_msg="$_"}
                    }
                start-sleep 10
                $tries++
         }
    }

if($FlexConnFailed -ne 1)
{
Write-host "Executing ""call mysql.az_show_binlog_file_and_pos_for_mysql_import""" -ForegroundColor Blue

$MyData=ExecMySqlQuery("call mysql.az_show_binlog_file_and_pos_for_mysql_import;")

$binlog=$MyData.File
$binLogFile=$binlog.substring($binlog.IndexOf("/")+1)
$Position=$MyData.position

Write-host "`nFile:"$binLogFile
Write-host "Position:"$Position


If ($sslEnforcement -eq "Enabled")
  {

  $cert = $(Write-Host "Input your certificate path (e.g. C:\cert\DigiCertGlobalRootG2.crt.pem; Leave blank for Default ./Validation_Scripts/DigiCertGlobalRootG2.crt.pem)::" -ForegroundColor Red -BackgroundColor Yellow -NoNewLine; Read-Host)
  #$cert=Read-Host -Prompt 'Input your certificate path  name(Leave blank for Default ./Validation_Scripts/DigiCertGlobalRootG2.crt.pem):' -ForegroundColor Blue

  If($cert -eq "")
  {
  $cert=Get-Content $folder/Validation_Scripts/DigiCertGlobalRootG2.crt.pem -Raw
  }
  Else
  {
  $cert=Get-Content $cert -Raw
 
  }
  
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
#Write-host "Call mysql.az_replication_change_master executed successfully!!" -ForegroundColor Green
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
#Write-host "call mysql.az_replication_start executed successfully!!" -ForegroundColor Green
Write-host $MyData.message -ForegroundColor Green
$Output_data += New-Object psobject -Property @{Host_Name=$hostname;Status="SUCCESS";Error_msg="NA"}
    
}
else
{
Write-host "`nFailed to execute ""call mysql.az_replication_start""`n" -ForegroundColor Red
write-host "Error Message:"$MyData.message -ForegroundColor Red
}

}

$Connection.Close()
}
else
{
 $Output_data += New-Object psobject -Property @{Host_Name=$hostname;Status="Failed";Error_msg="NA"}
}

}
Write-host "`n---------------Refer below for final Status table--------------------------`n"
Write-Host ($Output_data | select Host_Name,Status,Error_Msg| Format-Table -AutoSize -wrap| Out-String)  
    Stop-Transcript
}