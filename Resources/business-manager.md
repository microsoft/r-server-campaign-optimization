<img src="Images/management.png" align="right">
# For the Business Manager

This solution template uses (simulated) historical data to predict  **how** and **when** to contact leads for your campaign. The recommendations include  the **best channel** to contact a lead (in our example, email, SMS, or cold call), the **best day of the week** and the **best time of day** in which to make the contact.  
 
SQL Server R Services brings the compute to the data by allowing R to run on the same computer as the database. It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime. 

This solution packet shows how to create and refine data, train R models, and perform predictions on the SQL Server machine. The final predictions table in SQL Server gives the recommendations for **how** and **when** to contact each lead. This data is then visualized in PowerBI.  PowerBI also presents visual summaries of the effectiveness of the campaign recommendations (shown here with simulated data).


![Visualize](Images/visualize.png?raw=true)


You can try out this dashboard in either of the following ways:

* Visit the [Cortana Intelligence Gallery](https://gallery.cortanaintelligence.com/Solution/e992f8c1b29f4df897301d11796f9e7c) and push the `Try it Now` button.

*  <a href="https://powerbi.microsoft.com/en-us/desktop/" target="_blank">Install PowerBI Desktop</a> and <a href="../Campaign%20Optimization%20Dashboard.pbix" target="_blank">download and open the CampaignManagement Dashboard</a> to see the simulated results.

The Recommendations tab of this dashboard shows the predicted recommendations.  At the top is a table of individual leads for our new deployment - lead ID, campaign and product, populated with leads using business rules, followed by the model predictions for each one, giving the optimal channel and time to contact the lead, and finally the conversion probability for the lead using these recommendations.  Since these recommendation represent the optimal combination for contacting the lead, this probability would be useful in limiting the number of leads to contact --  either by using the value itself (i.e., "all over .65") or by taking the top "N" leads.

Also on the Recommendations tab are various summaries of recommendations and demographic information on the leads. 

The Campaign Summary tab of the dashboard shows summaries of the historical data used to create the predicted recommendations.  While this tab also shows values of Day of Week, Time of Day, and Channel, these values are actual past observations, not to be confused with the recommendations shown on the Recomnmendations tab.  

To understand more about the entire process of modeling and deploying this example, see [For the Data Scientist](data-scientist.md).
 

[&lt; Back to ReadMe](../readme.md)
