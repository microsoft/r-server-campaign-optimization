SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Stored Procedure to join the 4 tables and create the raw data set  ******/

DROP PROCEDURE IF EXISTS [dbo].[Merging_Raw_Tables]
GO

CREATE PROCEDURE [dbo].[Merging_Raw_Tables]
AS
BEGIN

	DROP TABLE if exists Campaign_Product
	DROP TABLE if exists Market_Lead
    DROP TABLE if exists CM_AD0
	UPDATE STATISTICS Product;
	UPDATE STATISTICS Campaign_Detail;
	UPDATE STATISTICS Lead_Demography;
	UPDATE STATISTICS Market_Touchdown;

/* Inner join of the tables Product and Campaign_Detail */ 
	SELECT Campaign_Detail.*, Term, No_of_people_covered, Payment_frequency, Net_Amt_Insured, Amt_on_Maturity_Bin, 
               Product, Premium
	INTO Campaign_Product
	FROM Campaign_Detail JOIN Product
	ON Product.Product_Id = Campaign_Detail.Product_Id

/* Inner join of the tables Market_Touchdown and Lead_Demography */
	SELECT Lead_Demography.Lead_Id, Age, Phone_No, Annual_Income_Bucket, Credit_Score, Country, [State],
               No_Of_Dependents, Highest_Education, Ethnicity, No_Of_Children, Household_Size, Gender, 
               Marital_Status, Channel, Time_Of_Day, Conversion_Flag, Campaign_Id, Day_Of_Week, Comm_Id, Time_Stamp
	INTO Market_Lead
	FROM Market_Touchdown JOIN Lead_Demography
	ON Market_Touchdown.Lead_Id = Lead_Demography.Lead_Id

/* Inner join of the tables Campaign_Product and Market_Lead */ 
	UPDATE STATISTICS Campaign_Product;
	UPDATE STATISTICS Market_Lead;
	
	SELECT Market_Lead.*, Product, Category, Term, No_of_people_covered, Premium, Payment_frequency,
           Amt_on_Maturity_Bin, Sub_Category, Campaign_Drivers, Campaign_Name, Launch_Date, Call_For_Action, 
           Focused_Geography, Tenure_Of_Campaign, Net_Amt_Insured, Product_Id
	INTO CM_AD0
	FROM Campaign_Product JOIN Market_Lead
	ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id 

;
END
GO

/****** Stored Procedure to compute the mode and fill the missing values with it for 1 column. ******/
DROP PROCEDURE IF EXISTS [dbo].[fill_NA]
GO

CREATE PROCEDURE [fill_NA] @name varchar(max), @table varchar(max)
AS
BEGIN
	
	DECLARE @mode varchar(50);
	DECLARE @sql1 nvarchar(max);
	DECLARE @Parameter nvarchar(500);
	SELECT @sql1 = N'
    SELECT @modeOUT = mode
	FROM (SELECT TOP(1) ' + @name + ' as mode, count(*) as cnt
		   FROM ' + @table + ' 
	       GROUP BY ' + @name + ' 
	       ORDER BY cnt desc) as t ';
	SET @Parameter = N'@modeOUT varchar(max) OUTPUT';
	EXEC sp_executesql @sql1, @Parameter, @modeOUT=@mode OUTPUT;

    DECLARE @sql2 nvarchar(max)
	SET @sql2 = 
   'UPDATE ' + @table + '
	SET ' + @name + ' = ISNULL(' + @name + ', (SELECT '''  + @mode + '''))';

	EXEC sp_executesql @sql2;
	 		   
END
GO
;


/****** Stored Procedure to replace the missing values with the modes for all columns ******/
DROP PROCEDURE IF EXISTS [dbo].[fill_NA_all]
GO

CREATE PROCEDURE [fill_NA_all] 
AS
BEGIN
     /* Select all column names into the table sql_columns */
	DROP TABLE if EXISTS sql_columns
	SELECT name 
	INTO sql_columns
	FROM syscolumns 
	WHERE id = object_id('CM_AD0')

    /* Exclude variables for which we assume there are no missing values */
	DELETE FROM sql_columns 
	WHERE name = 'Lead_Id' or name = 'Phone_No' or name = 'Product_Id' 
	   or name = 'Campaign_Id' or name = 'Comm_Id' or name = 'Launch_Date' or name = 'Time_Stamp'

    /* Loops to fill missing values for the variables in CM_AD0 */
	DECLARE @name_1 NVARCHAR(100)
	DECLARE @getname CURSOR

	SET @getname = CURSOR FOR
	SELECT name
	FROM  sql_columns

	OPEN @getname
	FETCH NEXT
	FROM @getname INTO @name_1
	WHILE @@FETCH_STATUS = 0
	BEGIN
		print @name_1
		EXEC fill_NA @name_1,'CM_AD0' 
		FETCH NEXT
		FROM @getname INTO @name_1
	END
	CLOSE @getname
	DEALLOCATE @getname
END
GO
;

