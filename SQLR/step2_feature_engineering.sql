/****** Stored Procedure for feature engineering  ******/
/****** SMS_Count, Email_Count, and Call_Count: how many times each Lead_Id was contacted through each channel  ******/
/****** Previous_Channel: the previous channel used towards every Lead_Id for every campaign activity ******/
/****** Only the latest campaign activity each Lead_Id received is kept ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[feature_engineering]
GO

CREATE PROCEDURE [dbo].[feature_engineering]  
AS
BEGIN

/* Create SMS_Count, Email_Count, and Call_Count. */ 

	DROP TABLE if exists Intermediate;
	CREATE TABLE Intermediate(
		Lead_Id varchar(50) NOT NULL Primary Key,
		SMS_Count int NOT NULL,
		Call_Count int NOT NULL,
		Email_Count int NOT NULL
	);

	INSERT INTO Intermediate
	SELECT Lead_Id, 
	       coalesce(count(case when Channel = 'SMS' then 1 end), 0) as SMS_Count,
               coalesce(count(case when Channel = 'Cold Calling' then 1 end), 0) as Call_Count,
               coalesce(count(case when Channel = 'Email' then 1 end), 0) as Email_Count
	FROM CM_AD0
	GROUP BY Lead_Id;

	UPDATE STATISTICS Intermediate;

/* Create Previous_Channel. The first campaign activity for each Lead_Id will be disregarded. */ 
	DROP TABLE IF EXISTS Intermediate2; 
	
	SELECT CM_AD0.*, Intermediate.SMS_Count, Intermediate.Email_Count, Intermediate.Call_Count, 
	       LAG(Channel, 1,0) OVER (PARTITION BY CM_AD0.Lead_ID ORDER BY CM_AD0.Lead_Id, Comm_Id ASC) AS Previous_Channel,
	       ROW_NUMBER() OVER (PARTITION BY CM_AD0.Lead_Id ORDER BY Comm_Id DESC) AS Row 
	INTO Intermediate2
	FROM Intermediate JOIN CM_AD0 
	ON Intermediate.Lead_Id = CM_AD0.Lead_Id;

	CREATE NONCLUSTERED INDEX idx_row ON Intermediate2(Row);

/* Keep the latest record for each Lead_Id. */ 
	INSERT INTO CM_AD
	SELECT * 
	FROM Intermediate2
	WHERE Row = 1

	ALTER TABLE CM_AD DROP COLUMN Row

/* Drop intermediate tables. */
	DROP TABLE  Intermediate
	DROP TABLE  Intermediate2
;
END
GO



