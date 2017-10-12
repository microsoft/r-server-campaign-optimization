##########################################################################################################################################
## This R script will do the following :
## 1. Create the variables SMS_Count, Email_Count, and Call_Count: number of times each Lead_Id was contacted through each channel.
## 2. Aggregate the data by Lead_Id, keeping the latest campaign activity each Lead_Id received. 

## Input:  1. Working directories on edge node and HDFS (assume the data, CM_AD_Clean for this step is already created there by step1)
##         2. Number of splits returned from step1.
##         3. Column info of CM_AD_Clean returned from step1
## Output: 1. Data set with new features and the latest campaign activity each Lead_Id received, CM_AD_Features.
##         2. Column info of CM_AD_Features

##########################################################################################################################################

## Function of feature engineering:
# LocalWorkDir: the working directory on local edge node.
# HDFSWorkDir the working directory on HDFS
# numSplits: number of splits
# CM_AD_Clean_colInfo: column info of CM_AD_Clean

feature_engineer <- function(LocalWorkDir,
                             HDFSWorkDir,
                             numSplits,
                             CM_AD_Clean_colInfo)
{ 
  
  print("Start step2: feature engineering...")
  
  # make the folder storing intermediate results
  LocalIntermediateDir <- file.path(LocalWorkDir, "temp")
  HDFSIntermediateDir <- file.path(HDFSWorkDir,"temp")
  
  # function perform feature engineer to each subeset. It will be applied to each subeset by rxExec function.
  featureEngrg <- function(partNum, HDFSIntermediateDir, colInfo) {
    
    print(paste0("partNum is ",partNum))
    
    # make directory for temporary results
    myTempDir <- file.path(tempdir(), paste0("part", partNum))
    dir.create(myTempDir)
    print(paste0("The temp folder is ", myTempDir))
    
    # make txt pointer to subset created from step1
    CM_AD_Clean <- RxTextData(file.path(HDFSIntermediateDir, "cmadclean", paste0("cmadclean", partNum, ".csv")),
                              colInfo = colInfo, firstRowIsColNames = F, fileSystem = RxHdfsFileSystem())  
    
    ###########################################################################################################################
    
    ## The block below will do the following:
    ## 1. Make a count table for Channel column by:
    ##    1) Calculate the count of SMS, Call and Email of Channel column for each Lead Id.
    ##    2) Make the count as new columns and fill missing with 0
    ##    3) Save the count table as xdf file
    ## 2. Append new columns to original table using left join based on Lead Id
    
    ###########################################################################################################################
    
    #calculate the count table for channel 
    
    print("calculating count table for channel...")
    library(dplyr)
    
    CM_AD_Clean_df <- rxDataStep(CM_AD_Clean, maxRowsByCols = 1e9) # make sure the data does not exceed maxRowsByCols
    CM_AD_Clean_df$Day_Of_Week <- as.character(CM_AD_Clean_df$Day_Of_Week)
    CM_AD_Clean_df$Conversion_Flag <- as.character(CM_AD_Clean_df$Conversion_Flag)
    t2.1 <- system.time(
      dt0 <- CM_AD_Clean_df %>%
        select(Lead_Id, Channel) %>%
        group_by(Lead_Id, Channel) %>%
        summarise(cnt = n())
    )
    
    # reshape, rename and fill missing with 0
    print("reshaping...")
    dt <- reshape(as.data.frame(dt0), v.names = "cnt", idvar = "Lead_Id", timevar = "Channel", direction = "wide")
    names(dt)[grep("SMS",colnames(dt))] <- "SMS_Count"
    names(dt)[grep("Email",colnames(dt))] <- "Email_Count"
    names(dt)[grep("Call",colnames(dt))] <- "Call_Count"
    # reserve the order of the three count variable
    SMS_Count <- dt$SMS_Count
    Email_Count <- dt$Email_Count
    Call_Count <- dt$Call_Count
    dt$SMS_Count <- dt$Email_Count <- dt$Call_Count <- NULL
    dt <- data.frame(dt, SMS_Count, Email_Count, Call_Count)
    print("filling missing...")
    dt[is.na(dt)] <- 0
    dt$Lead_Id <- as.character(dt$Lead_Id)
    
    # save as Xdf
    channel_cnt_xdf <- RxXdfData(paste(myTempDir,"/channel_cnt_xdf",sep=""))
    t2.2 <- system.time(
      rxDataStep(inData = dt, outFile = channel_cnt_xdf, overwrite = TRUE, reportProgress = 0)
    )
    
    # assign new created features by merging (left join) with CM_AD_Clean by lead id. 
    CM_AD_Clean_ChannelCnt_xdf <- RxXdfData(paste(myTempDir,"/CM_AD_Clean_channelcnt",sep=""))
    t2.3 <- system.time(
      rxMerge(inData1 = CM_AD_Clean_df, 
              inData2 = channel_cnt_xdf, 
              outFile = CM_AD_Clean_ChannelCnt_xdf, 
              matchVars = "Lead_Id",
              type = "left",
              overwrite = TRUE,
              autoSort = TRUE)
    )
    
    ###################################################################################################################################################
    
    ## The block below will do the following:
    ## 1. Create the table containing max comm_id for each Lead_Id
    ## 2. Assign the max comm_id to the table created in last block by left join on Lead_Id
    ## 3. For each Lead Id, only keep the row with comm_id equals to max comm_id
    
    ###################################################################################################################################################
    
    # create max table containing max comm_id of each lead_id 
    print("create max table containing max comm_id of each lead_id...")
    CM_AD_Clean_ChannelCnt_xdf_df <- rxDataStep(CM_AD_Clean_ChannelCnt_xdf, maxRowsByCols = 1e9) # make sure the data does not exceed maxRowsByCols
    t2.4 <- system.time(
      max_comm_id <- CM_AD_Clean_ChannelCnt_xdf_df %>%
        select(Lead_Id, Comm_Id) %>%
        group_by(Lead_Id) %>%
        summarise(max_comm_id = max(Comm_Id))
    )
    
    max_comm_id <- as.data.frame(max_comm_id)
    max_comm_id$Lead_Id <- as.character(max_comm_id$Lead_Id)
    max_comm_id_xdf <- RxXdfData(paste(myTempDir,"/max_comm_id_xdf",sep=""))
    t2.5 <- system.time(
      rxDataStep(inData = max_comm_id, outFile = max_comm_id_xdf, overwrite = TRUE, reportProgress = 0)
    )
    
    # assign the max comm_id to each lead id by merging with CM_AD_Clean_ChannelCnt 
    print("assign the max comm_id to each Lead_Id")
    CM_AD1 <- RxXdfData(paste(myTempDir,"/cm_ad1_xdf",sep=""))
    t2.6 <- system.time(
      rxMerge(inData1 = CM_AD_Clean_ChannelCnt_xdf, 
              inData2 = max_comm_id_xdf, 
              outFile = CM_AD1, 
              matchVars = "Lead_Id",
              type = "left",
              overwrite = TRUE)
    )
    
    CM_AD1_info <- rxGetInfo(CM_AD1, getVarInfo = T)
    
    # Keeping the record with largest comm_id for each Lead_Id and export to HDFS
    print("Keep the record with largest comm_id for each Lead_Id...")
    
    # CM_AD_Features is written as a txt folder on HDFS so that all .csv files under that folder can be read as ONE by rx-functions
    CM_AD_Features <- RxTextData(file = file.path(HDFSIntermediateDir, paste0("CMADFeatures/CMADFeaturespart", partNum, ".csv")),fileSystem = RxHdfsFileSystem(), firstRowIsColNames = F)
    t2.7 <- system.time(
      rxDataStep(inData = CM_AD1, 
                 outFile = CM_AD_Features, 
                 overwrite = TRUE,
                 varsToDrop = "max_comm_id",
                 rowSelection = (Comm_Id == max_comm_id))
    )
    
    # remove temporary dir
    system(paste("rm -rf", myTempDir))
    
    CM_AD1_names <- names(CM_AD1_info$varInfo)
    return(CM_AD1_names)
    
  } # end of featureEngrg function
  
  colInfo <- CM_AD_Clean_colInfo
  
  print("start execute feature Engrg")
  
  # invoke featureEngrg function parallelly by rxExec function
  t2.9 <- system.time(
    returnList2 <- rxExec(featureEngrg, partNum = rxElemArg(0:(numSplits-1)), HDFSIntermediateDir, colInfo)
  )
  
  
  CM_AD1_names <- returnList2$rxElem1
  CM_AD_Features_names <- CM_AD1_names[!CM_AD1_names %in% c("max_comm_id")]
  
  return(list(CM_AD_Features_names = CM_AD_Features_names))
  
}
