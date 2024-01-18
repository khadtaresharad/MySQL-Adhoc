#---------------------------------------------------------------------------------------------------------------------------*
#  Purpose        : Trigger Script for Information gathering of Azure MySQL Single Server
#  Schedule       : Ad-Hoc / On-Demand
#  Date           : 09-Oct-2023
#  Author         : Rackimuthu Kandaswamy , ArunKumar , Lekshmy MK
#  Version        : NA
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
# Powershell.exe -File .\CMF-MySQL-Trigger.ps1
#
$command = @"
    powershell.exe -File .\CMF-MySQL-Trigger.ps1
"@

cmd.exe /C $command

