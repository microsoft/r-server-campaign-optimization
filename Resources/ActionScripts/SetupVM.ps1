

[CmdletBinding()]
param(
[parameter(Mandatory=$True, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$True, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$True, Position=3)]
[ValidateNotNullOrEmpty()] 
[string]$password,

[parameter(Mandatory=$false, Position=4)]
[ValidateNotNullOrEmpty()] 
[string]$Prompt
)
$startTime = Get-Date



#$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}
$Prompt = 'N'


##Change Values here for Different Solutions 
$SolutionName = "Campaign"
$SolutionFullName = "r-server-campaign-optimization" 
$JupyterNotebook = "Campaign Optimization R Notebook.ipynb"
$Shortcut = "CampaignHelp.url"


### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "dev2" 
$InstallR = 'Yes'  ## If Solution has a R Version this should be 'Yes' Else 'No'
$InstallPy = 'No' ## If Solution has a Py Version this should be 'Yes' Else 'No'
$SampleWeb = 'No' ## If Solution has a Sample Website  this should be 'Yes' Else 'No' 
$EnableFileStream = 'No' ## If Solution Requires FileStream DB this should be 'Yes' Else 'No' 
$Prompt = 'N'


$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime = Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 


###These probably don't need to change , but make sure files are placed in the correct directory structure 
$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = $SolutionName
$SolutionPath = $solutionTemplatePath + '\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath = $SolutionPath + "\Resources\ActionScripts\"
$SolutionData = $SolutionPath + "\Data\"



####$Query = "SELECT SERVERPROPERTY('ServerName')"
##$si = invoke-sqlcmd -Query $Query
##$si = $si.Item(0)


###$serverName = if($serverName -eq $null) {$si}

##WRITE-HOST " ServerName set to $ServerName"



##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $SolutionPath) { Write-Host " Solution has already been cloned"}
ELSE {Invoke-Expression $clone}

If ($InstalR -eq 'Yes')
{
Write-Host -ForeGroundColor magenta "Installing R Packages"
Set-Location "C:\Solutions\$SolutionName\Resources\ActionScripts\"
# install R Packages
Rscript install.R 
}


#################################################################
##DSVM Does not have SQLServer Powershell Module Install or Update 
#################################################################



Write-Host " Installing SQLServer Power Shell Module or Updating to latest "

if (Get-Module -ListAvailable -Name SQLServer) {Update-Module -Name "SQLServer"}
 else 
    {
    Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
    Import-Module -Name SQLServer
    }


## if FileStreamDB is Required Alter Firewall ports for 139 and 445
if ($EnableFileStream -eq 'Yes')
    {
    netsh advfirewall firewall add rule name="Open Port 139" dir=in action=allow protocol=TCP localport=139
    netsh advfirewall firewall add rule name="Open Port 445" dir=in action=allow protocol=TCP localport=445
    Write-Host -ForeGroundColor cyan " Firewall as been opened for filestream access..."
    }


############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

#Write-Host -ForegroundColor 'Cyan' " Switching SQL Server to Mixed Mode"


### Change Authentication From Windows Auth to Mixed Mode 
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

Write-Host -ForeGroundColor 'cyan' " Configuring SQL to allow running of External Scripts "
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL
Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
Write-Host -ForeGroundColor 'cyan' " SQL Server Configured to allow running of External Scripts "

### Enable FileStreamDB if Required by Solution 
if ($EnableFileStream -eq 'Yes') 
    {
# Enable FILESTREAM
        $instance = "MSSQLSERVER"
        $wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement14" -Class FilestreamSettings | where {$_.InstanceName -eq $instance}
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
    Write-Host -ForeGroundColor 'cyan' " Restarting SQL Services "
    ### Changes Above Require Services to be cycled to take effect 
    ### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
    Restart-Service -Name "MSSQ*" -Force
}
### Start the SQL Service 
#Start-Service -Name "MSSQ*"
#Write-Host -ForegroundColor 'Cyan' " SQL Services Restarted"


$Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue

$Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue


####Run Configure SQL to Create Databases and Populate with needed Data
$ConfigureSql = "C:\Solutions\$SolutionName\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $Prompt"
Invoke-Expression $ConfigureSQL 

Write-Host -ForegroundColor 'Cyan' " Done with configuration changes to SQL Server"




Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

if (!$?) {
    Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
}


##Create Shortcuts and Autostart Help File 
Copy-Item "$ScriptPath\$Shortcut" C:\Users\Public\Desktop\
Copy-Item "$ScriptPath\$Shortcut" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"


$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()



## copy Jupyter Notebook files
Move-Item $SolutionPath\R\$JupyterNotebook  c:\tmp\
sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\R\




#cp $SolutionData*.csv  c:\dsvm\notebooks
 # substitute real username and password in notebook file
#XXXXXXXXXXChange to NEw NotebookNameXXXXXXXXXXXXXXXXXX# 

if ($InstallPy -eq "Yes")
{
    Move-Item $SolutionPath\Python\$JupyterNotebook  c:\tmp\
    sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
    sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
    Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\Python\
}

# install modules for sample website
if($SampleWeb  -eq "Yes")
{
cd $SolutionPath\Website\
npm install
Move-Item $SolutionPath\Website\server.js  c:\tmp\
sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\server.js
sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\server.js
Move-Item  c:\tmp\server.js $SolutionPath\Website
}

$endTime = Get-Date

Write-Host -foregroundcolor 'green'(" $SolutionFullName Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 

Stop-Transcript


##Launch HelpURL 
Start-Process "https://microsoft.github.io/$SolutionFullName/Typical.html"




## Close Powershell 
Exit-PSHostProcess
EXIT 