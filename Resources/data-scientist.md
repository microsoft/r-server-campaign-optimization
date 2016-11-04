<img src="../Images/management.png" align="right">
# For the Data Scientist

<div style="width:200px; float:right; padding-left:20px">
<h2>Table of Contents</h2>
<ul style=" list-style-type:none; padding:0; margin-left:0px;">
<li><a href="#analytical-dataset-preprocessing-and-feature-engineering">Analytical Dataset Preprocessing and Feature Engineering</a></li>
<li><a href="#model-development">Model Development</a></li>
<li><a href="#scoring">Scoring</a></li>
<li><a href="#>deploy-and-visualize-results">Deploy and Visualize Results</a></li>
<li><a href="#template-contents">Template Contents</a></li>
<li><a href="#system-requirements">System Requirements</a></li>
</div>

#<img src="Images/management.png" align="right">

# For the Data Scientist

SQL Server R Services takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server package) by allowing R to run on the same server as the database. 

It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime. 

This solution package shows how to pre-process data (cleaning and feature engineering), train prediction models, and perform scoring on the SQL Server machine. 

Data scientists who are testing and developing solutions can work from the convenience of their R IDE on their client machine, while [setting the computation context to SQL] (https://msdn.microsoft.com/en-us/library/mt604885.aspx) (see **R** folder for code).  They can then deploy the completed solutions to SQL Server 2016 by embedding calls to R in stored procedures (see **SQLR** folder for code). These solutions can then be further automated by the use of SQL Server Integration Services and SQL Server agent: a PowerShell script (.ps1 file) automates the running of the SQL code.


## Campaign Optimization

This template is focused on marketing campaign optimization. In particular, customer-oriented businesses can learn patterns from their data to intelligently design acquisition campaigns and convert the highest possible number of customers. 

Among the key variables to learn from data are the best communication channel (e.g. SMS, Email, Call), the day of the week and the time of the day through which/ during which a given potential customer is targeted by a marketing campaign.

In this template, the final scored database table in SQL Server gives the recommendations for how and when to contact each lead. This data is then visualized in PowerBI. Also in PowerBI is a summary of the success of the recommendations after the new campaign has completed (shown in this template with simulated data).

To try this out yourself, see the [Quick Start](../readme.md#quickstart) section on the main page.

This page describes what happens in each of the steps: dataset creation, model development, recommendations, and deployment in more detail.


##  Analytical Dataset Preprocessing and Feature Engineering

This part simulates input data and performs preprocessing and feature engineering to create the analytical dataset. 
The **R** code to perform these steps can be run from an R client with the following scripts:

### step1_data_processing.R

This script exports the 4 input data sets to SQL tables, merges them, and then performs missing value treatment on the raw table in-database.

### step2_feature_engineering.R

This script performs feature engineering in-database to generate the Analytical Dataset. 

1.	SMS_Count, Call_Count, Email_Count: number of times every customer (Lead_Id) has been contacted through every Channel.

2.	Previous_Channel: the previous channel used towards every customer for every campaign activity. 

Finally, only the latest campaign activity for every customer is kept.

The corresponding **SQL** stored procedures can be run manually after loading the data into tables with PowerShell. They can be found in the scripts **step1_data_processing.sql** and **step2_feature_engineering.sql**.

![Data Processing ](Images/datacreate.png?raw=true)

## Model Development
Two models, Random Forest and Gradient Boosting are developed to model Campaign Responses.  The **R** code to develop these models is included in the **step3_training_evaluation.R script**.

### step3_training_evaluation.R

In this step, after splitting the analytical data set into a training and a testing set, two prediction models are built (Random Forest and Gradient Boosted Trees) on the training set. Once the models are trained, AUC of both the models are calculated using the testing set. The model with the best AUC is selected as the champion model and will be used for recommendations.

The corresponding **SQL** stored procedures can be run manually. They can be found in the scripts **step3a_splitting.sql**, **step3b_train_model.sql**, and **step3c_test_model.sql**.

![Training / Testing ](Images/model.png?raw=true)

##  Scoring
The champion model is used to provide recommendations about how and when to contact each customer. The **R** code to provide the recommendations is inlcuded in the **step4_campaign_recommendations.R script**.

### step4_campaign_recommendations.R

This script creates a full table with 63 rows for each customer, corresponding to the possible 63 combinations of day, time and channel (7 Days x 3 Times x 3 Channels = 63).  Each combination is scored with the champion model and, for each customer, the one with the highest conversion probability is used as the recommendation for that lead.  Results from this step are stored in the **Recommendations** database table. 

The corresponding **SQL** stored procedures can be run manually in **step4_campaign_recommendations.sql**. 

![Scoring](Images/model_score.png?raw=true)

  
##  Deploy and Visualize Results
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
