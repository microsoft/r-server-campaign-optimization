##########################################################################################################################################
## This R script will do the following :
## 1. Create the variables SMS_Count, Email_Count, and Call_Count: number of times each Lead_Id was contacted through each channel.
## 2. Create the variable Previous_Channel: the previous channel used towards the Lead_Id in the campaign.
## 3. Aggregate the data by Lead_Id, keeping the latest campaign activity each Lead_Id received. 

## Input : CM_AD0: Data set before feature engineering, and with all the campaign activities received by each Lead_Id.
## Output: CM_AD: Data set with new features and the latest campaign activity each Lead_Id received.

##########################################################################################################################################

## Packages, system info and Compute Context

##########################################################################################################################################

# Load revolution R libraries
library(RevoScaleR)
library(dplyr)

# File system
hdfs <- RxHdfsFileSystem()

# The default directory on local edge node
myShareDir <- paste( "/var/RevoShare", Sys.info()[["user"]],sep="/" ) 

# Compute Contexts
myHadoopCluster <- RxSpark()

##########################################################################################################################################

## Input: Point to the .Xdf file with the cleaned raw data set

##########################################################################################################################################

CM_AD0 <- RxXdfData(file = "/CampaignManagement/CMAD0Xdf",fileSystem = hdfs)

##########################################################################################################################################

## Feature Engineering: SMS_Count, Email_Count, and Call_Count
## Determine how many times each Lead_Id was contacted through SMS, Email and Call

##########################################################################################################################################
#set compute context 
rxSetComputeContext('local')

# Function that determines how many times each Lead_Id was contacted through SMS, Email and Call. 
Counts <- function(data){
  library(data.table)
  data <- data.table(data)
  dt <- dcast.data.table(data, Lead_Id ~ Channel, fun = length, value.var = "Channel")
  names(dt)[grep("SMS",colnames(dt))] <- "SMS_Count"
  names(dt)[grep("Email",colnames(dt))] <- "Email_Count"
  names(dt)[grep("Call",colnames(dt))] <- "Call_Count"
  data_new <- merge(data, dt, by="Lead_Id", all.x =TRUE)
  return(data_new)
}

# Applying the function to CM_AD0 , and sort it. 
CM_AD0_dataFrame <- rxImport(CM_AD0)
CM_AD0_dataFrame <- Counts(CM_AD0_dataFrame)
CM_AD0_dataFrame <- CM_AD0_dataFrame[order(CM_AD0_dataFrame$Lead_Id,CM_AD0_dataFrame$Comm_Id),]

##########################################################################################################################################

## Feature Engineering: Previous_Channel
## Determine the previous channel used towards every Lead_Id for every campaign activity (disregarding the first record for each Lead_Id) 

##########################################################################################################################################
# Determine the previous channel used towards the Lead_Id, for every record except the first.
# Create a lag variable corresponding to the previous channel. 
pc_tbl <- CM_AD0_dataFrame %>% 
          select(Lead_Id, Channel) %>% 
          group_by(Lead_Id) %>%
          summarise(Previous_Channel = shift(Channel, n=1, type="lag")) 

CM_AD0_dataFrame$Previous_Channel <- pc_tbl$Previous_Channel

##########################################################################################################################################

## Keep the latest campaign activity each Lead_Id received

##########################################################################################################################################
# re-sort the data by decreasing order of Comm_Id
CM_AD0_dataFrame <- CM_AD0_dataFrame[order(CM_AD0_dataFrame$Lead_Id,CM_AD0_dataFrame$Comm_Id, decreasing = TRUE),]

# Keeping the last record for each Lead_Id, which is the one with biggest Comm_Id for each Lead_Id.
CM_AD0_dataFrame_new <- CM_AD0_dataFrame[which(!duplicated(CM_AD0_dataFrame$Lead_Id)),]

# export to HDFS
CM_AD <- RxXdfData(file = "/CampaignManagement/CMADXdf",fileSystem = hdfs)
rxDataStep(inData = CM_AD0_dataFrame_new, outFile = CM_AD, overwrite = TRUE)
