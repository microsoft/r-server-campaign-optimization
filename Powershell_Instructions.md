---
layout: default
title: PowerShell Instructions
---

<div class="alert alert-success" role="alert"> This page describes the 
<strong>
<span class="cig">{{ site.cig_text }}</span>
<span class="onp">{{ site.onp_text }}</span>
</strong>
solution.
 {% include sqlchoices.md %}

</div> 

## PowerShell Instructions
---------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li> <a href="#setup">Setup</a></li>
            <li> <a href="#execute-powershell-script">Execute PowerShell Script</a></li>
            <li> <a href="#review-data">Review Data</a></li>
            <li> <a href="#visualizing-results">Visualizing Results</a> </li>
            <li> <a href="#other-steps">Other Steps</a></li>
        </div>
    </div>
    <div class="col-md-6">
        If you have deployed a VM through the  
        <a href="http://aka.ms/campaignoptimization">Cortana Intelligence Gallery</a>, all the steps below have already been performed and your database on that machine has all the resulting tables and stored procedures.  Skip to the <a href="Typical.html?platform=cig">Typical Workflow</a> for a description of how these files were first created in R by a Data Scientist and then deployed to SQL stored procedures.
    </div>
</div>

If you are configuring your own server, or if you want to reset your VM to its initial state, continue with the steps below to run the PowerShell script.

## Setup 
-----------

First, make sure you have set up your SQL Server by  <a href="SetupSQL.html">following these instructions</a>.  Then proceed with the steps below to run the solution template using the automated PowerShell file. 

## Execute PowerShell Script
----------------------------

Running this PowerShell script will create the data tables and stored procedures for the the operationalization of this solution in R in the `{{ site.db_name }}_R` database.  It will also execute these procedures to create full database with results of the steps  – dataset creation, modeling, and scoring as described  [here](dba.html).


1. Log onto the machine that contains the SQL Server you wish to use.

2. Download  <a href="https://raw.githubusercontent.com/Microsoft/r-server-campaign-optimization/master/Resources/ActionScripts/SetupVM.ps1" download>SetupVM.ps1</a> to your computer.

1.  Right click on SetupVM.ps1 and select `Run with PowerShell`.

1.  Answer `Y` if asked if it is ok to execute this script.

1.  When prompted, enter the servername, username, and password for your SQL 2016 or SQL 2017 server. Use the username and password of the user who will be creating the solution. 

1. This will make the following modification to your SQL Server:
    * Installs the SQL Server PowerShell module. If this is already installed, it will update it if necessary.
    * Changes Authentication Method to Mixed Mode, which is needed in this version of the solution.
    * Creates the SLQRUserGroup for running R and Python code.
    * Elevates the login user's credentials to SA.
    * Reconfigures SQL Server to allow running of external scripts.
    * Clones the solution code and data into the c:\Solutions\{{ site.folder_name }} directory
    * Creates the solution database `{{ site.db_name }}_R` and configures an ODBC connection to the database.

## Review Data
--------------

Once the PowerShell script has completed successfully, log into the SQL Server Management Studio to view all the datasets that have been created in the `Campaign` database.  
Hit `Refresh` if necessary.
<br/>
<img src="images/alltables.png" >

[Click here](tables.html) to view more information about each of these tables.

Right click on `dbo.Recommendations` and select `View Top 1000 Rows` to preview the scored data.

[Click here](tables.html) to view the details all tables created in this solution.

## Visualizing Results 
---------------------

You've now  created and processed data, created models, picked the best one and used the model to recommend a combination of Channel/Time/Day as described  [here](data-scientist.html). This PowerShell script also created the stored procedures that can be used to score new data for the next campaign.  

Let's look at our current results. Proceed to <a href="Visualize_Results.html">Visualizing Results with PowerBI</a>.

## Other Steps
----------------

You've just completed the fully automated solution that simulates the data, trains and scores the models, and provide recommendations by executing PowerShell scripts.  

See the <a href="Typical.html">Typical Workflow</a> for a description of how these files were first created in R by a Data Scientist and then incorporated into the SQL stored procedures that you just deployed.