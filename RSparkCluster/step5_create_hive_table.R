##########################################################################################################################################
## This R script will do the following:
## Create a hive table and upload all final .csv files into that hive table which can be consumed by PowerBI for visulization

## Input : 1. .csv files of final recommendations
##         2. number of splits
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: Hive table of final recommendation

##########################################################################################################################################

Convert2HiveTable <- function(LocalWorkDir,
                              HDFSWorkDir, 
                              numSplits,
                              Stage)
{ 
  print("Starting Step5: Create Hive tables...")
  # load library
  library(RevoScaleR)
  
  # the folder stores the .csv files of final recommendation
  HDFSIntermediateDir <- file.path(HDFSWorkDir,"temp")
  
  # hive table name
  table_name <- "recommendation"
  
  # remove directory if exits
  if(rxHadoopFileExists(file.path("/hive/warehouse", table_name))){
    rxHadoopRemoveDir(file.path("/hive/warehouse", table_name))
  }
  
  # drop table if exists
  drop_table_command <- paste0("hive -e \"DROP TABLE if exists ",table_name,"\"")
  cat(drop_table_command)
  system(drop_table_command)
  
  # create table
  ## Import the best model from local edge node.
  myLocalTrainDir <- file.path(LocalWorkDir, "model")
  if(Stage == "Web"){
    
    # "model_obj" is defined in script "campaign_deployment" when publishing web servie
    # "model_obj" is a list containing all useful objects. We can directly refer to its elements when calling the published web service
    best_model_name <- model_obj$best_model_name
  } else {
    best_model_name <- readRDS(file = file.path(myLocalTrainDir, "best_model_name.rds"))
  }
  
  # make hive table schemas
  # the schemas from random forest and logistic are different, i.e., order of columns is different
  if(best_model_name == "random_forest"){
    table_schema <- " (
    prob1 Double,
    Conversion_Flag_Pred STRING,
    Conversion_Flag Int,
    Campaign_Name String,
    Product String,
    Recommended_Channel String,
    Recommended_Time String,
    Recommended_Day STRING,
    Age String,
    Annual_Income_Bucket String,
    Credit_Score String,
    State String,
    Lead_Id String,
    Day_Of_Week STRING,
    Time_Of_Day String,
    Channel String)
    "
  } else {
    table_schema <- " (
    prob1 Double,
    Lead_Id String,
    Age String,
    Annual_Income_Bucket String,
    Credit_Score String,
    Product String,
    Campaign_Name String,
    State String,
    Day_Of_Week STRING,
    Time_Of_Day String,
    Channel String,
    Conversion_Flag Int,
    Recommended_Day STRING,
    Recommended_Time String,
    Recommended_Channel String)
    "
  }
  
  
  create_table_command <- paste0("hive -e \"CREATE EXTERNAL TABLE if not exists ", 
                                 table_name,
                                 table_schema, 
                                 "ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' lines terminated by '\\n' 
                                 tblproperties(\\\"skip.header.line.count\\\"=\\\"1\\\");\"")
  cat(create_table_command)
  system(create_table_command)
  
  # load all .csv files into the hive table
  for(partNum in (0:(numSplits - 1))){
    upload_table_command <- paste0("hive -e \"LOAD DATA INPATH '",file.path(HDFSIntermediateDir, paste0("recomergefinal", partNum, ".csv")),"' INTO TABLE ",table_name, ";\"")
    cat(upload_table_command)
    system(upload_table_command)
  }
  
  # return the directory stores the hive table
  return(paste0("The data for final hive table is stored under the folder: ","/hive/warehouse/recommendation"))
  
  }

