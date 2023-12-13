function exitCode
{
    Write-Host "-Ending Execution"
    Stop-Transcript
    exit
}

$folder = $PSScriptRoot

function Check-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

if (Check-Command -cmdname 'az') {
    Write-Host "Azure CLI is found..."
    $status="SUCCESS"
    $comments="Azure CLI Exists."
}
else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile $folder\Downloads\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi' # Remove-Item $folder\Downloads\AzureCLI.msi
    Write-Host "======================================================================================="  
    Write-Host "Azure CLI not found."  -BackgroundColor Red
    Write-Host "=======================================================================================" 
    $response = read-host "Do you want to continue download and install Azure CLI? 'Y' or 'N' : "

    if($response.ToUpper() -eq "Y")
    {
    try {Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLIInstaller.msi}
    catch{
        Write-Host "======================================================================================="  
        Write-Host "Error while invoking web request for Azure CLI Installer. Please make sure computer is connected to internet  "  -ForegroundColor Red  
        Write-Host "======================================================================================="  
        Write-Host "Please see the error below. Stopping execution ...          " 
        throw  $_.Exception.Response.StatusCode.Value__
        }

                                       
    # Install Azure CLI
    Write-Host '-Installing Azure CLI ...Please wait!' -ForegroundColor Green
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLIInstaller.msi /quiet'

    # Clean up the installer file
    Remove-Item .\AzureCLIInstaller.msi
    }

    elseif ($response.ToUpper() -eq "N")
    {
        Write-Host "Consent not provided for Azure CLI installation. Aborting the execution."  -BackgroundColor Red
        $status="FAILED"
        $comments="Azure CLI is mandatory for execution. Kindly install manually/re-execute and provide consent for Azure CLI installation."
        break
    }
    else
    {
        Write-Host "Invalid response. Exiting.."  -BackgroundColor Red
        $status="FAILED"
        $comments="Azure CLI is mandatory for execution. Kindly install manually/re-execute and provide consent for Azure CLI installation."
        break
    }

    if (Check-Command -cmdname 'az') {

    $status="SUCCESS"
    $comments=" Azure CLI Exists."
    }else{

    $status="FAILED"
    $comments="Azure CLI Installation successfuly initiated. Kindly validate and re-run the automation in a new Window."

    }
    
    
}

$Output = New-Object psobject -Property @{Validation_Type="Check Azure CLI is available";Status =$status;Comments=$comments}
return $Output