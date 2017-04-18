---
layout: default
title: Operationalization with R Server
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
{{ site.hdi_text }} 
</strong>
solution.
</div> 

##  Operationalization with R Server
---------------------------------------
To use R Server Operationalization services from your local computer, you must first connect to the edge node using the steps below.   

## Connect to Edge Node
<ul>
<li> <strong>Windows users:</strong>
For instructions on how to use PuTTY to connect to your HDInsight Spark cluster, visit the
<a href="http://go.microsoft.com/fwlink/p/?LinkID=620303#connect-to-a-linux-based-hdinsight-cluster"> Azure documentation. </a> Your edge node address is of the form <code>CLUSTERNAME-ed-ssh.azurehdinsight.net</code>.  
</li>
<li><strong>Linux, Unix, and OS X users:</strong>
For instructions on how to use the terminal to connect to your HDInsight Spark cluster, visit this
<a href="http://go.microsoft.com/fwlink/p/?LinkID=619886">Azure documentation</a>.  The edge node address is of the form <code>sshuser@CLUSTERNAME-ed-ssh.azurehdinsight.net</code>
</li>
<li>
<strong>All platforms:</strong> Your login name and password are the ones you created when you deployed this solution from the <a href="http://aka.ms/campaign-hdi">Cortana Intelligence Gallery</a>  
</li>
</ul>

## Configure Deployment Server

* Once you have connected to the edge node you can access the Administration Utilities for the web server with:

```
sudo dotnet /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Utils.AdminUtil/Microsoft.DeployR.Utils.AdminUtil.dll
```

Your server has been configuered with a password of  `D@tascience2017` for the  `admin` user.  You can use this utitlity to change the password if you wish. (If you do so, you will need to change the password in the  <strong>campaign_deployment.R</strong> script.)

You can also use this utility to check on the status of the web server. 

* Enter `6` to select "6. Run diagnostic tests";
* Enter `a` to select “A. Test configuration”;
* Provide username as `admin` and the password you just created;
* You should see “Overall Health: pass”;
* Now press `e` followed by ‘8’ to exit this tool

<div class="alert alert-info">
Do <strong>not</strong> close the terminal window - it should remain open when you execute <strong>campaign_web_scoring.R</strong> to try the web API on your local computer, after it is created with <strong>campaign_deployment.R</strong> from RStudio the cluster.
</div>


 

<a href="Typical.html#step3">Return to Typical Workflow<a>