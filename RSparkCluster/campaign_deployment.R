##########################################################################################################################################
##  IMPORTANT: Before you run this for the first time, you must first CONFIGURE THE OPERATIONALIZATION SERVER
##  See https://aka.ms/campaigntypical?path=hdi#step3 for details
##
##########################################################################################################################################
## This R script will do the following:
## 1. Remote login to the edge node for authentication purpose
## 2. Load model related files as a list which will be used when publishing web service
## 3. Create the scoring function
## 4. Publish the web service
## 3. Verify the webservice locally

## Input : 1. Full path of the four input tables on HDFS or four tables in data frame
##         2. Working directories on local edge node and HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##################################################################################################################################
#
#                                        Define Scoring Function                                                                 #
#
##################################################################################################################################

# Load mrsdeploy package
library(mrsdeploy)

# Remote login for authentication purpose
remoteLogin(
  "http://localhost:12800",
  username = "admin",
  password = "XXYOURPW",
  session = FALSE
)

# Specify working directories on edge node and HDFS
LocalProdDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/Campaign/dev", sep="" ) 
HDFSProdDir <- "/Campaign/prod"



# Load .rds files
# These .rds files are saved from development stage and will be used for web-scoring.
# These .rds files are loaded locally and packed as a list to be published along with the scoring function.
# After publishing, the objects in the list can be directly used by the scoring function
summary_dev <- readRDS(file.path(LocalProdDir,"model/num_col_stats.rds"))
forest_model <- readRDS(file.path(LocalProdDir,"model/forest_model.rds"))
logistic_model <- readRDS(file.path(LocalProdDir,"model/logistic_model.rds"))
CM_AD_factorized_colInfoFull <- readRDS(file.path(LocalProdDir,"model/CM_AD_factorized_colInfoFull.rds"))
best_model_name <- readRDS(file.path(LocalProdDir,"model/best_model_name.rds"))

model_obj <- list(summary_dev = summary_dev, 
                  forest_model = forest_model,
                  logistic_model = logistic_model,
                  CM_AD_factorized_colInfoFull = CM_AD_factorized_colInfoFull,
                  best_model_name = best_model_name)

# Define the scoring function
# Please replace the directory in "source" function with the directory of your own
# The directory should be full path containing the source scripts
campaign_web_scoring <- function(Campaign_Detail, 
                                 Lead_Demography, 
                                 Market_Touchdown, 
                                 Product,
                                 LocalWorkDir,
                                 HDFSWorkDir,
                                 userName,
                                 Stage = "Web")
{
  # load RevoScaleR package
  library(RevoScaleR)
  
  # connect to spark session
  rxSparkConnect(reset = TRUE)
  
  # step1: data processing
  source(paste("/home/", userName, "/step1_data_processing.R", sep=""))
  step1_res_list <- data_process(Campaign_Detail = Campaign_Detail,
                                 Lead_Demography = Lead_Demography,
                                 Market_Touchdown = Market_Touchdown,
                                 Product = Product,
                                 LocalWorkDir = LocalWorkDir,
                                 HDFSWorkDir = HDFSWorkDir,
                                 Stage = Stage)
  
  # step2: feature engineering
  source(paste("/home/", userName, "/step2_feature_engineering.R", sep=""))
  step2_res_list <- feature_engineer(LocalWorkDir = LocalWorkDir,
                                     HDFSWorkDir = HDFSWorkDir,
                                     numSplits = step1_res_list$numSplits,
                                     CM_AD_Clean_colInfo = step1_res_list$CM_AD_Clean_colInfo)
  
  # step3: campaign recommendations
  source(paste("/home/", userName, "/step4_campaign_recommendations.R", sep=""))
  score_recommendation(LocalWorkDir = LocalWorkDir,
                       HDFSWorkDir = HDFSWorkDir,
                       numSplits = step1_res_list$numSplits,
                       Stage = Stage)
  
  # step4: create hive table
  source(paste("/home/", userName, "/step5_create_hive_table.R", sep=""))
  hive_table_dir <- Convert2HiveTable(LocalWorkDir = LocalWorkDir,
                                      HDFSWorkDir = HDFSWorkDir, 
                                      numSplits = step1_res_list$numSplits,
                                      Stage = Stage)
  
  
  return(hive_table_dir)
  
  # disconnect spark session
  rxSparkDisconnect()
}

##################################################################################################################################
#
#                                        Publish as a Web Service                                                                #
#
##################################################################################################################################

# Specify the version of the web service
version <- "v1.2.47"

# Publish the api for character input
api_string <- publishService(
  "campaign_scoring_string_input",
  code = campaign_web_scoring,
  model = model_obj,
  inputs = list(Campaign_Detail = "character",
                Lead_Demography = "character",
                Market_Touchdown = "character",
                Product = "character",
                LocalWorkDir = "character",
                HDFSWorkDir = "character",
                userName = "character",
                Stage = "character"),
  outputs = list(answer = "character"),
  v = version
)

# Publish the api for data frame input
api_frame <- publishService(
  "campaign_scoring_frame_input",
  code = campaign_web_scoring,
  model = model_obj,
  inputs = list(Campaign_Detail = "data.frame",
                Lead_Demography = "data.frame",
                Market_Touchdown = "data.frame",
                Product = "data.frame",
                LocalWorkDir = "character",
                HDFSWorkDir = "character",
                userName = "character",
                Stage = "character"),
  outputs = list(answer = "character"),
  v = version
)

##################################################################################################################################
#
#                                    Verify The Published API                                                                    #
#
##################################################################################################################################

# Specify the full path of input .csv files on HDFS
campaign_detail_str <- "/Campaign/Data/Campaign_Detail1000.csv"
lead_demography_str <- "/Campaign/Data/Lead_Demography1000.csv"
market_touchdown_str <- "/Campaign/Data/Market_Touchdown1000.csv"
product_str <- "/Campaign/Data/Product1000.csv"

# Import the .csv files as data frame 
campaign_detail_df <- rxImport(RxTextData(file = campaign_detail_str, fileSystem = RxHdfsFileSystem()))
lead_demography_df <- rxImport(RxTextData(file = lead_demography_str, fileSystem = RxHdfsFileSystem()))
market_touchdown_df <- rxImport(RxTextData(file = market_touchdown_str, fileSystem = RxHdfsFileSystem()))
product_df <- rxImport(RxTextData(file = product_str, fileSystem = RxHdfsFileSystem()))

# Verify the string input case
result_string <- api_string$campaign_web_scoring(
  Campaign_Detail = campaign_detail_str,
  Lead_Demography = lead_demography_str,
  Market_Touchdown = market_touchdown_str,
  Product = product_str,
  LocalWorkDir = LocalProdDir,
  HDFSWorkDir = HDFSProdDir,
  userName = Sys.info()[["user"]],
  Stage = "Web"
)

# Verify the data frame input case
result_frame <- api_frame$campaign_web_scoring(
  Campaign_Detail = campaign_detail_df,
  Lead_Demography = lead_demography_df,
  Market_Touchdown = market_touchdown_df,
  Product = product_df,
  LocalWorkDir = LocalProdDir,
  HDFSWorkDir = HDFSProdDir,
  userName = Sys.info()[["user"]],
  Stage = "Web"
)
