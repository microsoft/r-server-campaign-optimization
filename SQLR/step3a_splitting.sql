/****** Stored Procedure for splitting the data set into a training and a testing set  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[splitting]
GO

CREATE PROCEDURE [splitting]  @splitRatio float,
			      @connectionString varchar(300)
AS
BEGIN
  EXEC sp_execute_external_script @language = N'R',
                                  @script = N'								  
# Point to the input table. 
CM_AD_N <- RxSqlServerData(table = "CM_AD_N", connectionString = connection_string)

# Point to the output table. 
CM_AD1 <- RxSqlServerData(table = "CM_AD1", connectionString = connection_string)

# Add a Split_Vector variable. For each unique Lead_Id, it is equal to 1 with proportion splitRatio, and 0 otherwise. 
# When splitRatio = 1, the record goes to the training set. When splitRatio = 0, it goes to the testing set.
rxDataStep(inData = CM_AD_N, outFile = CM_AD1, overwrite = TRUE, transforms = list(
					Split_Vector = rbinom(.rxNumRows, 1, splitRatio)),
					transformObjects = list(splitRatio = splitRatio))
'
, @params = N' @splitRatio  float, @connection_string varchar(300)'
, @splitRatio = @splitRatio     
, @connection_string = @connectionString                

;
END
GO

