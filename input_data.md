---
layout: default
title: Input Data
---

 
## CSV File Description
--------------------------

There are four input files used in this solution. They are:

* [Campaign_Detail.csv](#campaign-detail)
* [Lead_Demography.csv](#lead-demography)
* [Market_Touchdown.csv](#market-touchdown)
* [Product.csv](#product)

See each section below for a description of the data fields for each file.

<h3 id="campaign-detail">Campaign_Detail.csv</h3>
			
This file contains  ata about each marketing campaign that occurred.
<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Type</th><th>Description</th></tr>
<tr><td>1</td><td>	Campaign_Id</td><td>String</td><td>Unique Id of the campaign </td></tr>
<tr><td>2</td><td>	Campaign_Name</td><td>String</td><td>Name given to the campaign e.g., Above all in Service</td></tr>
<tr><td>3</td><td>	Category</td><td>String</td><td>Category of the campaign e.g., Acquisition</td></tr>
<tr><td>4</td><td>	Launch_Date</td><td>String</td><td>Launch date of the campaign e.g., 01/01/14</td></tr>
<tr><td>5</td><td>	Sub_Category</td><td>String</td><td>Sub-category of the campaign e.g., Seasonal</td></tr>
<tr><td>6</td><td>	Campaign_Drivers</td><td>String</td><td>Drivers of the campaign e.g. Discount Offer</td></tr>
<tr><td>7</td><td>	Product_Id</td><td>String</td><td>Unique Id of the product</td></tr>
<tr><td>8</td><td>	Call_For_Action</td><td>String</td><td>Objective of the campaign e.g. 1,2 </td></tr>
<tr><td>9</td><td>	Focused_Geography</td><td>String</td><td>Area of focus of the campaign e.g. Nation Wide</td></tr>
<tr><td>10</td><td>	Tenure_Of_Campaign</td><td>String</td><td>Tenure of the campaign e.g., 1,2</td></tr>
</table>

<h3 id="lead-demography">Lead_Demography.csv	</h3>

This file contains demographics and financial data about each customer.
<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Type</th><th>Description</th></tr>
<tr><td>1</td><td>	Lead_Id</td><td>String</td><td>	Unique Id of the customer </td></tr>
<tr><td>2</td><td>	Age	</td><td> String</td><td>Age of the customer e.g., Young, Middle Age, Senior Citizen</td></tr>
<tr><td>3</td><td>	Phone_No</td><td>String</td><td>Phone number of the customer.  Format: 000-000-0000</td></tr>
<tr><td>4</td><td>	Annual_Income_Bucket</td><td>String</td><td>Annual income range of the customer e.g., 60k-120k</td></tr>
<tr><td>5</td><td> Credit_Score</td><td>String</td><td>Credit score range of the customer e.g., > 700</td></tr>
<tr><td>6</td><td> Country</td><td>String</td><td>Country of residence of the customer</td></tr>
<tr><td>7</td><td>	State</td><td>String</td><td>State of residence of the customer in the US e.g., MA</td></tr>
<tr><td>8</td><td>	No_Of_Dependents</td><td>Integer</td><td>Number of dependents the customer has</td></tr>
<tr><td>9</td><td>	Highest_Education</td><td>String</td><td>Highest level of education received by the customer e.g., High School</td></tr>
<tr><td>10</td><td>	Ethnicity</td><td>String</td><td>Ethnicity of the customer e.g., Hispanic</td></tr>
<tr><td>11</td><td>	No_Of_Children</td><td>Integer</td><td>Number of children the customer has</td></tr>
<tr><td>12</td><td>	Household_Size</td><td>Integer</td><td>Number of people in the household of the customer</td></tr>
<tr><td>13</td><td>	Gender</td><td> String</td><td>	Gender of the customer.  Values taken: M or F</td></tr>
<tr><td>14</td><td>	Marital_Status</td><td>String</td><td>Marital status of the customer.  Values taken:  S, M, D, W (Single, Married, Divorced, Widowed)</td></tr>
</table>

<h3 id="market-touchdown">Market_Touchdown.csv</h3>

This file contains channel-day-time data used for every customer of Lead_Demography in every campaign he was targeted.
<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Type</th><th>Description</th></tr>
<tr><td>1</td><td>Lead_Id</td><td>String</td><td>Id of the customer</td></tr>
<tr><td>2</td><td>Channel</td><td>String</td><td>Channel used to contact the customer in a given campaign. Values taken:  SMS, Email, and Cold Calling</td></tr>
<tr><td>3</td><td>Time_Of_Day</td><td>String</td><td>Time of the day when the customer was contacted  in a given campaign.  Values taken:  Morning, Afternoon, and Evening</td></tr>
<tr><td>4</td><td>Day_Of_Week</td><td>String</td><td>Day of the week when the customer was contacted  in a given campaign. Values taken: 1,2,…,7</td></tr>
<tr><td>5</td><td>Campaign_Id</td><td>String</td><td>Id of the campaign during which the customer was contacted</td></tr>
<tr><td>6</td><td>	Conversion_Flag</td><td>String</td><td>	Binary variable indicating the success of a purchase or conversion (dependent variable).  Values taken: 0 (No conversion), or 1 (Conversion)</td></tr>
<tr><td>7</td><td>Source</td><td>String</td><td>	Source from which the data row came into the database
e.g., Previous Campaign</td></tr>
<tr><td>8</td><td>Time_Stamp</td><td>String</td><td>Date when the customer was contacted
e.g. 05/12/14</td></tr>
<tr><td>9</td><td>Comm_Id</td><td>Integer</td><td>Rank of communications for each unique customer, from the oldest to the most recent e.g., 1 is the first time a customer was contacted</td></tr>
</table>

<h3 id="product">	Product.csv		</h3>

This file contains data about the product marketed in each campaign.
<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Type</th><th>Description</th></tr>
<tr><td>1</td><td>	Product_Id</td><td>	String</td><td>Unique Id of the product</td></tr>
<tr><td>2</td><td>	Product</td><td>String</td><td>Name of the product e.g., Live Free</td></tr>
<tr><td>3</td><td>	Category</td><td>String</td><td>Category of the product e.g., Health</td></tr>
<tr><td>4</td><td>	Term</td><td>Integer</td><td>Number of months of coverage (if business is an insurance company)</td></tr>
<tr><td>5</td><td>	No_Of_People_Covered</td><td>Integer</td><td>Number of people covered in the policy (if business is an insurance company)</td></tr>
<tr><td>6</td><td>	Premium</td><td>Integer</td><td>Price to be paid by the customer (Premium if business is an insurance company)</td></tr>
<tr><td>7</td><td>	Payment_Frequency</td><td>String</td><td>Payment frequency of the product (if business is an insurance company) e.g., Monthly</td></tr>
<tr><td>8</td><td>	Net_Amt_Insured</td><td>Integer</td><td>Net amount insured (if business is an insurance company)</td></tr>
<tr><td>9</td><td>	Amt_on_Maturity</td><td> Integer</td><td>Dollar amount on maturity (if business is an insurance company)</td></tr>
<tr><td>10</td><td>	Amt_on_Maturity_Bin</td><td>String</td><td>Bucketed dollar amount on maturity (if business is an insurance company) e.g., &lt; 400000 </td></tr>
</table>
