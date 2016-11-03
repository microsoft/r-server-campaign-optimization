# Campaign Optimization - Predicting How and When to Contact Leads


<div style="width:300px; float:right; padding-left:20px">
<img src="Resources/Images/management.png" >
<h2>Table of Contents</h2>
<ul style=" list-style-type:none; padding:0; margin-left:0px;">
<li><a href="#introduction">Introduction</a></li>
<li><a href="#for-the-business-manager">For the Business Manager</a></li>
<li><a href="#for-the-data-scientist">For the Data Scientist</a></li>
<li><a href="#quick-start">Quick Start</a></li>
<li><a href="#typical-workflow">Typical Workflow</a></li>
<li><a href="#template-contents">Template Contents</a></li>
</div>


## Implemented on SQL Server 2016 R Services
## Introduction

When a business launches a marketing campaign to interest customers in new or existing product(s), they often use a set of business rules to select leads for their campaign to target. Machine learning can be used to help increase the response rate from these leads. This solution demonstrates how to use a model to predict actions that are expected to maximize the purchase rate of leads targeted by the campaign. These predictions serve as the basis for recommendations to be used by a renewed campaign on **how to contact** (for example, e-mail, SMS, or cold call) and **when to contact** (day of week and time of day) the targeted leads. 

The solution presented here uses simulated data from the insurance industry to model responses of the leads to the campaign. The model predictors include demographic details of the leads, historical campaign performance, and product-specific details. The model predicts the probability that each lead in the database makes a purchase from a particular channel, on each day of the week at various times of day. Recommendations on which channel, day of week and time of day to use when targeting users are based then on the channel and timing combination that the model predicts will have the highest probability a purchase being made. 

For customers who prefer an on-premise solution, the implementation with SQL Server R Services is a great option that takes advantage of the powerful combination of SQL Server and the R language. We have modeled the steps in the template after a realistic team collaboration on a data science process. Data scientists do the data preparation, model training, and evaluation from their favorite R IDE. DBAs can then take care of the deployment using SQL stored procedures with embedded R code. Power BI is also available for analysts to visualize the deployed results. We also show how each of these steps can be executed on a SQL Server client environment such as SQL Server Management Studio, as well as from other applications. A Windows PowerShell script that invokes the SQL scripts that execute the end-to-end modeling process is provided for convenience. 


## For the Business Manager

A high level description of this solution is [described here](Resources/business-manager.md).

## For the Data Scientist 

This template showcases the use of Random Forest and Gradient Boosting to model for Campaign Responses. Data Scientists can follow the steps of data creation, model development, scoring and deployment.  The final deployed recommendations will then be visualized in PowerBI. [See more details and explanations of all the files involved in this solution.](Resources/data-scientist.md).   Also make sure to use the Typical Workflow below to get a better sense of how these scripts fit into the overall solution.

 <a name="quickstart" id="quickstart"></a>
## Quick Start
If you’re interested in creating this solution yourself, use this fully automated solution that uploads the data to your SQL Server, preprocesses data, performs feature engineering, trains and scores the models by executing a PowerShell script. This is the fastest way to deploy the entire solution. 

* Visit the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c) to deploy this solution on an Azure VM.

* Or use the [PowerShell Instructions](Resources/Instructions/Powershell_Instructions.md) to deploy to your own machine.  There are a number of steps to perform here that have already been done for you if you use the above Cortana Intelligence Gallery deployment.

## Typical Workflow
We have modeled the steps in the template after a real-life data science process, where the data preparation, model training and evaluation can be done by a data scientist, from the convenience of their R IDE, and the deployment is done using SQL stored procedures with embedded R code.

Follow along with this typical workflow and view the details and follow the solution from start to finish:

* If you are using the solution deployed from the Cortana Intelligence Gallery, [click here](Resources/Instructions/CIG_Workflow.md).

* If you are deploying this solution on your own machine, [click here](Resources/Instructions/Typical_Workflow.md) 

##Template Contents 

[View the contents of this solution template](Resources/contents.md)


**NOTE:** Please don't use "Download ZIP" to get this repository, as it will change the line endings in the data files. Use "git clone" to get a local copy of this repository. 
 
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.