<img src="../Resources/Images/management.png" align="right">
# Campaign Management Template with SQL Server 2016 R Services – Input Data


The folder contains following files:

| File | Description |
| --- | --- |
| Campaign\_Detail.csv | Campaign Metadata |
| Market\_Touchdown.csv | Historical Campaign data including lead responses |
| Product.csv | Product Metadata |
| Lead\_Demography.csv | Demographic data of 100,000 leads |

The metadata for each of these file is below

**Campaign**

| Data Fields | Type | Description |
| --- | --- | --- |
| Campaign\_Id | Int | Unique identifier of each Campaign |
| Campaign\_Name | Varchar | Name of the Campaign |
| Launch\_Date | Varchar | Launch date of the campaign |
| Sub\_Category | Varchar | Sub Category of the Campaign |
| Campaign\_Drivers | Varchar | Has values like &#39;discount offer&#39;, &#39;additional coverage&#39; and &#39;extra benefit&#39; |
| Product\_Id | Varchar | Unique identifier of the product |
| Product\_Category | Varchar | Category of the product |
| Call\_For\_Action | Varchar | Objective of the campaign |
| Channel\_1 | Varchar | Shows if the lead was contacted via email or not |
| Channel\_2 | Varchar | Shows if the lead was contacted via cold call or not |
| Channel\_3 | Varchar | Shows if the lead was contacted via an agent or not |
| Focused\_Geography | Varchar | All values are populated as &#39;Nationwide&#39; |
| Tenure\_Of\_Campaign | Varchar | Tenure of the campaign |


**Market Touchdown**

| Data Fields | Type | Description |
| --- | --- | --- |
| Lead\_Id | Varchar | Unique Identifier of each Lead |
| Lead\_Ph | Varchar | Contact Phone Number of each Lead |
| Source | Varchar | Source from which the lead came into the database |
| Channel | Varchar | Channel through which the lead was contacted. Distinct values are &#39;Email&#39;, &#39;Cold Call&#39; and &#39;SMS&#39; |
| Day\_Of\_Week | Integer | Integer values showing the day of the week the lead was contacted |
| Time\_Of\_Day | Varchar | Time of day when the lead was contacted |
| Age | Varchar | Age group of the lead |
| Conversion\_Flag | Int | Final dependent variable with the value &#39;1&#39; indicating a successful purchase. |
| Campaign\_Id | Int | Unique Identifier of each Campaign |
| Response\_Latency | Varchar | Shows the latency in response for historical campaigns. Can have values &#39;none&#39;, &#39;quick&#39;, &#39;normal&#39; and &#39;late&#39; |

**Product**

| Data Fields | Type | Description |
| --- | --- | --- |
| Product\_Id | Varchar | Unique Identified of each product |
| Product | Varchar | Product Name |
| Category | Varchar | Category of the product |
| Term | Int | Number of months of coverage |
| No\_Of\_People\_Covered | Int | Number of people covered in the policy |
| Premium | int | Premium to be paid by the user |
| Payment\_Frequency | Varchar | Payment frequency of the product |
| Net\_Amt\_Insured | Int | Dollar Amount Insured |
| Amt\_On\_Maturity | int | Dollar Amount on Maturity |
| Amt\_On\_Maturity\_Bin | Varchar | Bucketed Dollar Amount on Maturity |

**Lead Demography**

| Data Fields | Type | Description |
| --- | --- | --- |
| Lead\_Id | Varchar | Unique identifier of lead. Same as lead\_id |
| Age | Int | Integer values of the lead&#39;s age |
| Phone\_No | Varchar | Contact Phone Number of each Lead |
| Annual\_Income\_Bucket | Int | Annual Income Range of the lead   |
| Credit\_Score | Int | Credit Score Range of the lead |
| Country | Varchar | Country of the lead |
| State | Varchar | Geographical state of the lead |
| No\_Of\_Children | Int | Number of children the lead has |
| Highest\_Education | Varchar | Highest Education of the lead |
| Ethnicity | Varchar | Ethnicity of the lead |
| No\_Of\_Dependants | Int | Number of dependents the lead has |
| Household\_Size | Int | Number of people in the house |
| Gender | Varchar | Gender of the lead |
| Marital\_Status | Varchar | Marital status of the lead |
