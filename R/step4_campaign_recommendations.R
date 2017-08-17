##########################################################################################################################################
## This R script will determine recommendations for each Lead_Id
## The goal is to determine, for each Lead_Id, the best combination of Day_of_Week, Channel, Time_Of_Day to target him.
## The best combination will be the one that was assigned the highest probability of conversion with the best model selected by scoring.

## This is done by doing the following: 
## 1. Create a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day. 
## 2. Compute the predicted probabilities for each Lead_Id, for each combination of Day_Of_Week, Channel, Time_Of_Day, using best_model.
## 3. For each Lead_Id, choose the combination of Day_Of_Week, Channel, Time_Of_Day that has the highest conversion probability.

## Input : Data set CM_AD and the best prediction model, best_model. 
## Output: Recommended Day_Of_Week, Channel and Time_Of_Day for each Lead_Id, to get a higher conversion rate.  

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the compute context to Local.
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

## Input: - Point to the SQL table with the whole data set 
##        - Import the best model from the SQL server. 

##########################################################################################################################################

# Point to the SQL table holding the whole data set.
CM_AD <- RxSqlServerData(table = "CM_AD", connectionString = connection_string, colInfo = column_info)

# Create an Odbc connection with SQL Server using the name of the table storing the model. 
OdbcModel <- RxOdbcData(table = "Model", connectionString = connection_string) 

# Import the fitted best model
best_model <- rxReadObject(OdbcModel, best)

# Close the Obdc connection used. 
rxClose(OdbcModel)

##########################################################################################################################################

## Create a full data table with all the unique combinations of Day_of_Week, Channel, Time_Of_Day 


##########################################################################################################################################

# Create a table with all the unique combinations of Day_of_Week, Channel, Time_Of_Day.
Day_of_Week_unique <- data.frame(seq(1, 7))
Channel_unique <-data.frame(c("Email", "Cold Calling", "SMS"))
Time_Of_Day_unique <- data.frame(c("Morning", "Afternoon", "Evening"))
Unique_Combos <- merge(merge(Day_of_Week_unique, Channel_unique), Time_Of_Day_unique)
colnames(Unique_Combos) <- c("Day_Of_Week", "Channel", "Time_Of_Day")

# Export it to SQL
Unique_Combos_sql <- RxSqlServerData(table = "Unique_Combos", connectionString = connection_string)
rxDataStep(inData = Unique_Combos, outFile = Unique_Combos_sql, overwrite = T)


# We create a table that has, for each Lead_Id and its corresponding variables (except Day_of_Week, Channel, Time_Of_Day),
# One row for each possible combination of Day_of_Week, Channel and Time_Of_Day.
# This is a pointer. The table will be created on the fly while scoring.

# For a faster implementation, we are selecting only the top 10K customers. 
# For a full solution, you can remove TOP(10000) from the query below. 

AD_full_merged_sql <- RxSqlServerData(
  sqlQuery = "SELECT * 
              FROM (
                    SELECT TOP(10000) Lead_Id, Age, Annual_Income_Bucket, Credit_Score, State, No_Of_Dependents, Highest_Education,
                           Ethnicity, No_Of_Children, Household_Size, Gender, Marital_Status, Campaign_Id, Product_Id, Term,
                           No_Of_People_Covered, Premium, Payment_Frequency, Amt_On_Maturity_Bin, Sub_Category, Campaign_Drivers,
                           Tenure_Of_Campaign, Net_Amt_Insured, SMS_Count, Email_Count,  Call_Count, 
                           Previous_Channel, Conversion_Flag
                    FROM CM_AD) a,
                    (SELECT * FROM Unique_Combos) b", 
  stringsAsFactors = T, connectionString = connection_string, colInfo = column_info)


##########################################################################################################################################

## Compute the predicted probabilities for each Lead_Id, for each combination of Day_of_Week, Channel, Time_Of_Day, using best_model

##########################################################################################################################################

# Score the full data by using the best model.
Prob_Id <- RxSqlServerData(table = "Prob_Id ", stringsAsFactors = T, connectionString = connection_string)
rxPredict(best_model, data = AD_full_merged_sql, outData = Prob_Id, overwrite = T, type = "prob",
          extraVarsToWrite = c("Lead_Id", "Day_Of_Week", "Time_Of_Day", "Channel"))


##########################################################################################################################################

## For each Lead_Id, choose a combination of Day_of_Week, Channel, and Time_Of_Day that has the highest conversion probability    

##########################################################################################################################################

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

# Get the best combination per Lead_Id. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Recommended_Combinations;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"SELECT Lead_Id, Day_of_Week, Channel, Time_Of_Day, Max_Prob
 INTO Recommended_Combinations
 FROM (
       SELECT maxp.Lead_Id, Day_of_Week, Channel, Time_Of_Day, Max_Prob, 
              ROW_NUMBER() OVER (partition by maxp.Lead_Id ORDER BY NEWID()) as RowNo
       FROM ( SELECT Lead_Id, max([1_prob]) as Max_Prob
              FROM Prob_Id
              GROUP BY Lead_Id) maxp
       JOIN Prob_Id 
       ON (maxp.Lead_Id = Prob_Id.Lead_Id AND maxp.Max_Prob = Prob_Id.[1_prob])
  ) candidates
  WHERE RowNo = 1;"
, sep=""))


##########################################################################################################################################

## Add demographics information to the recommendation table  

##########################################################################################################################################

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Recommendations;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("
SELECT Age, Annual_Income_Bucket, Credit_Score, Product, Campaign_Name, State,  
       CAST(Conversion_Flag AS int) AS Conversion_Flag, CM_AD.Day_Of_Week, CM_AD.Time_Of_Day,
       CM_AD.Channel, CM_AD.Lead_Id, Recommended_Combinations.Day_Of_Week as [Recommended_Day],
       Recommended_Combinations.Time_Of_Day as [Recommended_Time], Recommended_Combinations.Max_Prob,
       Recommended_Combinations.Channel as [Recommended_Channel]
INTO Recommendations
FROM CM_AD JOIN Recommended_Combinations
ON CM_AD.Lead_Id = Recommended_Combinations.Lead_Id;"
, sep=""))

# Drop intermediate table.
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Recommended_Combinations;"
, sep=""))

