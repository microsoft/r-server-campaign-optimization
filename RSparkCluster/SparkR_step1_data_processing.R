##########################################################################################################################################
## This R script will do the following:
## 1. Create pointers pointing to the 4 data sets on HDFS: Campaign_Detail.csv, Lead_Demography.csv, Market-Touchdown.csv, and Product.csv.
## 2. Join the 4 datasets into one.
## 2. Clean the merged data set: replace NAs with the mode for categorical variables, and with the mean for numerical ones.

## Input : 4 Data files: Campaign_Detail.csv, Lead_Demography.csv, Market-Touchdown.csv, and Product.csv.
## Output: Cleaned raw data set CM_AD0.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load revolution R library and data.table. 
library(RevoScaleR)

# Compute Contexts
fs <- RxHdfsFileSystem()
myHadoopCluster <- RxSpark()

##########################################################################################################################################

## load 'SparkR' package, set context as SQLContext to perform join on data files

##########################################################################################################################################

if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "/home/spark")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sc <- sparkR.init(sparkPackages="com.databricks:spark-csv_2.11:1.5.0") # 1)check the latest version and replace it; 2)spark.stop() to stop
sqlContext <- sparkRSQL.init(sc)
Campaign_Detail <- read.df(sqlContext,"/CampaignManagement/Campaign_Detail.csv","csv",header = "true")
Lead_Demography <- read.df(sqlContext,"/CampaignManagement/Lead_Demography.csv","csv",header = "true")
Market_Touchdown <- read.df(sqlContext,"/CampaignManagement/Market_Touchdown.csv","csv",header = "true")
Product <- read.df(sqlContext,"/CampaignManagement/Product.csv","csv",header = "true")

# Register DataFrames as tables
registerTempTable(Campaign_Detail, "Campaign_Detail")
registerTempTable(Lead_Demography, "Lead_Demography")
registerTempTable(Market_Touchdown, "Market_Touchdown")
registerTempTable(Product, "Product")

# Inner join of the tables Product and Campaign_Detail
Campaign_Product <- sql(sqlContext, 
                        "SELECT Campaign_Detail.*, Product.Product, Product.Term, Product.No_of_people_covered, Product.Premium, 
                        Product.Payment_frequency, Product.Net_Amt_Insured, Product.Amt_on_Maturity, Product.Amt_on_Maturity_Bin
                        FROM Campaign_Detail 
                        INNER JOIN Product
                        ON Product.Product_Id = Campaign_Detail.Product_Id")

# Inner join of the tables Market_Touchdown and Lead_Demography
Market_Lead <- sql(sqlContext,
                   "SELECT Lead_Demography.*, Market_Touchdown.Channel, Market_Touchdown.Time_Of_Day, Market_Touchdown.Conversion_Flag,
                   Market_Touchdown.Campaign_Id, Market_Touchdown.Day_Of_Week, Market_Touchdown.Comm_Id, Market_Touchdown.Time_Stamp
                   FROM Market_Touchdown 
                   INNER JOIN Lead_Demography
                   ON Market_Touchdown.Lead_Id = Lead_Demography.Lead_Id")

# register Dataframes as tables
registerTempTable(Campaign_Product, "Campaign_Product")
registerTempTable(Market_Lead, "Market_Lead")

# Inner join of the two previous tables.
Campaign_Product_Market_Lead <- sql(sqlContext,
                                    "SELECT Market_Lead.*, Campaign_Product.Product, Campaign_Product.Category, Campaign_Product.Term, 
                                    Campaign_Product.No_of_people_covered, Campaign_Product.Premium, Campaign_Product.Payment_frequency, 
                                    Campaign_Product.Amt_on_Maturity, Campaign_Product.Sub_Category, Campaign_Product.Campaign_Drivers, 
                                    Campaign_Product.Campaign_Name, Campaign_Product.Launch_Date, Campaign_Product.Call_For_Action, 
                                    Campaign_Product.Focused_Geography, Campaign_Product.Tenure_Of_Campaign, Campaign_Product.Net_Amt_Insured, 
                                    Campaign_Product.Product_Id
                                    FROM Campaign_Product 
                                    INNER JOIN Market_Lead 
                                    ON Campaign_Product.Campaign_Id = Market_Lead.Campaign_Id ")

# write the merged table as .csv to HDFS
# write.df will get error or end up with empty file 
write.df(Campaign_Product_Market_Lead, "/CampaignManagement/Merged.csv", mode = "overwrite")

# stop spark session
sparkR.stop()

# detach sparkR package
detach("package:SparkR", unload=TRUE)