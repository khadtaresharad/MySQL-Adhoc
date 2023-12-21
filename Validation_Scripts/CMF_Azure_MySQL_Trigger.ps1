#---------------------------------------------------------------------------------------------------------------------------*
#  Purpose        : Trigger Script for Azure MySQL Single Server to Flexible server migration
#  Schedule       : Ad-Hoc / On-Demand
#  Date           : 15-Dec-2023
#  Author         : Rackimuthu Kandaswamy , ArunKumar , Lekshmy MK, Madan
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
# Powershell.exe -File .\CMF-MySQL_Azure_SingleServer_to_Flexible.ps1
#
$command = @"
    powershell.exe -File .\CMF-MySQL_Azure_SingleServer_to_Flexible.ps1
"@

cmd.exe /C $command

