##########################################################################################################################################
## This R script will do the following:
## 1. Read the 4 data sets Campaign_Detail, Lead_Demography, Market_Touchdown, and Product, and copy them into local edge node
## 2. Join the 4 tables into one
## 3. Clean the merged data set: replace NAs with the mode

## Input : 1. 4 Data Tables: Campaign_Detail, Lead_Demography, Market_Touchdown, and Product
##         2. Working directories on edge node and HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: 1. Cleaned raw data set CM_AD_Clean and its column info 
##         2. Number of splits

##########################################################################################################################################

## Function of data processing:
# Campaign_Detail: full name of the campaign detail table in .csv format.
# Lead_Demography: full name of the lead demography table in .csv format.
# Market_Touchdown: full name of the market touchdown table in .csv format.
# Product: full name of the product table in .csv format.
# LocalWorkDir: the working directory on local edge node.
# HDFSWorkDir the working directory on HDFS
# Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service

data_process <- function(Campaign_Detail, 
                         Lead_Demography, 
                         Market_Touchdown, 
                         Product, 
                         LocalWorkDir,
                         HDFSWorkDir,
                         Stage)
{ 
  print("Start Step1: data processing...")
  
  # load library
  library(RevoScaleR)
  # spark cc object
  myHadoopCluster <- RxSpark()
  # set compute context to local
  rxSetComputeContext('local')
  
  ##############################################################################################################################
  
  ## The block below will do the following:
  ## 1. Make folders storing intermediate results. If a directory with same name already exists, it will be cleaned/removed first.
  ## 2. Copy data from HDFS to local edge node. This is because currently rxMerge is only supported locally.
  ## 3. Change data format from txt to xdf which is most efficient data format for rx-functions.
  
  ##############################################################################################################################
  
  # make folders storing intermediate results
  LocalIntermediateDir <- file.path(LocalWorkDir, "temp")
  HDFSIntermediateDir <- file.path(HDFSWorkDir,"temp")
  
  # clean up/remove the previous intermediate folders and make a new one.
  if(dir.exists(LocalIntermediateDir)){
    system(paste("rm -rf ",LocalIntermediateDir, sep="")) # remove the directory if exists
    system(paste("mkdir -p -m 777 ", LocalIntermediateDir, sep="")) # create a new directory
  } else {
    system(paste("mkdir -p -m 777 ", LocalIntermediateDir, sep="")) # make new directory if doesn't exist
  }
  if(rxHadoopFileExists(HDFSIntermediateDir)){
    rxHadoopRemoveDir(HDFSIntermediateDir, skipTrash = TRUE)
    rxHadoopMakeDir(HDFSIntermediateDir)
  } else {
    rxHadoopMakeDir(HDFSIntermediateDir)
  }
  
  # grant access permission for web service 
  system(paste("setfacl -d -m o::rwx ", LocalIntermediateDir, sep=""))
  
  # make xdf pointers for local edge node
  print("making local .xdf files...")
  Campaign_Detail_xdf <- RxXdfData(paste(LocalIntermediateDir,"/campaign_detail",sep=""))
  Lead_Demography_xdf <- RxXdfData(paste(LocalIntermediateDir,"/lead_demography",sep=""))
  Market_Touchdown_xdf <- RxXdfData(paste(LocalIntermediateDir,"/market_touchdown",sep=""))
  Product_xdf <- RxXdfData(paste(LocalIntermediateDir,"/product",sep=""))
  
  # data input can be a string of directory or a data frame
  if(is(Campaign_Detail)[1] == "character"){
    # copy file to local so that rxMerge function can be applied. 
    # currently, rxMerge function is only supported locally.
    rxHadoopCopyToLocal(source = Campaign_Detail, dest = LocalIntermediateDir)
    rxHadoopCopyToLocal(source = Lead_Demography, dest = LocalIntermediateDir)
    rxHadoopCopyToLocal(source = Market_Touchdown, dest = LocalIntermediateDir)
    rxHadoopCopyToLocal(source = Product, dest = LocalIntermediateDir)
    
    # grab .csv file names
    campaign_detail_split <- unlist(strsplit(Campaign_Detail,"/"))
    campaign_detail_csv <- campaign_detail_split[length(campaign_detail_split)]
    lead_demography_split <- unlist(strsplit(Lead_Demography,"/"))
    lead_demography_csv <- lead_demography_split[length(lead_demography_split)]
    market_touchdown_split <- unlist(strsplit(Market_Touchdown,"/"))
    market_touchdown_csv <- market_touchdown_split[length(market_touchdown_split)]
    product_split <- unlist(strsplit(Product,"/"))
    product_csv <- product_split[length(product_split)]
    
    # change txt to Xdf.
    rxTextToXdf(inFile = file.path(LocalIntermediateDir,campaign_detail_csv), outFile = Campaign_Detail_xdf, reportProgress = 0, overwrite = TRUE)
    rxTextToXdf(inFile = file.path(LocalIntermediateDir,lead_demography_csv), outFile = Lead_Demography_xdf, reportProgress = 0, overwrite = TRUE)
    rxTextToXdf(inFile = file.path(LocalIntermediateDir,market_touchdown_csv), outFile = Market_Touchdown_xdf, reportProgress = 0, overwrite = TRUE)
    rxTextToXdf(inFile = file.path(LocalIntermediateDir,product_csv), outFile = Product_xdf, reportProgress = 0, overwrite = TRUE)
    
    # remove .csv file on local
    system(paste("rm ", LocalIntermediateDir, "/*.csv", sep=""))
    
  } else if (is(Campaign_Detail)[1] == "data.frame"){
    # save data frame as xdf on local edge node
    rxDataStep(inData = Campaign_Detail, outFile = Campaign_Detail_xdf, overwrite = TRUE, reportProgress = 0)
    rxDataStep(inData = Lead_Demography, outFile = Lead_Demography_xdf, overwrite = TRUE, reportProgress = 0)
    rxDataStep(inData = Market_Touchdown, outFile = Market_Touchdown_xdf, overwrite = TRUE, reportProgress = 0)
    rxDataStep(inData = Product, outFile = Product_xdf, overwrite = TRUE, reportProgress = 0)
    
  } else {
    stop("invalid input format")
  }
  
  
  
  #################################################################################################################################################################
  
  ## The block below will do the followng:
  ## 1. Automatically determine the number of splits for the whole data set
  ## 2. Define the partition function, which will do the following:
  ##    1) Hash multiple Lead ID into one hash code. One unique Lead ID belongs to only one hash code. The number of unique hash code equal to the number of splits
  ##    2) Split the data into subsets based on the hash code
  ##    3) Output those subsets under one directory
  ## 3. Apply the partition function to Lead_Demography and Market_Touchdown tables.
  
  #################################################################################################################################################################
  
  # automatically determine the number of splits based on the number of unique lead id.
  num_lead_id <- rxGetInfo(Lead_Demography_xdf)$numRows
  numSplits <- 2 # default number of splits = 2, as if it is set to 1, it will cause problem from rxSplit function
  if(num_lead_id <= 10000){
    numSplits <- numSplits
  } else if(num_lead_id <= 100000){
    numSplits <- 5
  } else if(num_lead_id <= 1000000){
    numSplits <- 10
  } else {
    numSplits <- 100
  }
  
  # The partition function. It will partition the whole dataset into multiple (number = numSplits) subsets and rows with same lead id will be put into one subsets.
  # inData: input data
  # outFilesBase: the output path for each subset
  # numSplits: the number of splits.
  partitionByLeadId <- function(inData, outFilesName, numSplits, LocalIntermediateDir)  {
    
    #library(hashFunction)
    
    previousContext <- rxSetComputeContext('local')
    
    outFilesBase <- as.vector(sapply(0:(numSplits - 1), function(i){file.path(LocalIntermediateDir, paste0("Part", i), outFilesName)}))
    
    hashedData <- RxXdfData(paste0(LocalIntermediateDir,"/",outFilesName,"hashed"))
    
    rxDataStep(inData = inData,
               outFile = hashedData,
               transforms = list(hashCode = factor(sapply(as.character(Lead_Id), murmur3.32) %% n_chunk, levels = 0:(n_chunk-1))),
               transformObjects = list(n_chunk = numSplits),
               transformPackages = "hashFunction",
               overwrite = T)
    
    # currently rxSplit function is only supported for local compute context.
    splits <- rxSplit(hashedData,
                      outFilesBase = outFilesBase,
                      splitByFactor = "hashCode",
                      overwrite = T
    )
    
    rxSetComputeContext(previousContext)
  }
  
  # invoke the partition function
  print("partitioning by Lead_Id...")
  partitionByLeadId(inData =  Lead_Demography_xdf,
                    outFilesName = "LeadDemo", numSplits, LocalIntermediateDir)
  
  partitionByLeadId(inData =  Market_Touchdown_xdf,
                    outFilesName = "MarketTouchdown", numSplits, LocalIntermediateDir)
  
  
  #############################################################################################################################################
  
  ## The block below will do the following:
  ## 1. Merge Campaign_Detail table with Product table into Campaign_Product table
  ## 2. Define mergeTables function which will do the following:
  ##    1) Merge one subeset of Lead_Demography table and Maret_touchdown table pairwisly into Market_Lead table
  ##    2) Merge Campaign_Product table with Market_Lead table into the final merged table
  ##    3) Output the final merged table and copy it back to HDFS
  ## 3. Apply mergeTables function to each subeset of Lead_Demography and Market_Touchdown table parallely by invoking rxExec function
  
  ############################################################################################################################################
  
  # merge campaign_detail table and product table
  print("merging campaign_detail and product table...")
  Campaign_Product_xdf <- RxXdfData(paste(LocalIntermediateDir,"/campaign_product",sep=""))
  m1.1 <- system.time(
    rxMerge(inData1 = Campaign_Detail_xdf, 
            inData2 = Product_xdf, 
            outFile = Campaign_Product_xdf, 
            matchVars = "Product_Id",
            type = "inner",
            varsToDrop2 = "Category",
            overwrite = TRUE)
  )
  
  # Define mergeTables function:
  # This function will merge the market_touchdown and lead_demography table as market_lead table.
  # The merge campaign_product table with market_lead table
  # This function will be applied to each splitted subset by rxExec function.
  mergeTables <- function(partNum, LocalIntermediateDir, HDFSIntermediateDir, Campaign_Product_xdf) {
    
    Lead_Demography_xdf <-file.path(LocalIntermediateDir, paste0("Part", partNum), paste0("LeadDemo.hashCode.", partNum, ".xdf"))
    Market_Touchdown_xdf <-file.path(LocalIntermediateDir, paste0("Part", partNum), paste0("MarketTouchdown.hashCode.", partNum, ".xdf"))
    
    # merge market_touchdown and lead_demography table
    Market_Lead_xdf <- RxXdfData(file.path(LocalIntermediateDir, paste0("Part", partNum), "market_lead"))
    m1.2 <- system.time(
      rxMerge(inData1 = Market_Touchdown_xdf, 
              inData2 = Lead_Demography_xdf, 
              outFile = Market_Lead_xdf, 
              matchVars = "Lead_Id",
              type = "inner",
              varsToDrop1 = c("Source","Time_Stamp","hashCode"),
              varsToDrop2 = c("hashCode"),
              overwrite = TRUE)
    )
    # merge the output two tables
    Campaign_Product_Market_Lead_xdf <- RxXdfData(file.path(LocalIntermediateDir, paste0("Part", partNum), "campaign_product_market_lead"))
    m1.3 <- system.time(
      rxMerge(inData1 = Campaign_Product_xdf, 
              inData2 = Market_Lead_xdf, 
              outFile = Campaign_Product_Market_Lead_xdf, 
              matchVars = "Campaign_Id",
              type = "inner",
              varsToDrop1 = c("Launch_Date","Amt_on_Maturity_Bin"),
              overwrite = TRUE)
    )
    
    # change to .csv files
    Campaign_Product_Market_Lead_txt_filename <- file.path(LocalIntermediateDir, paste0("campaign_product_market_lead/campaign_product_market_lead", partNum, ".csv"))
    Campaign_Product_Market_Lead_txt <- RxTextData(file = Campaign_Product_Market_Lead_txt_filename,
                                                   firstRowIsColNames = F)
    rxDataStep(inData = Campaign_Product_Market_Lead_xdf, outFile = Campaign_Product_Market_Lead_txt)
    
    # copy the final merged files to HDFS
    rxHadoopCopyFromLocal(source = Campaign_Product_Market_Lead_txt_filename,
                          dest = file.path(HDFSIntermediateDir, "campaign_product_market_lead"))
    
    colNames <- names(Campaign_Product_Market_Lead_xdf)
    
    return(colNames)
  } # end of mergeTables
  
  if(!dir.exists(file.path(LocalIntermediateDir, "campaign_product_market_lead"))){
    dir.create(file.path(LocalIntermediateDir, "campaign_product_market_lead"), showWarnings = F)
  }
  unlink(file.path(LocalIntermediateDir, "campaign_product_market_lead", "*")) # make sure directory is empty
  
  campaign_product_market_lead_dir <- file.path(HDFSIntermediateDir, "campaign_product_market_lead")
  #rxHadoopCommand(paste("fs -rm -r", campaign_product_market_lead_dir))
  rxHadoopMakeDir(campaign_product_market_lead_dir)
  
  # mergeTables(0, LocalIntermediateDir, HDFSIntermediateDir, Campaign_Product_xdf) # for debugging
  
  rxOptions(numCoresToUse = -1) # use as many cores as possible 
  
  # set compute context for rxExec function.
  # as a rule of thumb, if it takes less than two minutes to complete calculation of each subset, compute context is better to be set as "localpar", otherwise, spark.
  rxSetComputeContext('localpar')
  # invoke rxExec function. use rxElemArg to control the total number of iteration.
  print("merging tables in parallel...")
  t1.1 <- system.time(
    mergeTablesResults <- rxExec(mergeTables, rxElemArg(0:(numSplits-1)), LocalIntermediateDir, HDFSIntermediateDir, Campaign_Product_xdf)
  )
  rxSetComputeContext('local')
  
  ############################################################################################################################################
  
  ## The block below will do the following:
  ## 1. Use rxSummary to get missing information.
  ## 2. Define replaceMissing function which will replace missing values with mean
  ## 3. Apply replaceMissing function to subsets of final merged table parallely using rxExec function
  
  ############################################################################################################################################
  
  # Assumption: no NAs in the Id variables (Lead_Id, Product_Id, Campaign_Id, Comm_Id) and in (Phone_No, Launch_Date, Time_Stamp).
  # Find the variables that have missing values (NA) and their global mean
  print("replace missing values...")
  colnames <- mergeTablesResults[[1]]
  var <- colnames[!colnames %in% c("Lead_Id", "Product_Id", "Campaign_Id", "Comm_Id", "Phone_No", "Launch_Date", "Time_Stamp")]
  formula <- as.formula(paste("~", paste(var, collapse = "+")))
  
  # make column info since txt files don't have headers
  colInfo <- mapply(function(i, colname){list(index=i, newName = colname)}, 1:length(colnames), colnames, SIMPLIFY = F)
  
  Campaign_Product_Market_Lead_txt = RxTextData(file = file.path(HDFSIntermediateDir, "campaign_product_market_lead"),
                                                colInfo = colInfo,
                                                firstRowIsColNames = F,
                                                fileSystem = RxHdfsFileSystem())
  
  
  # use rxSummary function to get missing information
  # rxSetComputeContext(myHadoopCluster) if large data
  summary <- rxSummary(formula, Campaign_Product_Market_Lead_txt, byTerm = TRUE)
  var_with_NA <- summary$sDataFrame[summary$sDataFrame$MissingObs > 0, 1]
  
  if(Stage == "Dev") {
    
    # save summary statistics of numeric columns for later use
    # it will be copied to production folder in step3 along with other model objects
    saveRDS(summary$sDataFrame, paste0(LocalIntermediateDir, "/num_col_stats.rds"))
    var_with_NA_mean <- round(summary$sDataFrame[summary$sDataFrame$MissingObs > 0,2])
    
  }
  if (Stage == "Prod") {
    
    # load summary statistics generated from development stage from local directory
    LocalModelDir <- file.path(LocalWorkDir, "model")
    summary_dev <- readRDS(paste(LocalModelDir,"/num_col_stats.rds", sep=""))
    var_with_NA_mean <- round(summary_dev$Mean[which(summary_dev$Name %in% var_with_NA)])
  }
  if (Stage == "Web") {
    
    # refer to summary statistics generated from development stage and loaded when publishing 
    # "model_obj" is defined in script "campaign_deployment" when publishing web servie
    # "model_obj" is a list containing all useful objects. We can directly refer to its elements when calling the published web service
    summary_dev <- model_obj$summary_dev
    var_with_NA_mean <- round(summary_dev$Mean[which(summary_dev$Name %in% var_with_NA)])
  }
  
  
  if(length(var_with_NA) == 0){
    
    print("No missing values: no treatment will be applied.")
    missing <- 0
    
  } else{
    
    # function to replace missing values with mean.
    Mean_Replace <- function(datalist) {
      data <- data.frame(datalist)
      for(i in 1:length(var_name)){
        na_id <- which(is.na(data[var_name[i]][,1]))
        data[na_id, var_name[i]] <- var_mean[i]
      }
      return(data)
    }
    
    # the main function to perform missing value replacement. it will be applied to each subset by rxExec function.
    replaceMissing <- function(partNum, colInfo, Mean_Replace, var_with_NA, var_with_NA_mean, HDFSIntermediateDir) {
      rxSetComputeContext("local")
      Campaign_Product_Market_Lead_txt <- RxTextData(file = file.path(HDFSIntermediateDir, "campaign_product_market_lead", paste0("campaign_product_market_lead", partNum, ".csv")),
                                                     colInfo = colInfo,
                                                     firstRowIsColNames = F,
                                                     fileSystem = RxHdfsFileSystem())
      
      CM_AD_Clean <- RxTextData(file.path(HDFSIntermediateDir, "cmadclean", paste0("cmadclean", partNum, ".csv")), 
                                firstRowIsColNames = F, fileSystem = RxHdfsFileSystem())
      
      rxDataStep(inData = Campaign_Product_Market_Lead_txt, 
                 outFile = CM_AD_Clean, 
                 overwrite = TRUE, 
                 transformFunc = Mean_Replace,
                 transformObjects = list(var_name = var_with_NA, var_mean = var_with_NA_mean))  
    }
    
    cmadclean_dir <- file.path(HDFSIntermediateDir, "cmadclean")
    #rxHadoopCommand(paste("fs -rm -r", cmadclean_dir))
    rxHadoopMakeDir(cmadclean_dir)
    
    rxOptions(numCoresToUse = -1)
    rxSetComputeContext('localpar')
    t1.2 <- system.time(
      replaceMissingResults <- rxExec(replaceMissing, partNum = rxElemArg(0:(numSplits-1)), colInfo, Mean_Replace, var_with_NA, var_with_NA_mean, HDFSIntermediateDir)
    )
    rxSetComputeContext('local')
  }
  
  # return the number of splits for later use
  return(list(numSplits = numSplits, CM_AD_Clean_colInfo = colInfo))
  
}