##########################################################################################################################################
## This R script will do the following:
## 1. Split CM_AD into a Training CM_AD_Train, and a Testing set CM_AD_Test.  
## 2. Train two models Random Forest (RF) and Gradient Boosting Trees (GBT) on CM_AD_train, and save them. 
## 3. Score RF & GBT on CM_AD_Test.
## 4. Select the best model based on AUC. 

## Input : Data set CM_AD
## Output: Saved random forest and a GBT models. One of them is chosen based on AUC. 

##########################################################################################################################################

## Packages, system info and Compute Context

##########################################################################################################################################

# Load revolution R library and data.table. 
library(RevoScaleR)

# File system
hdfs <- RxHdfsFileSystem()

# The default directory on local edge node
myShareDir <- paste( "/var/RevoShare", Sys.info()[["user"]],sep="/" ) 

# Compute Contexts
myHadoopCluster <- RxSpark()

##########################################################################################################################################

## Input: Point to HDFS with the data set for modeling

##########################################################################################################################################

CM_AD <- RxXdfData(file = "/CampaignManagement/CMADXdf",fileSystem = hdfs)

##########################################################################################################################################

##	Change character type into factor

##########################################################################################################################################
CM_AD_factors <-  RxXdfData(file = "/CampaignManagement/CMADfactorsXdf",fileSystem = hdfs)
rxFactors(inData = CM_AD, 
          outFile = CM_AD_factors, 
          overwrite = TRUE, 
          factorInfo = c(
            "Age",
            "Annual_Income_Bucket",
            "Credit_Score",
            "State",
            "Highest_Education",
            "Ethnicity",
            "Gender",
            "Marital_Status",
            "Channel",
            "Previous_Channel",
            "Time_Of_Day",
            "Day_Of_Week",
            "Campaign_Id",
            "Product_Id",
            "Product",
            "Term",
            "Payment_frequency",
            "Amt_on_Maturity_Bin",
            "Sub_Category",
            "Campaign_Drivers",
            "Campaign_Name",
            "Call_For_Action",
            "Tenure_Of_Campaign",
            "Conversion_Flag"
          )
)

##########################################################################################################################################

##	Split the data set into a training and a testing set 

##########################################################################################################################################
# randomly split the data into a training set and a testing set, with training/testing ratio 7:3.
# It creates a random variable, Split_Vector. For each unique Lead_Id, it is equal to 1 with proportion 0.7, and 0 otherwise. 

# create "Split_Vector" for indicating training and testing
CM_AD1 <- RxXdfData(file = "/CampaignManagement/CMAD1Xdf",fileSystem = hdfs, stringsAsFactors = TRUE)
rxSetComputeContext(myHadoopCluster)
rxDataStep(inData = CM_AD_factors, 
           outFile = CM_AD1, overwrite = TRUE,
           transforms = list(
             Split_Vector = rbinom(.rxNumRows, 1, 0.7)) # 0.7 can be set to any other number between (0,1]
)

# split into training and testing
CM_AD_Train <- RxXdfData(file = "/CampaignManagement/CMADTrainXdf",fileSystem = hdfs, stringsAsFactors = TRUE)
CM_AD_Test <- RxXdfData(file = "/CampaignManagement/CMADTestXdf",fileSystem = hdfs, stringsAsFactors = TRUE)
rxDataStep(inData = CM_AD1,
           outFile = CM_AD_Train,
           overwrite = TRUE,
           rowSelection = (Split_Vector == 1),
           varsToDrop = "Split_Vector"
)
rxDataStep(inData = CM_AD1,
           outFile = CM_AD_Test,
           overwrite = TRUE,
           rowSelection = (Split_Vector == 0),
           varsToDrop = "Split_Vector"
)

##########################################################################################################################################

##	Specify the variables to keep for the training 

##########################################################################################################################################

# Write the formula after removing variables not used in the modeling.
variables_all <- rxGetVarNames(CM_AD_Train)
variables_to_remove <- c("Lead_Id", "Phone_No", "Country", "Comm_Id", "Time_Stamp", "Category", "Launch_Date", "Focused_Geography")
training_variables <- variables_all[!(variables_all %in% c("Conversion_Flag", variables_to_remove))]
formula <- as.formula(paste("Conversion_Flag ~", paste(training_variables, collapse = "+")))

#########################################################################################################################################

##	Random Forest Training and saving the model to local edge node

##########################################################################################################################################

# Train the Random Forest.
forest_model <- rxDForest(formula = formula,
                          data = CM_AD_Train,
                          nTree = 40, 
                          cp = 0.05,
                          seed = 5,
                          method = "class",
                          scheduleOnce = TRUE, # true can speed up computation on small data set
                          computeOobError=-1 )

# save the fitted model to local edge node.
rxSetComputeContext('local')
saveRDS(forest_model, file = paste(myShareDir,"/forest_model.rds",sep=""))

# Set back the compute context to Spark.
rxSetComputeContext(myHadoopCluster)

##########################################################################################################################################

##	Gradient Boosted Trees Training and saving the model to local edge node

##########################################################################################################################################

# Train the GBT.
btree_model <- rxBTrees(formula = formula,
                        data = CM_AD_Train,
                        learningRate = 0.0005,
                        minSplit = 100,
                        minBucket = 33,
                        cp = 0.05,
                        nTree = 40,
                        seed = 5,
                        lossFunction = "multinomial",
                        scheduleOnce = TRUE,
                        importance = FALSE)

# save the fitted model to local edge node.
rxSetComputeContext('local')
saveRDS(btree_model, file = paste(myShareDir,"/btree_model.rds",sep=""))

# Set back the compute context to Spark.
rxSetComputeContext(myHadoopCluster)

##########################################################################################################################################

##	Binary classification model evaluation metrics

##########################################################################################################################################

# Write a function that computes the AUC, Accuracy, Precision, Recall, and F-Score.
evaluate_model <- function(observed, predicted_probability, threshold) { 
  
  # Given the observed labels and the predicted probability, plot the ROC curve and determine the AUC.
  data <- data.frame(observed, predicted_probability)
  data$observed <- as.numeric(as.character(data$observed))
  rxRocCurve(actualVarName = "observed", predVarNames = "predicted_probability", data = data, numBreaks = 1000)
  ROC <- rxRoc(actualVarName = "observed", predVarNames = "predicted_probability", data = data, numBreaks = 1000)
  auc <- rxAuc(ROC)
  
  # Given the predicted probability and the threshold, determine the binary prediction.
  predicted <- ifelse(predicted_probability > threshold, 1, 0) 
  predicted <- factor(predicted, levels = c(0, 1)) 
  
  # Build the corresponding Confusion Matrix, then compute the Accuracy, Precision, Recall, and F-Score.
  confusion <- table(observed, predicted) 
  print(confusion) 
  tp <- confusion[1, 1] 
  fn <- confusion[1, 2] 
  fp <- confusion[2, 1] 
  tn <- confusion[2, 2] 
  accuracy <- (tp + tn) / (tp + fn + fp + tn) 
  precision <- tp / (tp + fp) 
  recall <- tp / (tp + fn) 
  fscore <- 2 * (precision * recall) / (precision + recall) 
  
  # Return the computed metrics.
  metrics <- list("Accuracy" = accuracy, 
                  "Precision" = precision, 
                  "Recall" = recall, 
                  "F-Score" = fscore,
                  "AUC" = auc) 
  return(metrics) 
} 


##########################################################################################################################################

##	Random Forest Scoring

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_RF <- RxXdfData(file = "/CampaignManagement/PredictionTableRFXdf",fileSystem = hdfs, stringsAsFactors = TRUE)
rxPredict(forest_model, data = CM_AD_Test, outData = Prediction_Table_RF, overwrite = TRUE, type = "prob",
          extraVarsToWrite = c("Conversion_Flag"))

rxSetComputeContext('local')
Prediction_RF <- rxImport(inData = Prediction_Table_RF, stringsAsFactors = T, outFile = NULL)
observed <- Prediction_RF$Conversion_Flag

# Assign the decision threshold to the median of the predicted probabilities.
threshold <- median(Prediction_RF$`1_prob`)

# Compute the performance metrics of the model. The Compute Context should be set to local. 
Metrics_RF <- evaluate_model(observed = observed, predicted_probability = Prediction_RF$`1_prob`,threshold = threshold)

# Set back the compute context to Spark.
rxSetComputeContext(myHadoopCluster)

##########################################################################################################################################

##	Gradient Boosted Trees Scoring 

##########################################################################################################################################
# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_GBT <- RxXdfData(file = "/CampaignManagement/PredictionTableGBTXdf",fileSystem = hdfs, stringsAsFactors = TRUE)
rxPredict(btree_model,data = CM_AD_Test, outData = Prediction_Table_GBT, overwrite = T, type="prob",
          extraVarsToWrite = c("Conversion_Flag"))

rxSetComputeContext('local')
Prediction_GBT <- rxImport(inData = Prediction_Table_GBT, stringsAsFactors = T, outFile = NULL)
observed <- Prediction_GBT$Conversion_Flag

# Assign the decision threshold to the median of the predicted probabilities.
threshold <- median(Prediction_GBT$`1_prob`)

# Compute the performance metrics of the model. The Compute Context should be set to local.
Metrics_GBT <- evaluate_model(observed = observed, predicted_probability = Prediction_GBT$`1_prob`,threshold = threshold)

##########################################################################################################################################

## Select the best model based on AUC

##########################################################################################################################################

best_model <- ifelse(Metrics_RF$AUC >= Metrics_GBT$AUC, "random_forest", "GBT")
