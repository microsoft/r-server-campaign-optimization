##########################################################################################################################################
## This R script will determine recommendations for each Lead_Id
## The goal is to determine, for each Lead_Id, the best combination of Day_of_Week, Channel, Time_Of_Day to target him.
## The best combination will be the one that was assigned the highest probability of conversion with the best model selected by scoring.

## This is done by doing the following: 
## 1. Create a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day. 
## 2. Compute the predicted probabilities for each Lead_Id, for each combination of Day_Of_Week, Channel, Time_Of_Day, using best_model.
## 3. For each Lead_Id, choose the combination of Day_Of_Week, Channel, Time_Of_Day that has the highest conversion probability.

## Input : Data set CM_AD and the best prediction model: best_model. 
## Output: Recommended Day_Of_Week, Channel and Time_Of_Day for each Lead_Id, to get a higher conversion rate.  

##########################################################################################################################################

## Packages, system info and Compute Context

##########################################################################################################################################
# Load revolution R library and data.table. 
library(RevoScaleR)
library(dplyrXdf)

# File system
hdfs <- RxHdfsFileSystem()

# The default directory on local edge node
myShareDir <- paste( "/var/RevoShare", Sys.info()[["user"]],sep="/" ) 

# Compute Contexts
myHadoopCluster <- RxSpark()

##########################################################################################################################################

## Input: - Point to the HDFS with the whole data set 
##        - Import the best model from local edge node. 

##########################################################################################################################################
# Point to Xdf file holding the whole data set.
CM_AD <- RxXdfData(file = "/CampaignManagement/CMADXdf",fileSystem = hdfs)

# Import the fitted best model
rxSetComputeContext('local')
if(best_model == "random_forest"){
  import_model <- readRDS(file=paste(myShareDir,"/forest_model.rds",sep=""))
} else {
  import_model <- readRDS(file=paste(myShareDir,"/btree_model.rds",sep=""))
}
best_model <- import_model

##########################################################################################################################################

## Create a full data table with all the unique combinations of Day_of_Week, Channel, Time_Of_Day 

##########################################################################################################################################

# Create a table with all the unique combinations of Day_of_Week, Channel, Time_Of_Day.
Day_of_Week_unique <- data.frame(seq(1, 7))
Channel_unique <-data.frame(c("Email", "Cold Calling", "SMS"))
Time_Of_Day_unique <- data.frame(c("Morning", "Afternoon", "Evening"))
Unique_Combos <- merge(merge(Day_of_Week_unique, Channel_unique), Time_Of_Day_unique)
colnames(Unique_Combos) <- c("Day_Of_Week", "Channel", "Time_Of_Day")

# create a key used for later merge
Unique_Combos$key <- rep(1,nrow(Unique_Combos))

# export to local edge node 
rxSetComputeContext('local') # write a dataframe to HDFS requires compute context set as local
Unique_Combos_Xdf <- RxXdfData(file = paste(myShareDir,"/UniqueCombosXdf",sep=""))
rxDataStep(inData = Unique_Combos, outFile = Unique_Combos_Xdf, overwrite = TRUE)

# We create a table that has, for each Lead_Id and its corresponding variables (except Day_of_Week, Channel, Time_Of_Day),
# One row for each possible combination of Day_of_Week, Channel and Time_Of_Day.
# create key for CM_AD and export it to local edge node
CM_AD_key <- RxXdfData(file = paste(myShareDir,"/CMADkeyXdf",sep=""))
rxDataStep(inData = CM_AD, outFile = CM_AD_key, overwrite = TRUE, transforms = list(key = rep(1, .rxNumRows)))

# merge by key
AD_full_merged <- RxXdfData(file = paste(myShareDir,"/ADfullmergedXdf",sep=""))
rxMerge(CM_AD_key, Unique_Combos_Xdf, matchVars = "key", type = "full", outFile = AD_full_merged, varsToDrop1 = c("Day_Of_Week","Time_Of_Day","Channel"),overwrite = TRUE)

##########################################################################################################################################

## Compute the predicted probabilities for each Lead_Id, for each combination of Day_of_Week, Channel, Time_Of_Day, using best_model

##########################################################################################################################################

# Score the full data by using the best model. Keep Lead_Id in the prediction table to be able to do an inner join with the full table.
score <- RxXdfData(file = paste(myShareDir,"/scoreXdf",sep=""))
rxSetComputeContext('local')
rxPredict(best_model, data = AD_full_merged, outData = score, overwrite = TRUE, type = "prob",
          extraVarsToWrite = c("Lead_Id", "Day_Of_Week","Time_Of_Day","Channel"), reportProgress = 0)

##########################################################################################################################################

## For each Lead_Id, choose a combination of Day_of_Week, Channel, and Time_Of_Day that has the highest conversion probability    

##########################################################################################################################################
# change variable names
varInfo <- list(list(position = 2, newName='prob1'))
rxSetVarInfo(varInfo, score)

# calculate the max probability of each Lead_Id using package dyplyrXdf
max_prob_tbl <- score %>% 
  select(Lead_Id, prob1) %>%
  group_by(Lead_Id) %>%
  summarise(max_prob = max(prob1))

# save max_prob_table as xdf to local edge node
max_prob_tbl_xdf <- RxXdfData(file = paste(myShareDir,"/maxprobtblXdf",sep=""))
rxDataStep(inData = max_prob_tbl, outFile = max_prob_tbl_xdf, overwrite = TRUE, transforms = list(Lead_Id = as.character(Lead_Id)))

# assign max probability for each row based its Lead_Id
reco_merge_xdf <- RxXdfData(file = paste(myShareDir,"/recomergeXdf",sep=""))
rxMerge(score, max_prob_tbl_xdf, outFile = reco_merge_xdf, matchVars = "Lead_Id", type = "left", overwrite = TRUE, varsToDrop1 = c("0_prob","Conversion_Flag_Pred"))

# select the row with max probability for each Lead_Id
# save to local edge node
reco_final_xdf <- RxXdfData(file = paste(myShareDir,"/recofinalXdf",sep=""))
rxDataStep(inData = reco_merge_xdf, outFile = reco_final_xdf, overwrite = TRUE, rowSelection = (prob1 == max_prob), varsToDrop = c("prob1","max_prob"))
