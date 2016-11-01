<img src="Images/management.png" align="right">
# Campaign Optimization Template with SQL Server 2016 R Services – Template Contents

The following is the directory structure for this template:

- [**Data**](#copy-of-input-datasets)  This contains the copy of the simulated input data
- [**R**](#model-development-in-r)  This contains the R codes to simulate the input datasets, create the analytical datasets, train the models, identify champion model and score the analytical/scorings dataset
- [**Resources**](#resources-for-the-solution-packet) This directory contains the detailed description and instructions for this packet as well as the PowerBI file used to visualize results
- [**SQLR**](#model-development-in-sql-server-2016-r-services) This contains the SQLR codes to simulate the input datasets, create the analytical datasets, train the models, identify champion model and score the analytical/scorings dataset. It also contains PowerShell scripts automate the entire process

In this template with SQL Server R Services, two versions of the implementation:

1. [**Model Development in R IDE**](#model-development-in-r)  . Run the R code in R IDE (e.g., RStudio, R Tools for Visual Studio).
2. [**Operationalize in SQL**](#model-development-in-sql-server-2016-r-services). Run the SQL code in SQL Server using SQLR scripts, automated with the use of a PowerShell script.


## Copy of Input Datasets

| File | Description |
| --- | --- |
| .\Data\Campaign\_Detail.csv | Campaign Metadata |
| .\Data\Market\_Touchdown.csv | Historical Campaign data including lead responses |
| .\Data\Product.csv | Product Metadata |
| .\Data\Lead\_Demography.csv | Demographic data of the leads |

## Model Development in R

| File | Description |
| --- | --- |
| step0\_data\_generation.R | Simulates the 4 input datasets |
| step1\data\_processing.R | uploads .csv files to SQL and performs data preprocessing steps such as outlier treatment and missing value treatment  | 
| step2\_feature\_engineering.R | Performs Feature Engineering and creates the Analytical Dataset 
| step3\_training\_evaluation.R | Builds the Random Forest &amp; Gradient Boosting models, identifies the champion model | 
| step4\_campaign\_recommendations.R | Build final recommendations from scoring 63 combinations per lead and selecting combo with highest conversion probability  |


See the Typical Workflow documentation to execute these scripts:
* If you are using the solution deployed from the Cortana Intelligence Gallery, [click here](Resources/Instructions/CIG_Workflow.md).

* If you are deploying this solution on your own machine, [click here](Resources/Instructions/Typical_Workflow.md) 


## Model Development in SQL Server 2016 R Services

| File | Description |
| --- | --- |
| .\SQLR\step0\create\tables.sql | SQL Script to upload data tables into SQL |
| .\SQLR\step1\_data\_processing.sql  | Outliers and missing values in data tables are treated |
| .\SQLR\step2\_feature\_engineering.sql | Market touchdown dataset is aggregated and variables like #Emails, #Calls and #SMS are created |
| .\SQLR\step43a\_splitting.sql | Split the analytical dataset (AD) into Train and Test |
| .\SQLR\Step3b\train\_model.sql | Trains either RF or GBT model, depending on input parameter |
| .\SQLR\Step3c)_test\_model.sql | Tests either RF or GBT model, dpending on input parameter |
| .\SQLR\step4\_campaign\_recommendations.sql | score data with best model and output recommendations |

Follow the [PowerShell Instructions](Instructions/PowerShell_Instructions.md) to execute these scripts.

| --- | --- |
| .\SQLR\Campaign_Management.ps1 | Creates the Analytical/Scoring dataset |


## Resources for the Solution Packet
| File | Description |
| --- | --- |
| .\Resources\business-manager.md | Describes the solution for the Business Manager |
| .\Resources\Campaign Management Dashboard.pbix | PowerBI Dashboard showing the recommendation results |
| .\Resources\contents.md | This document |
| .\Resources\createusr.sql | used during initial SQL Server setup, referenced in **.\Resources\Instructions\START HERE.docx** |
| .\Resources\data-scientist.md | Describes the solution for the Data Scientist |
| .\Resources\Microsoft - Campaign Management.pptx | Powerpoint description of the solution packet |
| .\Resources\Images\ | Directory of images used for the various Readme.md files in this packet |

###  Instructions for Running this Solution Packet
| File | Description |
| --- | --- |
| .\Resources\Instructions\START_HERE.md | **[START HERE](Instructions/START_HERE.md)** to learn how to set up your computer for all solution paths |
| .\Resources\Instructions\Powershell_Instructions.md | [Instructions for running the solution from PowerShell](Instructions/Powershell_Instructions.md) |
| .\Resources\Instructions\R_Instructions.md | [Instructions for running the solution in R](Instructions/R_Instructions.md) on a local machine |
| .\Resources\Instructions\Visualize_Results.md | [Instructions for visualizing your results](Instructions/Visualize_Results.md) in the PowerBI template |


[&lt; Back to ReadMe](../readme.md)