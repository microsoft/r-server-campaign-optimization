<img src="../Images/management.png" align="right">
<h1>Campaign Optimization:
Execution with R Scripts</h1>

Make sure you have set up your SQL Server 2016 set up by following the instructions in <a href="START_HERE.md">START HERE</a>.  Then proceed with the steps below to run the solution template using the R script files. 

The R files in this solution package represent the files created by the data scientist, who would  typically work from their own machine and push the R compute to a SQL Server. The user of this solution package can choose to deploy Microsoft R Client on their machine and push the compute to the SQL Server, or deploy R Client on the same machine as SQL Server.  (Note the latter would not be typical in a real enterprise setting).


Running these scripts will walk through the initial R code used to create this solution – dataset creation, modeling, and scoring as described [here](../data-scientist.md).

The R code shown here was then incorporated into the [.sql files](../../SQLR/readme.md) to operationalize the solution.


<h2>Solution with R Server</h2>

1.  You will need  [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) to execute these R scripts.  You will also want to [install and configure an R IDE](https://msdn.microsoft.com/en-us/microsoft-r/r-client-get-started#configure-ide) to use with R Client.  (These are both already installed and configured if you are using a Data Science VM created from the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c).)


3.  Open the files from the R directory into your IDE configured with R Client.

3.  In SSMS, create the database table you wish to use if it does not yet exist.  (If you have previously run the PowerShell script, the database "Campaign" will already exist.)

4.	Replace the connection string at the top of each file with details of your login and database name in each of the files.  For example:

    ```
    connection_string <- "Driver=SQL Server; Server=.; Database=Campaign; UID=rdemo; PWD=D@tascience"
    ```
 
 Note: You can use “.” for the server name as shown here if using a local SQL Server (on the same machine as your code). Also note that there can be NO SPACES between the "=" in the connection string.  That is  "Database=Campaign" will work while " Database = Campaign" will give an error!  

5.	The scripts perform the following actions:

    a.	**step0_data_generation.R**:  Simulates the 4 input datasets.  Use this to create different size datasets.  

    b.	**step1_data_processing.R**: Uploads .csv files to the database and perfroms preprocessing steps such as missing value treatment on the input datasets.  Notice it is set up to use the files from the ../Data directory.  Change the path if you wish to use different data, such as that created from the step0_data_generation.R script.

    c.	**step2_feature_engineering.R**:  Performs Feature Engineering and creates the Analytical Dataset.   Feature Engineering consists of creating new variables in the market touchdown dataset by aggregating the data in multiple levels.  The table is aggregated at a lead level, so variables like channel which will have more than one value for each user are pivoted and aggregated to variables like SMS count, Email count, Call Count, Last Communication Channel, Second Last Communication Channel etc.

    After running this script, take a look at the features created by running the following query in SSMS:
    
    ```
    SELECT TOP 1000 [Lead_Id]
        ,[Sms_Count]
        ,[Email_Count]
        ,[Call_Count]
        ,[Previous_Channel]
    FROM [Campaign].[dbo].[CM_AD]
    ```

    d.	**step3_training_evaluation.R**:  Builds the Random Forest & Gradient Boosting models and identifies the champion model. Displays an ROC curve and confusion matrix for each model.  

    e.   **step4_campaign_recommendations.R**: Creates 63 combinations for each lead: 7 Days x 3 Times x 3 Channels = 63.  Each combination is scored with the best model and the combo with the highest conversion probability is used as the recommendation for that lead.  Results from this step are stored in the **Recommendations** database table.  This script may take some time to complete, depending on your machine resources.

6.	Run each script in order.  Note some may take some time to finish.  You’ll know they are done when you put cursor in the Console area (labeled “R Interactive” in RTVS)  and it is no longer spinning.  Also when done you’ll see the command prompt “>” ready for the next interactive command. 
<br/>
<img src="../Images/r4.png" width="70%">
 
	After each step completes, feel free to go back to SSMS and look at the contents of the database.  You’ll need to right click on Database and `Refresh` to see the most recent set of results.
 <br/>
 <img src="../Images/r5.png" width="30%">

7.	When you have finished with all  scripts, log into the SQL Server to view all the datasets that have been created in the `Campaign` database.  Hit `Refresh` if necessary.
 <br/>
 <img src="../Images/alltables.png" width="30%">

 Right click on `dbo.Recommendations` and select `View Top 1000 Rows` to preview the scored data.
 
<h2>Visualizing Results </h2>
Now proceed to <a href="Visualize_Results.md">Visualizing Results with PowerBI</a>.

## Other Solution Paths
You have just completed a step-through of the  process from the perspective of a data scientist writing in R.

You may also want to try out the fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts. This is the fastest way to deploy. See [PowerShell Instructions](Powershell_Instructions.md) for this deployment.
	
While we show multiple paths in this solution package as full alternatives, we expect that a more typical scenario would be for a data scientist to perform data exploration and predictive modeling in R followed by scoring in production using T-SQL.  See [Typical Workflow](Typical_Workflow.md) for more details.