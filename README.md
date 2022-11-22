# Collect-HCIRegistrationInfo
Collect Azure Stack HCI registration related logs and data

 Diagnostic data collector script for AZHCI registration related issues.                                                            
 This script update/install Az.StackHCI, Az.Resources, Az.Account modules.                                                          
 Installs the AzStackHci.EnvironmentChecker module then collect Cluster registration and Arc agent related data.                    



      
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
