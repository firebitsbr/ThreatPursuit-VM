#ThreatPursuit Installer Script#############
# ThreatPursuit Installation Script 
# 
# To execute this script:
# 1) Open powershell window as administrator
# 2) Unblock the script by running command "Unblock-File install.ps1"
# 3) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"
# 4) Execute the script by running ".\install.ps1"
#
###########################################
param (
  [string]$password = "",  
	[string]$profile_file = $null, 
  [bool]$nochecks = $false
)

function ConvertFrom-Json([object] $item) {
<#
.SYNOPSIS
  Convert a JSON string into a hash table

.DESCRIPTION
  Convert a JSON string into a hash table, without any validation

.OUTPUTS
  [hashtable] or $null
#>
  Add-Type -Assembly system.web.extensions
  $ps_js = New-Object system.web.script.serialization.javascriptSerializer

  try {
    $result = $ps_js.DeserializeObject($item)
  } catch {
    $result = $null
  }
  
  # Cast dictionary to hashtable
  [hashtable] $result
}


function ConvertTo-Json([object] $data) {
<#
.SYNOPSIS
  Convert a hashtable to a JSON string

.DESCRIPTION
  Convert a hashtable to a JSON string, without any validation

.OUTPUTS
  [string] or $null
#>
  Add-Type -Assembly system.web.extensions
  $ps_js = New-Object system.web.script.serialization.javascriptSerializer

  #The comma operator is the array construction operator in PowerShell
  try {
    $result = $ps_js.Serialize($data)
  } catch {
    $result = $null
  }
  
  $result
}


function Import-JsonFile {
<#
.DESCRIPTION
  Load a hashtable from a JSON file
  
.OUTPUTS
  [hashtable] or $null
#>
  param([string] $path)
  try {
    $json = Get-Content $path
    $result = ConvertFrom-Json $json
  } catch {
    $result = $null
  }
  
  $result
}


function Make-InstallerPackage($PackageName, $TemplateDir, $packages) {
	<#
	.SYNOPSIS
	Make a new installer package

	.DESCRIPTION
	Make a new installer package named installer. This package uses the custom packages.json file specified by the user.
	User can then call "Install-BoxStarterPackage installer" using the local repo.
	#>

	$PackageDir = Join-Path $BoxStarter.LocalRepo $PackageName
	if (Test-Path $PackageDir) {
		Remove-Item -Recurse -Force $PackageDir
	}

	$Tmp = [System.IO.Path]::GetTempFileName()
	Write-Host -ForegroundColor Green "packages file is" + $tmp
	ConvertTo-Json @{"packages" = $packages} | Out-File -FilePath $Tmp
	
	$Here = Get-Location
	$ToolsDir = Join-Path (Join-Path $Here $TemplateDir) "tools"
	$Dest = Join-Path $ToolsDir "packages.json"

	Move-Item -Force -Path $Tmp -Destination $Dest
	New-BoxstarterPackage -Name $PackageName -Description "My Own Installer" -Path $ToolsDir
}

function installBoxStarter()
{
  <#
  .SYNOPSIS
  Install BoxStarter on the current system  
  .DESCRIPTION
  Install BoxStarter on the current system. Returns $true or $false to indicate success or failure. On
  fresh windows 7 systems, some root certificates are not installed and updated properly. Therefore,
  this funciton also temporarily trust all certificates before installing BoxStarter.  
  #> 
  

  # Try to install BoxStarter as is first, then fall back to be over trusing only if this step fails.
  try {
		iex ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1')); get-boxstarter -Force
		return $true
	} catch {
	}
   
  # https://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error
  # Allows current PowerShell session to trust all certificates
  # Also a good find: https://www.briantist.com/errors/could-not-establish-trust-relationship-for-the-ssltls-secure-channel/
  
  try {
  Add-Type @"
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
  } catch {
    Write-Debug "Failed to add new type"
  }  
  try {
  	$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
  } catch {
  	Write-Debug "Failed to find SSL type...1"
  }  
  try {
  	$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls'
  } catch {
  	Write-Debug "Failed to find SSL type...2"
  }  
  $prevSecProtocol = [System.Net.ServicePointManager]::SecurityProtocol
  $prevCertPolicy = [System.Net.ServicePointManager]::CertificatePolicy  
  Write-Host "[ * ] Installing Boxstarter"
  # Become overly trusting
  [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy  
  # download and instal boxstarter
  iex ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1')); get-boxstarter -Force  
  # Restore previous trust settings for this PowerShell session
  # Note: SSL certs trusted from installing BoxStarter above will be trusted for the remaining PS session
  [System.Net.ServicePointManager]::SecurityProtocol = $prevSecProtocol
  [System.Net.ServicePointManager]::CertificatePolicy = $prevCertPolicy
  return $true
}
Write-Host "[+] Beginning install..."
Write-Host " ____________________________________________________________________________ " -ForegroundColor Red 
Write-Host "|                                                                            |" -ForegroundColor Red 
Write-Host "|    "  -ForegroundColor Red -NoNewline; Write-Host "                  " -ForegroundColor Green -NoNewline; Write-Host "                                                      |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "  __  .__                         __   " -ForegroundColor Green -NoNewline; Write-Host "                     |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "_/  |_|  |_________  ____ _____ _/  |_   " -ForegroundColor Green -NoNewline; Write-Host "                   |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "/    \  \/ /  _ \ /     \ /     \\__  \  " -ForegroundColor Green -NoNewline; Write-Host "                   |" -ForegroundColor Red        
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host " |  | |   Y  |  | \\  ___/ / __ \|  |     " -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host " |__| |___|  |__|   \___  (____  |__|     " -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "______  __ _________ ________ __|___/  |_ " -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "\____ \|  |  \_  __ /  ___|  |  |  \   __\" -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "|  |_> |  |  /|  | \\___ \|  |  |  ||  |  " -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "|   __/|____/ |__| /____  |____/|__||__|  " -ForegroundColor Green -NoNewline; Write-Host "                  |" -ForegroundColor Red 
Write-Host "|                "  -ForegroundColor Red -NoNewline; Write-Host "|__|                    \/                 " -ForegroundColor Green -NoNewline; Write-Host "                 |" -ForegroundColor Red 
Write-Host "|                               M A N D I A N T                              |" -ForegroundColor Red 
Write-Host "|                          T H R E A T - I N T E L L I G E N C E - V M       |" -ForegroundColor Red 
Write-Host "|                                                                            |" -ForegroundColor Red 
Write-Host "|                                  Version 0.1                               |" -ForegroundColor Red 
Write-Host "|                             threatpursuitvm@fireeye.com                    |" -ForegroundColor Red 
Write-Host "|____________________________________________________________________________|" -ForegroundColor Red 
Write-Host "|                                                                            |" -ForegroundColor Red 
Write-Host "|                              Developed by                                  |" -ForegroundColor Red
Write-Host "|                                                                            |" -ForegroundColor Red
Write-Host "|                           Dan Kennedy @iTzDan1337                          |" -ForegroundColor Red
Write-Host "|                           Nhan Huynh                                       |" -ForegroundColor Red
Write-Host "|                           Blaine Stancill @MalwareMechanic                 |" -ForegroundColor Red
Write-Host "|                           Jake Barteaux @day1player                        |" -ForegroundColor Red
Write-Host "|                                                                            |" -ForegroundColor Red
Write-Host "|                    Front Line Applied Research and Expertise               |" -ForegroundColor Red
Write-Host "|____________________________________________________________________________|" -ForegroundColor Red 
Write-Host ""

if ([string]::IsNullOrEmpty($profile_file)) {
  Write-Host "[+] No custom profile is provided..."
  $profile = $null
} else {
  Write-Host "[+] Using the following profile $profile_file"
  $profile = Import-JsonFile $profile_file
  if ($profile -eq $null) {
    Write-Error "Invaild configuration! Exiting..."
    exit 1
  }
  # Confirmation message
  $TemplateDir = $profile.env.TEMPLATE_DIR
  $Packages = $profile.packages
  Write-Warning "[+] You are using a custom profile and list of packages. You will NOT receive updates"
  Write-Warning "[+] on new packages from ThreatPursuit VM automatically when running choco update."

  if ($nochecks -eq $false) {
    Write-Host "[-] Do you want to continue? Y/N " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -ne "Y") {
      Write-Host "[*] Exiting..." -ForegroundColor Red
      exit
  }
}

Write-Host "`tContinuing..." -ForegroundColor Green
}


# Check to make sure script is run as administrator
Write-Host "[+] Checking if script is running as administrator.."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "`t[ERR] Please run this script as administrator`n" -ForegroundColor Red
  Read-Host  "Press any key to continue"
  exit
}
else {
  Start-Sleep -Milliseconds 500
  Write-Host "`thunt " -ForegroundColor Magenta -NoNewLine
  Start-Sleep -Milliseconds 500
  Write-Host "analyze " -ForegroundColor Cyan -NoNewLine
  Start-Sleep -Milliseconds 500
  Write-Host "share " -ForegroundColor Green
  Start-Sleep -Milliseconds 500
}

 
if (-Not $nochecks) { 
  # Check to make sure host is supported
  Write-Host "[+] Checking to make sure Operating System is compatible"
  if ([System.Environment]::OSVersion.Version.Major -ne 10){
    Write-Host "`t[ERR] $((Get-WmiObject -class Win32_OperatingSystem).Caption) is not supported, Windows 10" -ForegroundColor Red
    exit 
  }
  else
  {
    Write-Host "`t$((Get-WmiObject -class Win32_OperatingSystem).Caption) supported" -ForegroundColor Green
  }

  # Check to make sure host has been updated
  Write-Host "[+] Checking if host has been configured with updates"
  if (-Not (get-hotfix | where { (Get-Date($_.InstalledOn)) -gt (get-date).adddays(-30) })) {
    Write-Host "`t[ERR] This machine has not been updated in the last 30 days, please run Windows Updates to continue`n" -ForegroundColor Red
    Read-Host  "Press any key to continue"
    exit
  }

  #Check to make sure host has enough disk space
  Write-Host "[+] Checking if host has enough disk space"
  $disk = Get-PSDrive C
  Start-Sleep -Seconds 1
  if (-Not (($disk.used + $disk.free)/1GB -gt 60)){
    Write-Host "`t[ERR] This install requires a minimum 60 GB hard drive, please increase hard drive space to continue`n" -ForegroundColor Red
    Read-Host "Press any key to continue"
    exit
  }
  else
  {
    Write-Host "`t> 60 GB hard drive. looks good" -ForegroundColor Green
  }

  # Prompt user to remind them to take a snapshot
  Write-Host "[-] Do you need to take a snapshot before continuing? Y/N " -ForegroundColor Yellow -NoNewline
  $response = Read-Host
  if ($response -ne "N") {
    Write-Host "[ * ] Exiting..." -ForegroundColor Red
    exit
  }
  Write-Host "`tContinuing..." -ForegroundColor Green
}
# Get user credentials for autologin during reboots
Write-Host "[ * ] Getting user credentials ..."
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name "ConsolePrompting" -Value $True
if ([string]::IsNullOrEmpty($password)) {
	$cred=Get-Credential $env:username
} else {
	$spasswd=ConvertTo-SecureString -String $password -AsPlainText -Force
	$cred=New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $env:username, $spasswd
}

Write-Host "[ * ] Installing Boxstarter"
$rc = installBoxStarter
if ( -Not $rc ) {
	Write-Host "[ERR] Failed to install BoxStarter"
	Read-Host  "      Press ANY key to continue..."
	exit 1
}

# Boxstarter options
$Boxstarter.RebootOk = $true    # Allow reboots?
$Boxstarter.NoPassword = $false # Is this a machine with no login password?
$Boxstarter.AutoLogin = $true   # Save my password securely and auto-login after a reboot
Set-BoxstarterConfig -NugetSources "https://www.myget.org/F/fireeye/api/v2;https://chocolatey.org/api/v2"

# Needed for many applications
# Set up the correct feed


$fireeyeFeed = "https://www.myget.org/F/fireeye/api/v2"
iex "choco sources add -n=fireeye -s $fireeyeFeed --priority 1"
iex "choco upgrade -y vcredist-all.flare"
iex "choco install -y powershell"
iex "choco install -y googlechrome.fireeye"
iex "refreshenv"



if ($profile -eq $null) {
  # Default install
  Write-Host "[+] Performing normal installation..."
  iex "choco upgrade -y common.fireeye"
  if ([System.Environment]::OSVersion.Version.Major -eq 10) {
    choco config set cacheLocation ${Env:TEMP}
    iex "choco upgrade -y threatpursuit.win10.preconfig.fireeye"
    Install-BoxstarterPackage -PackageName threatpursuit.win10.installer.fireeye -Credential $cred
    Install-BoxStarterPackage -PackageName threatpursuit.win10.config.fireeye  -Credential $cred
  }
  
  exit 0
} 

# The necessary basic environment variables
$EnvVars = @(
  "VM_COMMON_DIR",
  "TOOL_LIST_DIR",
  "TOOL_LIST_SHORTCUT",
  "RAW_TOOLS_DIR"
  )

foreach ($envVar in $EnvVars) {
  try {
    [Environment]::SetEnvironmentVariable($envVar, [Environment]::ExpandEnvironmentVariables($profile.env.($envVar)), 2)
  } catch {}
}

if ([System.Environment]::OSVersion.Version.Major -eq 10) {
  choco config set cacheLocation ${Env:TEMP}
  iex "choco upgrade -y threatpursuitvm.win10.preconfig.fireeye"
}

iex "choco install -y common.fireeye"
refreshenv

$PackageName = "MyInstaller"
Make-InstallerPackage $PackageName $TemplateDir $Packages
Invoke-BoxStarterBuild $PackageName
Install-BoxStarterPackage -PackageName $PackageName -Credential $cred
if ([System.Environment]::OSVersion.Version.Major -eq 10) {
  Install-BoxStarterPackage -PackageName threatpursuitvm.win10.config.fireeye  -Credential $cred
}
exit 0
