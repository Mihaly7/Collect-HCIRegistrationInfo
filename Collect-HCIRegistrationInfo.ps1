######################################################################################################################################
#                                                                                                                                    #
# Diagnostic data collector script for AZHCI registration related issues.                                                            #
# This script update/install Az.StackHCI, Az.Resources, Az.Account modules.                                                          #
# Installs the AzStackHci.EnvironmentChecker module then collect Cluster registration and Arc agent related data.                    #
#                                                                                                                                    #
######################################################################################################################################

Function Collect-HCIRegistrationInfo
      <#
        .SYNOPSIS
        Collect Azure Stack HCI registration related logs and Azure Arc setup related logs.

        .DESCRIPTION
        This script update/install Az.StackHCI, Az.Resources, Az.Account modules, install the AzStackHci.EnvironmentChecker module then collect Cluster registration and Arc agent related data.
        It can run remotely or directly on the cluster. 
        
        !!! WARNING !!!
        This script installs nuget package provider on the cluster nodes.
        Update/Install powershell modules.
        
        .PARAMETER ClusterName
        Name of the cluster

        .PARAMETER WorkFolder 
        Working path where the data will be collected (current location by default)

        .PARAMETER ConnectionCheck
        Run Invoke-AzStackHciConnectivityValidation (enabled by default, disable with $false)

        .EXAMPLE 
        PS> Collect-HCIRegistrationInfo -ClusterName Cluster -ConnectionCheck $false

    #>
{
    Param 
    ( 
    $ClusterName = (Get-Cluster), #Name of the cluster
    $WorkFolder = (Get-Location), #Working folder location, default is where you run the cmdlet
    $ConnectionCheck = $true #Check connection
    )
 
# include az.accounts , az.resource updates before stackhci

$nodes = get-clusternode -Cluster $clustername
$path = New-Item -ItemType Directory -Path (Get-Item -Path $WorkFolder).FullName -Name $clustername"_RegistrationInfo" -Force
$path.fullname
foreach ($node in $nodes)
    {
        Write-Host "Checking node $node" -ForegroundColor Cyan
        $session = New-PSSession -ComputerName $Node.Name
        Invoke-Command -session $session -scriptblock {

        # Creating working folder
        New-Item -ItemType Directory -Path c:\ -Name $using:node -ErrorAction SilentlyContinue
        $ExportPath =  (Get-Item "C:\$using:node").FullName

        # Enabling debug log
        Write-Host "Setting debug log for HCISVC if not already" -NoNewLine
        $ErrorActionPreference = "Silentlycontinue"
        Wevtutil.exe sl /q /e:true Microsoft-AzureStack-HCI/Debug 
        $ErrorActionPreference = "continue"
        Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green

        #Installing nuget package provider
        Write-Host "Installing Package provider Nuget" -NoNewLine
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-File $ExportPath"\"$using:node'-nuget_install.txt'  
        Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
        # "Setting PsRepository named PSGallery to trusted"
        If ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted")
            {
                Write-Host "Setting PsRepository named PSGallery to trusted" -NoNewLine
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
            }
    
        #Update modules
        Write-Host "Update Modules" -NoNewLine   
        If (Get-InstalledModule Az.StackHCI) {Update-Module -Confirm:$False -ErrorAction SilentlyContinue} Else {Install-Module Az.StackHCI -AllowClobber -Confirm:$False -ErrorAction SilentlyContinue}
        If (Get-InstalledModule Az.Accounts) {Update-Module -Confirm:$False -ErrorAction SilentlyContinue} Else {Install-Module Az.Accounts -Confirm:$False -ErrorAction SilentlyContinue}
        If (Get-InstalledModule Az.Resources) {Update-Module -Confirm:$False -ErrorAction SilentlyContinue} Else {Install-Module Az.Resources -Confirm:$False -ErrorAction SilentlyContinue}
        Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
    
        
     
        # Cmdlets to drop in TXT and XML forms
                #
                # cmd is of the form "cmd arbitraryConstantArgs -argForComputerOrSessionSpecification"
                # will be trimmed to "cmd" for logging
                # _A_ token will be replaced with the chosen cluster access node
                # _C_ token will be replaced with node fqdn for cimsession/computername callouts
                # _N_ token will be replaced with node non-fqdn
    
        Write-Host "Collect registration related data" -NoNewLine
        $cmdlist = 
            @{C = 'Get-AzureStackHci'; F = $null},
            @{C = 'Get-AzureStackHCIArcIntegration'; F = $null},
            @{C = 'Get-ClusteredScheduledTask | fl *'; F = $null}
            
        Foreach ($cmd in $cmdlist)
                {
                                    
                    $cmdstr = $cmd.C
                    $file = $cmd.F

                    # Default rule: base cmdlet name no dash
                    if ($null -eq $file) {
                        $LocalFile = (Join-Path ($ExportPath+"\")((($cmdstr.split(' '))[0] -replace "-","")))
                    } else {
                        $LocalFile = (Join-Path ($ExportPath+"\")$file)
                    }

                    try {

                        $cmdex = $cmdstr #-replace '_C_',$using:Node -replace '_N_',$using:Node -replace '_A_',$using:Node
                        $out = Invoke-Expression $cmdex
                        # capture as txt and xml for quick analysis according to taste
                        $out | Format-Table -AutoSize | Out-File -Width 9999 -Encoding ascii -FilePath "$LocalFile.txt" -Confirm:$false
                        $out | Export-Clixml -Path "$LocalFile.xml" -confirm:$false                       
                        } 
                    catch {
                        Write-host "'$cmdex' failed for node $Node ($($_.Exception.Message))"
                    }
                }
        Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
        If ($using:connectioncheck -eq $true)
            {
            If (Get-Module AzStackHci.EnvironmentChecker -ErrorAction SilentlyContinue)
                {
                Invoke-AzStackHciConnectivityValidation -outputpath $ExportPath
                }
            Else
                {
                Find-Module -Name AzStackHci.EnvironmentChecker  | Install-Module -AllowClobber -Confirm:$false
                Invoke-AzStackHciConnectivityValidation -outputpath $ExportPath 
                }
            }
        Else 
            {
                Write-host "Connection check skipped"
            }
        
        # Collecting event logs    
            Write-host `n
            Write-host "Collecting system related logs" -NoNewLine
            $logPath = $ExportPath+"\"+$using:node+"-System.csv" ; Get-WinEvent -ComputerName $using:node -LogName System -Oldest | Export-Csv -Path $logPath
            $logPath = $ExportPath+"\"+$using:node+'-Application.csv' ; Get-WinEvent -ComputerName $using:node -LogName Application -Oldest | Export-Csv -Path $logPath
            $logPath = $ExportPath+"\"+$using:node+'-Admin.csv' ; Get-WinEvent -ComputerName $using:node -LogName Microsoft-AzureStack-HCI/Admin -Oldest | select TimeCreated, Id, LevelDisplayName,Message | Export-Csv -Path $logPath
            $logPath = $ExportPath+"\"+$using:node+'-Debug.csv' ; Get-WinEvent -ComputerName $using:node -LogName Microsoft-AzureStack-HCI/Debug -Oldest | select TimeCreated, Id, LevelDisplayName,Message | Export-Csv -Path $logPath
            $logPath = $ExportPath+"\"+$using:node+'-BootOp.csv' ; Get-WinEvent -ComputerName $using:node -LogName Microsoft-Windows-Kernel-Boot/Operational -Oldest | select TimeCreated, Id, LevelDisplayName,Message | Export-Csv -Path $logPath 
            $logPath = $ExportPath+"\"+$using:node+'-IOOp.csv' ; Get-WinEvent -ComputerName $using:node -LogName Microsoft-Windows-Kernel-IO/Operational -Oldest | select TimeCreated, Id, LevelDisplayName,Message | Export-Csv -Path $logPath 
            $logPath = $ExportPath+"\"+$using:node+'-systeminfo.txt' ; systeminfo.exe | out-file $logPath
        
        #ARC diagnostic
            Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
            Write-host "Collecting Arc agent related logs" -NoNewLine
            Azcmagent show | Out-File $ExportPath"\"$using:node'-Azcmagent.txt'
            Get-ChildItem -Path HKLM:\Cluster\ArcForServers | Out-File $ExportPath"\"$using:node'-ArcForServers_registry.txt' 
            Copy-Item -Path "C:\Windows\Tasks\ArcforServers\*" -Destination $ExportPath"\"
            Copy-Item -Path "C:\ProgramData\AzureConnectedMachineAgent\Log\*" -Destination $ExportPath"\"
            Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green

        }
        # Copy and compress data
        Write-Host "Copy data" -NoNewLine    
        Copy-Item -Path "c:\$node" -Recurse -Destination "$path\" -FromSession $session -force
        Remove-PSSession $session -Confirm:$false
        Write-host " - " -NoNewLine; Write-Host "OK" -ForegroundColor Green
    }

    #save output
    $date = (Get-Date -Format yyyyMMdd_HHMM).tostring()
    Compress-Archive -Path $path -DestinationPath $WorkFolder"\"$ClusterName"_RegistrationInfo_"$date".zip" 
    Write-host "Diagnostics finished. Check for the zip file: " (Get-ChildItem $WorkFolder"\"$ClusterName"_RegistrationInfo_"$date".zip").fullname
}
