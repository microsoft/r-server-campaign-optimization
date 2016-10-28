SET ansi_nulls on
GO

SET quoted_identifier on
GO


/*  Create the Campaign_Detail Table. */  

DROP TABLE IF EXISTS Campaign_Detail
GO
CREATE TABLE Campaign_Detail
(
Campaign_Id varchar(1),
Campaign_Name varchar(50),
Category varchar(15),
Launch_Date varchar(12),
Sub_Category varchar(15),
Campaign_Drivers varchar(50),
Product_Id varchar(1),
Call_For_Action	varchar(1),
Focused_Geography varchar(15),
Tenure_Of_Campaign varchar(1)
);

CREATE CLUSTERED COLUMNSTORE INDEX campaign_detail_cci ON Campaign_Detail WITH (DROP_EXISTING = OFF);

/*  Create the Lead_Demography Table. */  

DROP TABLE IF EXISTS Lead_Demography
GO
CREATE TABLE Lead_Demography
(
Lead_Id varchar(15),
Age	varchar(30),
Phone_No varchar(15),
Annual_Income_Bucket varchar(15),
Credit_Score varchar(15),
Country varchar(5),
[State] varchar(2),
No_Of_Dependents int,
Highest_Education varchar(30),
Ethnicity varchar(20),
No_Of_Children int,
Household_Size int,
Gender varchar(1),
Marital_Status varchar(1)
);

CREATE CLUSTERED COLUMNSTORE INDEX lead_demography_cci ON Lead_Demography WITH (DROP_EXISTING = OFF);

/* Create the Market_Touchdown Table*/  

DROP TABLE IF EXISTS Market_Touchdown
GO
CREATE TABLE Market_Touchdown
(
Lead_Id varchar(15),
Channel varchar(15),
Time_Of_Day varchar(15),
Day_Of_Week varchar(1),
Campaign_Id varchar(1),
Conversion_Flag varchar(1),
Source	varchar(30),
Time_Stamp varchar(12),
Comm_Id int
);

CREATE CLUSTERED COLUMNSTORE INDEX Market_cci ON Market_Touchdown WITH (DROP_EXISTING = OFF);


/* Create the Product Table. */  

DROP TABLE IF EXISTS Product
GO
CREATE TABLE Product
(
Product_Id	varchar(1),
Product varchar(50),
Category varchar(50),
Term int,
No_of_people_covered int,
Premium	int,
Payment_frequency varchar(20),
Net_Amt_Insured	int,
Amt_on_Maturity int,
Amt_on_Maturity_Bin	varchar(30)
);

CREATE CLUSTERED COLUMNSTORE INDEX Product_cci ON Product WITH (DROP_EXISTING = OFF);

/* Create the CM_AD0 Table. It will be filled in Step 1, after removing NAs from the raw data. */  

DROP TABLE IF EXISTS CM_AD0
GO
CREATE TABLE CM_AD0
(
 Lead_Id varchar(15) NOT NULL
,Age varchar(30)
,Phone_No varchar(15)
,Annual_Income_Bucket varchar(15)
,Credit_Score  varchar(15)
,Country varchar(5)
,[State] varchar(2)
,No_Of_Dependents int
,Highest_Education varchar(30) 
,Ethnicity varchar(20)
,No_Of_Children int 
,Household_Size int 
,Gender varchar(1)
,Marital_Status varchar(1)
,Channel varchar(15)
,Time_Of_Day varchar(15)
,Conversion_Flag varchar(1)
,Campaign_Id varchar(1)
,Day_Of_Week varchar(1)
,Comm_Id int  NOT NULL
,Time_Stamp date
,Product varchar(50)
,Category varchar(15)
,Term int
,No_of_people_covered int
,Premium int 
,Payment_frequency varchar(20)
,Amt_on_Maturity_Bin varchar(30)
,Sub_Category varchar(15)
,Campaign_Drivers varchar(50)
,Campaign_Name varchar(50)
,Launch_Date date
,Call_For_Action varchar(1)
,Focused_Geography varchar(15)
,Tenure_Of_Campaign varchar(1)
,Net_Amt_Insured int
,Product_Id varchar(1)
)
;

ALTER TABLE CM_AD0 add constraint pk_cmad0 primary key clustered (Lead_Id, Comm_Id);

/* Create the CM_AD Table. It will be filled in Step 2, after feature engineering. */  

DROP TABLE IF EXISTS CM_AD
GO
CREATE TABLE CM_AD
(
 Lead_Id varchar(15) NOT NULL Primary Key
,Age varchar(30)
,Phone_No varchar(50)
,Annual_Income_Bucket varchar(15)
,Credit_Score  varchar(15)
,Country varchar(5)
,[State] varchar(2)
,No_Of_Dependents int
,Highest_Education varchar(30) 
,Ethnicity varchar(20)
,No_Of_Children int 
,Household_Size int 
,Gender varchar(1)
,Marital_Status varchar(1)
,Channel varchar(15)
,Time_Of_Day varchar(15)
,Conversion_Flag varchar(1)
,Campaign_Id varchar(1)
,Day_Of_Week varchar(1)
,Comm_Id int 
,Time_Stamp varchar(12)
,Product varchar(50)
,Category varchar(15)
,Term int
,No_of_people_covered int
,Premium int 
,Payment_frequency varchar(50)
,Amt_on_Maturity_Bin varchar(50)
,Sub_Category varchar(15)
,Campaign_Drivers varchar(50)
,Campaign_Name varchar(50)
,Launch_Date varchar(12)
,Call_For_Action varchar(1)
,Focused_Geography varchar(15)
,Tenure_Of_Campaign varchar(1)
,Net_Amt_Insured int
,Product_Id varchar(1)
,SMS_Count int
,Email_Count int
,Call_Count int 
,Previous_Channel varchar(15)
,[Row] int
)
;

/* Create the CM_AD1 Table. It will be filled in Step 3a, after creating a Split_Vector variable for splitting into a training and a testing set. */  

DROP TABLE IF EXISTS CM_AD1
GO
CREATE TABLE CM_AD1
(
  Lead_Id varchar(15) NOT NULL Primary Key
,Age varchar(30)
,Phone_No varchar(50)
,Annual_Income_Bucket varchar(15)
,Credit_Score  varchar(15)
,Country varchar(5)
,[State] varchar(2)
,No_Of_Dependents int
,Highest_Education varchar(30) 
,Ethnicity varchar(20)
,No_Of_Children int 
,Household_Size int 
,Gender varchar(1)
,Marital_Status varchar(1)
,Channel varchar(15)
,Time_Of_Day varchar(15)
,Conversion_Flag varchar(1)
,Campaign_Id varchar(1)
,Day_Of_Week varchar(1)
,Comm_Id int 
,Time_Stamp varchar(12)
,Product varchar(50)
,Category varchar(15)
,Term int
,No_of_people_covered int
,Premium int 
,Payment_frequency varchar(50)
,Amt_on_Maturity_Bin varchar(50)
,Sub_Category varchar(15)
,Campaign_Drivers varchar(50)
,Campaign_Name varchar(50)
,Launch_Date varchar(12)
,Call_For_Action varchar(1)
,Focused_Geography varchar(15)
,Tenure_Of_Campaign varchar(1)
,Net_Amt_Insured int
,Product_Id varchar(1)
,SMS_Count int
,Email_Count int
,Call_Count int 
,Previous_Channel varchar(15)
,Split_Vector int
)
;

/* Create the AD_full_merged Table. It will be filled in Step 4, after scoring the full data table with the selected model. */  
DROP TABLE IF EXISTS AD_full_merged
GO
CREATE TABLE AD_full_merged
(
 Lead_Id varchar(15) NOT NULL 
,Age varchar(30)
,Annual_Income_Bucket varchar(15)
,Credit_Score  varchar(15)
,[State] varchar(2)
,No_Of_Dependents int
,Highest_Education varchar(30) 
,Ethnicity varchar(20)
,No_Of_Children int 
,Household_Size int 
,Gender varchar(1)
,Marital_Status varchar(1)
,Campaign_Id varchar(1)
,Product_Id varchar(1)
,Product varchar(50)
,Term int
,No_of_people_covered int
,Premium int 
,Payment_frequency varchar(50)
,Amt_on_Maturity_Bin varchar(50)
,Sub_Category varchar(15)
,Campaign_Drivers varchar(50)
,Campaign_Name varchar(50)
,Call_For_Action varchar(1)
,Tenure_Of_Campaign varchar(1)
,Net_Amt_Insured int
,SMS_Count int
,Email_Count int
,Call_Count int 
,Previous_Channel varchar(15)
,Conversion_Flag varchar(1)
,Channel varchar(15) NOT NULL
,Day_Of_Week varchar(1) NOT NULL
,Time_Of_Day varchar(15) NOT NULL
)
;

ALTER TABLE AD_full_merged add constraint pk_cadfull primary key clustered (Lead_Id, Channel, Day_Of_Week, Time_Of_Day);

/* Create the Prob_Id Table. It will be filled in Step 4, after scoring the full data table with the selected model. */  

DROP TABLE IF EXISTS Prob_Id
GO
CREATE TABLE Prob_Id
(
[0_prob] float,
[1_prob] float, 
[Majority_Vote] int,
Lead_Id varchar(15) NOT NULL, 
Day_Of_Week varchar(1) NOT NULL, 
Time_Of_Day varchar(15) NOT NULL, 
Channel varchar(15) NOT NULL
)
;

