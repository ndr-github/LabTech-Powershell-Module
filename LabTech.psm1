<#
.SYNOPSIS
    This is a PowerShell Module for LabTech.
    labtechconsulting.com
    labtechsoftware.com
    msdn.microsoft.com/powershell


.DESCRIPTION
    This is a set of commandlets to interface with the LabTech Agent v10.5

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
  
#>

#requires -version 3
if (-not ($PSVersionTable)) {Write-Output 'PS1 Detected. PowerShell Version 2.0 or higher is required.';return}
if (-not ($PSVersionTable) -or $PSVersionTable.PSVersion.Major -lt 3 ) {Write-Verbose 'PS2 Detected. PowerShell Version 3.0 or higher may be required for full functionality';return}

#Module Version
$ModuleVersion = "1.0"

#Ignore SSL errors
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
 
#region-[Functions]------------------------------------------------------------

Function Get-LTServiceInfo{ 
<#
.SYNOPSIS
    This function will pull all of the registy data into an object.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    [CmdletBinding()]
    Param ()
      
  Begin{
    Write-Verbose "Verbose: Checking for registry keys."
    if ((Test-Path 'HKLM:\SOFTWARE\LabTech\Service') -eq $False){
        Write-Error "ERROR: Unable to find information on LTSvc. Make sure the service is running."
        Return
    }
    $exclude = "PSParentPath","PSChildName","PSDrive","PSProvider","PSPath"
  }#End Begin
  
  Process{
    Try{
        Get-ItemProperty HKLM:\SOFTWARE\LabTech\Service -ErrorAction Stop | Select * -exclude $exclude
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was a problem reading the registry keys. $($Error[0])"
    }#End Catch
  }#End Process
  
  End{
    if ($?){
        $key
    }    
  }#End End
}#End Function Get-LTServiceInfo

Function Get-LTServiceSettings{ 
<#
.SYNOPSIS
    This function will pull the registy data from HKLM:\SOFTWARE\LabTech\Service\Settings into an object.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    [CmdletBinding()]
    Param ()
      
  Begin{
    Write-Verbose "Verbose: Checking for registry keys."
    if ((Test-Path 'HKLM:\SOFTWARE\LabTech\Service\Settings') -eq $False){
        Write-Error "ERROR: Unable to find LTSvc settings. Make sure the service is running." -ErrorAction Stop
    }
    $exclude = "PSParentPath","PSChildName","PSDrive","PSProvider","PSPath"
  }#End Begin
  
  Process{
    Try{
        Get-ItemProperty HKLM:\SOFTWARE\LabTech\Service\Settings -ErrorAction Stop | Select * -exclude $exclude
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was a problem reading the registry keys. $($Error[0])" -ErrorAction Stop
    }#End Catch
  }#End Process
  
  End{
    if ($?){
        $key
    }    
  }#End End
}#End Function Get-LTServiceSettings

Function Restart-LTService{
<#
.SYNOPSIS
    This function will restart the LabTech Services.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
  
    [CmdletBinding()]
    Param()
  
  Begin{
    if (!(Get-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue)) {
        Write-Error "ERROR: Services NOT Found" $($Error[0]) -ErrorAction Stop
    }
  }#End Begin
  
  Process{
    Try{
      Stop-LTService
      Start-LTService
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was an error restarting the services. $($Error[0])" -ErrorAction Stop
    }#End Catch
  }#End Process
  
  End{
    If($?){Write-Output "Services Restarted successfully."}
    Else {$Error[0]}
  }#End End
}#End Function Restart-LTService

Function Stop-LTService{
<#
.SYNOPSIS
    This function will stop the LabTech Services.

.DESCRIPTION
    This funtion will verify that the LabTech services are present then attempt to stop them.
    It will then check for any remaining LabTech processes and kill them.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#>   
    [CmdletBinding()]
    Param()
  
  Begin{
    if (!(Get-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue)) {
        Write-Error "ERROR: Services NOT Found" $($Error[0]) -ErrorAction Stop
    }
  }#End Begin
  
  Process{
    Try{
        Stop-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue
        Get-Process | Where-Object -Property ProcessName -In -Value 'LTTray','LTSVC','LTSvcMon' | Stop-Process -Force -ErrorAction Stop
    }#End Try
    
    Catch{
        Write-Error "ERROR: There was an error stoping the LabTech proccesses. $($Error[0])" -ErrorAction Stop
    }#End Catch
  }#End Process
  
  End{
    If($?){
        Write-Output "Services Stopped successfully."
    }
    Else {$Error[0]}
  }#End End
}#End Function Stop-LTService

Function Start-LTService{
<#
.SYNOPSIS
    This function will start the LabTech Services.

.DESCRIPTION
    This function will verify that the LabTech services are present.
    It will then check for any proccess that is using port 42000 and kill it.
    Next it will start the services.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development

    Update Date: 5/11/2017
    Purpose/Change: added check for non standard port number and set services to auto start

.LINK
    http://labtechconsulting.com
#>
    
    [CmdletBinding()]
    Param()   
   
    Begin{
        if (!(Get-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue)) {
            Write-Error "ERROR: Services NOT Found" $($Error[0]) -ErrorAction Stop
        }
        #Kill all processes that are using the tray port 
        [array]$process = @()
        $Port = (Get-LTServiceInfo).TrayPort
        $netstat = netstat -a -o -n | Select-String $Port
        foreach ($line in $netstat){
            $process += ($line -split '  {3,}')[-1]
        }
        $process = $process | Sort-Object | Get-Unique
        foreach ($proc in $process){
            if ($proc -ne 0) {
                Write-Output "Process ID:$proc is using port $Port. Killing process."
                Stop-Process -ID $proc -Force -Verbose
            }
        }
    }#End Begin
  
    Process{
        Try{
            Start-Service 'LTService','LTSvcMon'
            Set-Service 'LTService' -StartupType Automatic
            Set-Service 'LTSvcMon' -StartupType Automatic
        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error starting theLabTech services. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End
    {
        If($?){
            Write-Output "Services Started successfully."
        }
        else{
             $($Error[0])
        }
    }#End End
}#End Function Start-LTService

Function Uninstall-LTService{
<#
.SYNOPSIS
    This function will uninstall the LabTech agent from the machine.

.DESCRIPTION
    This function will stop all the LabTech services. It will then download the current agent install MSI and issue an uninstall command.
    It will then download and run Agent_Uninstall.exe from the LabTech server. It will then scrub any remaining file/registry/service.

.PARAMETER Server
    This is the URL to your LabTech server. 
    example: https://lt.domain.com
    This is used to download the uninstallers.
    If no server is provided the uninstaller will use Get-LTServiceInfo to get the server address.

.PARAMETER Backup
    This will run a 'New-LTServiceBackup' before uninstalling.

.EXAMPLE
    Uninstall-LTService
    This will uninstall the LabTech agent using the server address in the registry.

.EXAMPLE
    Uninstall-LTService -Server 'https://lt.domain.com'
    This will uninstall the LabTech agent using the provided server URL to download the uninstallers.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 

    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]$Server = (Get-LTServiceInfo -ErrorAction SilentlyContinue).'Server Address',
        [switch]$Backup
    )   
    Begin{
        If (!([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))) {
            Throw "Needs to be ran as Administrator" 
        }
        if (!$Server){
            $Server = Read-Host -Prompt 'Provide the URL to you LabTech server (https://labtech.labtechconsulting.com)'
            if ($server -notlike 'http*://*'){
                Write-Error 'Server address is not formatted correctly. Example: https://labtech.labtechconsulting.com' -ErrorAction Stop
            }        
        }
        if($Backup){
            New-LTServiceBackup
        }
        $Server = ($Server.Split('|'))[0].trim()
        Write-Output "Starting uninstall."
        $BasePath = $(Get-LTServiceInfo -ErrorAction SilentlyContinue).BasePath
        if (!$BasePath){$BasePath = "$env:windir\LTSVC"}
        New-PSDrive HKU Registry HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
        $regs = @( 'Registry::HKEY_LOCAL_MACHINE\Software\LabTechMSP',
          'Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\LabTech\Service',
          'Registry::HKEY_CLASSES_ROOT\Installer\Dependencies\{3426921d-9ad5-4237-9145-f15dee7e3004}',
          'Registry::HKEY_CLASSES_ROOT\Installer\Dependencies\{3F460D4C-D217-46B4-80B6-B5ED50BD7CF5}',
          'Registry::HKEY_CLASSES_ROOT\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F',
          'Registry::HKEY_CURRENT_USER\SOFTWARE\LabTech\Service',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{3426921d-9ad5-4237-9145-f15dee7e3004}',
          'Registry::HKEY_CURRENT_USER\SOFTWARE\LabTech\LabVNC',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Appmgmt\{40bf8c82-ed0d-4f66-b73e-58a3d7ab6582}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{09DF1DCA-C076-498A-8370-AD6F878B6C6A}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{15DD3BF6-5A11-4407-8399-A19AC10C65D0}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{3C198C98-0E27-40E4-972C-FDC656EC30D7}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{459C65ED-AA9C-4CF1-9A24-7685505F919A}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{7BE3886B-0C12-4D87-AC0B-09A5CE4E6BD6}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{7E092B5C-795B-46BC-886A-DFFBBBC9A117}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{9D101D9C-18CC-4E78-8D78-389E48478FCA}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{B0B8CDD6-8AAA-4426-82E9-9455140124A1}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{B1B00A43-7A54-4A0F-B35D-B4334811FAA4}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{BBC521C8-2792-43FE-9C91-CCA7E8ACBCC9}',
          'Registry::HKEY_CLASSES_ROOT\CLSID\{C59A1D54-8CD7-4795-AEDD-F6F6E2DE1FE7}',
          'Registry::HKEY_CLASSES_ROOT\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Managed\\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F',
          'Registry::HKEY_CURRENT_USER\Software\Microsoft\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F',
          'HKU:\*\Software\Microsoft\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F',
          'Registry::HKEY_CLASSES_ROOT\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\D1003A85576B76D45A1AF09A0FC87FAC\InstallProperties',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall{58A3001D-B675-4D67-A5A1-0FA9F08CF7CA}',
          'Registry::HKEY_CLASSES_ROOT\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC',
          'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC',
          'Registry::HKEY_CLASSES_ROOT\LabTech'
)
        $installer = $server + '/Labtech/Deployment.aspx?Probe=1&installType=msi&MSILocations=1'
        $installerTest = invoke-webrequest $installer -DisableKeepAlive -UseBasicParsing -Method head
        if ($installerTest.StatusCode -ne 200) {
            Write-Error 'Unable to download Agent_Install from server.' -ErrorAction Stop
        }
        $uninstaller = $server +'/Labtech/Deployment.aspx?probe=1&ID=-2'
        $uninstallerTest = invoke-webrequest $uninstaller -DisableKeepAlive -UseBasicParsing -Method head
        if ($uninstallerTest.StatusCode -ne 200) {
            Write-Error 'Unable to download Agent_Uninstall from server.' -ErrorAction Stop
        }
        $xarg = "/x $installer /qn"
    }#End Begin
  
    Process{
        Try{
            #Kill all running processes from %ltsvcdir%   
            if(Test-Path $BasePath){
                $Executables = (Get-ChildItem $BasePath -Filter *.exe -Recurse -ErrorAction SilentlyContinue).Name.Trim('.exe')
                ForEach($Item in $Executables){
                    Stop-Process -Name $Item -Force -ErrorAction SilentlyContinue
                }

                #Unregister DLL
                regsvr32 /u $BasePath\wodVPN.dll /s            
            }     
            
            #Cleanup previous uninstallers
            Remove-Item 'Uninstall.exe','Uninstall.exe.config' -ErrorAction SilentlyContinue

            #Run MSI uninstaller for current installer
            Start-Process -Wait -FilePath msiexec -ArgumentList $xarg

            #Download and run Agent_Uninstall.exe
            Invoke-RestMethod -Uri $uninstaller -OutFile "$env:windir\temp\Agent_Uninstall.exe"
            Start-Process "$env:windir\temp\Agent_Uninstall.exe" -Wait
            Start-Sleep -Seconds 10

            #Remove %ltsvcdir%
            Remove-Item -Recurse -Force $BasePath -ErrorAction SilentlyContinue

            #Remove all registry keys
            foreach ($reg in $regs) {
                remove-item -Recurse -Path $reg -ErrorAction SilentlyContinue
            }

            #Remove Services
            Start-Process -FilePath sc -ArgumentList "delete LTService" -Wait
            Start-Process -FilePath sc -ArgumentList "delete LTSvcMon" -Wait

        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error durring the uninstall process. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        If($?){
            Write-Output "LabTech has been successfully uninstalled."
        }
        else {
            $($Error[0])
        }
    }#End End
}#End Function Uninstall-LTService

Function Install-LTService{
<#
.SYNOPSIS
    This function will install the LabTech agent on the machine.

.DESCRIPTION
    This function will install the LabTech agent on the machine with the specified server/password/location.

.PARAMETER Server
    This is the URL to your LabTech server. 
    example: https://lt.domain.com
    This is used to download the uninstallers.
    (Get-LTServiceInfo).'Server Address'

.PARAMETER Password
    This is the server password that agents use to authenticate with the LabTech server.
    (Get-LTServiceInfo).ServerPassword

.PARAMETER LocationID
    This is the LocationID of the location that the agent will be put into.
    (Get-LTServiceInfo).LocationID

.PARAMETER Rename
    This will call Rename-LTAddRemove after the install.

.PARAMETER Hide
    This will call Hide-LTAddRemove after the install.

.EXAMPLE
    Install-LTService -Server https://lt.domain.com -Password sQWZzEDYKFFnTT0yP56vgA== -LocationID 42
    This will install the LabTech agent using the provided server URL, Password, and LocationID.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Server,
        [Parameter(Mandatory=$True)]
        [string]$Password,
        [Parameter(Mandatory=$True)]
        [int]$LocationID,
        [string]$Rename,
        [switch]$Hide
	    
    )   
    Begin{
        If (!([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))) {
            Write-Error "Needs to be ran as Administrator" -ErrorAction Stop
        }
        
        $DotNET = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} | Select -ExpandProperty Version
        if(!($DotNet -like '3.5.*')){
            Write-Output ".NET 3.5 Needs installing."
            #Install-WindowsFeature Net-Framework-Core
            $OSVersion = [Version](Get-CimInstance Win32_OperatingSystem).version

            if($OSVersion -gt 6.2){
                try{
                    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All | Out-Null
                }
                catch{
                    Write-Error "ERROR: .NET 3.5 install failed." -ErrorAction Continue
                    Write-Error $Result -ErrorAction Stop
                }
            }
            else{
                $Result = Dism /online /get-featureinfo /featurename:NetFx3 
                If($Result -contains "State : Enabled"){ 
                    Write-Warning ".Net Framework 3.5 has been installed and enabled." 
                } 
                Else{
                    Write-Error "ERROR: .NET 3.5 install failed. $Result" -ErrorAction Stop
                } 
            }
            
            $DotNET = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where-Object{ $_.PSChildName -match '^(?!S)\p{L}'} | Select -ExpandProperty Version
        }
        if($DotNet -like '3.5.*'){
            if (Get-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue) {
                Write-Error "LabTech is already installed." -ErrorAction Stop
            }

            if ($server -notlike 'http*://*'){
                Write-Error 'Server address is not formatted correctly. Example: http://labtech.labtechconsulting.com' -ErrorAction Stop
            }
            $installer = "$($Server)/Labtech/Deployment.aspx?Probe=1&installType=msi&MSILocations=$LocationID"
            $installerTest = invoke-webrequest $installer -DisableKeepAlive -UseBasicParsing -Method head
            if ($installerTest.StatusCode -ne 200) {
                Write-Error 'Unable to download Agent_Install from server.' -ErrorAction Stop
            }
            else{
                New-Item $env:windir\temp\LabTech\Installer -type directory -ErrorAction SilentlyContinue | Out-Null
                Invoke-RestMethod -Uri $installer -OutFile $env:windir\temp\LabTech\Installer\Agent_Install.msi
            }

            $iarg = "/i  $env:windir\temp\LabTech\Installer\Agent_Install.msi SERVERADDRESS=$Server SERVERPASS=$Password LOCATION=$LocationID /qn /l $env:windir\temp\LabTech\LTAgentInstall.log"
            Write-Output "Starting install."
        }
        else{
            Write-Error "ERROR: .NET 3.5 is not detected and the install method has failed." -ErrorAction Stop
        }

        
    }#End Begin
  
    Process{
        Try{
            Start-Process -Wait -FilePath msiexec -ArgumentList $iarg
            Write-Host -NoNewline "Waiting for agent to register." 
            $timeout = new-timespan -Minutes 3
            $sw = [diagnostics.stopwatch]::StartNew()
            while (((Get-LTServiceInfo -ErrorAction SilentlyContinue).ID -lt 1 -or !(Get-LTServiceInfo -ErrorAction SilentlyContinue).ID) -and $sw.elapsed -lt $timeout){
                Write-Host -NoNewline '.'
                Start-Sleep 2
            }
            if ($Hide){Hide-LTAddRemove}
        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error durring the install process. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        If((Get-LTServiceInfo).ID -gt 1){
            Write-Host ""
            Write-Output "LabTech has been installed successfully. Agent ID: $((Get-LTServiceInfo).ID) LocationID: $((Get-LTServiceInfo).LocationID)"
            
            if($Rename){
                Rename-LTAddRemove -Name $Rename
            }
        }
        else {
            Write-Output "ERROR: There was an error installing LabTech. Check the log, $($env:windir)\temp\LabTech\LTAgentInstall.log" 
            Write-Output $($Error[0])
        }
    }#End End
}#End Function Install-LTService

Function Reinstall-LTService{
<#
.SYNOPSIS
    This function will reinstall the LabTech agent from the machine.

.DESCRIPTION
    This script will atempt to pull all current settings from machine and issue an 'Uninstall-LTService' 'Reinstall-LTService' with gathered information. 
    If the function is unable to find settings it will ask for needed paramaters. 

.PARAMETER Server
    This is the URL to your LabTech server. 
    example: https://lt.domain.com
    This is used to download the uninstallers.
    If no server is provided the uninstaller will use Get-LTServiceInfo to get the server address.
    If it is unable to find LT currently installed it will try Get-LTServiceInfoBackup

.PARAMETER Password
    This is the Server Password to your LabTech server. 
    example: sRWyzEF0KaFzHTnyP56vgA==
    You can find this from a configured agent with, '(Get-LTServiceInfo).ServerPassword'
    
.PARAMETER LocationID
    The LocationID of the location that you want the agent in
    example: 555

.PARAMETER Backup
    This will run a New-LTServiceBackup comand before uninstalling.

.PARAMETER Hide
    Will remove from add-remove programs

.PARAMETER Rename
    This will call Rename-LTAddRemove to rename the install in Add/Remove Programs

.EXAMPLE
    Uninstall-LTService 
    This will uninstall the LabTech agent using the server address in the registry.

.EXAMPLE
    Uninstall-LTService -Server 'https://lt.domain.com'
    This will uninstall the LabTech agent using the provided server URL to download the uninstallers.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    Param(
        [string]$Server,
        [string]$Password,
        [string]$LocationID,
        [switch]$Backup,
        [switch]$Hide,
        [string]$Rename
    )
           
    Begin{
        
        # Gather install stats from registry or backed up settings
        $Settings = Get-LTServiceInfo -ErrorAction SilentlyContinue
        if(!$Settings){
            $Settings = Get-LTServiceInfoBackup -ErrorAction SilentlyContinue
        }
        if($Settings){
            $Server = $Settings.'Server Address'
            $Password = $Settings.ServerPassword
            $LocationID = $Settings.LocationID
        }
        if (!$Server){
            $Server = Read-Host -Prompt 'Provide the URL to you LabTech server (https://lt.domain.com):'
            if ($server -notlike 'http*://*'){
                Write-Error 'Server address is not formatted correctly. Example: https://labtech.labtechconsulting.com' -ErrorAction Stop
            }
        }
        if (!$Password){
            $Password = Read-Host -Prompt 'Provide the server password:'
        }
        if (!$LocationID){
            $LocationID = Read-Host -Prompt 'Provide the LocationID'
        }
        if($Rename){
            $Rename = "-Rename $Rename"
        }

        $Server = ($Server.Split('|'))[0].trim()

        Write-host "Reinstalling LabTech with the following information, -Server $Server -Password $Password -LocationID $LocationID $Rename"
    }#End Begin
  
    Process{
        if($Backup){
            New-LTServiceBackup
        }
        Try{
            Uninstall-LTService -Server $Server
            Start-Sleep 10
            Install-LTService -Server $Server -Password $Password -LocationID $LocationID -Hide:$Hide $Rename
        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error durring the reinstall process. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        If($?){
        }
        else {
            $($Error[0])
        }
    }#End End
}#End Function Reinstall-LTService

Function Get-LTError{
<#
.SYNOPSIS
    This will pull the %ltsvcdir%\LTErrors.txt file into an object.

.EXAMPLE
    Get-LTError | where {(Get-date $_.Time) -gt (get-date).AddHours(-24)}
    Get a list of all errors in the last 24hr

.EXAMPLE
    Get-LTError | Out-Gridview
    Open the log file in a sortable searchable window.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 

    [CmdletBinding()]
    Param()
    
    Begin{
        $BasePath = $(Get-LTServiceInfo -ErrorAction SilentlyContinue).BasePath
        if (!$BasePath){$BasePath = "$env:windir\LTSVC"}
        if ($(Test-Path -Path $BasePath\LTErrors.txt) -eq $False) {
            Write-Error "ERROR: Unable to find log." $($Error[0]) -ErrorAction Stop
        }
    }#End Begin
  
    Process{
        Try{
            $errors = Get-Content "$BasePath\LTErrors.txt"
            $errors = $errors -join ' ' -split ':::'
            foreach($Line in $Errors){
                $items = $Line -split "`t" -replace ' - ',''
                if($items[1]){
                    $object = New-Object -TypeName PSObject
                    $object | Add-Member -MemberType NoteProperty -Name ServiceVersion -Value $items[0]
                    $object | Add-Member -MemberType NoteProperty -Name Timestamp -Value $([datetime]$items[1])
                    $object | Add-Member -MemberType NoteProperty -Name Message -Value $items[2]
                    Write-Output $object
                }
            }
            
        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error reading the log. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        if ($?){
        }
        Else {$Error[0]}
        
    }#End End
}#End Function Get-LTError


Function Reset-LTService{
<#
.SYNOPSIS
    This function will remove local settings on the aggent.

.DESCRIPTION
    This function can remove some of the agents local settings.
    ID, MAC, LocationID
    The function will stop the services, make the change, then start the services.
    Resetting all of these will force the agent to check in as a new agent.
    If you have MAC filtering enabled it should check back in with the same ID.
    This function is usefull for duplicate agents.

.PARAMETER ID
    This will reset the AgentID of the computer

.PARAMETER Location
    This will reset the LocationID of the computer

.PARAMETER MAC
    This will reset the MAC of the computer

.EXAMPLE
    Reset-LTService
    This resets the ID, MAC and LocationID on the agent. 

.EXAMPLE
    Reset-LTService -ID
    This resets only the ID of the agent.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 

    [CmdletBinding()]
    Param(
        [switch]$ID,
        [switch]$Location,
        [switch]$MAC
	    
    )   
    
    Begin{
        if (!(Get-Service 'LTService','LTSvcMon' -ErrorAction SilentlyContinue)) {
            Write-Error "ERROR: LabTech Services NOT Found" $($Error[0]) -ErrorAction Stop
        }
        $Reg = 'HKLM:\Software\LabTech\Service'
        if (!($ID -or $LocationID -or $MAC)){
            $ID=$true
            $Location=$true
            $MAC=$true
        }
        Write-Output "OLD ID: $((Get-LTServiceInfo).ID) LocationID: $((Get-LTServiceInfo).LocationID) MAC: $((Get-LTServiceInfo).MAC)"
        
    }#End Begin
  
    Process{
        Try{
            Stop-LTService
            if ($ID) {
                Write-Output ".Removing ID"
                Remove-ItemProperty -Name ID -Path $Reg -ErrorAction SilentlyContinue            
            }
            if ($Location) {
                Write-Output ".Removing LocationID"
                Remove-ItemProperty -Name LocationID -Path $Reg -ErrorAction SilentlyContinue
            }
            if ($MAC) {
                Write-Output ".Removing MAC"
                Remove-ItemProperty -Name MAC -Path $Reg -ErrorAction SilentlyContinue
            }
            Start-LTService
            $timeout = new-timespan -Minutes 1
            $sw = [diagnostics.stopwatch]::StartNew()
            While (!(Get-LTServiceInfo).ID -or !(Get-LTServiceInfo).LocationID -or !(Get-LTServiceInfo).MAC -and $sw.elapsed -lt $timeout){
                Write-Host -NoNewline '.'
                Start-Sleep 2
            }

        }#End Try
    
        Catch{
            Write-Error "ERROR: There was an error durring the reset process. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        if ($?){
            Write-Output ""
            Write-Output "NEW ID: $((Get-LTServiceInfo).ID) LocationID: $((Get-LTServiceInfo).LocationID) MAC: $((Get-LTServiceInfo).MAC)"
        }
        Else {$Error[0]}
    }#End End
}#End Function Get-LTError

Function Hide-LTAddRemove{
<#
.SYNOPSIS
    This function hides the LabTech install from add/remove programs list.

.DESCRIPTION
    This function will rename the DisplayName registry key to hide it from the add/remove programs list.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#>
    [CmdletBinding()]
    Param()

    Begin{
        $RegRoots = 'HKLM:\SOFTWARE\Classes\Installer\Products\C4D064F3712D4B64086B5BDE05DBC75F','HKLM:\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC'
        foreach($RegRoot in $RegRoots){
            if (Get-ItemProperty $RegRoot -Name ProductName -ErrorAction SilentlyContinue) {
                Write-Output "LabTech found in add/remove programs."
            }
            else {
                if (Get-ItemProperty $RegRoot -Name HiddenProductName -ErrorAction SilentlyContinue) {
                    Write-Error "LabTech already hidden from add/remove programs." -ErrorAction Stop
                }    
            }
        }
        
    }#End Begin
  
    Process{
        Try{
            Rename-ItemProperty $RegRoot -Name ProductName -NewName HiddenProductName
        }#End Try
    
        Catch{
            Write-Error "There was an error renaming the registry key. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        if($?){
            Write-Output "LabTech is now hidden from Add/Remove Programs."
        }
        else {$Error[0]}
    }#End End
}#End Function Hide-LTAddRemove

Function Show-LTAddRemove{
<#
.SYNOPSIS
    This function shows the LabTech install in the add/remove programs list.

.DESCRIPTION
    This function will rename the HiddenDisplayName registry key to show it in the add/remove programs list.
    If there is not HiddenDisplayName key the function will import a new entry.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#>
    [CmdletBinding()]
    Param()

    Begin{
        $RegRoots = 'HKLM:\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC'
    }#End Begin
  
    Process{
        Try{
            foreach($RegRoot in $RegRoots){

                if (Get-ItemProperty $RegRoot -Name HiddenProductName -ErrorAction SilentlyContinue){
                    Rename-ItemProperty $RegRoot -Name HiddenProductName -NewName ProductName
                }
                else{
                    $RegImport = @'
[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC]
"PackageCode"="8059C8AD908AB434A9F2225AF86355C2"
"Language"=dword:00000409
"Version"=dword:0b00016d
"Assignment"=dword:00000001
"AdvertiseFlags"=dword:00000184
"ProductIcon"="C:\\WINDOWS\\Installer\\{58A3001D-B675-4D67-A5A1-0FA9F08CF7CA}\\LabTeCh.ico"
"InstanceType"=dword:00000000
"AuthorizedLUAApp"=dword:00000000
"DeploymentFlags"=dword:00000003
"Clients"=hex(7):3a,00,00,00,00,00
"ProductName"="LabTech® Software Remote Agent"
'@
                    $RegImport | Out-File "$env:TEMP\LT.reg" -Force
                    Start-Process -Wait -FilePath reg -ArgumentList "import $($env:TEMP)\LT.reg"
                    Remove-Item "$env:TEMP\LT.reg" -Force
                    New-ItemProperty -Path "$RegRoot\SourceList" -Name LastUsedSource -Value "u;1;$(((Get-LTServiceInfo).'Server Address').Split(';'))/Labtech/" -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path "$RegRoot\SourceList\URL" -Name 1 -Value "$(((Get-LTServiceInfo).'Server Address').Split(';'))/Labtech/" -PropertyType ExpandString -Force | Out-Null
                }
            }
        }#End Try
    
        Catch{
            Write-Error "There was an error renaming the registry key. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        if ($?) {
            Write-Output "LabTech is now shown in Add/Remove Programs."
        }
        Else{$Error[0]}
    }#End End
}#End Function Show-LTAddRemove

Function Test-LTPorts{
<#
.SYNOPSIS
    This function will attempt to connect to all required TCP ports.

.DESCRIPTION
    The function will make sure that LTTray is using UDP 42000.
    It will then test all the required TCP ports.

.PARAMETER Quiet
    This will return a bool for connectivity to the Server

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development

    Update Date:    5/11/2017 
    Purpose/Change: Quiet feature

.LINK
    http://labtechconsulting.com
#>
    [CmdletBinding()]
    Param(
        [switch]$Quiet
    )

    Begin{
        Function TestPort{
        Param(
            [parameter(ParameterSetName='ComputerName', Position=0)]
            [string]
            $ComputerName,

            [parameter(ParameterSetName='IP', Position=0)]
            [System.Net.IPAddress]
            $IPAddress,

            [parameter(Mandatory=$true , Position=1)]
            [int]
            $Port

            )

        $RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};
    
        $test = New-Object System.Net.Sockets.TcpClient;
        Try
        {
            Write-Output "Connecting to $($RemoteServer):$Port (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Output "Connection successful";
        }
        Catch
        {
            Write-Output "ERROR: Connection failed";
            $Global:PortTestError = 1
        }
        Finally
        {
            $test.Close();
        }

    }#End Function TestPort
        $Servers = (((Get-LTServiceInfo -ErrorAction SilentlyContinue|Select-object -ExpandProperty 'Server Address').Split('|')) -replace("(http|https)://",'')|Foreach {$_.Trim()})
        [array]$process = @()
    }#End Begin
  
      Process{
        if($Quiet){
            Test-Connection $Servers -Quiet
            return
        }
        Try{
            #Get all processes that are using port 42000
            $netstat = netstat -a -o -n | Select-String 42000
            foreach ($line in $netstat) {
                $process += ($line -split '  {3,}')[-1]
            }
            $process = $process | Get-Unique;
            foreach ($proc in $process) {
                if ((Get-Process -id $proc).ProcessName -eq 'LTSvc') {
                    Write-Output "LTSvc is using port 42000"
                }
                else {
                    Write-Output "Error: $((Get-Process -id $proc).ProcessName) is using port 42000"
                }
            }
    
            foreach ($Server in $Servers) {
                Write-Output "Testing connectivity to required TCP ports"
                TestPort -ComputerName $Server -Port 70
                TestPort -ComputerName $Server -Port 80
                TestPort -ComputerName $Server -Port 443
                TestPort -ComputerName mediator.labtechsoftware.com -Port 8002
            }

        }#End Try
    
        Catch{
          Write-Error "ERROR: There was an error testing the ports. $($Error[0])" -ErrorAction Stop
        }#End Catch
      }#End Process
  
      End{
        If($?){
            if(!$Quiet){
                Write-Output "Finished"
            }          
        }
        else{$Error[0]}
      }#End End

}#End Function Test-LTPorts

Function Get-LTLogging{ 
<#
.SYNOPSIS
    This function will pull the logging level of the LabTech service.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    [CmdletBinding()]
    Param ()
      
  Begin{
    Write-Verbose "Verbose: Checking for registry keys."
    if ((Test-Path 'HKLM:\SOFTWARE\LabTech\Service\settings') -eq $False){
        Write-Error "ERROR: Unable to find logging settings for LTSvc. Make sure the service is running." -ErrorAction Stop
    }
  }#End Begin
  
  Process{
    Try{
        $Value = (Get-LTServiceSettings).Debuging
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was a problem reading the registry key. $($Error[0])" -ErrorAction Stop
    }#End Catch
  }#End Process
  
  End{
    if ($?){
        if($value -eq 1){
            Write-Output "Current logging level: Normal"
        }
        elseif($value -eq 1000){
            Write-Output "Current logging level: Verbose"
        }
        else{
            Write-Error "ERROR: Unknown Logging level $((Get-LTServiceInfo).Debuging)" -ErrorAction Stop
        }
    }    
  }#End End
}#End Function Get-LTLogging

Function Set-LTLogging{ 
<#
.SYNOPSIS
        This function will set the logging level of the LabTech service.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
   Param (
        [switch]$Normal,
        [switch]$Verbose
    )

      
  Begin{
    if ($Normal -ne $true -and $Verbose -ne $true ){
        Write-Error "Please provide a logging level. -Normal or -Verbose" -ErrorAction Stop
    }

  }#End Begin
  
  Process{
    Try{
        Stop-LTService
        if ($Normal){
            Set-ItemProperty HKLM:\SOFTWARE\LabTech\Service\Settings -Name 'Debuging' -Value 1
        }
        if($Verbose){
            Set-ItemProperty HKLM:\SOFTWARE\LabTech\Service\Settings -Name 'Debuging' -Value 1000
        }
        Start-LTService
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was a problem writing the registry key. $($Error[0])" -ErrorAction Stop
    }#End Catch
  }#End Process
  
  End{
    if ($?){
        Get-LTLogging          
    }    
  }#End End
}#End Function Set-LTSLogging

Function Get-LTProbeErrors {
<#
.SYNOPSIS
    This will pull the %ltsvcdir%\LTProbeErrors.txt file into an object.

.EXAMPLE
    Get-LTProbeErrors | where {(Get-date $_.Time) -gt (get-date).AddHours(-24)}
    Get a list of all errors in the last 24hr

.EXAMPLE
    Get-LTProbeErrors | Out-Gridview
    Open the log file in a sortable searchable window.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  3/14/2016
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 

    [CmdletBinding()]
    Param()
    
    Begin{
        $BasePath = $(Get-LTServiceInfo -ErrorAction SilentlyContinue).BasePath
        if (!$BasePath){$BasePath = "$env:windir\LTSVC"}
        if ($(Test-Path -Path $BasePath\LTProbeErrors.txt) -eq $False) {
            Write-Error "ERROR: Unable to find log." $($Error[0]) -ErrorAction Stop
        }
    }#End Begin
    process{
        $errors = Get-Content $BasePath\LTProbeErrors.txt
        $errors = $errors -join ' ' -split ':::'
        foreach($Line in $Errors){
            $items = $Line -split "`t" -replace ' - ',''
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name ServiceVersion -Value $items[0]
            $object | Add-Member -MemberType NoteProperty -Name Timestamp -Value $([datetime]$items[1])
            $object | Add-Member -MemberType NoteProperty -Name Message -Value $items[2]
            Write-Output $object
        }
    }
    End{
        if ($?){
        }
        Else {$Error[0]}
        
    }#End End
}#End Function Get-LTProbeErrors

Function New-LTServiceBackup {
<#
.SYNOPSIS
    This function will backup all the reg keys to 'HKLM\SOFTWARE\LabTechBackup'
    This will also backup those files to "$((Get-LTServiceInfo).BasePath)Backup"

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  5/11/2017
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    $BackupPath = "$((Get-LTServiceInfo).BasePath)Backup"
    $Keys = 'HKLM\SOFTWARE\LabTech'
    $Path = "$BackupPath\LTBackup.reg"
    reg export $Keys $Path /y
    $Reg = Get-Content $Path
    $Reg = $Reg -replace [Regex]::Escape('[HKEY_LOCAL_MACHINE\SOFTWARE\LabTech'),'[HKEY_LOCAL_MACHINE\SOFTWARE\LabTechBackup'
    $Reg | Out-File $Path
    reg import $Path
    Copy-Item $(Get-LTServiceInfo).BasePath "$((Get-LTServiceInfo).BasePath)Backup" -Recurse -Force    
}#End Function New-LTServiceBackup

Function Get-LTServiceInfoBackup { 
<#
.SYNOPSIS
    This function will pull all of the backed up registy data into an object.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  5/11/2017
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#> 
    [CmdletBinding()]
    Param ()
      
  Begin{
    Write-Verbose "Verbose: Checking for registry keys."
    if ((Test-Path 'HKLM:\SOFTWARE\LabTechBackup\Service') -eq $False){
        Write-Error "ERROR: Unable to find information on LTSvc. Make sure the service is running."
        Return
    }
    $exclude = "PSParentPath","PSChildName","PSDrive","PSProvider","PSPath"
  }#End Begin
  
  Process{
    Try{
        Get-ItemProperty HKLM:\SOFTWARE\LabTechBackup\Service -ErrorAction Stop | Select * -exclude $exclude
    }#End Try
    
    Catch{
      Write-Error "ERROR: There was a problem reading the registry keys. $($Error[0])"
    }#End Catch
  }#End Process
  
  End{
    if ($?){
        $key
    }    
  }#End End
}#End Function Get-LTServiceInfoBackup

Function Rename-LTAddRemove{
<#
.SYNOPSIS
    This function renames the LabTech install from add/remove programs list.

.DESCRIPTION
    This function will change the value of the DisplayName registry key to effect add/remove programs list.

.NOTES
    Version:        1.0
    Author:         Chris Taylor
    website:        labtechconsulting.com
    Creation Date:  5/14/2017
    Purpose/Change: Initial script development
.LINK
    http://labtechconsulting.com
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        $Name
    )

    Begin{
        $RegRoot = 'HKLM:\SOFTWARE\Classes\Installer\Products\D1003A85576B76D45A1AF09A0FC87FAC'       
    }#End Begin
  
    Process{
        Try{
            Set-ItemProperty $RegRoot -Name ProductName -Value $Name
        }#End Try
    
        Catch{
            Write-Error "There was an error renaming the registry key. $($Error[0])" -ErrorAction Stop
        }#End Catch
    }#End Process
  
    End{
        if($?){
            Write-Output "LabTech is now listed as '$Name' in Add/Remove Programs."
        }
        else {$Error[0]}
    }#End End
}#End Function Rename-LTAddRemove


#endregion Functions
