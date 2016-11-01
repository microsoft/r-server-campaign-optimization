<img src="../Images/management.png" align="right">
<h1>Campaign Optimization:
START HERE: Setup SQL Server 2016 </h1>
<h2>Quick Start</h2>
The instructions on this page will help you to add this solution to your own SQL Server 2016.  

If you instead would like to try this solution out on a virtual machine, visit the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c) and use the Deploy button.  All the configuration described below will be done for you, as well as the initial deployment of the solution.  You will be all set to follow along with the [Typical Workflow Walkthrough.](Typical_Workflow.md).

<h2>Prepare your SQL Server 2016 Installation</h2>
The rest of this page assumes you are configuring your own SQL Server 2016 for this solution.

If you need a trial version of SQL Server 2016, see [What's New in SQL Server 2016](https://msdn.microsoft.com/en-us/library/bb500435.aspx) for download or VM options. 

Complete the steps in the Set up SQL Server R Services (In-Database) Instructions. The set up instructions file can found at  <a href="https://msdn.microsoft.com/en-us/library/mt696069.aspx" target="_blank"> https://msdn.microsoft.com/en-us/library/mt696069.aspx</a>

<h2>Set up logins in SQL Server</h2>
If you are administering your own server and want to add a user to run the code of this solution, use the steps below.
<ol>
<li>	In SSMS, connect to the Server with your admin account</li>.
<li>	Create a new user: Right click on <code>Security</code> and select <code>New &gt; Login</code> <br/>
<br/>
<img src="../Images/newuser.png" width="50%" >
</li>
 
<li>	If you haven’t already done so, create a new Windows authentication user with the Login name <code>&lt;machinename&gt;/SQLRUserGroup</code>.
<p>
To find your computer name - Click the <code>Start</code> button, right-click <code>Computer</code>, and then click 
<code>Properties</code>. Under Computer name, domain, and workgroup settings, you can find your computer name and full computer name if your computer is on a domain.
<br/>
<img src="../Images/sqluser.png" width="75%" >
</li>
 
<li>	Create the "rdemo" user  by double clicking on the <code>Resources/createuser.sql</code> file and executing it.
 (This user login will be used to install data and procedures).
<br/>

<li>	Check to make sure you have set your Server Authentication mode to SQL Server and Windows Authentication mode.  
    <ul>
<li>	In SQL Server Management Studio Object Explorer, right-click the server, and then click <code>Properties</code>.</li>
<li>	On the Security page, under Server authentication, select <code>SQL Server and Windows Authentication mode</code> if it is not already selected.</li>
 <br/>
<img src="../Images/authmode.png" width="75%" >
<li>	In the SQL Server Management Studio dialog box, click OK.  If you changed the mode in the previous step, you will need to also acknowledge the requirement to restart SQL Server.</li>
<li>	If you changed the mode, restart the server.  In the Object Explorer, right-click your server, and then click <code>Restart</code>. If SQL Server Agent is running, it must also be restarted.</li>
</ul></li>

<li>	Now, click on <code>File</code> on the top left corner of the SQL Server window and select <code>Connect Object Explorer…</code> verify that you can connect to the server with this username(<code>rdemo</code>) &amp; password(<code>D@tascience</code>) using the SQL Server Authentication.</li>
</ol>

 

<h2>Ready to Run Code</h2>
You are now ready to run the code for this solution.  

+ Typically a data scientist will create and test a predictive model from their favorite R IDE, at which point the models will be stored in SQL Server and then scored in production using Transact-SQL (T-SQL) stored procedures. 
You can follow along with this by following the [Typical Workflow Walkthrough.](Typical_Workflow.md).

+ If you’re just interested in the outcomes of this process we have created a fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts. This is the fastest way to deploy. See [PowerShell Instructions](Powershell_Instructions.md) for this deployment.
	