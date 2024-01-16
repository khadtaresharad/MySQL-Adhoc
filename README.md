# Steps To-Do:

## Azure CLI
1.	Download the package zip file named `MySQL-Single-to-Flexi .zip`
2.	Extract the `unzip MySQL-Single-to-Flexi.zip` file.
3.	Run `rename rename.txt rename.bat` and Execute the `rename.bat` ( Windows ) 
4. 	Run `sh ./rename-linux.txt` ( Linux )
5.	Open the Input file `Azure_Subscription.csv` and provide the Tenant ID & Subscription ID 
6.	Execute `powershell.exe .\CMF-MySQL-CLI-Windows.ps1` (Windows)
7. 	Execute `pwsh ./CMF-MySQL-CLI-Linux.ps1` (Linux)
8.	Once the execution completed, you can check the output & Logs folder.

## Azure VM/On-premises
. Please refer to document “CMF-ON-Prem_Server_Info_gather.docx” from the zip folder and share the details.

## Update CMF_MySQL_Server_Input_file.csv 
 "**Host_Name**","Resource_Group","**Port**","VCore","Auth_Type","**User_ID**","**Password**","**DB_Name**","Tenant","Subscription_ID","**Approval_Status**","SSL_Mode","SSL_Cert","**Destination**","Tier","sku-name","storage-size","admin-user","admin-password"


 Note:- **Mandatory Fields** 
## Server Info Gathering:
1.	Execute `powershell.exe .\CMF-MySQL-Windows.ps1` ( Windows )
2. Execute `pwsh ./CMF-MySQL-Linux.ps1` ( Linux )
3.	Once the execution completed, you can check the output & Logs folder.

## Zip and share output & log folders 

Kindly follow the execution instructions mentioned in attached documents. 
If there is/are any queries, please let us know, we will connect and check.
