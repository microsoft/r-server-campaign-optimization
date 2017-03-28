---
layout: default
title: HOME
---

Marketing campaigns are not only about what you say, but also when you say it. Effective campaigns driven by advanced analytics systematically test and learn delivery timing to optimize open rates, click through rates and conversion rates. By delivering campaigns on different days and at different times of day, marketers can discover the optimum timing for distribution and direct customer contact. Algorithmic testing leads to improvements in world-class designs and copy, and is central to the campaign. Optimization is the formula for improving both sales leads and revenue generation, as well as producing strong ROI for your marketing investment.

The Microsoft Marketing Campaign Optimization solution is a combination of a Machine learning prediction model and an interactive visualization tool, PowerBI. The solution is used to increase the response rate to a campaign by recommending the channel to contact (for example, e-mail, SMS, or cold call) as well as when to contact (day of week and time of day) targeted leads for use in a new campaign. The solution uses simulated data, which can easily be configured to use your own organization’s data, to model the acquisition campaign response. The model uses predictors such as demographics, historical campaign performance and product details. 

This solution predicts the probability of a lead conversion from each channel, at various times of the day and days of the week, for every lead in the database. The final recommendation for targeting each lead is decided based upon the combination of channel, day of week and time of day with the highest probability of conversion. The solution has been modeled after a standardized data science process, where the data preparation, model training and evaluation can be easily done by a data scientist and the insights visualized and correlated to KPIs by marketing via Power BI visualization.



<div class="alert alert-success">
<h2>Select the platform you wish to explore:</h2>
 <form style="margin-left:30px"> 
    <label class="radio">
      <input type="radio" name="optradio" class="rb" value="cig" >{{ site.cig_text }}, deployed from <a href="https://aka.ms/campaignoptimization">Cortana Intelligence Gallery</a>
    </label>
    <label class="radio">
      <input type="radio" name="optradio" class="rb" value="onp">{{ site.onp_text }}
    </label>
   <label class="radio">
      <input type="radio" name="optradio" class="rb" value="hdi">{{ site.hdi_text }}, deployed from <a href="https://aka.ms/campaignoptimization-hdi">Cortana Intelligence Gallery</a>
    </label> 
</form>
</div>
<p></p>
<div class="cig">
On the VM created for you from the <a href="https://aka.ms/campaignoptimization">Cortana Intelligence Gallery</a>, the SQL Server 2016 database <code>Campaign</code> contains all the data and results of the end-to-end modeling process.  
</div>

<div class="onp">
For customers who prefer an on-premise solution, the implementation with SQL Server R Services is a great option that takes advantage of the powerful combination of SQL Server and the R language.  A Windows PowerShell script to invoke the SQL scripts that execute the end-to-end modeling process is provided for convenience. 
</div>

<div class="hdi">
This solution shows how to pre-process data (cleaning and feature engineering), train prediction models, and perform scoring on the  HDInsight Spark cluster with Microsoft R Server deployed from the <a href="https://aka.ms/campaignoptimization-hdi">Cortana Intelligence Gallery</a>.
<p></p>
<strong>HDInsight Spark cluster billing starts once a cluster is created and stops when the cluster is deleted. See <a href="hdinsight.html"> these instructions for important information</a> about deleting a cluster and re-using your files on a new cluster.</strong>

</div>

<p></p>
 We have modeled the steps in the template after a realistic team collaboration on a data science process. Data scientists do the data preparation, model training, and evaluation <span class="sql">from their favorite R IDE.</span><span  class="hdi">using the Open Source Edition of RStudio Server on the cluster edge node.</span>
 <span class="sql">
 DBAs can take care of the deployment using SQL stored procedures with embedded R code.  We show how each of these steps can be executed on a SQL Server client environment such as SQL Server Management Studio.
 </span> 
 <span class="hdi">
 Scoring is implemented with <a href="https://msdn.microsoft.com/en-us/microsoft-r/operationalize/about">R Server Operationalization</a>.
 </span>
 Finally, a Power BI report is used to visualize the deployed results.



 



