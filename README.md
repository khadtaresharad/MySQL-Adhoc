# Steps To-Do:

## Azure CLI
1.	Download the package zip file named `MySQL-Single-to-Flexi .zip`
2.	Extract the `unzip MySQL-Single-to-Flexi.zip` file.
3.	Run `rename rename.txt rename.bat` and Execute the `rename.bat` ( Windows ) 
4. 	Run `sh ./rename-linux.txt` ( Linux )
5.	Open the Input file `Azure_Subscription.csv` and provide the Tenant ID & Subscription ID 
6.	open the Inut file "CMF-MySQL_Single_Server_Input_file.csv" make sure correct server data with approved columns.
7. 	Execute CMF_Azure_MySQL_Trigger.ps1
8.	Once the execution completed, review final status table.Also you can check the output & Logs folder.

## Azure VM/On-premises
. Please refer to document “CMF - MySQL_Azure_Single_Server_to_Flexible - User Guide V1.0.docx” from the zip folder and share the details.

## Update CMF_MySQL_Server_Input_file.csv 
 "**Host_Name**","Resource_Group","**Port**","VCore","Auth_Type","**User_ID**","**Password**","**DB_Name**","Tenant","Subscription_ID","**Approval_Status**","SSL_Mode","SSL_Cert","**Destination**","Tier","sku-name","storage-size","admin-user","admin-password"


 Note:- **Mandatory Fields** 


