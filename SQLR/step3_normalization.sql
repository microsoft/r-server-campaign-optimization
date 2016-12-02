/** Stored Procedure that converts non numeric levels of factors to "stringed integers" **/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[normalization]
GO

CREATE PROCEDURE [dbo].[normalization]  
AS
BEGIN

/** Normalizing factors with non integer levels **/
DROP TABLE if exists Age_N
CREATE TABLE Age_N
(Age varchar(30),
 Age_id char(1) NOT NULL Primary Key);

INSERT INTO Age_N
SELECT Age, ROW_NUMBER() OVER (ORDER BY Age) AS Age_id
FROM (SELECT DISTINCT Age
	  FROM CM_AD) as t;

DROP TABLE if exists Annual_Income_Bucket_N
CREATE TABLE Annual_Income_Bucket_N
(Annual_Income_Bucket varchar(15),
 Annual_Income_Bucket_id char(1) NOT NULL Primary Key);

INSERT INTO Annual_Income_Bucket_N
SELECT Annual_Income_Bucket, ROW_NUMBER() OVER (ORDER BY Annual_Income_Bucket) AS Annual_Income_Bucket_id
FROM (SELECT DISTINCT Annual_Income_Bucket
		FROM CM_AD) as t;

DROP TABLE if exists Credit_Score_N
CREATE TABLE Credit_Score_N
(Credit_Score varchar(15),
 Credit_Score_id char(1) NOT NULL Primary Key);

INSERT INTO Credit_Score_N
SELECT Credit_Score, ROW_NUMBER() OVER (ORDER BY Credit_Score)  AS Credit_Score_id
FROM (SELECT DISTINCT Credit_Score
		FROM CM_AD) as t;

DROP TABLE if exists State_N
CREATE TABLE State_N
([State] char(2),
 State_id varchar(2) NOT NULL Primary Key);

INSERT INTO State_N
SELECT [State], ROW_NUMBER() OVER (ORDER BY [State]) AS State_id
FROM (SELECT DISTINCT [State]
		FROM CM_AD) as t;

DROP TABLE if exists Highest_Education_N 
CREATE TABLE Highest_Education_N
(Highest_Education varchar(30),
 Highest_Education_id char(1) NOT NULL Primary Key);

INSERT INTO Highest_Education_N
SELECT Highest_Education, ROW_NUMBER() OVER (ORDER BY Highest_Education) AS Highest_Education_id
FROM (SELECT DISTINCT Highest_Education
		FROM CM_AD) as t;

DROP TABLE if exists Ethnicity_N
CREATE TABLE Ethnicity_N
(Ethnicity varchar(20),
 Ethnicity_id char(1) NOT NULL Primary Key);

INSERT INTO Ethnicity_N
SELECT Ethnicity, ROW_NUMBER() OVER (ORDER BY Ethnicity) AS Ethnicity_id
FROM (SELECT DISTINCT Ethnicity
		FROM CM_AD) as t;

DROP TABLE if exists Gender_N
CREATE TABLE Gender_N
(Gender char(1),
 Gender_id char(1) NOT NULL Primary Key);

INSERT INTO Gender_N
SELECT Gender, ROW_NUMBER() OVER (ORDER BY Gender)  AS Gender_id
FROM (SELECT DISTINCT Gender
		FROM CM_AD) as t;

DROP TABLE if exists Marital_Status_N
CREATE TABLE Marital_Status_N
(Marital_Status char(1),
 Marital_Status_id char(1) NOT NULL Primary Key);

INSERT INTO Marital_Status_N
SELECT Marital_Status, ROW_NUMBER() OVER (ORDER BY Marital_Status)  AS Marital_Status_id
FROM (SELECT DISTINCT Marital_Status
		FROM CM_AD) as t;

DROP TABLE if exists Channel_N
CREATE TABLE Channel_N
(Channel varchar(15),
 Channel_id char(1) NOT NULL Primary Key);

INSERT INTO Channel_N
SELECT Channel, ROW_NUMBER() OVER (ORDER BY Channel)  AS Channel_id
FROM (SELECT DISTINCT Channel
		FROM CM_AD) as t;

DROP TABLE if exists Time_Of_Day_N
CREATE TABLE Time_Of_Day_N
(Time_Of_Day varchar(15),
 Time_Of_Day_id char(1) NOT NULL Primary Key);

INSERT INTO Time_Of_Day_N
SELECT Time_Of_Day, ROW_NUMBER() OVER (ORDER BY Time_Of_Day)  AS Time_Of_Day_id
FROM (SELECT DISTINCT Time_Of_Day
		FROM CM_AD) as t;

DROP TABLE if exists Payment_Frequency_N
CREATE TABLE Payment_Frequency_N
(Payment_Frequency varchar(20),
 Payment_Frequency_id char(1) NOT NULL Primary Key);

INSERT INTO Payment_Frequency_N
SELECT Payment_Frequency, ROW_NUMBER() OVER (ORDER BY Payment_Frequency)   AS Payment_Frequency_id
FROM (SELECT DISTINCT Payment_Frequency
		FROM CM_AD) as t;

DROP TABLE if exists Amt_On_Maturity_Bin_N
CREATE TABLE Amt_On_Maturity_Bin_N
(Amt_On_Maturity_Bin varchar(30),
 Amt_On_Maturity_Bin_id char(1) NOT NULL Primary Key);


INSERT INTO Amt_On_Maturity_Bin_N
SELECT Amt_On_Maturity_Bin, ROW_NUMBER() OVER (ORDER BY Amt_On_Maturity_Bin)  AS Amt_On_Maturity_Bin_id
FROM (SELECT DISTINCT Amt_On_Maturity_Bin
		FROM CM_AD) as t;


DROP TABLE if exists Sub_Category_N
CREATE TABLE Sub_Category_N
(Sub_Category varchar(15),
 Sub_Category_id char(1) NOT NULL Primary Key);

INSERT INTO Sub_Category_N
SELECT Sub_Category, ROW_NUMBER() OVER (ORDER BY Sub_Category)   AS Sub_Category_id
FROM (SELECT DISTINCT Sub_Category
		FROM CM_AD) as t;


DROP TABLE if exists Campaign_Drivers_N
CREATE TABLE Campaign_Drivers_N
(Campaign_Drivers varchar(50),
 Campaign_Drivers_id char(1) NOT NULL Primary Key);

INSERT INTO Campaign_Drivers_N
SELECT Campaign_Drivers, ROW_NUMBER() OVER (ORDER BY Campaign_Drivers)  AS Campaign_Drivers_id
FROM (SELECT DISTINCT Campaign_Drivers
		FROM CM_AD) as t;

DROP TABLE if exists Previous_Channel_N
CREATE TABLE Previous_Channel_N
(Previous_Channel varchar(50),
 Previous_Channel_id char(1) NOT NULL Primary Key);

INSERT INTO Previous_Channel_N
SELECT Previous_Channel, ROW_NUMBER() OVER (ORDER BY Previous_Channel)  AS Previous_Channel_id
FROM (SELECT DISTINCT Previous_Channel
		FROM CM_AD) as t;

/** Creating the normalized data set **/

DROP TABLE if exists CM_AD_N;

SELECT Lead_Id, Age_id as Age, Phone_No, Annual_Income_Bucket_id as Annual_Income_Bucket, Credit_Score_id as Credit_Score, Country,
       State_id as [State], No_Of_Dependents, Highest_Education_id as Highest_Education, Ethnicity_id as Ethnicity, No_Of_Children,
       Household_Size, Gender_id as Gender, Marital_Status_id as Marital_Status,  Channel_id as Channel, Time_Of_Day_id as Time_Of_Day,
       Conversion_Flag, Campaign_Id, Day_Of_Week, Comm_Id, Time_Stamp, Product, Category, Term, No_Of_People_Covered, Premium,
       Payment_Frequency_id as Payment_Frequency, Amt_On_Maturity_Bin_id as Amt_On_Maturity_Bin, Sub_Category_id as Sub_Category,
       Campaign_Drivers_id as Campaign_Drivers, Campaign_Name, Launch_Date, Call_For_Action, Focused_Geography, Tenure_Of_Campaign,
       Net_Amt_Insured, Product_Id, SMS_Count, Email_Count, Call_Count, Previous_Channel_id as Previous_Channel  
INTO CM_AD_N
FROM CM_AD
JOIN Age_N ON CM_AD.Age = Age_N.Age 
JOIN Annual_Income_Bucket_N ON CM_AD.Annual_Income_Bucket = Annual_Income_Bucket_N.Annual_Income_Bucket
JOIN Credit_Score_N ON CM_AD.Credit_Score = Credit_Score_N.Credit_Score
JOIN State_N ON CM_AD.State = State_N.[State]
JOIN Highest_Education_N ON CM_AD.Highest_Education = Highest_Education_N.Highest_Education
JOIN Ethnicity_N ON CM_AD.Ethnicity =Ethnicity_N.Ethnicity
JOIN Gender_N ON CM_AD.Gender = Gender_N.Gender 
JOIN Marital_Status_N ON CM_AD.Marital_Status = Marital_Status_N.Marital_Status 
JOIN Channel_N ON CM_AD.Channel = Channel_N.Channel
JOIN Time_Of_Day_N ON CM_AD.Time_Of_Day = Time_Of_Day_N.Time_Of_Day 
JOIN Payment_Frequency_N ON CM_AD.Payment_Frequency = Payment_Frequency_N.Payment_Frequency
JOIN Amt_On_Maturity_Bin_N ON CM_AD.Amt_On_Maturity_Bin = Amt_On_Maturity_Bin_N.Amt_On_Maturity_Bin
JOIN Sub_Category_N ON CM_AD.Sub_Category = Sub_Category_N.Sub_Category 
JOIN Campaign_Drivers_N ON CM_AD.Campaign_Drivers = Campaign_Drivers_N.Campaign_Drivers
JOIN Previous_Channel_N ON CM_AD.Previous_Channel  = Previous_Channel_N.Previous_Channel;  

;
END
GO