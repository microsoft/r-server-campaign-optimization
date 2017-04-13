---
layout: default
title: Description of SQL Database Tables
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
<span class="cig">{{ site.cig_text }}</span>
<span class="onp">{{ site.onp_text }}</span>
</strong>
solution.
 {% include sqlchoices.md %}

</div> 

## SQL Database Tables
--------------------------

Below are the different data sets that you will find in your database after deployment. 

<table class="table table-striped table-condensed">
   <tr>
    <th>Table</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Campaign_Detail</td>
    <td>Raw data about each marketing campaign that occurred</td>
  </tr>
  <tr>
    <td>Lead_Demography </td>
    <td>Raw demographics and financial data about each customer</td>
  </tr>
  <tr>
    <td>Market_Touchdown</td>
    <td>Raw channel-day-time data used for every customer of Lead_Demography in every campaign he was targeted</td>
  </tr>
  <tr>
    <td>Product</td>
    <td>Raw data about the product marketed in each campaign</td>
  </tr>
    <tr>
    <td>CM_AD0</td>
    <td>Merged data with missing values replaced by the mode</td>
  </tr>
    <tr>
    <td>CM_AD</td>
    <td>Analytical data set: aggregated cleaned data set with new features</td>
  </tr>
    <tr>
    <td>CM_AD_N</td>
    <td>Normalized version of CM_AD</td>
  </tr>
    <tr>
    <td>All tables with the _N (e.g. Age_N)</td>
    <td>Table holding the normalization correspondance between the factors of each variable and the assigned integer</td>
  </tr>
    <tr>
    <td>Train_Id</td>
    <td>Lead_Id that will go to the training set</td>
  </tr>
    <tr>
    <td>CM_AD_Train</td>
    <td>Training set</td>
  </tr>
    <tr>
    <td>CM_AD_Test</td>
    <td>Testing set</td>
  </tr>
    <tr>
    <td>Campaign_Models</td>
    <td>Table storing the trained models</td>
  </tr>
    <tr>
    <td>Forest_Prediction</td>
    <td>Prediction results for testing step with Random Forest</td>
  </tr>
    <tr>
    <td>Boosted_Prediction</td>
    <td>Prediction results for testing step with GBT</td>
  </tr>
    <tr>
    <td>Campaign_Metrics</td>
    <td>Performance metrics of the models tested</td>
  </tr>
    <tr>
    <td>Best_Model</td>
    <td>Table with the name of the best model based on AUC</td>
  </tr>
      <tr>
    <td>Prob_Id</td>
    <td>Table with the scoring results on the full table with the best model</td>
  </tr>
      <tr>
    <td>Recommendations</td>
    <td>Table with the recommendations for each customer</td>
  </tr>
</table>
