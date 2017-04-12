##########################################################################################################################################
##  IMPORTANT: Before you run this for the first time, make sure you've executed Copy_Dev2Prod.R to copy your
##   development model into the production directory!  Rerun that script whenever you have an updated model.
##
##########################################################################################################################################
## This R script will do the following:
## 1. Specify parameters for scoring function: 
##    1) Working directories on edge node and HDFS
##    2) Full path of the four input tables on HDFS
## 2. Define the scoring function for batch scoring 
## 3. Invoke the scoring function for batch scoring

## Input : 1. Working directories on edge node and HDFS
##         2. Full path of the four input tables on HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##############################################################################################################################
#
#                                                    Specify Parameters                                                      #
#
##############################################################################################################################

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/Campaign/prod", sep="" ) 
HDFSWorkDir <- "/Campaign/prod"

# Specify the full path of input .csv files on HDFS
Campaign_Detail <-  "/Campaign/Data/Campaign_Detail30000.csv"
Lead_Demography <-  "/Campaign/Data/Lead_Demography30000.csv"
Market_Touchdown <-  "/Campaign/Data/Market_Touchdown30000.csv"
Product <-  "/Campaign/Data/Product30000.csv"


##############################################################################################################################
#
#                                                  Define Scoring Function                                                   #
#
##############################################################################################################################

# Define the scoring function for batch scoring
campaign_score <- function(Campaign_Detail, 
                           Lead_Demography, 
                           Market_Touchdown, 
                           Product,
                           LocalWorkDir,
                           HDFSWorkDir,
                           Stage = "Prod")
{
  
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
  
  # step3: campaign recommendations
  source("step4_campaign_recommendations.R")
  score_recommendation(LocalWorkDir = LocalWorkDir,
                       HDFSWorkDir = HDFSWorkDir,
                       numSplits = step1_res_list$numSplits,
                       Stage = Stage)
  
  # step4: create hive table
  source("step5_create_hive_table.R")
  Convert2HiveTable(LocalWorkDir = LocalWorkDir,
                    HDFSWorkDir = HDFSWorkDir, 
                    numSplits = step1_res_list$numSplits,
                    Stage = Stage)
}

##############################################################################################################################
#
#                                                 Invoke the Scoring Function                                                #
#
##############################################################################################################################

# Invoke the scoring function for batch scoring
campaign_score(Campaign_Detail = Campaign_Detail, 
               Lead_Demography = Lead_Demography, 
               Market_Touchdown = Market_Touchdown, 
               Product = Product,
               LocalWorkDir = LocalWorkDir,
               HDFSWorkDir = HDFSWorkDir,
               Stage = "Prod")

