##########################################################################################################################################
##  IMPORTANT: Make sure you've run campaign_deployment.R to create the web service before using this script.  You'll also
##   need to have an ssh session open to the server, as described in the steps in https://aka.ms/campaigntypical?path=hdi#step3 
##   Finally, scroll to last section to read further instructions for testing the api_frame call
##
##########################################################################################################################################
## This R script should be executed in your local machine to test the web service
## Before remote login from local, please open a ssh session with localhost port 12800 (ssh user login, not admin)
##
## This R script will do the followings:
## 1. Remote connect to the port 12800 of the edge node which hosts the web service
## 2. Call the web service from your local machine

## Input : 1. Full path of the four input tables on HDFS or four tables in data frame
##         2. Working directories on local edge node and HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##############################################################################################################################
#
#                                                  Remote Login for Authentication                                           #
#
##############################################################################################################################

# Load mrsdeploy package
library(mrsdeploy)

# Remote login (admin login)
remoteLogin(
  "http://localhost:12800",
  username = "admin",
  password = "XXYOURPW",
  session = FALSE
)

##############################################################################################################################
#
#                                                Get and Call the Web Service for String Input                               #
#
##############################################################################################################################

# Specify the name and version of the web service
name_string <- "campaign_scoring_string_input"
version <- "v1.2.42" 

# Get the API for string input
api_string <- getService(name_string, version)

# Specify working directories on edge node and HDFS
ssh_username <- "sshuser"
HDFSProdDir <- "/Campaign/prod"
LocalProdDir <- paste("/var/RevoShare/", ssh_username, "/Campaign/prod", sep="" )

# Specify the full path of .csv files on HDFS
campaign_detail_str <- "/Campaign/Data/Campaign_Detail1000.csv"
lead_demography_str <- "/Campaign/Data/Lead_Demography1000.csv"
market_touchdown_str <- "/Campaign/Data/Market_Touchdown1000.csv"
product_str <- "/Campaign/Data/Product1000.csv"

# Call the web service
result_string <- api_string$campaign_web_scoring(
  Campaign_Detail = campaign_detail_str,
  Lead_Demography = lead_demography_str,
  Market_Touchdown = market_touchdown_str,
  Product = product_str,
  LocalWorkDir = LocalProdDir,
  HDFSWorkDir = HDFSProdDir,
  Stage = "Web"
)

##############################################################################################################################
#
#                                            Get and Call the Web Service for data frame Input  
#                                         Run this section after putting data into a local folder
#                                                      Change local_data_dir accordingly
#
##############################################################################################################################

# Specify the name and version of the web service
name_frame <- "campaign_scoring_frame_input"
version <- "v1.2.42" 

# Get the API for data frame input
api_frame <- getService(name_frame, version)

# Specify working directories on edge node and HDFS
ssh_username <- "sshuser"
HDFSProdDir <- "/Campaign/prod"
LocalProdDir <- paste("/var/RevoShare/", ssh_username, "/Campaign/prod", sep="" )

# Specify the local path contains the .csv files and load the .csv files
local_data_dir <- "Campaign/Data/1kData"
campaign_detail_df <- read.csv(file.path(local_data_dir, "Campaign_Detail1000.csv"))
lead_demography_df <- read.csv(file.path(local_data_dir, "Lead_Demography1000.csv"))
market_touchdown_df <- read.csv(file.path(local_data_dir, "Market_Touchdown1000.csv"))
product_df <- read.csv(file.path(local_data_dir, "Product1000.csv"))

# Call the web service
result_frame <- api_frame$campaign_web_scoring(
  Campaign_Detail = campaign_detail_df,
  Lead_Demography = lead_demography_df,
  Market_Touchdown = market_touchdown_df,
  Product = product_df,
  LocalWorkDir = LocalProdDir,
  HDFSWorkDir = HDFSProdDir,
  Stage = "Web"
)
