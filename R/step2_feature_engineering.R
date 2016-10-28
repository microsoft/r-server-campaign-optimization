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

# Load revolution R library. 
library(RevoScaleR)

# Compute Contexts.
connection_string <- "Driver=SQL Server; Server=[Server Name]; Database=Campaign; UID=[User ID]; PWD=[User Password]"
sql <- RxInSqlServer(connectionString = connection_string)
local <- RxLocalSeq()

# Set the compute context to SQL for feature engineering. It will be changed to local whenever data is exported from R to SQL.
rxSetComputeContext(sql)


##########################################################################################################################################

## Input: Point to the SQL table with the cleaned raw data set

##########################################################################################################################################

CM_AD0 <- RxSqlServerData(table = "CM_AD0", connectionString = connection_string, stringsAsFactors = T)


##########################################################################################################################################

## Feature Engineering: SMS_Count, Email_Count, and Call_Count
## Determine how many times each Lead_Id was contacted through SMS, Email and Call

##########################################################################################################################################

# Determine how many times each Lead_Id was contacted through SMS, Email and Call through a SQL query. 

Intermediate0 <- RxSqlServerData(  
  sqlQuery = "SELECT Lead_Id, 
                     coalesce(count(case when Channel = 'SMS' then 1 end), 0) as SMS_Count,
                     coalesce(count(case when Channel = 'Cold Calling' then 1 end), 0) as Call_Count,
                     coalesce(count(case when Channel = 'Email' then 1 end), 0) as Email_Count
              FROM CM_AD0
              GROUP BY Lead_Id",
  connectionString = connection_string)

Intermediate <- RxSqlServerData(table = "Intermediate", connectionString = connection_string)
rxDataStep(inData = Intermediate0, outFile = Intermediate, overwrite = TRUE)

##########################################################################################################################################

## Feature Engineering: Previous_Channel
## Determine the previous channel used towards every Lead_Id for every campaign activity (disregarding the first record for each Lead_Id) 

##########################################################################################################################################

# Determine the previous channel used towards the Lead_Id, for every record except the first.

## Create a lag variable corresponding to the previous channel, while performing an inner join to append the Counts. 
Intermediate1 <- RxSqlServerData(  
    sqlQuery = "SELECT CM_AD0.*, Intermediate.SMS_Count, Intermediate.Email_Count, Intermediate.Call_Count, 
                       LAG(Channel, 1,0) OVER (Partition by CM_AD0.Lead_Id ORDER BY CM_AD0.Lead_Id, Comm_Id ASC) AS Previous_Channel,
                       ROW_NUMBER() OVER (PARTITION BY CM_AD0.Lead_Id ORDER BY CM_AD0.Comm_Id DESC) AS Row
                FROM Intermediate JOIN CM_AD0 
                ON Intermediate.Lead_Id = CM_AD0.Lead_Id ",
    connectionString = connection_string)
  
Intermediate2 <- RxSqlServerData(table = "Intermediate2", connectionString = connection_string)
rxDataStep(inData = Intermediate1, outFile = Intermediate2, overwrite = TRUE )


##########################################################################################################################################
  
## Keep the latest campaign activity each Lead_Id received
  
##########################################################################################################################################

# Keeping the last record for each Lead_Id.
Intermediate3 <- RxSqlServerData(  
      sqlQuery = "SELECT *  
                  FROM Intermediate2
                  WHERE Row = 1 ",
      connectionString = connection_string)

# Removing the Row number variables. CM_AD is the data set that will be used for modeling. 
CM_AD <- RxSqlServerData(table = "CM_AD", connectionString = connection_string)
rxDataStep(inData = Intermediate3, outFile = CM_AD, overwrite = TRUE, transforms = list(
      Row = NULL
    ))
    

##########################################################################################################################################
    
## Drop intermediate tables. 
    
##########################################################################################################################################
    
rxSqlServerDropTable(table = "Intermediate")
rxSqlServerDropTable(table = "Intermediate2")
