---
layout: default
title: For the Business Manager
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

## For the Business Manager
------------------------------

This solution template uses (simulated) historical data to predict **how** and **when** to contact leads for your campaign. The recommendations include the **best channel** to contact a lead (in our example, Email, SMS, or Cold Call), the **best day of the week** and the **best time of day** during which to make the contact.  

<div class="sql"> 
SQL Server R Services takes advantage of the power of SQL Server 2016 and ScaleR (Microsoft R Server package) by allowing R to run on the same server as the database. It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime. 

This solution package shows how to create and refine data, train R models, and perform predictions in-database. The final table in the SQL Server database provides recommendations for **how** and **when** to contact each lead. This data is then visualized in Power BI. 

</div>
<div class="hdi">
Microsoft R Server on HDInsight Spark clusters provides distributed and scalable machine learning capabilities for big data, leveraging the combined power of R Server and Apache Spark. This solution demonstrates how to develop machine learning models for marketing campaign optimization (including data processing, feature engineering, training and evaluating models), deploy the models as a web service (on the edge node) and consume the web service remotely with Microsoft R Server on Azure HDInsight Spark clusters. 

The final predictions and recommendation table are saved to a Hive table containing recommendations for how and when to contact each lead. This data is then visualized in Power BI.
</div>



![Visualize](images/visualize.png?raw=true)


{% include pbix.md %}

The Recommendations tab of this dashboard shows the recommendations based on a prediction model. At the top is a table of individual leads for our new deployment. This includes fields for the Lead ID (unique customer ID), campaign and product, populated with leads on which our business rules are to be applied. This is followed by the optimal channel and time to contact each one, and then the estimated probabilities that the leads will buy our product using these recommendations. These probabilities can be used to increase the efficiency of the campaign by limiting the number of leads contacted to the subset most likely to buy.

Also on the Recommendations tab are various summaries of recommendations versus demographic information on the leads. 

The Campaign Summary tab of the dashboard shows summaries of the historical data used to create the prediction model. While this tab also shows values of Day of Week, Time of Day, and Channel, these values are actual past observations, not to be confused with the recommendations shown on the Recommendations tab.   

To understand more about the entire process of modeling and deploying this example, see [For the Data Scientist](data-scientist.html).
 

[&lt; Home](index.html)
