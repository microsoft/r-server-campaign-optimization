---
layout: default
title: For the IT Administrator
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
{{ site.hdi_text }}
</strong>
solution.
</div> 

## For the IT Administrator
------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
          <li><a href="#system-requirements">System Requirements</a></li>
          <li><a href="#step1">Cluster Maintenance</a></li>
          <li><a href="#workflow-automation">Workflow Automation</a></li>
        <li><a href="#step0">Data</a></li>
        </div>
    </div>
    <div class="col-md-6">
      As businesses are starting to acknowledge the power of data, leveraging machine learning techniques to grow has become a must. In particular, customer-oriented businesses can learn patterns from their data to intelligently design acquisition campaigns and convert the highest possible number of customers. 
          </div>
</div>
<p>
Among the key variables to learn from data are the best communication channel (e.g. SMS, Email, Call), the day of the week and the time of the day through which/ during which a given potential customer is targeted by a marketing campaign. This template provides a customer-oriented business with an analytics tool that helps determine the best combination of these three variables for each customer, based (among others) on financial and demographic data.
</p>

While this solution demonstrates the code with 100,000 leads for developing the model, using HDInsight Spark clusters makes it simple to extend to large data, both for training and scoring.  The only thing that changes is the size of the data and the number of clusters; the code remains exactly the same.

## System Requirements
-----------------------

This solution uses:

 * [R Server for HDInsight](https://azure.microsoft.com/en-us/services/hdinsight/r-server/)


## Cluster Maintenance
--------------------------

HDInsight Spark cluster billing starts once a cluster is created and stops when the cluster is deleted. <strong>See <a href="hdinsight.html"> these instructions for important information</a> about deleting a cluster and re-using your files on a new cluster. </strong>


## Workflow Automation
-------------------
Access RStudio on the cluster edge node by using the url of the form `http://CLUSTERNAME.azurehdinsight.net/rstudio`  Run the script **campain_main.R** to perform all the steps of the solution.

 
<a name="step0">

## Data Files
--------------


The following data files are available in the **Campaign/Data** directory in the storage account associated with the cluster:

 {% include data.md %}

<a name="step1">


