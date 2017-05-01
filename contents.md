---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**Data**](#copy-of-input-datasets)  This contains the copy of the simulated input data with 100K unique customers. 
- [**R**](#model-development-in-r)  This contains the R code to simulate the input datasets, pre-process them, create the analytical datasets, train the models, identify the champion model and provide recommendations.
- [**Resources**](#resources-for-the-solution-packet) This directory contains other resources for the solution package.
- [**SQLR**](#operationalize-in-sql-2016) This contains T-SQL code to pre-process the datasets, train the models, identify the champion model and provide recommendations. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).
- [**RSparkCluster**](#hdinsight-solution-on-spark-cluster) This contains the R code to pre-process the datasets, train the models, identify the champion model and provide recommendations on a Spark cluster. 

In this template with SQL Server R Services, two versions of the SQL implementation and another version for HDInsight implementation:

1. [**Model Development in R IDE**](#model-development-in-r)  . Run the R code in R IDE (e.g., RStudio, R Tools for Visual Studio).
2. [**Operationalize in SQL**](#operationalize-in-sql-2016). Run the SQL code in SQL Server using SQLR scripts from SSMS or from the PowerShell script.
3. [**HDInsight Solution on Spark Cluster**](#hdinsight-solution-on-spark-cluster).  Run this R code in RStudio on the edge node of the Spark cluster.


### Copy of Input Datasets
----------------------------

{% include data.md %}

###  Model Development in R
-------------------------
These files  in the **R** directory for the SQL solution.  

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td>Campaign Optimization R Notebook.ipynb  </td><td> Contains the Jupyter Notebook file that runs all the .R scripts </td></tr>
<tr><td>sql_connection.R </td><td> Contains details of connection to SQL Server used in all other scripts </td></tr>
<tr><td>step0_data_generation.R </td><td> Simulates the 4 input datasets, not needed unless you wish to regenerate data </td></tr>
<tr><td>step1_data_processing.R </td><td> Uploads .csv files to SQL and performs data preprocessing steps such as inner joins and missing value treatment  </td></tr>
<tr><td>step2_feature_engineering.R </td><td> Performs Feature Engineering and creates the Analytical Dataset </td></tr>
<tr><td>step3_training_evaluation.R </td><td> Builds the Random Forest &amp; Gradient Boosting models, identifies the champion model </td></tr>
<tr><td>step4_campaign_recommendations.R </td><td>Builds final recommendations from scoring 63 combinations per lead and selecting combo with highest conversion probability  </td></tr>
</table>

* See [For the Data Scientist](data_scientist.html?path=cig) for more details about these files.
* See [Typical Workflow](Typical.html?path=cig)  for more information about executing these scripts.

### Operationalize in SQL 2016 
-------------------------------------------------------

These files are in the **SQLR** directory.

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> step0_create_tables.sql </td><td> SQL Script to create empty tables in SQL. PowerShell script should be used to load the input data</td></tr>
<tr><td> step1_data_processing.sql  </td><td> Replaces Missing values in dataset with the modes </td></tr>
<tr><td> step2_feature_engineering.sql </td><td> Performs Feature Engineering and creates the Analytical Dataset</td></tr>
<tr><td> step3a_splitting.sql </td><td> Splits the analytical dataset into Train and Test</td></tr>
<tr><td> step3b_train_model.sql</td><td> Trains either RF or GBT model, depending on input parameter</td></tr>
<tr><td> step3c_test_evaluate_models.sql </td><td> Tests both RF and GBT models</td></tr>
<tr><td> step4_campaign_recommendations.sql </td><td> Scores data with best model and outputs recommendations </td></tr>
<tr><td> execute_yourself.sql  </td><td> Executes every stored procedure after running all the other .sql files </td></tr>
<tr><td> Campaign_Optimization.ps1 </td><td> Loads the input data into the SQL server and automates the running of all .sql files  </td></tr>
<tr><td> Readme.md  </td><td> Describes the stored procedures in more detail  </td></tr>
</table>

* See [ For the Database Analyst](dba.html?path=cig) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html?path=cig) to execute the PowerShell script which automates the running of all these .sql files.


### HDInsight Solution on Spark Cluster
------------------------------------
These files are in the **RSparkCluster** directory.

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td>Copy_Dev2Prod.R </td><td> Copies a model from the <strong>dev</strong> folder to the <strong>prod</strong> folder for production use </td></tr>
<tr><td>Create_LeadDemo_MarketTouch.R </td><td> Generates Lead_Demography and Market_touchdown tables, used from step0.  Not needed unless you wish to regenerate data </td></tr>
<tr><td>campaign_deployment.R </td><td> Publishes the scoring function as an analytic web service </td></tr>
<tr><td>campaign_main.R </td><td> Runs all steps of the solution </td></tr>
<tr><td>campaign_scoring.R </td><td> Scores new data using a model developed from <strong>campaign_main.R</strong> </td></tr>
<tr><td>campaign_web_scoring.R </td><td> Uses the scoring funtion created by <strong>campaign_deployment.R</strong>. </td></tr>
<tr><td>step0_data_generation.R </td><td> Simulates the 4 input datasets, not needed unless you wish to regenerate data </td></tr>
<tr><td>step1_data_processing.R </td><td> Uploads .csv files to SQL and performs data preprocessing steps such as inner joins and missing value treatment </td></tr>
<tr><td>step2_feature_engineering.R </td><td> Performs Feature Engineering and creates the Analytical Dataset </td></tr>
<tr><td>step3_training_evaluation.R </td><td> Builds the Random Forest &amp; Gradient Boosting models, identifies the champion model</td></tr>
<tr><td>step4_campaign_recommendations.R </td><td>Builds final recommendations from scoring 63 combinations per lead and selecting combo with highest conversion probability</td></tr>
<tr><td>step5_create_hive_table.R </td><td>Stores recommendations in a Hive table for use in PowerBI</td></tr>
</table>

* See [For the Data Scientist](data_scientist.html?path=hdi) for more details about these files.
* See [Typical Workflow](Typical.html?path=hdi)  for more information about executing these scripts.


### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> createuser.sql </td><td> Used during initial SQL Server setup to create the user and password and grant permissions</td></tr>
<tr><td> Campaign_Data_Dictionnary.xlsx  </td><td> Schema and description of the 4 input tables and variables</td></tr>
<tr><td> Images </td><td> Directory of images used for the  Readme.md  in this package </td></tr>
</table>




[&lt; Home](index.html)
