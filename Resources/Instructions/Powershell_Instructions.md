<img src="../Images/management.png" align="right">
<h1>Campaign Optimization:
Execution with PowerShell</h1>

If you have deployed a VM through the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c), all steps below have already been performed and your database on that machine has all the resulting tables and stored procedures.  See the [Typical Workflow](CIG_Workflow.md) for a description of how these files were first created in R by a Data Scientist.

If you are configuring your own server, run this PowerShell script to perform the automated version of the solution – dataset creation, modeling, and scoring as described  [here](../data-scientist.md).


Make sure you have set up your SQL Server by following the instructions in <a href="START_HERE.md">START HERE</a>.  Then proceed with the steps below to run the solution template using the automated PowerShell files. Run this on the machine where SQL Server 2016 is installed.


Running this PowerShell script will create stored procedures for the the operationalization of this solution.  It will also execute these procedures to create full database with results of the steps  – dataset creation, modeling, and scoring as described  [here](../../SQLR/README.md).



1.	Click on the windows key on your keyboard. Type the words `PowerShell`.  Right click on Windows Powershell to and select `Run as administrator` to open the PowerShell window.


2.	In the Powershell command window, type the following command:
  
    ```
    Set-ExecutionPolicy Unrestricted -Scope Process
    ```

    Answer `y` to the prompt to allow the following scripts to execute.

3. Create a directory on your computer where you will put this solution.  CD to the directory and then clone the repository into it:
    
    ```
    git clone https://github.com/Microsoft/r-server-campaign-optimization.git
    ```

4.  Now CD to the **r-server-campaign-optimization/SQLR** directory and run the following command, inserting your server name (or "." if you are on the same machine as the SQL server)
    
    ```
    .\Campaign_Optimization.ps1 -ServerName "Server Name" -DBName "Campaign"
    ```
5.  Answer the prompts.  The first time through, do not skip any steps.  (If you exit before completing all steps, the next time through you may skip the steps that have already been completed.)  


## Review Data

Once the PowerShell script has completed successfully, log into the SQL Server Management Studio to view all the datasets that have been created in the `Campaign` database.  
Hit `Refresh` if necessary.
<br/>
<img src="../Images/alltables.png" width="30%">

Right click on `dbo.Recommendations` and select `View Top 1000 Rows` to preview the scored data.

## Visualizing Results 
You've now  created and processed data, created models, picked the best one and used the model to recommend a combination of Channel/Time/Day as described  [here](../data-scientist.md). This powershell script also created the stored procedures that can be used to score new data for the next campaign.  

Let's look at our current results. Proceed to <a href="Visualize_Results.md">Visualizing Results with PowerBI</a>.

## Other Solution Paths

You've just completed the fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts.  

See the [Typical Workflow Walkthrough](Typical_Workflow.md) for a description of how these files were first created in R by a Data Scientist.