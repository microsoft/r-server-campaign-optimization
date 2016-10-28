# Campaign Management Template with R Scripts

This is the R (Microsoft R Server) code for Campaign Management template using SQL Server R Services. This code runs on a local R IDE (such as RStudio, R Tools for Visual Studio), and the computation is done in SQL Server (by setting compute context).

Below is a detailed description of the R code used to impement this solution.  Follow the [R Instructions](../Resources/Instructions/R_Instructions.md) to execute these scripts.

This is primarily for customers who prefer advanced analytical solutions on a local R IDE.

It consists of the following files:

| File | Description |
| --- | --- |
| step0\_data\_generation.R | Simulates the 4 input datasets |
| step1\data\_processing.R | uploads .csv files to SQL and performs data preprocessing steps such as outlier treatment and missing value treatment  | 
| step2\_feature\_engineering.R | Performs Feature Engineering and creates the Analytical Dataset 
| step3\_training\_evaluation.R | Builds the Random Forest &amp; Gradient Boosting models, identifies the champion model | 
| step4\_campaign\_recommendations.R | Build final recommendations from scoring 63 combinations per lead and selecting combo with highest conversion probability  |

Note: The connection parameters are not set in any of the scripts. The user will have to enter these parameters in the beginning of each script before running them.

## step0_data_generation.R

This script simulates the 4 input datasets. It is left here in case you want to generate new data, but is not needed in the current solution.  If you do use it, remember to move the newly generated files to the Data directory once they are created. 

The user also can change the number of leads to be simulated by entering the value in the script.

1.	Lead Demography: Based on the number of leads entered in line 36, the script creates Lead Ids and simulates other variables like age, annual income, credit score, location, educational background and many other demographic details for each lead. The script generates some missing values so they can be treated later in pre-processing.
2.	Market Touchdown: Every lead’s lead Id, age, annual income & credit scores are extracted from the Lead Demography table and variables from historical campaign data is simulated here by applying randomization. A few outliers are created here intentionally, so that they can later be handled in pre-processing.
3.	Campaign Detail: In this part of the script, the Campaign metadata like campaign name, launch date, category, sub-category are simulated.
4.	Product: In this part of the script, the Product metadata like product name, category, term, premium etc are simulated.

## step1_data_processing.R

This script creates the database tables and performs missing value and outlier treatment on the lead demography and market touchdown tables. Both these updated tables are then exported back to SQL Server 
1.	Market Touchdown: The Communication latency variable in this table was created to have outliers. The lower extremes are replaced with the difference of Mean and Standard Deviation. The higher extremes are replaced with the sum of Mean and two Standard Deviations
2.	Lead Demography: The missing values in variables like number of children/dependents, highest education & household size are replaced with the Mode value

## step2_feature_engineering.R

This scripts performs feature engineering on the Market Touchdown table and then merges the 4 input tables to generate the Analytical Dataset. Finally, the analytical dataset along with training and test datasets are exported to SQL Server.
1.	Market Touchdown: The table is aggregated at a lead level, so variables like channel which will have more than one value for each user are pivoted and aggregated to from variables like SMS count, Email count, Call Count, Last Communication Channel, Second Last Communication Channel etc.
2.	Analytical Dataset: Analytical Dataset: The latest version of all the 4 input datasets are merged together to create the analytical dataset. The analytical dataset is further split into train and test datasets. Some temporary tables are created which will later be overwritten with model variables in step_4.

## step3_training_evaluation.R

In this step, two models are built using 2 statistical techniques on the training Dataset. Once the models are trained, AUC of both the models are calculated using the test dataset. The model with the best AUC is selected as the champion model.

## step4_campaign_recommendations.R

This script scores 63 combinations for each lead: 7 Days x 3 Times x 3 Channels = 63.  Each combination is scored with the best model and the combo with the highest conversion probability is used as the recommendation for that lead.  Results from this step are stored in the **Recommendations** database table.  

Follow the [R Instructions](../Resources/Instructions/R_Instructions.md) to execute these scripts.