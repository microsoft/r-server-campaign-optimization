##########################################################################################################################################
## This R script will do the following:
## 1. Split CM_AD_Features into a Training CM_AD_Train, and a Testing set CM_AD_Test.  
## 2. Train Random Forest (RF) and Logistic Regression on CM_AD_Train, and save them as .rds file on local edge node 
## 3. Score RF and Logistic on CM_AD_Test.
## 4. Select the best model based on AUC. 

## Input: 1. Working directories on edge node and HDFS (assume the data, CM_AD_Features, for this step is already created there by step2)
##        2. Column names of CM_AD_Features returned from step2
## Output: 1. Random forest and Logistic models saved to local edge node. 
##         2. The name of the best model selected based on AUC 

##########################################################################################################################################

## Function of training and evaluation:
# LocalWorkDir: the working directory on local edge node.
# HDFSWorkDir the working directory on HDFS
# CM_AD_Features_names: Column names of CM_AD_Features

training_evaluation <- function(LocalWorkDir,
                                HDFSWorkDir,
                                CM_AD_Features_names)
{ 
  
  print("Start Step3: training and evaluation...")
  
  # make folders storing intermediate results
  LocalIntermediateDir <- file.path(LocalWorkDir, "temp")
  HDFSIntermediateDir <- file.path(HDFSWorkDir,"temp")
  
  # make folders store models and training xdf file
  myLocalTrainDir <- file.path(LocalWorkDir, "model")
  HDFSTrainDir <- file.path(HDFSWorkDir,"model")
  
  ##########################################################################################################################################
  
  ## The block below will identify factor columns by:
  ## 1. Create a vector containing names of all factor columns
  ## 2. Create column Information based on the factor information in 1.
  
  ##########################################################################################################################################
  
  print("making factor info for CM_AD_Features...")
  # names of factor columns
  factorCols = c(
    "Age",
    "Annual_Income_Bucket",
    "Credit_Score",
    "State",
    "Highest_Education",
    "Ethnicity",
    "Gender",
    "Marital_Status",
    "Channel",
    "Time_Of_Day",
    "Day_Of_Week",
    "Campaign_Id",
    "Product_Id",
    "Product",
    "Term",
    "Payment_frequency",
    "Sub_Category",
    "Campaign_Drivers",
    "Campaign_Name",
    "Call_For_Action",
    "Tenure_Of_Campaign",
    "Conversion_Flag"
  )
  
  CM_AD_colInfo <- mapply(function(i, colname){
    if (colname %in% factorCols) {
      list(index=i, newName = colname, type = "factor")
    } else {
      list(index=i, newName = colname)
    }
  }, 1:length(CM_AD_Features_names), CM_AD_Features_names, SIMPLIFY = F)
  
  CM_AD_Features <- RxTextData(file = file.path(HDFSIntermediateDir, "CMADFeatures"), fileSystem = RxHdfsFileSystem(), colInfo = CM_AD_colInfo, firstRowIsColNames = F)
  
  ##########################################################################################################################################
  
  ##	The block below will change character type into factor
  
  ##########################################################################################################################################
  
  CM_AD_factorized <-  RxXdfData(file = paste(HDFSIntermediateDir, "/CMADfactorsXdf", sep=""),fileSystem = RxHdfsFileSystem())
  
  t3.1 <- system.time(
    rxDataStep(inData = CM_AD_Features, outFile = CM_AD_factorized, overwrite = T)
  )
  
  colInfoFull <- rxCreateColInfo(CM_AD_factorized)
  
  # save the factorized column information before splitting
  # this column information will be used later. the global factor column info is important since in testing set it may not contain full factor info
  saveRDS(colInfoFull, file.path(LocalIntermediateDir, "CM_AD_factorized_colInfoFull.rds"))
  
  ##########################################################################################################################################
  
  ## The block below will split data into training and testing set by:
  ## 1. Create a new column "Split_Vector" to indicate training and testing set
  ## 2. Split data based on "Split_Vector" column and drop "Split_Vector" after splitting
  
  ##########################################################################################################################################
  # randomly split the data into a training set and a testing set, with training/testing ratio 7:3.
  # It creates a random variable, Split_Vector, with values uniformly distributed between 0 and 1. 
  
  # sort the label if necessary
  # sort the label to ensure "0" is coded as "0" during training
  CM_AD1 <- RxXdfData(file = paste(HDFSIntermediateDir, "/CMAD1Xdf", sep=""),fileSystem = RxHdfsFileSystem())
  if(rxGetVarInfo(CM_AD_factorized)$Conversion_Flag$levels[1] == "1"){
    print("Sorting labels...")
    rxFactors(inData = CM_AD_factorized, factorInfo = c("Conversion_Flag"), sortLevels = TRUE, outFile = CM_AD1, overwrite = TRUE)
  } else {
    print("No need to sort labels...")
    rxDataStep(inData = CM_AD_factorized, outFile = CM_AD1, reportProgress = 0, overwrite = TRUE)
  }
  
  # create "Split_Vector" for indicating training and testing
  print("Splitting into training and testing set...")
  CM_AD2 <- RxXdfData(file = paste(HDFSIntermediateDir, "/CMAD2Xdf", sep=""),fileSystem = RxHdfsFileSystem())
  
  t3.2 <- system.time(
    rxDataStep(inData = CM_AD1, 
               outFile = CM_AD2, overwrite = TRUE,
               transforms = list(
                 Split_Vector = runif(.rxNumRows)) 
    )
  )
  
  # split into training and testing
  CM_AD_Train <- RxXdfData(file = paste(HDFSIntermediateDir, "/CMADTrainXdf", sep=""),fileSystem = RxHdfsFileSystem())
  CM_AD_Test <- RxXdfData(file = paste(HDFSIntermediateDir, "/CMADTestXdf", sep=""),fileSystem = RxHdfsFileSystem())
  t3.3 <- system.time(
    rxDataStep(inData = CM_AD2,
               outFile = CM_AD_Train,
               overwrite = TRUE,
               rowSelection = (Split_Vector < 0.7), # 0.7 can be set to any other number between (0,1]
               varsToDrop = "Split_Vector"
    )
  )
  
  t3.4 <- system.time(
    rxDataStep(inData = CM_AD2,
               outFile = CM_AD_Test,
               overwrite = TRUE,
               rowSelection = (Split_Vector >= 0.7), # 0.7 can be set to any other number between (0,1]
               varsToDrop = "Split_Vector"
    )
  )
  
  ##########################################################################################################################################
  
  ##	The block below will make the formula used for the training
  
  ##########################################################################################################################################
  
  # Write the formula after removing variables not used in the modeling.
  variables_all <- rxGetVarNames(CM_AD_Train)
  variables_to_remove <- c("Lead_Id", "Phone_No", "Country", "Comm_Id", "Time_Stamp", "Category", "Launch_Date", "Focused_Geography")
  training_variables <- variables_all[!(variables_all %in% c("Conversion_Flag", variables_to_remove))]
  formula <- as.formula(paste("Conversion_Flag ~", paste(training_variables, collapse = "+")))
  
  #########################################################################################################################################
  
  ## The block below will do the following:
  ## 1. Determine the training parameter automatically based the number of rows in training set
  ## 2. Train Random Forest model with 40 trees
  ## 3. Save the trained RF model on local edge node
  
  ##########################################################################################################################################
  
  # Train the Random Forest.
  # If number of rows >= 1Mn, scheduleOnce=FALSE, nTree = 40 and commnent out timesToRun
  print("Training RF model...")
  n_rows <- rxGetInfo(CM_AD_Train)$numRows
  t3.5 <- system.time(
    if(n_rows <= 1000000){
      forest_model <- rxDForest(formula = formula,
                                data = CM_AD_Train,
                                nTree = 2, 
                                timesToRun = 20, # equal to ntree = 40
                                seed = 5,
                                method = "class",
                                scheduleOnce = TRUE, # true can speed up computation on small data set
                                computeOobError=-1 )
    } else {
      forest_model <- rxDForest(formula = formula,
                                data = CM_AD_Train,
                                nTree = 40, 
                                seed = 5,
                                method = "class",
                                scheduleOnce = FALSE, 
                                computeOobError=-1 )
    }
    
  )
  
  # save the fitted model to local edge node.
  saveRDS(forest_model, file = paste(LocalIntermediateDir,"/forest_model.rds",sep=""))
  
  ##########################################################################################################################################
  
  ## The following block will do the following:
  ## 1. Train a logisitc regression model
  ## 2. Save the trained logistic regression model on local edge node
  
  ##########################################################################################################################################
  
  # Train the logistic regression model.
  # If you want to try GBT model, change "TRUE" to "FALSE" below
  if(TRUE){
    print("Training Logistic model...")
    t3.6 <- system.time(
      logistic_model <- rxLogit(formula = formula,
                                data = CM_AD_Train,
                                reportProgress = 0)
    )
  } else{
    # Try GBT model.
    print("Training GBT model...")
    btree_model <- rxBTrees(formula = formula,
                            data = CM_AD_Train,
                            learningRate = 0.05,
                            minSplit = 10,
                            minBucket = 5,
                            cp = 0.0005,
                            nTree = 40,
                            seed = 5,
                            lossFunction = "multinomial")
  }
  
  saveRDS(logistic_model, file = paste(LocalIntermediateDir,"/logistic_model.rds",sep=""))
  
  ##########################################################################################################################################
  
  ## The block below will do the following:
  ## 1. Scoring the test set on RF model and output the predicion table
  ## 2. Calculate AUC 
  ## 3. Plot the ROC curve
  
  ##########################################################################################################################################
  
  # Make Predictions. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
  print("Predicting on RF model...")
  Prediction_Table_RF <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableRFXdf", sep=""),fileSystem = RxHdfsFileSystem())
  t3.7 <- system.time(
    rxPredict(forest_model, data = CM_AD_Test, outData = Prediction_Table_RF, overwrite = TRUE, type = "prob",
              extraVarsToWrite = c("Conversion_Flag"))
  )
  # change Conversion_Flag to numeric
  Prediction_Table_RF_New <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableRFNewXdf", sep=""),fileSystem = RxHdfsFileSystem())
  t3.8 <- system.time(
    rxDataStep(inData = Prediction_Table_RF,
               outFile = Prediction_Table_RF_New,
               overwrite = TRUE,
               transforms = list(observed = as.numeric(as.character(Conversion_Flag))))
  )
  
  # evaluate
  # set compute context to local as rxRoc doesn't work under spark cc
  rxSetComputeContext('local')
  t3.9 <- system.time(
    ROC_RF <- rxRoc(actualVarName = "observed", predVarNames = "1_prob", data = Prediction_Table_RF_New, numBreaks = 1000)
  )
  AUC_RF <- rxAuc(ROC_RF)
  
  # plot
  rxRocCurve(actualVarName = "observed", predVarNames = "1_prob", data = Prediction_Table_RF_New, numBreaks = 1000, title = "ROC Curve for Random Forest")
  
  ##########################################################################################################################################
  
  ## The block below will do the following:
  ## 1. Scoring the test set on logistic model and output the predicion table
  ## 2. Calculate AUC 
  ## 3. Plot the ROC curve
  
  ##########################################################################################################################################
  # Make Predictions. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
  print("Predicting on Logistic model...")
  Prediction_Table_Logit <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableLogitXdf", sep=""),fileSystem = RxHdfsFileSystem())
  t3.10 <- system.time(
    rxPredict(logistic_model,data = CM_AD_Test, outData = Prediction_Table_Logit, overwrite = T, type="response",
              extraVarsToWrite = c("Conversion_Flag"))
  )
  # change Conversion_Flag to numeric
  Prediction_Table_Logit_New <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableLogitNewXdf", sep=""),fileSystem = RxHdfsFileSystem())
  t3.11 <- system.time(
    rxDataStep(inData = Prediction_Table_Logit,
               outFile = Prediction_Table_Logit_New,
               overwrite = TRUE,
               transforms = list(observed = as.numeric(as.character(Conversion_Flag))))
  )
  
  # evaluate
  t3.12 <- system.time(
    ROC_Logit <- rxRoc(actualVarName = "observed", predVarNames = "Conversion_Flag_Pred", data = Prediction_Table_Logit_New, numBreaks = 1000)
  )
  AUC_Logit <- rxAuc(ROC_Logit)
  
  # plot
  rxRocCurve(actualVarName = "observed", predVarNames = "Conversion_Flag_Pred", data = Prediction_Table_Logit_New, numBreaks = 1000, title = "ROC Curve for Logistic Regression")
  
  ##########################################################################################################################################
  
  ## The block below will select the best model based on AUC
  
  ##########################################################################################################################################
  
  print("Select the best model...")
  best_model_name <- ifelse(AUC_RF >= AUC_Logit, "random_forest", "Logistic")
  saveRDS(best_model_name, file = file.path(LocalIntermediateDir, "best_model_name.rds"))
  
  # clean up/remove folders storing trained model/modelInfo and make new folders
  if(dir.exists(myLocalTrainDir)){
    system(paste("rm -rf ",myLocalTrainDir, sep="")) # remove the directory if exists
    system(paste("mkdir -p -m 777 ", myLocalTrainDir, sep="")) # create a new directory
  } else {
    system(paste("mkdir -p -m 777 ", myLocalTrainDir, sep="")) # make new directory if doesn't exist
  }
  
  # copy trained model and model info to the folder above. These info will be used for scoring in step4
  system(paste("cp ", LocalIntermediateDir, "/*.rds ", myLocalTrainDir, sep = ""))
  
  # set compute context back to spark
  rxSparkConnect(reset = F)
  
  #rbind(t3.1, t3.2, t3.3, t3.4, t3.5, t3.6, t3.7, t3.8, t3.9, t3.10, t3.11, t3.12)
  
}
