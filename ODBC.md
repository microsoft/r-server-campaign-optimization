---
layout: default
title: ODBC Setup
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
<span class="cig">{{ site.cig_text }}</span>
<span class="onp">{{ site.onp_text }}</span>
<span class="hdi">{{ site.hdi_text }}</span> 
</strong>
solution.
 {% include choices.md %}

</div> 

## Set up Connection between SQL Server and PowerBI  
<div class="sql">
Follow the instructions below to set up a connection between your SQL Server database and PowerBI.  Perform these steps after you have created the <code>Campaign</code> database.
</div>
<div class="hdi">
Follow the instructions below to set up a connection between your Hive table and PowerBI.  Perform these steps after you have <a href="Typical.html">created the <code>recommendations</code> table by executiong the <strong>campaign_main.R</strong> and <strong>campaign_scoring</strong> </a> scripts.
</div>
<ol>
<li class="hdi">Download and install the <a href="https://www.microsoft.com/en-us/download/details.aspx?id=49883">Spark ODBC driver.</a></li>
<li>	Push the <code>Windows</code> key on your keyboard</li>
<li>	Type <code>ODBC</code> </li>
<li>	Open the correct app depending on what type of computer you are using (64 bit or 32 bit). To find out if your computer is running 32-bit or 64-bit Windows, do the following:
<ul>
<li>	Open System by clicking the <code>Start</code> button, clicking <code>Control Panel</code>, clicking <code>System and Maintenance</code>, and then clicking <code>System</code>.</li>
<li>.	Under System, you can view the system type</li>
</ul>
</li>
<li>	Click on <code>Add</code>
  <br/>
<img src="images/odbc1.png" width="50%" >
</li>
<li class="sql">	
Select <code>Server Native Client 11.0</code> and click <code>Finish</code>.
   <br/>
<img src="images/odbc2.png" width="50%" >
</li>
<li class="hdi">
Select <code>Microsoft Spark ODBC Driver</code> and click <code>Finish</code><span class=""></span>
<img src="images/odbcs2.png" width="50%" >
</li>
<li class="sql">	
Under Name, Enter <code>Campaign</code>. Under Server enter the MachineName from the SQL Server logins set up section. Press <code>Next</code>.
   <br/>
<img src="images/odbc3.png" width="50%" >
</li>
<li class="hdi">
Under Name, Enter <code>Campaign</code>. Add the Host name (of the form <i>myclustername.azurehdinsight.net</i>).  For username, enter <code>admin</code>.  Enter the password you chose when you created the cluster.
<br/>
<img src="images/odbcs3.png" width="50%" >
</li>
<li class="sql">	
Select <code>SQL Server authentication</code> and enter the credentials you created in the SQL Server set up section. Press <code>Next</code>
<br/>
<img src="images/odbc4.png" width="50%" >
</li>

 
 <div class="sql">
<li>	Check the box for <code>Change the default database to</code> and enter <code>Campaign</code>. Press 
<code>Next</code>.
   <br/>
<img src="images/odbc5.png" width="50%" >
</li>
<li>Press <code>Finish</code>
  <br/>
<img src="images/odbcfinish.png" width="50%" > 
</li>
</div>

<li class="sql">
Press <code>Test Data Source</code>
  <br/>
<img src="images/odbc6.png" width="50%" >
</li>
<li class="hdi">
Press <code>Test</code>.
</li> 
<li>	Press <code>OK</code> in the new popover. This will close the popover and return to the previous popovers.
<span class="sql">   
<br/>
<img src="images/odbc7.png" width="50%" >
</span>
<span class="hdi">   
<br/>
<img src="images/odbcs7.png" width="50%" >
</span>
</li>
<li>	Now that the Data Source is tested. Press <code>OK</code>
<span class="sql">
<br/>
<img src="images/odbc8.png" width="50%" >
</span>
</li>
<li>	Finally, click <code>OK</code> and close the window 
<span class="sql">
<br/>
<img src="images/odbc9.png" width="50%">
</span>
</li>
<p></p>
You are now ready to use this connection in PowerBI by following the <a href="Visualize_Results.html">instructions here</a>.
	