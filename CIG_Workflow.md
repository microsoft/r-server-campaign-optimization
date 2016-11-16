---
layout: default
title: Typical Workflow for Cortana Intelligence Gallery Deployment
---


## Typical Workflow for Cortana Intelligence Gallery Deployment
---------------------------------------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
        <li><a href="#step1">Step 1: Server Setup and Configuration</a></li>
        <li><a href="#step2">Step 2: Data Prep and Modeling</a></li>
        <li><a href="#step3">Step 3: Operationalize</a></li>
        <li><a href="#step4">Step 4: Deploy and Visualize</a></li>
        </div>
    </div>

    <div class="col-md-6">

        {% include typicalintro.md %}

    </div>
</div>


This guide assumes you have deployed the Campaign Optimzation solution from the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c).  

*If you are using your own SQL Server for this solution, [use this guide instead](Typical_Workflow.html).*

SQL Server on your VM has been set up with a user `rdemo` and a default password of `D@tascience`.  If you wish to change the password, connect to the VM, log into SSMS with Windows Authentication and execute the following query:
    
        `
        ALTER LOGIN rdemo WITH PASSWORD = 'newpassword';  
        `

To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  While each persona would be working on a different computer, for simplicity your Virtual Machine (VM) has all the tools each persona would use on the same machine.  

 <a name="step1" id="step1"></a>
        
        {% include step1.md %}

This has already been done on your deployed Cortana Intelligence Gallery VM.

 <a name="step2" id="step2"></a>

## Step 2: Data Prep and Modeling with Debra the Data Scientist
------------------------------------------------------------------

Now let's meet Debra, the Data Scientist. Debra's job is to use historical data to predict a model for future campaigns. Debra's preferred language for developing the models is using R and SQL. She  uses Microsoft R Services with SQL Server 2016 as it provides the capability to run large datasets and also is not constrained by memory restrictions of Open R.  After analyzing the data she opted to create multiple models and choose the best one.  

She will create two machine learning models and compare them, then use the one she likes best to compute a prediction for each combination of day, time, and channel for each lead, and then select the combination with the highest probability of conversion - this will be the recommendation for that lead.  

Debra would work on her own machine, using  [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) to execute these R scripts. R Client has been installed on your VM.

Debra also uses an IDE to run R.  On your VM, R Tools for Visual Studio is installed.  You will however have to either log in or create a new account for using this tool.  If you prefer you can <a href="https://www.rstudio.com/products/rstudio/download3/" target="_blank">download and install RStudio</a> to your machine instead.

### Local Computer Instructions 

While you can follow along on the VM, you may also execute the code on your own computer if you wish. To do so, you will first need to open the Windows Firewall on the VM to allow a connection to the SQL Server.  Connect to the VM and execute the following command in a PowerShell window:

    `
    netsh advfirewall firewall add rule name="SQLServer" dir=in action=allow protocol=tcp localport=1433 
    `

Note this allows anyone with the VM name/IP address to connect to your SQL Server.  You should also change the  password as indicated above if you open the firewall.  

If you use your own computer you will also need to have a copy of [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) installed and configured for your IDE. 

Finally, own your computer you will need a copy of the code.  On you computer open a PowerShell window, navigate to the directory you wish to put the code, and execute the following command:
    
    `
    git clone https://github.com/Microsoft/r-server-campaign-optimization.git
    `
    
### Follow Along with Debra

Now that Debra's environment is set up, she  opens her IDE and creates a Project.  To follow along with her, open the `Campaign/R` directory on the VM desktop, or the `r-server-campaign-optimization` on your local machine.  There you will see three files with the name `CampaignOptimization`:

<img src="images/project.png">


* If you are using Visual Studio, double click on the "Visual Studio SLN" file (the third one in the image above).
* If you are using RStudio, double click on the "R Project" file (the first one in the image above).

    {% include step2.md %}

 <a name="step3" id="step3"></a>

    {% include step3.md %}

You can find this script in the **SQLR** directory, and execute it yourself by following the [PowerShell Instructions](Powershell_Instructions.html).  As noted earlier, this was already executed when your VM was first created.  

 <a name="step4" id="step4"></a>

    {% include step4.md %}