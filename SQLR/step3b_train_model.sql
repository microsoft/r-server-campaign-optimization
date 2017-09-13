/****** Stored Procedure to train models (Random Forest and GBT) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create an empty table to be filled with the trained models.
DROP TABLE if exists  [dbo].[Model];
CREATE TABLE [dbo].[Model](
	[id] [varchar](200) NOT NULL, 
	[value] [varbinary](max), 
	CONSTRAINT unique_id UNIQUE(id)
	) 

DROP PROCEDURE IF EXISTS [dbo].[train_model];
GO

CREATE PROCEDURE [train_model] @modelName varchar(20)
AS 
BEGIN

--	Get the current database name.
	DECLARE @database_name varchar(max) = db_name();

--	Train the model on CM_AD_Train.  
	DELETE FROM Model WHERE id = @modelName;

	EXECUTE sp_execute_external_script @language = N'R',
					   @script = N' 

##########################################################################################################################################
##	Set the compute context to SQL for faster training
##########################################################################################################################################
# Define the connection string. 
connection_string <- paste("Driver=SQL Server;Server=localhost;Database=", database_name, ";Trusted_Connection=true;", sep="")

# Set the Compute Context to SQL.
sql <- RxInSqlServer(connectionString = connection_string)
rxSetComputeContext(sql)

##########################################################################################################################################
##	Specify the types of the features before the training
##########################################################################################################################################
# Names of numeric variables: 
#numeric <- c("No_Of_Dependents", "No_Of_Children", "Household_Size", "No_Of_People_Covered", "Premium", "Net_Amt_Insured",
#			  "SMS_Count", "Email_Count", "Call_Count")

# Get the variables names, types and levels for factors.
CM_AD_N <- RxSqlServerData(table = "CM_AD_N", connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(CM_AD_N)

##########################################################################################################################################
##	Point to the training set and use the column_info list to specify the types of the features.
##########################################################################################################################################
CM_AD_Train <- RxSqlServerData(  
  sqlQuery = "SELECT *   
              FROM CM_AD_N 
              WHERE Lead_Id IN (SELECT Lead_Id from Train_Id)",
  connectionString = connection_string, colInfo = column_info)

##########################################################################################################################################
##	Specify the variables to keep for the training 
##########################################################################################################################################
variables_all <- rxGetVarNames(CM_AD_Train)
# We remove time stamps, variables with zero variance, and variables directly correlated to ones that are kept.
variables_to_remove <- c("Lead_Id", "Phone_No", "Country", "Comm_Id", "Time_Stamp", "Category", "Launch_Date", "Focused_Geography",
						 "Call_For_Action", "Product", "Campaign_Name")
traning_variables <- variables_all[!(variables_all %in% c("Conversion_Flag", variables_to_remove))]
formula <- as.formula(paste("Conversion_Flag ~", paste(traning_variables, collapse = "+")))

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
if (model_name == "RF") {
	# Train the Random Forest.
	model <- rxDForest(formula = formula,
	 			     data = CM_AD_Train,
				     nTree = 40,
 				     minBucket = 5,
				     minSplit = 10,
				     cp = 0.00005,
				     seed = 5
				     )
} else {
	# Train the GBT.
	model <- rxBTrees(formula = formula,
				    data = CM_AD_Train,
				    learningRate = 0.05,				    
				    minBucket = 5,
				    minSplit = 10,
				    cp = 0.0005,
				    nTree = 40,
				    seed = 5,
				    lossFunction = "multinomial")
}

########################################################################################################################################## 
## Save the model in SQL Server 
########################################################################################################################################## 
# Set the compute context to local for tables exportation to SQL.  
rxSetComputeContext("local") 

# Open an Odbc connection with SQL Server. 
OdbcModel <- RxOdbcData(table = "Model", connectionString = connection_string) 
rxOpen(OdbcModel, "w") 

# Write the model to SQL.  
rxWriteObject(OdbcModel, model_name, model) 
'
, @params = N'@model_name varchar(20), @database_name varchar(max)'
, @model_name = @modelName
, @database_name = @database_name  
;
END
GO
