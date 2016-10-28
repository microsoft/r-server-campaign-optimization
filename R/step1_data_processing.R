
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

# Load revolution R library. 
library(RevoScaleR)

# Compute Contexts.
connection_string <- "Driver=SQL Server; Server=[Server Name]; Database=Campaign; UID=[User ID]; PWD=[User Password]"
sql <- RxInSqlServer(connectionString = connection_string)
local <- RxLocalSeq()

# Set the Compute Context to Local, to load files in-memory.
rxSetComputeContext(local)

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

# Set the Compute Context to SQL to perform computations on SQL tables.
rxSetComputeContext(sql)

# Inner join of the tables Product and Campaign_Detail
Campaign_Product_sql <- RxSqlServerData(      
  sqlQuery = "SELECT Campaign_Detail.*, Product.Product, Product.Term, Product.No_of_people_covered, Product.Premium, 
                     Product.Payment_frequency, Product.Net_Amt_Insured, Product.Amt_on_Maturity, Product.Amt_on_Maturity_Bin
                FROM Campaign_Detail JOIN Product
                ON Product.Product_Id = Campaign_Detail.Product_Id",
    connectionString = connection_string)
Campaign_Product <- RxSqlServerData(table = "Campaign_Product", connectionString = connection_string)
rxDataStep(inData = Campaign_Product_sql, outFile = Campaign_Product, overwrite = TRUE )

# Inner join of the tables Market_Touchdown and Lead_Demography
Market_Lead_sql <- RxSqlServerData(  
  sqlQuery = "SELECT Lead_Demography.*, Market_Touchdown.Channel, Market_Touchdown.Time_Of_Day, Market_Touchdown.Conversion_Flag,
                     Market_Touchdown.Campaign_Id, Market_Touchdown.Day_Of_Week, Market_Touchdown.Comm_Id, Market_Touchdown.Time_Stamp
              FROM Market_Touchdown JOIN Lead_Demography
              ON Market_Touchdown.Lead_Id = Lead_Demography.Lead_Id",
  connectionString = connection_string)
Market_Lead <- RxSqlServerData(table = "Market_Lead", connectionString = connection_string)
rxDataStep(inData = Market_Lead_sql, outFile = Market_Lead, overwrite = TRUE )

# Inner join of the two previous tables.
Campaign_Product_Market_Lead_sql <- RxSqlServerData(  
  sqlQuery = "SELECT Market_Lead.*, Campaign_Product.Product, Campaign_Product.Category, Campaign_Product.Term, 
                     Campaign_Product.No_of_people_covered, Campaign_Product.Premium, Campaign_Product.Payment_frequency,                      Campaign_Product.Amt_on_Maturity_Bin, Campaign_Product.Sub_Category, Campaign_Product.Campaign_Drivers, 
                     Campaign_Product.Campaign_Name, Campaign_Product.Launch_Date, Campaign_Product.Call_For_Action, 
                     Campaign_Product.Focused_Geography, Campaign_Product.Tenure_Of_Campaign, Campaign_Product.Net_Amt_Insured, 
                     Campaign_Product.Product_Id
              FROM Campaign_Product JOIN Market_Lead 
              ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id "
  ,connectionString = connection_string)
Merged <- RxSqlServerData(table = "Merged", connectionString = connection_string)
rxDataStep(inData = Campaign_Product_Market_Lead_sql, outFile = Merged, overwrite = TRUE )

# Drop intermediate tables.
rxSqlServerDropTable(table = "Campaign_Product")
rxSqlServerDropTable(table = "Market_Lead")


##########################################################################################################################################

## Clean the Merged data set: replace NAs with the mode

##########################################################################################################################################

# Assumption: no NAs in the Id variables (Lead_Id, Product_Id, Campaign_Id, Comm_Id) and in (Phone_No, Launch_Date, Time_Stamp).

# Function to deal with NAs. 
Mode_Replace <- function(data) {
  data <- data.frame(data)
  var <- colnames(data)[!colnames(data) %in% c("Lead_Id", "Phone_No","Campaign_Id","Comm_Id","Time_Stamp","Launch_Date","Product_Id")]
  for(j in 1:length(var)){
    row_na <- which(is.na(data[,var[j]]) ==TRUE) 
    if(length(row_na) > 0){
      xtab <- table(data[,var[j]])
      mode <- names(which(xtab==max(xtab)))
      if(is.character(data[,var[j]]) | is.factor(data[,var[j]])){
        data[row_na,var[j]] <- mode
      } else{
        data[row_na,var[j]] <- as.integer(mode)
      }}}
  return(data)
}

# Create the CM_AD0 table by dealing with NAs in Merged and save it to a SQL table.
CM_AD0 <- RxSqlServerData(table = "CM_AD0", connectionString = connection_string)
rxDataStep(inData = Merged, outFile = CM_AD0, overwrite = TRUE, transformFunc = Mode_Replace)

# Drop intermediate tables.
rxSqlServerDropTable(table = "Merged")
 
