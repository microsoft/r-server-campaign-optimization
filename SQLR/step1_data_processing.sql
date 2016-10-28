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
        DROP TABLE if exists Merged
	UPDATE STATISTICS Product;
	UPDATE STATISTICS Campaign_Detail;
	UPDATE STATISTICS Lead_Demography;
	UPDATE STATISTICS Market_Touchdown;

/* Inner join of the tables Product and Campaign_Detail */ 
	SELECT Campaign_Detail.*, Product.Product, Product.Term, Product.No_of_people_covered, Product.Premium, 
	       Product.Payment_frequency, Product.Net_Amt_Insured, Product.Amt_on_Maturity, Product.Amt_on_Maturity_Bin
	INTO Campaign_Product
	FROM Campaign_Detail JOIN Product
	ON Product.Product_Id = Campaign_Detail.Product_Id

/* Inner join of the tables Market_Touchdown and Lead_Demography */
	SELECT Lead_Demography.*, Market_Touchdown.Channel, Market_Touchdown.Time_Of_Day, Market_Touchdown.Conversion_Flag,
               Market_Touchdown.Campaign_Id, Market_Touchdown.Day_Of_Week, Market_Touchdown.Comm_Id, Market_Touchdown.Time_Stamp
	INTO Market_Lead
	FROM Market_Touchdown JOIN Lead_Demography
	ON Market_Touchdown.Lead_Id = Lead_Demography.Lead_Id

/* Inner join of the tables Campaign_Product and Market_Lead */ 
	UPDATE STATISTICS Campaign_Product;
	UPDATE STATISTICS Market_Lead;

	SELECT Market_Lead.*, Campaign_Product.Product, Campaign_Product.Category, Campaign_Product.Term, 
           Campaign_Product.No_of_people_covered, Campaign_Product.Premium, Campaign_Product.Payment_frequency, 
           Campaign_Product.Amt_on_Maturity_Bin, Campaign_Product.Sub_Category, Campaign_Product.Campaign_Drivers, 
           Campaign_Product.Campaign_Name, Campaign_Product.Launch_Date, Campaign_Product.Call_For_Action, 
           Campaign_Product.Focused_Geography, Campaign_Product.Tenure_Of_Campaign, Campaign_Product.Net_Amt_Insured, 
           Campaign_Product.Product_Id
	INTO Merged
	FROM Campaign_Product JOIN Market_Lead
	ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id 

/* Delete intermediate tables */
	DROP TABLE if exists Campaign_Product
	DROP TABLE if exists Market_Lead
;
END
GO

/****** Stored Procedure to deal with NA in the raw merged data set ******/
/****** Replace NAs with the mode ******/

DROP PROCEDURE IF EXISTS [dbo].[fill_NA]
GO

CREATE PROCEDURE [fill_NA] @connectionString varchar(300)
AS
BEGIN
  EXEC sp_execute_external_script @language = N'R',
                                  @script = N'								  
# Input Data Set 
Merged <- RxSqlServerData(table = "Merged", connectionString = connection_string)

# Function to deal with NAs. 
## We assume no NA in Lead_Id, Phone_No, Campaign_Id, Comm_Id, Time_Stamp, Launch_Date, and Product_Id.
## For the other variables, we detect the rows with NAs, and if any, we replace them with the mode.
## Among those, for integer variables, the mode has to be converted to an integer before writing the results (to comply with the type).

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

# Clean the data set and save it into a SQL table.
CM_AD0 <- RxSqlServerData(table = "CM_AD0", connectionString = connection_string)
rxDataStep(inData = Merged, outFile = CM_AD0, overwrite = TRUE, transformFunc = Mode_Replace)
'
, @params = N'@connection_string varchar(300)'
, @connection_string = @connectionString
;
END
GO
