
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

/** Stored Procedure to Compute the predicted probabilities for each Lead_Id, for each combination of Day-Channel-Time using best_model ******/

DROP PROCEDURE IF EXISTS [dbo].[scoring]
GO

CREATE PROCEDURE [scoring] @bestModel varchar(300)

AS
BEGIN

/*	Get the current database name. */
	DECLARE @database_name varchar(max) = db_name();

/* Create a table containing all the unique combinations of Day_of_Week. Channel and Time_Of_Day were created before normalization. */
	DROP TABLE IF EXISTS Day_Of_Week
	DROP TABLE IF EXISTS Unique_Combos

	CREATE TABLE Day_Of_Week (Day_Of_Week char(1)) 	
	INSERT INTO Day_Of_Week (Day_Of_Week) VALUES ('1'), ('2'), ('3'), ('4'),('5'),('6'),('7')

	SELECT *
	INTO Unique_Combos
	FROM(SELECT Channel_id AS Channel FROM Channel_N)  c, (SELECT * FROM Day_Of_Week) d, (SELECT Time_Of_Day_id AS Time_Of_Day FROM Time_Of_Day_N) t

/* Scoring on a table created on the fly. */
/* It has, for each Lead_Id and its corresponding variables, One row for each possible combination of Day_of_Week, Channel and Time_Of_Day. */
    
    EXEC sp_execute_external_script @language = N'R',
				    @script = N'								  

##########################################################################################################################################
##	Get the model.
##########################################################################################################################################
# Define the connection string. 
connection_string <- paste("Driver=SQL Server;Server=localhost;Database=", database_name, ";Trusted_Connection=true;", sep="")

# Create an Odbc connection with SQL Server using the name of the table storing the models. 
OdbcModel <- RxOdbcData(table = "Model", connectionString = connection_string) 

# Read the model from SQL. 
best_model <- rxReadObject(OdbcModel, bestModel)

##########################################################################################################################################
##	Specify the types of the features before the scoring
##########################################################################################################################################
# Names of numeric variables: 
#numeric <- c("No_Of_Dependents", "No_Of_Children", "Household_Size", "No_Of_People_Covered", "Premium", "Net_Amt_Insured",
#			  "SMS_Count", "Email_Count", "Call_Count")

# Get the variables names, types and levels for factors.
CM_AD_N <- RxSqlServerData(table = "CM_AD_N", connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(CM_AD_N)

##########################################################################################################################################
##	Point to the input and output tables and use the column_info list to specify the types of the features.
##########################################################################################################################################
# For a faster implementation, we are taking the TOP 10K customers. 
# For a full solution, you can remove TOP(10000) from the query below. 

AD_full_merged_sql <- RxSqlServerData(
  sqlQuery = "	SELECT * 
		FROM (
		      SELECT TOP(10000) Lead_Id, Age, Annual_Income_Bucket, Credit_Score, [State], No_Of_Dependents, Highest_Education,
			     Ethnicity, No_Of_Children, Household_Size, Gender, Marital_Status, Campaign_Id, Product_Id, Term,
			     No_Of_People_Covered, Premium, Payment_Frequency, Amt_On_Maturity_Bin, Sub_Category, Campaign_Drivers,
			     Tenure_Of_Campaign, Net_Amt_Insured, SMS_Count, Email_Count,  Call_Count, 
			     Previous_Channel, Conversion_Flag
			     FROM CM_AD_N) a,
		      (SELECT * FROM Unique_Combos)  b", 
  stringsAsFactors = T, connectionString = connection_string, colInfo = column_info)

# Point to the output data set.
Prob_Id <- RxSqlServerData(table = "Prob_Id", connectionString = connection_string)

##########################################################################################################################################
##	Score the full data by using the best model.
##########################################################################################################################################
rxPredict(best_model, data = AD_full_merged_sql, outData = Prob_Id, type = "prob", overwrite = T,
		  extraVarsToWrite = c("Lead_Id", "Day_Of_Week", "Time_Of_Day", "Channel"))
'
, @params = N' @bestModel varchar(300), @database_name varchar(max)' 
, @bestModel = @bestModel 
, @database_name = @database_name 
   
;
END
GO

/** Stored Procedure to provide, for each Lead, the Day_of_Week, Channel, and Time_Of_Day with the highest conversion probability **/

DROP PROCEDURE IF EXISTS [dbo].[campaign_recommendation]
GO

CREATE PROCEDURE [campaign_recommendation] @bestModel varchar(300)
																						  
AS
BEGIN

	DROP TABLE IF EXISTS Recommended_Combinations
	DROP TABLE IF EXISTS Recommendations

	EXEC [scoring] @bestModel = @bestModel

/* For each Lead_Id, get one of the combinations of Day_of_Week, Channel, and Time_Of_Day giving highest conversion probability */ 
	
	SELECT Lead_Id, Day_of_Week, Channel, Time_Of_Day, Max_Prob
	INTO Recommended_Combinations
	FROM (
		SELECT maxp.Lead_Id, Day_of_Week, Channel, Time_Of_Day, Max_Prob, 
		       ROW_NUMBER() OVER (partition by maxp.Lead_Id ORDER BY NEWID()) as RowNo
		FROM (
			SELECT Lead_Id, max([1_prob]) as Max_Prob
			FROM Prob_Id
			GROUP BY Lead_Id) maxp
		JOIN Prob_Id
		ON (maxp.Lead_Id = Prob_Id.Lead_Id AND maxp.Max_Prob = Prob_Id.[1_prob])
         ) candidates
	WHERE RowNo = 1

/* Add demographics information to the recommendation table  */

	SELECT Age, Annual_Income_Bucket, Credit_Score, Product, Campaign_Name, [State], CM_AD.Channel, 
               CM_AD.Day_Of_Week, CM_AD.Time_Of_Day, CAST(Conversion_Flag AS int) as Conversion_Flag,
	       Recommended_Combinations.Day_Of_Week as [Recommended_Day], Time_Of_Day_N.Time_Of_Day as [Recommended_Time],
	       Channel_N.Channel as [Recommended_Channel], Recommended_Combinations.Max_Prob, Recommended_Combinations.Lead_Id
        INTO Recommendations
	FROM CM_AD 
	JOIN Recommended_Combinations ON CM_AD.Lead_Id = Recommended_Combinations.Lead_Id
	JOIN Channel_N ON Channel_N.Channel_id = Recommended_Combinations.Channel
	JOIN Time_Of_Day_N ON Time_Of_Day_N.Time_Of_Day_id = Recommended_Combinations.Time_Of_Day

/* Drop intermediate table  */
	DROP TABLE Recommended_Combinations
;
END
GO
