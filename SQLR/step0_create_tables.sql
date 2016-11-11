SET ansi_nulls on
GO
SET quoted_identifier on
GO

/*  Create the Campaign_Detail Table. */  

DROP TABLE IF EXISTS Campaign_Detail
GO
CREATE TABLE Campaign_Detail
(
Campaign_Id char(1),
Campaign_Name varchar(50),
Category varchar(15),
Launch_Date varchar(12),
Sub_Category varchar(15),
Campaign_Drivers varchar(50),
Product_Id char(1),
Call_For_Action	char(1),
Focused_Geography varchar(15),
Tenure_Of_Campaign char(1)
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
[State] char(2),
No_Of_Dependents int,
Highest_Education varchar(30),
Ethnicity varchar(20),
No_Of_Children int,
Household_Size int,
Gender char(1),
Marital_Status char(1)
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
Day_Of_Week char(1),
Campaign_Id char(1),
Conversion_Flag char(1),
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
Product_Id	char(1),
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
,No_of_people_covered int
,Premium int 
,Payment_frequency varchar(50)
,Amt_on_Maturity_Bin varchar(50)
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
)
;
