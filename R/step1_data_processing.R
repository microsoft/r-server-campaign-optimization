##########################################################################################################################################
## This R script will do the following:
## 1. Read the 4 data sets Campaign_Detail, Lead_Demography, Market_Touchdown, and Product, and load them into SQL.
## 2. Join the 4 tables into one.
## 3. Clean the merged data set: replace NAs with the mode.

## Input : 4 Data Tables: Campaign_Detail, Lead_Demography, Market_Touchdown, and Product.
## Output: Cleaned raw data set CM_AD0.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the Compute Context to Local, to load files in-memory.
rxSetComputeContext(local)

##########################################################################################################################################

## Function to get the top n rows of a table stored on SQL Server.
## You can execute this function at any time during  your progress by removing the comment "#", and inputting:
##  - the table name.
##  - the number of rows you want to display.

##########################################################################################################################################

display_head <- function(table_name, n_rows){
  table_sql <- RxSqlServerData(sqlQuery = sprintf("SELECT TOP(%s) * FROM %s", n_rows, table_name), connectionString = connection_string)
  table <- rxImport(table_sql)
  print(table)
}

# table_name <- "insert_table_name"
# n_rows <- 10
# display_head(table_name, n_rows)


##########################################################################################################################################

## Read the 4 data sets from file, and upload them to SQL

##########################################################################################################################################

# Read the 4 tables.
file_path <- "../Data" 

table_Campaign_Detail <- read.csv(file.path(file_path, "Campaign_Detail.csv")) 
table_Lead_Demography <- read.csv(file.path(file_path, "Lead_Demography.csv")) 
table_Market_Touchdown <- read.csv(file.path(file_path, "Market_Touchdown.csv")) 
table_Product <- read.csv(file.path(file_path, "Product.csv")) 

# Upload the 4 tables to SQL 
Campaign_Detail <- RxSqlServerData(table = "Campaign_Detail", connectionString = connection_string)
rxDataStep(inData = table_Campaign_Detail, outFile = Campaign_Detail, overwrite = TRUE)

Lead_Demography <- RxSqlServerData(table = "Lead_Demography", connectionString = connection_string)
rxDataStep(inData = table_Lead_Demography, outFile = Lead_Demography, overwrite = TRUE)
  
Market_Touchdown <- RxSqlServerData(table = "Market_Touchdown", connectionString = connection_string)
rxDataStep(inData = table_Market_Touchdown, outFile = Market_Touchdown, overwrite = TRUE)

Product <- RxSqlServerData(table = "Product",connectionString = connection_string)
rxDataStep(inData = table_Product, outFile = Product, overwrite = TRUE)


##########################################################################################################################################

## Join the 4 tables to create the raw data set

##########################################################################################################################################

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

# Inner join of the tables Product and Campaign_Detail
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Campaign_Product;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
  "SELECT Campaign_Detail.*, Term , No_Of_People_Covered, 
  Payment_Frequency, Net_Amt_Insured, Amt_On_Maturity_Bin,
  Product, Premium
  INTO Campaign_Product
  FROM Campaign_Detail JOIN Product
  ON Product.Product_Id = Campaign_Detail.Product_Id;"
  , sep=""))

# Inner join of the tables Market_Touchdown and Lead_Demography
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Market_Lead;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"SELECT Lead_Demography.Lead_Id, Age, Phone_No, Annual_Income_Bucket, Credit_Score, Country, State,
        No_Of_Dependents, Highest_Education, Ethnicity,
        No_Of_Children, Household_Size, Gender, 
        Marital_Status, Channel, Time_Of_Day, Conversion_Flag, Campaign_Id, Day_Of_Week, Comm_Id, Time_Stamp
 INTO Market_Lead
 FROM Market_Touchdown JOIN Lead_Demography
 ON Market_Touchdown.Lead_Id = Lead_Demography.Lead_Id;"
, sep=""))

# Point to an inner join of the two previous tables. This table will not be materialized. It is created on the fly when removing NAs. 
# Numeric variables are converted to characters only to get their mode for NA cleaning. 
# numeric_names <- c("No_Of_Dependents", "No_Of_Children", "Household_Size", "No_of_people_covered", "Premium", "Net_Amt_Insured", "Term")

Merged_sql <- RxSqlServerData(  
  sqlQuery = 
"SELECT Lead_Id, Age, Phone_No, Annual_Income_Bucket, Credit_Score, Country, State,
        CAST(No_Of_Dependents AS char(1)) AS No_Of_Dependents, Highest_Education, Ethnicity,
        CAST(No_Of_Children AS char(1)) AS No_Of_Children, CAST(Household_Size AS char(1)) AS Household_Size, Gender, 
        Marital_Status, Channel, Time_Of_Day, Conversion_Flag, Market_Lead.Campaign_Id, Day_Of_Week, Comm_Id, Time_Stamp,
        Product, Category, Term, CAST(No_Of_People_Covered AS char(1)) AS No_Of_People_Covered,
        CAST(Premium AS varchar(4)) AS Premium, Payment_Frequency,
        Amt_On_Maturity_Bin, Sub_Category, Campaign_Drivers, Campaign_Name, Launch_Date, Call_For_Action, 
        Focused_Geography, Tenure_Of_Campaign, CAST(Net_Amt_Insured AS varchar(7)) AS Net_Amt_Insured , Product_Id
 FROM Campaign_Product JOIN Market_Lead 
 ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id "
  ,connectionString = connection_string, stringsAsFactors = TRUE)

##########################################################################################################################################


## Clean the Merged data set: replace NAs with the mode

##########################################################################################################################################

# Assumption: no NAs in the Id variables (Lead_Id, Product_Id, Campaign_Id, Comm_Id) and in (Phone_No, Launch_Date, Time_Stamp).
# Find the variables that have missing values (NA). 
colnames <- names(rxGetVarInfo(Merged_sql))
var <- colnames[!colnames %in% c("Lead_Id", "Product_Id", "Campaign_Id", "Comm_Id", "Phone_No", "Launch_Date", "Time_Stamp")]
formula <- as.formula(paste("~", paste(var, collapse = "+")))
summary <- rxSummary(formula, Merged_sql, byTerm = TRUE)
var_with_NA <- summary$sDataFrame[summary$sDataFrame$MissingObs > 0, 1] 
var_number_with_NA <- which(summary$sDataFrame$MissingObs > 0) 

# Compute the mode of variables with missing values. 
mode <- c()
k <- 0
for(n in var_number_with_NA ){
  k <- k + 1
  mode[k] <- as.character(summary$categorical[[n]][which.max(summary$categorical[[n]][,2]),1])
}

# Point again to the merged table without stringsAsFactors = TRUE and with correct variable types. 
Merged_sql2 <- RxSqlServerData(  
  sqlQuery = 
"SELECT Market_Lead.*, Product, Category, Term, No_Of_People_Covered, Premium, Payment_Frequency,
        Amt_On_Maturity_Bin, Sub_Category, Campaign_Drivers, Campaign_Name, Launch_Date, Call_For_Action, 
        Focused_Geography, Tenure_Of_Campaign, Net_Amt_Insured, Product_Id
 FROM Campaign_Product JOIN Market_Lead
 ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id "
  ,connectionString = connection_string)

# Function to deal with NAs. 
Mode_Replace <- function(data) {
  data <- data.frame(data)
  for(j in 1:length(var_with_NA_1)){
    row_na <- which(is.na(data[,var_with_NA_1[j]]) == TRUE) 
        if (var_with_NA_1[j] %in% c("No_Of_Dependents", "No_Of_Children", "Household_Size", "No_Of_People_Covered", "Premium", "Net_Amt_Insured")){
          data[row_na,var_with_NA_1[j]] <- as.integer(mode_1[j])
        } else{
          data[row_na,var_with_NA_1[j]] <- mode_1[j]
        }
  }
  return(data)
}

# Create the CM_AD0 table by dealing with NAs in Merged_sql and save it to a SQL table.
CM_AD0 <- RxSqlServerData(table = "CM_AD0", connectionString = connection_string)
rxDataStep(inData = Merged_sql2 , outFile = CM_AD0, overwrite = TRUE, transformFunc = Mode_Replace, 
           transformObjects = list(var_with_NA_1 = var_with_NA, mode_1 = mode))

# Drop intermediate tables.
rxSqlServerDropTable(table = "Campaign_Product", connectionString = connection_string)
rxSqlServerDropTable(table = "Market_Lead", connectionString = connection_string)
