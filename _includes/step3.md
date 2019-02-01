
<h2> Step 3: Operationalize with Debra <span class="sql">and Danny</span></h2>
<hr />
<p/>
Debra has completed her tasks.  <span class="sql">She has connected to the SQL database, executed code from her R IDE that pushed (in part) execution to the SQL machine to clean the data, create new features, train two models and select the champion model.</span><span class="hdi">She has executed code from RStudio that pushed (in part) execution to Hadoop to clean the data, create new features, train two models and select the champion model</span> She has scored data, created recommendations, and also created a summary report which she will hand off to Bernie - see below.
<p/>
While this task is complete for the current set of leads, our company will want to perform these actions for each new campaign that they deploy.  <span class="sql">Instead of going back to Debra each time, Danny can operationalize the code in TSQL files which he can then run himself each month for the newest campaign rollouts.</span> 
<p/>
<div class="sql">
Debra hands over her scripts to Danny who adds the code to the database as stored procedures, using embedded R code, or SQL queries.  You can see these procedures by logging into SSMS and opening the <code>Programmability>Stored Procedures</code> section of the <code>Campaign</code> database.
<img src="images/storedproc.png">

You can find this script in the <strong>SQLR</strong> directory, and execute it yourself by following the <a href="Powershell_Instructions.html">PowerShell Instructions</a>.  <span class="cig">
 As noted earlier, this was already executed when your VM was first created.</span><span class="onp"> As noted earlier, this is the fastest way to execute all the code included in this solution.  (This will re-create the same set of tables and models as the above R scripts.)
</span>
</div>

<div class="hdi">
<p/>
In the steps above, we saw the first way of scoring new data, using <strong>campaign_scoring.R</strong> script. 
Debra now creates an analytic web service  with <a href="https://docs.microsoft.com/en-us/machine-learning-server/what-is-operationalization">ML Server Operationalization</a> that incorporates these same steps: data processing, feature engineering, and scoring.
<p/>
 <strong>campaign_deployment.R</strong> will create a web service and test it on the edge node.  If you wish, you can also download the file <strong>campaign_web_scoring.R</strong> and access the web service on any computer with Microsoft ML Server 9.0.1 or later installed.  
<p/>
<div class="alert alert-info" role="alert">
Before running  <strong>campaign_web_scoring.R</strong> on any computer, you must first connect to edge node from that computer.
Once you have connected you can also use the web server admin utility to reconfigure or check on the status of the server.
<p></p>
Follow <a href="deployr.html">instructions here</a> to connect to the edge node and/or use the admin utility.
</div>
<p/>
The service can also be used by application developers, which is not shown here.
<p/>
</div>
