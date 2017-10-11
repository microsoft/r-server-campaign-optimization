##########################################################################################################################################
## This R script will do the following:
## 1. Specify parameters for main function: 
##    1) Working directories on edge node and HDFS
##    2) Full path of the four input tables on HDFS
## 2. Define the main function for development 
## 3. Invoke the main function for development

## Input : 1. Working directories on edge node and HDFS
##         2. Full path of the four input tables on HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##############################################################################################################################
#
#                                             Specify Parameters                                                             #
#
##############################################################################################################################

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/Campaign/dev", sep="" ) 
HDFSWorkDir <- "/Campaign/dev"

# Specify the full path of input .csv files on HDFS
Campaign_Detail <-  "/Campaign/Data/Campaign_Detail.csv"
Lead_Demography <-  "/Campaign/Data/Lead_Demography.csv"
Market_Touchdown <-  "/Campaign/Data/Market_Touchdown.csv"
Product <-  "/Campaign/Data/Product.csv"

##############################################################################################################################
#
#                                       Define Main Function for Development                                                 #
#
##############################################################################################################################

# The main function for development
campaign_main <- function(Campaign_Detail, 
                          Lead_Demography, 
                          Market_Touchdown, 
                          Product,
                          LocalWorkDir,
                          HDFSWorkDir,
                          Stage = "Dev"){
  
  # load RevoScaleR package
  library(RevoScaleR)
  
  # connect to spark session
  rxSparkConnect(reset = TRUE)
  
  # step1: data processing
  source("step1_data_processing.R")
  step1_res_list <- data_process(Campaign_Detail = Campaign_Detail,
                                 Lead_Demography = Lead_Demography,
                                 Market_Touchdown = Market_Touchdown,
                                 Product = Product,
                                 LocalWorkDir = LocalWorkDir,
                                 HDFSWorkDir = HDFSWorkDir,
                                 Stage = Stage)
  
  # step2: feature engineering
  source("step2_feature_engineering.R")
  step2_res_list <- feature_engineer(LocalWorkDir = LocalWorkDir,
                                     HDFSWorkDir = HDFSWorkDir,
                                     numSplits = step1_res_list$numSplits,
                                     CM_AD_Clean_colInfo = step1_res_list$CM_AD_Clean_colInfo)
  
  # step3: training and evaluation
  source("step3_training_evaluation.R")
  training_evaluation(LocalWorkDir = LocalWorkDir,
                      HDFSWorkDir = HDFSWorkDir,
                      CM_AD_Features_names = step2_res_list$CM_AD_Features_names)
  
  # step4: campaign recommendations
  source("step4_campaign_recommendations.R")
  score_recommendation(LocalWorkDir = LocalWorkDir,
                       HDFSWorkDir = HDFSWorkDir,
                       numSplits = step1_res_list$numSplits,
                       Stage = Stage)
  
  # step5: create hive table
  source("step5_create_hive_table.R")
  Convert2HiveTable(LocalWorkDir = LocalWorkDir,
                    HDFSWorkDir = HDFSWorkDir, 
                    numSplits = step1_res_list$numSplits,
                    Stage = Stage)
  
  # disconnect spark session
  rxSparkDisconnect()
}

##############################################################################################################################
#
#                                             Invoke Main Function                                                           #
#
##############################################################################################################################

# Invoke main function for development
campaign_main(Campaign_Detail = Campaign_Detail, 
              Lead_Demography = Lead_Demography, 
              Market_Touchdown = Market_Touchdown, 
              Product = Product,
              LocalWorkDir = LocalWorkDir,
              HDFSWorkDir = HDFSWorkDir,
              Stage = "Dev")
