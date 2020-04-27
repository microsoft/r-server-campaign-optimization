
[CmdletBinding()]
param(
[parameter(Mandatory=$false, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$false, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$false, Position=3)]
[ValidateNotNullOrEmpty()] 
[string]$password,

[parameter(Mandatory=$false, Position=4)]
[ValidateNotNullOrEmpty()] 
[string]$Prompt
)

###Check to see if user is Admin

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")
        
if ($isAdmin -eq 'True') {





##Change Values here for Different Solutions 
$SolutionName = "Campaign"
$SolutionFullName = "r-server-campaign-optimization" 
$Shortcut = "CampaignHelp.url"

### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "master" 
$InstallR = 'Yes'  ## If Solution has a R Version this should be 'Yes' Else 'No'
$InstallPy = 'No' ## If Solution has a Py Version this should be 'Yes' Else 'No'
$SampleWeb = 'No' ## If Solution has a Sample Website  this should be 'Yes' Else 'No' 
$EnableFileStream = 'No' ## If Solution Requires FileStream DB this should be 'Yes' Else 'No'
$IsMixedMode = 'No' ##If solution needs mixed mode this should be 'Yes' Else 'No'
$Prompt = 'N'



###These probably don't need to change , but make sure files are placed in the correct directory structure 
$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = $SolutionName
$SolutionPath = $solutionTemplatePath + '\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath = $SolutionPath + "\Resources\ActionScripts\"
$SolutionData = $SolutionPath + "\Data\"



$setupLog = "c:\tmp\campaign_setup_log.txt"
Start-Transcript -Path $setupLog
$startTime = Get-Date
Write-Host 
("Start time: $startTime")

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

if ($SampleWeb -eq "Yes") 
    {
    if([string]::IsNullOrEmpty($username)) 
        {
        $Credential = $Host.ui.PromptForCredential("Need credentials", "Please supply an user name and password to configure SQL for mixed authentication.", "", "")
        $username = $credential.Username
        $password = $credential.GetNetworkCredential().password 
        }  
    }

##################################################################
##DSVM Does not have SQLServer Powershell Module Install or Update 
##################################################################



if (Get-Module -ListAvailable -Name SQLServer) 
    {
    Write-Host 
    ("Updating SQLServer Power Shell Module")    
    Update-Module -Name "SQLServer" -MaximumVersion 21.0.17199
    Import-Module -Name SqlServer -MaximumVersion 21.0.17199 -Force
    }
Else 
    {
    Write-Host 
    ("Installing SQLServer Power Shell Module")  
    Install-Module -Name SqlServer -RequiredVersion 21.0.17199 -Scope AllUsers -AllowClobber -Force
    Import-Module -Name SqlServer -MaximumVersion 21.0.17199 -Force
    }


##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $SolutionPath) { Write-Host "Solution has already been cloned"}
ELSE {Invoke-Expression $clone}

If ($InstalR -eq 'Yes') {
    Write-Host 
    ("Installing R Packages")
    Set-Location "C:\Solutions\$SolutionName\Resources\ActionScripts\"
    # install R Packages
    Rscript install.R 
}


## if FileStreamDB is Required Alter Firewall ports for 139 and 445
if ($EnableFileStream -eq 'Yes')
    {
    netsh advfirewall firewall add rule name="Open Port 139" dir=in action=allow protocol=TCP localport=139
    netsh advfirewall firewall add rule name="Open Port 445" dir=in action=allow protocol=TCP localport=445
    Write-Host 
    ("Firewall as been opened for filestream access")
    }
If ($EnableFileStream -eq 'Yes')
    {
    Set-Location "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\python.exe" 
    .\setup.py install
    Write-Host 
    ("Py Instal has been updated to latest version")
    }


############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

##Get Server name if none was provided during setup

    if([string]::IsNullOrEmpty($serverName))   
    {$Query = "SELECT SERVERPROPERTY('ServerName')"
    $si = Invoke-Sqlcmd  -Query $Query
    $si = $si.Item(0)}
    else 
    {$si = $serverName}
    $serverName = $si

    Write-Host 
    ("Servername set to $serverName")

### Change Authentication From Windows Auth to Mixed Mode 


if ($IsMixedMode = 'Yes') {
    Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

    $Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
    Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue

    $Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
    Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue
}


    Write-Host 
    ("Configuring SQL to allow running of External Scripts")
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL
    Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
    Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
    Write-Host 
    ("SQL Server Configured to allow running of External Scripts")

### Enable FileStreamDB if Required by Solution 
    if ($EnableFileStream -eq 'Yes') 
    {
# Enable FILESTREAM
        $instance = "MSSQLSERVER"
        $wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement14" -Class FilestreamSettings | where-object {$_.InstanceName -eq $instance}
        $wmi.EnableFilestream(3, $instance)
        Stop-Service "MSSQ*" -Force
        Start-Service "MSSQ*"
 
        Set-ExecutionPolicy Unrestricted
        #Import-Module "sqlps" -DisableNameChecking
        Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 2"
        Invoke-Sqlcmd "RECONFIGURE WITH OVERRIDE"
        Stop-Service "MSSQ*"
        Start-Service "MSSQ*"
    }
    ELSE
    { 
    Write-Host 
    ("Restarting SQL Services")
    ### Changes Above Require Services to be cycled to take effect 
    ### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
    Restart-Service -Name "MSSQ*" -Force
}



####Run Configure SQL to Create Databases and Populate with needed Data
    $ConfigureSql = "C:\Solutions\$SolutionName\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $Prompt"
    Invoke-Expression $ConfigureSQL 
    Write-Host
    ("Done with configuration changes to SQL Server")

#### Install Power BI
    Write-Host 
    ("Installing latest Power BI")
    #Download PowerBI Desktop installer
    Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

##Silently install PowerBI Desktop
    msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

    if (!$?) 
    {
    Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
    }


##Create Shortcuts and Autostart Help File 
    Copy-Item "$ScriptPath\$Shortcut" C:\Users\Public\Desktop\
    Copy-Item "$ScriptPath\$Shortcut" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    Write-Host  
    ("Help Files Copied to Desktop")


    $WsShell = New-Object -ComObject WScript.Shell
    $shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
    $shortcut.TargetPath = $solutionPath
    $shortcut.Save()


# install modules for sample website
    if($SampleWeb  -eq "Yes")
        {
        Set-Location $SolutionPath\Website\npm install
        (Get-Content $SolutionPath\Website\server.js).replace('XXYOURSQLPW', $password) | Set-Content $SolutionPath\Website\server.js
        (Get-Content $SolutionPath\Website\server.js).replace('XXYOURSQLUSER', $username) | Set-Content $SolutionPath\Website\server.js 
        }

    $endTime = Get-Date

    Write-Host 
    ("$SolutionFullName Workflow Finished Successfully!")
    $Duration = New-TimeSpan -Start $StartTime -End $EndTime 

    Write-Host 
    ("Total Deployment Time = $Duration")

    Stop-Transcript


    ##Launch HelpURL 
    Start-Process "https://microsoft.github.io/$SolutionFullName/Typical.html"


    ## Close Powershell if not run on 
   ## if ($baseurl)
   Exit-PSHostProcess
   EXIT
}

ELSE 
    {
    Write-Host ("To install this Solution you need to run Powershell as an Administrator. This program will close automatically in 20 seconds")
    Start-Sleep -s 20
    ## Close Powershell 
    Exit-PSHostProcess
    EXIT 
    }
