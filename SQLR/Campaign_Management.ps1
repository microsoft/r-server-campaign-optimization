<#
.SYNOPSIS
Script to provide recommendations in a marketing campaign, using SQL & MRS.

.DESCRIPTION
This script will show the E2E work flow of market campaign machine learning
templates with Microsoft SQL Server 2016 and Microsoft R services. 

For the detailed description, please read README.md.
#>
[CmdletBinding()]
param(
# SQL server address
[parameter(Mandatory=$true,ParameterSetName = "CM")]
[ValidateNotNullOrEmpty()] 
[String]    
$ServerName = "",

# SQL server database name
[parameter(Mandatory=$true,ParameterSetName = "CM")]
[ValidateNotNullOrEmpty()]
[String]
$DBName = ""
)

##########################################################################
# Script level variables
##########################################################################
$scriptPath = Get-Location
$filePath = $scriptPath.Path+ "\"
$parentPath = Split-Path -parent $scriptPath
##########################################################################
# Function wrapper to invoke SQL command
##########################################################################
function ExecuteSQL
{
param(
[String]
$sqlscript
)
    Invoke-Sqlcmd -ServerInstance $ServerName  -Database $DBName -Username $username -Password $password -InputFile $sqlscript -QueryTimeout 200000
}
##########################################################################
# Function wrapper to invoke SQL query
##########################################################################
function ExecuteSQLQuery
{
param(
[String]
$sqlquery
)
    Invoke-Sqlcmd -ServerInstance $ServerName  -Database $DBName -Username $username -Password $password -Query $sqlquery -QueryTimeout 200000
}

##########################################################################
# Get connection string
##########################################################################
function GetConnectionString
{
    $connectionString = "Driver=SQL Server;Server=$ServerName;Database=$DBName;UID=$username;PWD=$password"
    $connectionString
}

##########################################################################
# Get the credential of SQL user
##########################################################################
Write-Host -foregroundcolor 'green' ("Please enter the credential for Database {0} of SQL server {1}" -f $dbname, $server)
$username = Read-Host 'Username:'
$pwd = Read-Host 'Password:' -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))

##########################################################################
# Construct the SQL connection strings
##########################################################################
$connectionString = GetConnectionString

##########################################################################
# Check if the SQL server or database exists
##########################################################################
$query = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE NAME = '$DBName') CREATE DATABASE $DBName"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query -ErrorAction SilentlyContinue
if ($? -eq $false)
{
    Write-Host -ForegroundColor Red "Failed the test to connect to SQL server: $ServerName database: $DBName !"
    Write-Host -ForegroundColor Red "Please make sure: `n`t 1. SQL Server: $ServerName exists;
                                     `n`t 2. SQL database: $DBName exists;
                                     `n`t 3. SQL user: $username has the right credential for SQL server access."
    exit
}

$query = "USE $DBName;"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query 

##########################################################################
# Create input tables and populate with data from csv files.
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 0: Create and populate tables in Database" -f $dbname)
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    try
    {
        # create training and test tables
        Write-Host -ForeGroundColor 'green' ("Create SQL tables: Campaign_Detail, Lead_Demography,  Market_Touchdown and Product")
        $script = $filePath + "step0_create_tables.sql"
        ExecuteSQL $script
    
        Write-Host -ForeGroundColor 'green' ("Populate SQL tables: Campaign_Detail, Lead_Demography,  Market_Touchdown and Product")
        $dataList = "Campaign_Detail", "Lead_Demography", "Market_Touchdown", "Product"
		
		# upload csv files into SQL tables
        foreach ($dataFile in $dataList)
        {
            $destination = $parentPath + "/data/" + $dataFile + ".csv"
            Write-Host -ForeGroundColor 'magenta'("    Populate SQL table: {0}..." -f $dataFile)
            $tableName = $DBName + ".dbo." + $dataFile
            $tableSchema = $parentPath + "/data/" + $dataFile + ".xml"
            bcp $tableName format nul -c -x -f $tableSchema  -U $username -S $ServerName -P $password  -t ','
            Write-Host -ForeGroundColor 'magenta'("    Loading {0} to SQL table..." -f $dataFile)
            bcp $tableName in $destination -t ',' -S $ServerName -f $tableSchema -F 2 -C "RAW" -b 20000 -U $username -P $password
            Write-Host -ForeGroundColor 'magenta'("    Done...Loading {0} to SQL table..." -f $dataFile)
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
        Write-Host -ForegroundColor Red $Error[0].Exception 
        throw
    }
}

##########################################################################
# Create and execute the stored procedure for data processing
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 1: Data Processing")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedures for preprocessing
    $script = $filepath + "step1_data_processing.sql"
    ExecuteSQL $script

    # execute the merging
    Write-Host -ForeGroundColor 'Cyan' (" Merging the 4 raw tables...")
    $query = "EXEC Merging_Raw_Tables"
    ExecuteSQLQuery $query

    # execute the NA replacement
    Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with the mode...")
    $query = "EXEC fill_NA '$connectionString'"
    ExecuteSQLQuery $query
}

##########################################################################
# Create and execute the stored procedure for feature engineering
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 2: Feature Engineering")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the ultility procedure for feature engineering
    $script = $filepath + "step2_feature_engineering.sql"
    ExecuteSQL $script

    # execute the feature engineering
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features and keeping last record per customer...")
    $query = "EXEC feature_engineering"
    ExecuteSQLQuery $query
}

##########################################################################
# Create and execute the stored procedure to split data into train/test
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3a: Split the data into train and test")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for splitting into train and test data sets
    $script = $filepath + "step3a_splitting.sql"
    ExecuteSQL $script

    # execute the procedure
    Write-Host -foregroundcolor 'Cyan' ("Split Ratio ?") 
    $splitRatio = Read-Host 
    Write-Host -ForeGroundColor 'Cyan' (" Splitting the data set...")
    $query = "EXEC splitting $splitRatio, '$connectionString'"
    ExecuteSQLQuery $query
}

##########################################################################
# Create and execute the stored procedure for Training
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3b: Models Training")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for training
    $script = $filepath + "step3b_train_model.sql"
    ExecuteSQL $script

    # execute the training
    Write-Host -ForeGroundColor 'Cyan' (" Training Random Forest (RF)...")
    $modelName = 'RF'
    $query = "EXEC TrainModel $modelName, '$connectionString'"
    ExecuteSQLQuery $query

    Write-Host -ForeGroundColor 'Cyan' (" Training Gradient Boosted Trees (GBT)...")
    $modelName = 'GBT'
    $query = "EXEC TrainModel $modelName, '$connectionString'"
    ExecuteSQLQuery $query
}

##########################################################################
# Create and execute the stored procedure for models evaluation
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3c: Models Evaluation")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for predicting
    $script = $filepath + "step3c_test_model.sql"
    ExecuteSQL $script

    # execute the evaluation
    Write-Host -ForeGroundColor 'Cyan' (" Testing Random Forest (RF) and Gradient Boosted Trees (GBT)...")
    $models = "'RF', 'GBT'"
    $query = "EXEC TestModel $models, '$connectionString'"
    ExecuteSQLQuery $query

    $best_model = Invoke-sqlcmd -ServerInstance $ServerName -Database $DBName -Username $username -Password $password -Query "select best_model from best_model;"
    $best_model = $best_model.best_model
    
    if ($best_model -eq 'RF')
    { 
        $not_selected = 'GBT'
    } 
    else
    {
        $not_selected = 'RF'
    }
}

##########################################################################
# Create and execute the stored procedure for channel recommmendations
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 4: Campaign Recommendations")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    Write-Host -foregroundcolor 'Cyan' ("Best Model based on AUC is $best_model. Would you like to try $not_selected instead? ")
    $ans = Read-Host 'Yes use the best model based on AUC [y|Y], No use the alternative model [n|N]?'
    if($ans -eq 'n' -or $ans -eq 'N')
    { 
        $best_model = $not_selected
    }

    # create the stored procedure for recommendations
    $script = $filepath + "step4_campaign_recommendations.sql"
    ExecuteSQL $script 

    # compute campaign recommendations
    Write-Host -ForeGroundColor 'Cyan' (" Computing channel-day-time recommendations...")
    $query = "EXEC campaign_recommendation_not_in_memory $best_model, '$connectionString'"
    ExecuteSQLQuery $query
}

Write-Host -foregroundcolor 'green'("Market Campaign Workflow Finished Successfully!")
