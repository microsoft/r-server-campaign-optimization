<img src="../Resources/Images/management.png" align="right">

# Campaign Optimization Template in SQL Server with R Services
--------------------------
 * **Introduction**
	 * **System Requirements**
	 * **Workflow Automation**
 * **Step 0: Creating Tables**
 * **Step 1: Pre-Processing and Cleaning**
 * **Step 2: Feature Engineering**
 * **Step 3a: Splitting the data set**
 * **Step 3b: Training**
 * **Step 3c: Predicting (Scoring)**
 * **Step 4: Channel-day-time Recommendations**

### Introduction:
-------------------------

As businesses are starting to acknowledge the power of data, leveraging machine learning techniques to grow has become a must. In particular, customer-oriented businesses can learn patterns from their data to intelligently design acquisition campaigns and convert the highest possible number of customers. 

Among the key variables to learn from data are the best communication channel (e.g. SMS, Email, Call), the day of the week and the time of the day through which/ during which a given potential customer is targeted by a marketing campaign. This template provides a customer-oriented business with an analytics tool that helps determine the best combination of these three variables for each customer, based (among others) on financial and demographic data.

For businesses that prefers an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server). In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code. 

All the steps can be executed on SQL Server client environment (such as SQL Server Management Studio), as well as from other applications. We provide a Windows PowerShell script which invokes the SQL scripts and demonstrates the end-to-end modeling process.

### System Requirements
-----------------------

To run the scripts requires the following:
 * SQL server 2016 CTP 3 with Microsoft R server installed and configured;
 * The SQL user name and password, and the user is configured properly to execute R scripts in-memory;
 * SQL Database which the user has write permission and execute stored procedures;
 * For more information about SQL server 2016 and R service, please visit: https://msdn.microsoft.com/en-us/library/mt604847.aspx


### Workflow Automation
-------------------
Follow the [PowerShell instructions](../Resources/Instructions/Powershell_instructions.md) to execute all the scripts described below.
 

### Step 0: Creating Tables

The following data are provided in the Data directory:

<table style="width:85%">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>.\Data\Campaign_Detail.csv</td>
    <td>Raw data about each marketing campaign that occurred</td>
  </tr>
  <tr>
    <td>.\Data\Lead_Demography.csv</td>
    <td>Raw demographics and financial data about each customer</td>
  </tr>
  <tr>
    <td>.\Data\Market_Touchdown.csv</td>
    <td>Raw channel-day-time data used for every customer of Lead_Demography in every campaign he was targeted</td>
  </tr>
  <tr>
    <td>.\Data\Product.csv</td>
    <td>Raw data about the product marketed in each campaign</td>
  </tr>
</table>

In this step, we create four tables: "Campaign_Detail", "Lead_Demography", “Market_Touchdown”, and “Product” in a SQL Server database, and the data is uploaded to these tables using bcp command in the PowerShell script.

Six other empty tables are created and will be filled in the next steps.

Input:
,
* Raw data: Campaign_Detail.csv, Lead_Demography.csv, Market_Touchdown.csv, and Product.csv  

Output:

* 4 Tables filled with the raw data: Campaign_Detail, Lead_Demography, Market_Touchdown, and Product.
* 6 Tables that will be filled in the next steps: Merged, CM_AD0, CM_AD, CM_AD1, AD_full_merged, and Prob_Id. 

Related files:
* step0_create_tables.sql

### Step 1: Pre-Processing and Cleaning

In this step, we first merge the 4 raw data tables that we filled in Step 0 through inner joins: Campaign_Detail and Product are merged into an intermediate table, “Campaign_Product”, through an inner join on Product_Id. 
Lead_Demography and Market_Touchdown are merged into an intermediate table “Market_Lead” through an inner join on Lead_Id. Finally, the two intermediate tables are merged into one, “Merged”, through an inner join on Lead_Id. 
Intermediate tables are then deleted from the database. This is implemented though a stored procedure [dbo].[Merging_Raw_Tables].

Then, the raw data in Merged is cleaned through a SQL stored procedure calling R services, [dbo].[fill_NA]. This assumes that the ID variables (Lead_Id, Product_Id, Campaign_Id, Comm_Id) as well as dates and phone numbers do not contain blanks. For every variable that might contain missing values: we first look for the rows containing missing values. If it is not an empty set, we compute the mode (most repeated value) and replace the missing values with it. This stored procedure outputs a table, “CM_AD0”

Input:
* 4 Tables filled with the raw data: Campaign_Detail, Lead_Demography, Market_Touchdown, and Product.

Output:
* "CM_AD0" table containing the merged data set without missing values.

Related files:
* step1_data_processing.sql

### Step 2: Feature Engineering

In this step, we create a stored procedure [dbo].[feature_engineering] that designs new features by following these steps:  

* SMS_Count, Call_Count, Email_Count: they are created by counting the number of times every customer (Lead_Id) has been contacted through every Channel. The new data is stored in an intermediate table called “Intermediate”. 
* Previous_Channel: the previous channel used towards every customer for every campaign activity. It is created by adding a lag variable on Channel. The first record for each customer should thus be disregarded. In this SQL statement, we also order the records of every customer by putting the latest campaign activity on top. The resulting data is stored in an intermediate table called “Intermediate2”.
* Keeping the last record: only the latest campaign activity for every customer is kept. The resulting analytical data is stored in the table “CM_AD”. Intermediate tables are dropped. 

Input:

* "Merged" table.

Output:

* "CM_AD" table containing new features and one record per customer.

Related files:

* step2_feature_engineering.sql


### Step 3a: Splitting the data set

In this step, we create a stored procedure [dbo].[slitting] that splits the data into a training set and a testing set. The user has to specify a splitting ratio between 0 and 1. For example, if the splitting ratio is 0.7, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The resulting data, with a random binary vector Split_Vector, is stored in the table “CM_AD1”.


.Input:

* "CM_AD0" table.

Output:

* "CM_AD1" table containing Split_Vector to split between training and testing set.

Related files:

* step3a_splitting.sql

### Step 3b: Training

In this step, we create a stored procedure [dbo].[TrainModel] that trains a Random Forest (RF) or a Gradient Boosted Trees (GBT) on the training set. The trained models are serialized then stored in a table called “Campaign_Models”. The PowerShell script automatically calls the procedure twice in order to train both models. 


Input:

* "CM_AD1" table.

Output:

* "Campaign_Models" table containing the RF and GBT trained models. 

Related files:

* step3b_train_model.sql

### Step 3c: Predicting (Scoring)
In this step, we create a stored procedure [dbo].[TestModel] that scores the two trained models on the testing set, and then compute performance metrics (AUC and accuracy among others). The predictions are written in a table called “Prediction_Test”, and the performance metrics are written in “metrics_table”. The best model name based on AUC is written to the table "best_model".

Before proceeding to the next step, the user might want to inspect the metrics_table in order to select himself the model to be used for campaign recommendations. Since the AUC does not depend on the chosen decision threshold for the models, it is wiser to use it for model comparison. The PowerShell script will use by default the best model based on AUC but will give the user the option of choosing the other model.

Input:

* "CM_AD1" table.

Output:

* "Prediction_Test" table storing the predicted score in the last two columns.
* "metrics_table" table containing the performance metrics of the two models.
* "best_model" table containing the name of the model that gave the highest AUC on the testing set.


Related files:

* step3c_test_model.sql

### Step 4: Channel-day-time Recommendations

In this step, we create three stored procedures that use the selected prediction model to provide channel-day-time recommendations for every customer. 

In the first one, [dbo].[generate_full_table], every row (every customer Lead_Id) of CM_AD is replicated 63 times, each row corresponding to a different combination of Channel, Day_Of_Time and Day_Of_Week. The full data set is stored in a table called “AD_full_merged”. Intermediate tables are dropped at the end of the procedure. 

The second one, [dbo].[scoring], scores the full data set through R services, by using the selected model stored in table Campaign_Models. The results are written in a table called “Prob_Id”, containing part of the full table in addition to the scored probability. 

The third one, [dbo].[campaign_recommendation], is the only one called by the PowerShell. It first executes the first two stored procedures, and then select from Prob_Id the rows corresponding the the channel-day-time with the highest predicted conversion probability. If for a given customer, two or more combinations give the highest predicted probability, one is selected randomly. This is stored in an intermediate table called “Recommended_Combinations”. Finally, an inner join adds back demographic and financial variables to the previous table, and the result is stored in “Recommendations”. 

Input:

* "Campaign_Models" table containing the trained models. 
* "CM_AD" table containing the analytical data set. 

Output:

* "Recommendations” table containing demographic and financial data as well as the recommended channel, day and time to target every customer. 

Related files:

* step4_campaign_recommendations.sql 



