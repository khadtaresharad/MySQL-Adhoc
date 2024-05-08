## MySQL single to MySQL Flexible server migration using Azure CLI
# Steps To-Do:


1.	Download the package zip file provided by CMF team named as `MySQL-Single-to-Flexi .zip`.

2.	Extract the `unzip MySQL-Single-to-Flexi.zip` file.

3.	Open command prompt -> run as administrator and browse the unzipped folder(CD path).
	Run `rename rename.txt rename.bat` and Execute the `rename.bat` (for Windows )
	Run `sh ./rename-linux.txt` ( for Linux )

4.	Open the Input file `Azure_Subscription.csv` and provide/add the Tenant ID & Subscription ID.

	If you have "CMF_MySQL_Server_Input_file.csv" input file ready which cointains single server info, go to step 7 
	otherwise proceed with next step to generate the input CSV file.

5. 	Execute `powershell .\CMF-MySQL-CLI-Windows.ps1` on command prompt.(for Windows )
	Execute `sudo pwsh .\CMF-MySQL-CLI-Windows.ps1`(for Linux )
	This will generate the CSV input file - "CMF_MySQL_Server_Input_file.csv".
	Also this will generate the single server info/log to output folder.
   	
6. 	Open the Inut file "CMF_MySQL_Server_Input_file.csv" make sure correct server data with approved columns. 
   	Mandatory fields are listed below...
	
7. 	Once input CSV file "CMF_MySQL_Server_Input_file.csv" was verified...
	execute  `powershell .\CMF-MySQL_Azure_SingleServer_to_Flexible.ps1` on command prompt.(for Windows )
	Execute `pwsh CMF-MySQL_Azure_SingleServer_to_Flexible.ps1`(for Linux )

8.	Once the execution completed, review final status table.Also you can check the output & Logs folder.

## more info
. Please refer to document “CMF - MySQL_Azure_Single_Server_to_Flexible - User Guide V1.0.docx” from the zip folder for more details.

## Update CMF_MySQL_Server_Input_file.csv 

"**Host_Name**","Resource_Group","**Port**","VCore","Auth_Type","**User_ID**","**Password**","**DB_Name**","Tenant","Subscription_ID","**Approval_Status**","SSL_Mode","SSL_Cert","**Destination**","Tier","sku-name","storage-size","admin-user","admin-password"

 Note:- **Mandatory Fields** 


