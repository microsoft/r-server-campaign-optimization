##########################################################################################################################################
## This R script will do the following:
## 1. Copy the 4 .csv files from HDFS to local edge node: Campaign_Detail.csv, Lead_Demography.csv, Market-Touchdown.csv, and Product.csv.
## 2. Join the 4 datasets into one.
## 3. Clean the merged data set: replace NAs with the mode and export the cleaned data into HDFS

## Input : 4 Data files: Campaign_Detail.csv, Lead_Demography.csv, Market-Touchdown.csv, and Product.csv.
## Output: Cleaned raw data set CM_AD0.

##########################################################################################################################################

## Packages, system info and Compute Context

##########################################################################################################################################

# Load revolution R library. 
library(RevoScaleR)

# File system
hdfs <- RxHdfsFileSystem()

# The default directory on local edge node
myShareDir <- paste( "/var/RevoShare", Sys.info()[["user"]],sep="/" ) 

# Compute Contexts
myHadoopCluster <- RxSpark()

##########################################################################################################################################

## copy files from HDFS to edge node (local) in order to use rxMerge/rxMergeXdf functions which are not available on HDFS yet
## make .Xdf copies of the four tables  

##########################################################################################################################################
# set compute context to local
rxSetComputeContext('local')

# copy files from HDFS to local edge node
rxHadoopCopyToLocal(source = "/CampaignManagement/Campaign_Detail.csv", dest = myShareDir)
rxHadoopCopyToLocal(source = "/CampaignManagement/Lead_Demography.csv", dest = myShareDir)
rxHadoopCopyToLocal(source = "/CampaignManagement/Market_Touchdown.csv", dest = myShareDir)
rxHadoopCopyToLocal(source = "/CampaignManagement/Product.csv", dest = myShareDir)

# make .Xdf pointers 
Campaign_Detail <- RxXdfData(file = paste(myShareDir,"/CampaignDetailXdf",sep=""))
Lead_Demography <- RxXdfData(file = paste(myShareDir,"/LeadDemographyXdf",sep=""))
Market_Touchdown <- RxXdfData(file = paste(myShareDir,"/MarketTouchdownXdf",sep=""))
Product <- RxXdfData(file = paste(myShareDir,"/ProductXdf",sep=""))

# copy .csv files to .Xdf files
rxTextToXdf(inFile = paste(myShareDir,"/Campaign_Detail.csv",sep=""),outFile = Campaign_Detail, overwrite = TRUE)
rxTextToXdf(inFile = paste(myShareDir,"/Lead_Demography.csv",sep=""),outFile = Lead_Demography, overwrite = TRUE)
rxTextToXdf(inFile = paste(myShareDir,"/Market_Touchdown.csv",sep=""),outFile = Market_Touchdown, overwrite = TRUE)
rxTextToXdf(inFile = paste(myShareDir,"/Product.csv",sep=""),outFile = Product, overwrite = TRUE)

##########################################################################################################################################

## Join tables

##########################################################################################################################################
# Inner join of the tables Product and Campaign_Detail
Campaign_Product <- RxXdfData(file = paste(myShareDir,"/CampaignProductXdf",sep=""))
rxMerge(Campaign_Detail, Product, outFile = Campaign_Product, type = "inner", matchVars = "Product_Id", overwrite = TRUE, varsToDrop2 = "Category")

# Inner join of the tables Market_Touchdown and Lead_Demography
Market_Lead <- RxXdfData(file = paste(myShareDir,"/MarketLeadXdf",sep=""))
rxMerge(Market_Touchdown, Lead_Demography, outFile = Market_Lead, type = "inner", matchVars = "Lead_Id", overwrite = TRUE, varsToDrop1 = "Source")

# Inner join of the two previous tables.
Merged <- RxXdfData(file = paste(myShareDir,"/MergedXdf",sep=""))
rxMerge(Campaign_Product, Market_Lead, outFile = Merged, type = "inner", matchVars = "Campaign_Id", overwrite = TRUE, varsToDrop1 = "Amt_on_Maturity")

##########################################################################################################################################

## Clean the Merged data set: 
## Replace NAs with the mode.

##########################################################################################################################################
# Assumption: there are no NAs in the Id variables (Lead_Id, Product_Id, Campaign_Id)
# Function to deal with NAs. 
Mode_Replace <- function(data) {
  data <- data.frame(data)
  var <- colnames(data)[! colnames(data) %in% c("Lead_Id", "Phone_No", "Campaign_Id", "Comm_Id", "Time_Stamp", "Launch_Date", "Product_Id")]
  for(j in 1:length(var)){
    row_na <- which(is.na(data[, var[j]]) == TRUE) 
    if(length(row_na) > 0){
      xtab <- table(data[,var[j]])
      mode <- names(which(xtab==max(xtab)))
      if(is.character(data[, var[j]]) | is.factor(data[, var[j]])){
        data[row_na, var[j]] <- as.character(mode)
      } else{
        data[row_na, var[j]] <- as.integer(mode)
      }
    }
  }
  return(data)
}

Merged_df <- rxImport(Merged)
Merged_df_new <- Mode_Replace(Merged_df)

# Create the CM_AD0 Xdf file by dealing with NAs in Merged and save it to HDFS.
CM_AD0 <- RxXdfData(file = "/CampaignManagement/CMAD0Xdf",fileSystem = hdfs)
rxDataStep(inData = Merged_df_new, outFile = CM_AD0, overwrite = TRUE)  

# clean up local directory
system(paste("rm ",myShareDir,"/*",sep=""))