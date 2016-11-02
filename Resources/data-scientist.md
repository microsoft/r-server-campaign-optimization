<img src="Images/management.png" align="right">

# For the Data Scientist

SQL Server R Services brings the compute to the data by running R on the computer that hosts the database. It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime. 

This solution walks through the steps to create and refine data, train R models, and perform scoring on the SQL Server machine. The final scored database table in SQL Server gives the recommendations for **how** and **whe** to contact each lead. This data is then visualized in PowerBI, which also contains a summary of the success of the recommendations used in your new campaign after it has completed. (Simulated data is shown in this template to illustrate the feature.)


Data scientists who are testing and developing solutions can work, conveniently, from their favorite R IDE on their client machine and then <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx" target="_blank">push the compute to the SQL Server machine</a>.  The completed solutions are deployed to SQL Server 2016 by embedding calls to R in stored procedures. These solutions can then be further automated with SQL Server Integration Services and SQL Server agent.

This solution packet includes the R code a data scientist would develop in the **R** folder.  It then incorporates this R code in  stored procedures (.sql files) that can be found in the **SQLR** folder.  Finally, there is a PowerShell script (.ps1 file) that automates the running of the SQL/R code.
 
To try this out yourself, see the [Quick Start](../readme.md#quickstart) section on the main page.

This page describes what happens in each of the steps: dataset creation, model development, scoring, and deployment in more detail.

##  Analytical Dataset Preprocessing and Feature Engineering

This templage simulates input data and performs preprocessing and feature engineering to create the analytical dataset. 

The R code to perform these steps can be run from an R client with the following scripts:

### step1_data_processing.R

This script creates the database tables and performs missing value and outlier treatment on the lead demography and market touchdown tables. Both these updated tables are then exported back to SQL Server.

1.	Market Touchdown: The Communication latency variable in this table was created to have outliers. The lower extremes are replaced with the difference of Mean and Standard Deviation. The higher extremes are replaced with the sum of Mean and two Standard Deviations

2.	Lead Demography: The missing values in variables like number of children/dependents, highest education & household size are replaced with the Mode value.


### step2_feature_engineering.R

This script performs feature engineering on the Market Touchdown table and then merges to generate the Analytical Dataset. Finally, the analytical dataset along with training and test datasets are exported to SQL Server.

1.	Market Touchdown: The table is aggregated at a lead level, so variables like channel which will have more than one value for each user are pivoted and aggregated to from variables like SMS count, Email count, Call Count, Last Communication Channel, Second Last Communication Channel etc.

2.	Analytical Dataset: Analytical Dataset: The latest version of all the 4 input datasets are merged together to create the analytical dataset. The analytical dataset is further split into train and test datasets. Some temporary tables are created which will later be overwritten with model variables in step_4.


![Data Processing ](Images/datacreate.png?raw=true)

## Model Development
Two models, Random Forest and Gradient Boosting are developed to model Campaign Responses.  The R code to develop these models is included in the **step4_model_rf_gbm.R script**.

## step3_training_evaluation.R

In this step, two models are built using 2 statistical techniques on the training Dataset. Once the models are trained, AUC of both the models are calculated using the test dataset. The model with the best AUC is selected as the champion model.

![Training / Testing ](Images/model.png?raw=true)


##  Scoring

The models are compared and the champion model is used for scoring.  The prediction results from the scoring step are the recommendations for contact for the campaigns - when and how to contact each lead for the optimal predicted response rate.

## step4_campaign_recommendations.R

This script scores 63 combinations for each lead: 7 Days x 3 Times x 3 Channels = 63.  Each combination is scored with the best model and the combo with the highest conversion probability is used as the recommendation for that lead.  Results from this step are stored in the **Recommendations** database table. 

![Scoring](Images/model_score.png?raw=true)

  
##  Deploy / Visualize Results
The deployed data resides in a newly created database table, showing recommendations for each lead.  The final step of this solution visualizes these recommendations, and once the new campaigns have been completed we can also visualize a summary of how well the model worked.  

![Visualize](Images/visualize.png?raw=true)

You can find an example of this in the  [Campaign Optimization Dashboard](Campaign%20Optimization%20Dashboard.pbix).



## Template Contents 

[View the contents of this solution template](contents.md).


## System Requirements

To run the scripts requires the following:

- SQL Server 2016 with Microsoft R server installed and configured.     
- The SQL user name and password, and the user configured properly to execute R scripts in-memory;
- SQL Database which the user has write permission and execute stored procedures;
- For more information about SQL server 2016 and R service, please visit: [https://msdn.microsoft.com/en-us/library/mt604847.aspx](https://msdn.microsoft.com/en-us/library/mt604847.aspx)


To try this out yourself: 
* View the [Quick Start](../readme.md#quickstart) section on the main page.

[&lt; Back to ReadMe](../readme.md)

