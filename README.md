# Collect-HCIRegistrationInfo
Collect Azure Stack HCI registration related logs and data

 Diagnostic data collector script for AZHCI registration related issues.                                                            
 This script update/install Az.StackHCI, Az.Resources, Az.Account modules.                                                          
 Installs the AzStackHci.EnvironmentChecker module then collect Cluster registration and Arc agent related data.                    

**Usage**
1. Download the ps1 file to your env 
2. Dot source it to import the function:
   
   C:\Temp\>. .\Collect-HCIRegistrationInfo
   
4. Run the function to collect data
   
   Collect-HciRegistrationInfo

   
      
        
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

    
