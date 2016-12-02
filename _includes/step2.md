
1.  First she'll develop R scripts to prepare the data.  To view the scripts she writes, open the files mentioned below.  If you are using Visual Studio, you will see these file in the `Solution Explorer` tab on the right.  In RStudio, the files can be found in the `Files` tab, also on the right. 

    a.  **SQLR_ connection.R**: configures the compute context used in all the rest of the scripts. The connection string is pre-poplulated with the default values created for a VM from the Cortana Intelligence Gallery.  You must  change the values accordingly for your implementation if you are not using the default server (`localhost` represents a server on the same machine as the R code),  user (`rdemo`), and password (`D@tascience`).  If you are connecting to an Azure VM from a different machine, the server name can be found in the Azure Portal under the "Network interfaces" section - use the Public IP Address as the server name. The user and the password can be modified from the script **createuser.sql**. 

    b.  **step0_data_generation.R**:  This file was used to generate data for the current solution - in a real setting it would not be present.  It is left here in case you'd like to generate additional data.  Otherwise simply ignore this file.

    c.	**step1_data_processing.R**:  Uploads data and performs preprocessing steps -- merging of the [input data sets](input_data.html) and missing value treatment.  

    d.	**step2_feature_engineering.R**:  Performs Feature Engineering and creates the Analytical Dataset. Feature Engineering consists of creating new variables in the cleaned dataset.  `SMS_Count`, `Email_Count` and `Call_Count` are computed: they correspond to the number of times every customer was contacted through these three channels. It also computes `Previous_Channel`: for each communication with the `Lead`, it corresponds to the `Channel` that was used in the communication that preceded it (a NULL value is attributed to the first record of each Lead). Finally, an aggregation is performed at the Lead Level by keeping the latest record for each one. 
    
    *You can run these scripts if you wish, but you may also skip them if you want to get right to the modeling.  The data that these scripts create already exists in the SQL database.* 

    In both Visual Studio and RStudio, there are multiple ways to execute the code from the R Script window.  The fastest way for both IDEs is to use Ctrl-Enter on a single line or a selection.  Learn more about  <a href="http://microsoft.github.io/RTVS-docs/">R Tools for Visual Studio</a> or <a href="https://www.rstudio.com/products/rstudio/features/">RStudio</a>.

2.  If you are following along, if you have modified any of the default values created by this solution package you will need to replace the connection string in the **SQL_connection.R** file with details of your login and database name.  
   
       
        connection_string <- "Driver=SQL Server;Server=localhost;Database=Campaign;UID=rdemo;PWD=D@tascience"
        

    *Make sure there are no spaces around the "=" in the connection string - it will not work correctly when spaces are present*

    If you are creating a new database by using these scripts, you must first create the database name in SSMS.  Once it exists it can be referenced in the connection string.  (Log into SSMS using the same username/password you supply in the connection string, or `rdemo`, `D@tascience` if you haven't changed the default values.)

    This connection string contains all the information necessary to connect to the SQL Server from inside the R session. As you can see in the script, this information is then used in the `RxInSqlServer()` command to setup a `sql` string.  The `sql` string is in turn used in the `rxSetComputeContext()` to execute code directly in-database.  You can see this in the **SQL_connection.R** file:

        connection_string <- "Driver=SQL Server;Server=localhost;Database=Campaign;UID=rdemo;PWD=D@tascience"
        sql <- RxInSqlServer(connectionString = connection_string)
        rxSetComputeContext(sql)
      

    
 3.  After running the step1 and step2 scripts, Debra goes to SQL Server Management Studio to log in and view the results of feature engineering by running the following query:
        

        SELECT TOP 1000 [Lead_Id]
        ,[Sms_Count]
        ,[Email_Count]
        ,[Call_Count]
        ,[Previous_Channel]
        FROM [Campaign].[dbo].[CM_AD]


4.  Now she is ready for training the models.  She creates and executes the script you can find in **step3_training_evaluation.R**.  This step will train two different models and evaluate each.  

   The R script draws the ROC or Receiver Operating Characteristic for each prediction model. It shows the performance of the model in terms of true positive rate and false positive rate, when the decision threshold varies. 

    {% include auc.md %}

    Debra will use the AUC to select the champion model to use in the next step.

5.  Finally Debra will create and execute **step4_campaign_recommendations.R** to score data for leads to be used in a new campaign. The code uses the champion model to score each lead multiple times - for each combination of day of week, time of day, and channel - and selects the combination with the highest probability to convert for each lead.  This becomes the recommendation for that lead.  The scored datatable shows the best way to contact each lead for the next campaign. The recommendations table (`Recommendations`) is used for the next campaign the company wants to deploy.
   *This step may take 10-15 minutes to complete.  Feel free to skip it if you wish, the data already exists in the SQL database.*

6.  Debra will now use PowerBI to visualize the recommendations created from her model.  She creates the PowerBI Dashboard which you can find in the `Campaign` directory.  She uses an ODBC connection to connect to the data, so that it will always show the most recently modeled and scored data, using the [instructions here](Visualize_Results.html).
  <img src="images/visualize.png">.  If you want to refresh data in your PowerBI Dashboard, make sure to [follow these instructions](Visualize_Results.html) to setup and use an ODBC connection to the dashboard.

7.  A summary of this process and all the files involved is described in more detail [here](data-scientist.html).
