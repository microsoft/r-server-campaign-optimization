##########################################################################################################################################
## This R script will do the following :
## 1. Create the variables SMS_Count, Email_Count, and Call_Count: number of times each Lead_Id was contacted through each channel.
## 2. Create the variable Previous_Channel: the previous channel used towards the Lead_Id in the campaign.
## 3. Aggregate the data by Lead_Id, keeping the latest campaign activity each Lead_Id received. 

## Input : Data set before feature engineering, and with all the campaign activities received by each Lead_Id, CM_AD0.
## Output: Data set with new features and the latest campaign activity each Lead_Id received, CM_AD.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the Compute Context to SQL.
rxSetComputeContext(sql)


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

## Input: Point to the SQL table with the cleaned raw data set

##########################################################################################################################################

CM_AD0 <- RxSqlServerData(table = "CM_AD0", connectionString = connection_string)


##########################################################################################################################################

## Feature Engineering: SMS_Count, Email_Count, and Call_Count
## Determine how many times each Lead_Id was contacted through SMS, Email and Call

##########################################################################################################################################

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

# Determine how many times each Lead_Id was contacted through SMS, Email and Call through a SQL query. 

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Intermediate;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"SELECT Lead_Id, 
        coalesce(count(case when Channel = 'SMS' then 1 end), 0) as SMS_Count,
        coalesce(count(case when Channel = 'Cold Calling' then 1 end), 0) as Call_Count,
        coalesce(count(case when Channel = 'Email' then 1 end), 0) as Email_Count
 INTO Intermediate
 FROM CM_AD0
 GROUP BY Lead_Id;"
, sep=""))


##########################################################################################################################################

## Feature Engineering: Previous_Channel
## Determine the previous channel used towards every Lead_Id for every campaign activity (disregarding the first record for each Lead_Id) 

##########################################################################################################################################

# Determine the previous channel used towards the Lead_Id, for every record except the first.
# Create a lag variable corresponding to the previous channel, while performing an inner join to append the Counts. 

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Intermediate2;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"SELECT CM_AD0.*, Intermediate.SMS_Count, Intermediate.Email_Count, Intermediate.Call_Count, 
        LAG(Channel, 1,0) OVER (Partition by CM_AD0.Lead_Id ORDER BY CM_AD0.Lead_Id, Comm_Id ASC) AS Previous_Channel,
        ROW_NUMBER() OVER (PARTITION BY CM_AD0.Lead_Id ORDER BY CM_AD0.Comm_Id DESC) AS Row
 INTO Intermediate2
 FROM Intermediate JOIN CM_AD0 
 ON Intermediate.Lead_Id = CM_AD0.Lead_Id ;"
, sep=""))


##########################################################################################################################################
  
## Keep the latest campaign activity each Lead_Id received
  
##########################################################################################################################################

# CM_AD is the data set that will be used for modeling. 
# In order to ensure coherence between the SQL SP code and the R code, we specify here the types of the variables in CM_AD. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists CM_AD;", sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("CREATE TABLE CM_AD
(
  Lead_Id varchar(15) NOT NULL Primary Key
  ,Age varchar(30)
  ,Phone_No varchar(50)
  ,Annual_Income_Bucket varchar(15)
  ,Credit_Score  varchar(15)
  ,Country varchar(5)
  ,[State] char(2)
  ,No_Of_Dependents int
  ,Highest_Education varchar(30) 
  ,Ethnicity varchar(20)
  ,No_Of_Children int 
  ,Household_Size int 
  ,Gender char(1)
  ,Marital_Status char(1)
  ,Channel varchar(15)
  ,Time_Of_Day varchar(15)
  ,Conversion_Flag char(1)
  ,Campaign_Id char(1)
  ,Day_Of_Week char(1)
  ,Comm_Id char(1)
  ,Time_Stamp date
  ,Product varchar(50)
  ,Category varchar(15)
  ,Term char(2)
  ,No_Of_People_Covered int
  ,Premium int 
  ,Payment_Frequency varchar(50)
  ,Amt_On_Maturity_Bin varchar(50)
  ,Sub_Category varchar(15)
  ,Campaign_Drivers varchar(50)
  ,Campaign_Name varchar(50)
  ,Launch_Date date
  ,Call_For_Action char(1)
  ,Focused_Geography varchar(15)
  ,Tenure_Of_Campaign char(1)
  ,Net_Amt_Insured int
  ,Product_Id char(1)
  ,SMS_Count int
  ,Email_Count int
  ,Call_Count int 
  ,Previous_Channel varchar(15)
  ,[Row] int
);"
, sep=""))


# Keeping the last record for each Lead_Id. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"INSERT INTO CM_AD
 SELECT *  
 FROM Intermediate2
 WHERE Row = 1  ;"
  , sep=""))

# Removing the Row number variables. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("ALTER TABLE CM_AD DROP COLUMN Row;", sep=""))
    

##########################################################################################################################################
    
## Drop intermediate tables
    
##########################################################################################################################################
    
rxSqlServerDropTable(table = "Intermediate", connectionString = connection_string)
rxSqlServerDropTable(table = "Intermediate2", connectionString = connection_string)