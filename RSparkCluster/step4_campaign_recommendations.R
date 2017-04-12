##########################################################################################################################################
## This R script will determine recommendations for each Lead_Id
## The goal is to determine, for each Lead_Id, the best combination of Day_of_Week, Channel, Time_Of_Day to target him.
## The best combination will be the one that was assigned the highest probability of conversion with the best model selected by scoring.

## This is done by doing the following: 
## 1. Create a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day. 
## 2. Compute the predicted probabilities for each Lead_Id, for each combination of Day_Of_Week, Channel, Time_Of_Day, using best_model.
## 3. For each Lead_Id, choose the combination of Day_Of_Week, Channel, Time_Of_Day that has the highest conversion probability.

## Input:  1. Working directories on edge node and HDFS.
##         2. number of splits.
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: Recommended Day_Of_Week, Channel and Time_Of_Day for each Lead_Id, to get a higher conversion rate.  

## assume the following four object from training are stored under myLocalTrainDir: 
## 1) best_model_name.rds 2) logistic_model.rds 3) forest_model.rds 4) CM_AD_factorized_colInfoFull.rds (from training) 

##########################################################################################################################################

## Function of score and recommendation:
# LocalWorkDir: the working directory on local edge node.
# HDFSWorkDir the working directory on HDFS
# numSplits: number of splits
# Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service

score_recommendation <- function(LocalWorkDir,
                                 HDFSWorkDir, 
                                 numSplits,
                                 Stage)
{ 
  print("Start step4: recommendations....")
  # load library
  library(RevoScaleR)
  # spark cc object
  myHadoopCluster <- RxSpark()
  
  # specify folders storing intermediate results
  LocalIntermediateDir <- file.path(LocalWorkDir, "temp")
  HDFSIntermediateDir <- file.path(HDFSWorkDir,"temp")
  
  # specify the folder store models and training xdf file
  myLocalTrainDir <- file.path(LocalWorkDir, "model")
  
  # the block below will do:
  # 1. Import the best model name 
  # 2. Import the best model based on the best model name
  # 3. Import factor column info
  print("Importing the best model and info of factor columns...")
  rxSetComputeContext('local')
  
  if(Stage == "Web"){
    # "model_obj" is defined in script "campaign_deployment" when publishing web servie
    # "model_obj" is a list containing all useful objects. We can directly refer to its elements when calling the published web service
    best_model_name <- model_obj$best_model_name
    
    if(best_model_name == "random_forest"){
      
      import_model <- model_obj$forest_model
      
    } else if (best_model_name == "Logistic"){
      
      import_model <- model_obj$logistic_model
      
    } else {
      
      stop("Unrecognized value for best_model: ", best_model_name)
      
    }
    
    colInfoFull0 <- model_obj$CM_AD_factorized_colInfoFull
    
  } else {
    
    best_model_name <- readRDS(file = file.path(myLocalTrainDir, "best_model_name.rds"))
    
    if(best_model_name == "random_forest"){
      
      import_model <- readRDS(file=paste(myLocalTrainDir,"/forest_model.rds",sep=""))
      
    } else if (best_model_name == "Logistic"){
      
      import_model <- readRDS(file=paste(myLocalTrainDir,"/logistic_model.rds",sep=""))
      
    } else {
      
      stop("Unrecognized value for best_model: ", best_model_name)
      
    }
    
    colInfoFull0 <- readRDS(file.path(myLocalTrainDir, "CM_AD_factorized_colInfoFull.rds"))
  }
  
  best_model <- import_model
  
  colInfoFull <- mapply(function(colInfoElement, colname){
    append(colInfoElement, list(newName = colname))
  }, colInfoFull0, names(colInfoFull0), SIMPLIFY = F)
  
  defaultNames <- lapply(1:length(colInfoFull0), function(i){paste0("V", i)})
  
  names(colInfoFull) <- defaultNames
  
  #####################################################################################################################################
  
  ## The main function will do the following to each subset:
  ## 1. Create a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day. 
  ## 2. Compute the predicted probabilities for each Lead_Id, for each combination of Day_Of_Week, Channel, Time_Of_Day, using best_model.
  ## 3. For each Lead_Id, choose the combination of Day_Of_Week, Channel, Time_Of_Day that has the highest conversion probability.
  
  #####################################################################################################################################
  
  maxConversion <- function(partNum, HDFSIntermediateDir, best_model, best_model_name, colInfoFull, colInfoFull0) {
    myTempShareDir <- file.path(tempdir(), paste0("part", partNum))
    dir.create(myTempShareDir)
    CM_AD <- RxTextData(file = file.path(HDFSIntermediateDir, paste0("CMADFeatures/CMADFeaturespart", partNum, ".csv")),fileSystem = RxHdfsFileSystem(),
                        colInfo = colInfoFull, 
                        firstRowIsColNames = F)
    
    ###############################################################################################################################
    
    ## The block below will do the following:                                                             
    ## 1. Create a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day          
    ## 2. Export to local edge node and make columns as factors                                           
    ## 3. Full merge with original data set (original Day_Of_Week, Channel, Time_Of_Day dropped)          
    
    ###############################################################################################################################
    print("Creating a full data table with  all the unique combinations of Day_Of_Week, Channel, Time_Of_Day...")
    Day_of_Week_unique <- data.frame(seq(1, 7))
    Channel_unique <-data.frame(c("Email", "Cold Calling", "SMS"))
    Time_Of_Day_unique <- data.frame(c("Morning", "Afternoon", "Evening"))
    Unique_Combos <- merge(merge(Day_of_Week_unique, Channel_unique), Time_Of_Day_unique)
    colnames(Unique_Combos) <- c("Day_Of_Week", "Channel", "Time_Of_Day")
    Unique_Combos$Day_Of_Week <- as.factor(Unique_Combos$Day_Of_Week)
    
    # create a key used for later merge
    Unique_Combos$key <- rep(1,nrow(Unique_Combos))
    
    # export to local edge node as xdf and drop Channel, Time_Of_Day and Day_Of_Week Variables
    rxSetComputeContext('local') # write a dataframe to native file system requires compute context set as local
    Unique_Combos_Xdf <- RxXdfData(paste(myTempShareDir,"/uniquecombosxdf",sep=""))
    t4.1 <- system.time(
      rxDataStep(inData = Unique_Combos, 
                 outFile = Unique_Combos_Xdf, 
                 overwrite = TRUE
      )
    )
    
    # making factors, preserve the order of factors
    Unique_Combos_factor_Xdf <- RxXdfData(paste(myTempShareDir,"/uniquecombosfactorxdf",sep=""))
    # get the factor info of the three new created variables from trainining
    
    channel_newLevels <- colInfoFull0$Channel$levels
    timeofday_newLevels <- colInfoFull0$Time_Of_Day$levels
    dayofweek_newLevels <- colInfoFull0$Day_Of_Week$levels
    
    rxFactors(inData = Unique_Combos_Xdf, 
              outFile = Unique_Combos_factor_Xdf, 
              overwrite = TRUE,
              factorInfo = list(Channel = list(newLevels = channel_newLevels),
                                Time_Of_Day = list(newLevels = timeofday_newLevels),
                                Day_Of_Week = list(newLevels = dayofweek_newLevels))
    )
    
    # We create a table that has, for each Lead_Id and its corresponding variables (except Day_of_Week, Channel, Time_Of_Day),
    # One row for each possible combination of Day_of_Week, Channel and Time_Of_Day.
    # create a key for CM_AD and export to local edge node so that rxMerge can be applied
    CM_AD_local_xdf <- RxXdfData(paste(myTempShareDir,"/cmadlocalxdf",sep=""))
    t4.2 <- system.time(
      rxDataStep(inData = CM_AD, 
                 outFile = CM_AD_local_xdf, 
                 transforms = list(key = rep(1, .rxNumRows)), 
                 overwrite = TRUE
      )
    )
    
    # change names of Channel, Time_Of_Day, and Day_Of_Week
    nm <- rxGetVarInfo(CM_AD_local_xdf)
    id_channel <- which(names(nm) == "Channel")
    id_time_of_day <- which(names(nm) == "Time_Of_Day")
    id_day_of_week <- which(names(nm) == "Day_Of_Week")
    varInfo <- list(list(position = id_channel, 
                         newName = "CM_AD_Channel"),
                    list(position = id_time_of_day, 
                         newName = "CM_AD_Time_Of_Day"),
                    list(position = id_day_of_week, 
                         newName = "CM_AD_Day_Of_Week")
    )
    
    rxSetVarInfo(varInfo, CM_AD_local_xdf)
    
    # create the table to be scored by full merge
    AD_full_merged_xdf <- RxXdfData(paste(myTempShareDir,"/adfullmergedxdf",sep=""))
    t4.3 <- system.time(
      rxMerge(inData1 = CM_AD_local_xdf, 
              inData2 = Unique_Combos_factor_Xdf, 
              matchVars = "key", 
              outFile = AD_full_merged_xdf, 
              overwrite = TRUE, 
              reportProgress = 0
      )
    )
    
    # drop "key"
    AD_full_merged2_xdf <- RxXdfData(paste(myTempShareDir,"/adfullmerged2xdf",sep=""))
    rxDataStep(inData = AD_full_merged_xdf, 
               outFile = AD_full_merged2_xdf, transforms = list(key = NULL),
               reportProgress = 0,
               overwrite = TRUE)
    
    ##########################################################################################################################################
    
    ## The block below will compute the predicted probabilities for each Lead_Id, for each combination of Day_of_Week, Channel, Time_Of_Day, using best_model
    
    ##########################################################################################################################################
    
    # Score the full data by using the best model. Keep Lead_Id in the prediction table to be able to do an inner join with the full table.
    print("Scoring the data with all the unique combinations of Day_Of_Week, Channel, Time_Of_Day...")
    score <- RxXdfData(file = paste(myTempShareDir,"/scoreXdf",sep=""))
    # specify the extra variables to be written to scored data set
    extra_vars2write <- c("Lead_Id", 
                          "Age",
                          "Annual_Income_Bucket",
                          "Credit_Score",
                          "Product",
                          "Campaign_Name",
                          "State",
                          "CM_AD_Day_Of_Week",
                          "CM_AD_Time_Of_Day",
                          "CM_AD_Channel",
                          "Conversion_Flag",
                          "Day_Of_Week",
                          "Time_Of_Day",
                          "Channel")
    rxSetComputeContext('local')
    if(best_model_name == "random_forest"){
      t4.4 <- system.time(
        rxPredict(best_model, data = AD_full_merged2_xdf, outData = score, overwrite = TRUE, type = "prob",
                  extraVarsToWrite = extra_vars2write, 
                  reportProgress = 0)
      )
    } else {
      t4.4 <- system.time(
        rxPredict(best_model, data = AD_full_merged2_xdf, outData = score, overwrite = TRUE, type = "response",
                  extraVarsToWrite = extra_vars2write, 
                  reportProgress = 0
        )
      )
    }
    
    ##########################################################################################################################################
    
    ## The block below will select the latest communicated (with max comm_id value) records for each Lead_Id by:
    ## 1. Calculate the max probability (scores) for each Lead Id and save it as a xdf table
    ## 2. Add the max probability as a new column by left join original table with above table
    ## 3. For each Lead_Id, choose a combination of Day_of_Week, Channel, and Time_Of_Day that has the highest conversion probability    
    
    ##########################################################################################################################################
    print("Calculating the max probability for each Lead Id...")
    # change variable names
    nm <- rxGetVarInfo(score)
    id_prob1 <- which(names(nm) == ifelse(best_model_name == "random_forest", "1_prob", "Conversion_Flag_Pred"))
    id_day_of_week <- which(names(nm) == "Day_Of_Week")
    id_time_of_day <- which(names(nm) == "Time_Of_Day")
    id_channel <- which(names(nm) == "Channel")
    varInfo <- list(list(position = id_prob1, newName='prob1'),
                    list(position = id_day_of_week, newName = "Recommended_Day"),
                    list(position = id_time_of_day, newName = "Recommended_Time"),
                    list(position = id_channel, newName = "Recommended_Channel"))
    rxSetVarInfo(varInfo, score)
    
    nm <- rxGetVarInfo(score)
    id_cmad_day_of_week <- which(names(nm) == "CM_AD_Day_Of_Week")
    id_cmad_time_of_day <- which(names(nm) == "CM_AD_Time_Of_Day")
    id_cmad_channel <- which(names(nm) == "CM_AD_Channel")
    varInfo <- list(list(position = id_cmad_day_of_week, newName = "Day_Of_Week"),
                    list(position = id_cmad_time_of_day, newName = "Time_Of_Day"),
                    list(position = id_cmad_channel, newName = "Channel"))
    rxSetVarInfo(varInfo, score)
    
    # calculate the max probability of each Lead_Id using package dyplyr
    library(dplyr)
    scoreDF <- rxDataStep(score, maxRowsByCols = 1e9, reportProgress = 0, overwrite = T) # make sure the data does not exceed maxRowsByCols
    
    t4.5 <- system.time(
      max_prob_tbl <- scoreDF %>% 
        select(Lead_Id, prob1) %>%
        group_by(Lead_Id) %>%
        summarise(max_prob = max(prob1))
    )
    max_prob_tbl <- as.data.frame(max_prob_tbl)
    
    # save max_prob_table as xdf file
    max_prob_tbl_xdf<- RxXdfData(file = paste(myTempShareDir,"/maxprobtblxdf",sep=""))
    t4.6 <- system.time(
      rxDataStep(inData = max_prob_tbl, 
                 outFile = max_prob_tbl_xdf, 
                 overwrite = TRUE, 
                 transforms = list(Lead_Id = as.character(Lead_Id))
      )
    )
    
    # add max probability as a new column
    reco_merge_xdf <- RxXdfData(file = paste(myTempShareDir,"/recomergexdf",sep=""))
    t4.7 <- system.time(
      rxMerge(inData1 = score, 
              inData2 = max_prob_tbl_xdf, 
              outFile = reco_merge_xdf, 
              matchVars = "Lead_Id", 
              type="left", 
              overwrite = TRUE, 
              reportProgress = 0)
    )
    
    # pick the row with max probability for each Lead_Id 
    reco_merge1_xdf <- RxXdfData(file = paste(myTempShareDir,"/recomerge1xdf",sep=""))
    t4.8 <- system.time(
      rxDataStep(inData = reco_merge_xdf, 
                 outFile = reco_merge1_xdf, 
                 rowSelection = (max_prob == prob1),
                 overwrite = TRUE,
                 transforms = list(Conversion_Flag = as.numeric(as.character(Conversion_Flag))),
                 reportProgress = 0)
    )
    
    # drop useless columns and save the final recommendation
    reco_merge_final_txt <- RxTextData(file.path(HDFSIntermediateDir, paste0("recomergefinal", partNum, ".csv")), fileSystem = RxHdfsFileSystem())
    if(best_model_name == "random_forest"){
      rxDataStep(inData = reco_merge1_xdf,
                 outFile = reco_merge_final_txt,
                 varsToDrop = c("max_prob", "0_prob"),
                 overwrite = T,
                 reportProgress = 0)
    } else {
      rxDataStep(inData = reco_merge1_xdf,
                 outFile = reco_merge_final_txt,
                 varsToDrop = c("max_prob"),
                 overwrite = T,
                 reportProgress = 0)
    }
    
    
    
    system(paste("rm -rf", myTempShareDir))
    
    timings <- rbind(t4.1, t4.2, t4.3, t4.4, t4.5, t4.6, t4.7, t4.8)[, "elapsed"]
    memUsed <- gc()
    returnList4 <- list(timings = timings, memUsed = memUsed, reco_merge_final_txt = reco_merge_final_txt)
    return(returnList4)
    
  } # end of maxConversion function
  
  # set compute context to spark
  rxSetComputeContext(myHadoopCluster)
  ## Invoke the scoring in parallel by rxExec function
  t4.9 <- system.time(
    returnList4 <- rxExec(maxConversion, partNum = rxElemArg(0:(numSplits-1)), HDFSIntermediateDir, best_model, best_model_name, colInfoFull, colInfoFull0)
  )
  
  rxSetComputeContext("local")
  
}