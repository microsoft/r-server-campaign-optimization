[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1)]
[string]$ServerName,

[parameter(Mandatory=$true, Position=2)]
[string]$SolutionName,

[parameter(Mandatory=$true, Position=3)]
[string]$InstallPy,

[parameter(Mandatory=$true, Position=4)]
[string]$Prompt
)






$Prompt = 'N'






###$ServerName = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter SQL Server Name Or SQL InstanceName you are installing on"} else {$si}


WRITE-HOST " ServerName set to $ServerName"

$db = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter Desired Database Base Name"} else {$SolutionName} 

$dataList = ("Campaign_Detail", "Lead_Demography", "Market_Touchdown", "Product")



##########################################################################

# Create Database and BaseTables 

#########################################################################

####################################################################
# Check to see If SQL Version is at least SQL 2017 and Not SQL Express 
####################################################################


$query = 
"select 
        case 
            when 
                cast(left(cast(serverproperty('productversion') as varchar), 4) as numeric(4,2)) >= 14 
                and CAST(SERVERPROPERTY ('edition') as varchar) Not like 'Express%' 
            then 'Yes'
        else 'No' end as 'isSQL17'"

$isCompatible = Invoke-Sqlcmd -ServerInstance $ServerName -Database Master -Query $query
$isCompatible = $isCompatible.Item(0)
if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {
    Write-Host " This Version of SQL is Compatible with SQL Py "

    ## Create Py Database
    Write-Host "  Creating SQL Database for Py "


    Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

    ## Create PY Server DB
    $dbName = $db + "_Py"
    $SqlParameters = @("dbName=$dbName")

    $CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

    $CreateSQLObjects = "$ScriptPath\CreateSQLObjectsPy.sql"
    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
    invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


    Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
    invoke-sqlcmd "USE $dbName;" 

    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
    invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


    Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")
$OdbcName = "obdc" + $dbname
 ## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $OdbcName -DriverName "ODBC Driver 13 for SQL Server" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru




}
else 
{
    if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {"This Version of SQL is not compatible with Py , Py Code and DB's will not be Created "}
    else {" There is not a py version of this solution"}
}

 




Write-Host "  Creating SQL Database for R "


Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

$dbName = $db + "_R"


## Create RServer DB 
$SqlParameters = @("dbName=$dbName")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjectsR.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")


###Configure Database for R 
Write-Host "  
Configuring $SolutionName Solution for R
"

$dbName = $db + "_R" 

## Create ODBC Connection for PowerBI to Use 
$OdbcName = "obdc" + $dbname
## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $OdbcName -DriverName "ODBC Driver 13 for SQL Server" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru

##########################################################################
# Deployment Pipeline
##########################################################################

$RStart = Get-Date
try
{

Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
 ##Move this to top 


# upload csv files into SQL tables
foreach ($dataFile in $dataList)
{
$destination = $SolutionData + $dataFile + ".csv" 
$tableName = $DBName + ".dbo." + $dataFile
$tableSchema = $dataPath + "\" + $dataFile + ".xml"
$dataSet = Import-Csv $destination
Write-Host -ForegroundColor 'cyan' ("         Loading $dataFile.csv into SQL Table, this will take about 30 seconds per file....") 
Write-SqlTableData -InputData $dataSet  -DatabaseName $dbName -Force -Passthru -SchemaName dbo -ServerInstance $ServerName -TableName $dataFile


Write-Host -ForeGroundColor 'cyan' (" $datafile table loaded from CSV File(s).")
}
}
catch
{
Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
Write-Host -ForegroundColor Red $Error[0].Exception 
throw
}
Write-Host -ForeGroundColor 'cyan' (" Finished loading .csv File(s).")

Write-Host -ForeGroundColor 'Cyan' (" Training Model and Scoring Data...")



$query = "EXEC Initial_Run_Once_R"
#SqlServer\Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0
SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0

$Rend = Get-Date

$Duration = New-TimeSpan -Start $RStart -End $Rend 
Write-Host -ForegroundColor 'green'(" R Server Configured in $Duration")



###Conifgure Database for Py 
if ($isCompatible -eq 'Yes'-and $InstallPy -eq 'Yes')
{
$PyStart = get-date
Write-Host "  
Configuring $SolutionName Solution for Py
# "
$dbname = $db + "_Py"

##########################################################################
# Deployment Pipeline Py not
##########################################################################


try
{

Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
#$dataList = "LengthOfStay"


# upload csv files into SQL tables
foreach ($dataFile in $dataList)
{
    $destination = $SolutionData + $dataFile + ".csv" 
    $tableName = $DBName + ".dbo." + $dataFile
    $tableSchema = $dataPath + "\" + $dataFile + ".xml"
    $dataSet = Import-Csv $destination
 Write-Host -ForegroundColor 'cyan' ("         Loading $dataFile.csv into SQL Table, this will take about 30 seconds per file....") 
    Write-SqlTableData -InputData $dataSet  -DatabaseName $dbName -Force -Passthru -SchemaName dbo -ServerInstance $ServerName -TableName $dataFile

    
 Write-Host -ForeGroundColor 'cyan' (" $datafile table loaded from CSV File(s).")
}
}
catch
{
Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
Write-Host -ForegroundColor Red $Error[0].Exception 
throw
}
Write-Host -ForeGroundColor 'cyan' (" Finished loading .csv File(s).")

Write-Host -ForeGroundColor 'Cyan' (" Training Model and Scoring Data...")
$query = "EXEC Inital_Run_Once_Py"
SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0

$Pyend = Get-Date

$Duration = New-TimeSpan -Start $PyStart -End $Pyend 
Write-Host -ForegroundColor 'green'(" Py Server Configured in $Duration")

}