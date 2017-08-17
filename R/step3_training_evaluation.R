##########################################################################################################################################
## This R script will do the following:
## 1. Split CM_AD into a Training CM_AD_Train, and a Testing set CM_AD_Test.  
## 2. Train Random Forest (RF) and Gradient Boosting Trees (GBT) on CM_AD_Train, and save them to SQL. 
## 3. Score RF and GBT on CM_AD_Test.
## 4. Select the best model based on AUC. 

## Input : Data set CM_AD
## Output: Random forest and GBT models saved to SQL. One of them is chosen based on AUC. 

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load revolution R library. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the compute context to Local for splitting. It will be changed to sql when appropriate.
rxSetComputeContext(local)


##########################################################################################################################################

## Function to get the top n rows of a table stored on SQL Server.
## You can execute this function at any time during  your progress by removing the comment "#", and inputting:
##  - the table name.
##  - the number of rows you want to display.

##########################################################################################################################################

display_head <- function(table_name, n_rows){
  table_sql <- RxSqlServerData(sqlQuery = sprintf("SELECT TOP(%s) * FROM %s", n_rows, table_name), connectionString = connection_string)
  table <- rxImport(table_sql)
  print(table)
}

# table_name <- "insert_table_name"
# n_rows <- 10
# display_head(table_name, n_rows)


##########################################################################################################################################

## Input: Point to the SQL table with the data set for modeling

##########################################################################################################################################

CM_AD <- RxSqlServerData(table = "CM_AD", connectionString = connection_string, stringsAsFactors = T)


##########################################################################################################################################

##	Specify the type of the features before the training

##########################################################################################################################################

column_info <- rxCreateColInfo(CM_AD)


##########################################################################################################################################

##	Split the data set into a training and a testing set 

##########################################################################################################################################

# Randomly split the data into a training set and a testing set, with a splitting % p.
# p % goes to the training set, and the rest goes to the testing set. Default is 70%. 

p <- "70" 

## Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

## Create the Train_Id table containing Lead_Id of training set. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Train_Id;", sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf(
  "SELECT Lead_Id
   INTO Train_Id
   FROM CM_AD
   WHERE ABS(CAST(BINARY_CHECKSUM(Lead_ID, NEWID()) as int)) %s < %s ;"
  ,"% 100", p ))

## Point to the training set. It will be created on the fly when training models. 
CM_AD_Train <- RxSqlServerData(  
  sqlQuery = "SELECT *   
              FROM CM_AD 
              WHERE Lead_Id IN (SELECT Lead_Id from Train_Id)",
  connectionString = connection_string, colInfo = column_info)

## Point to the testing set. It will be created on the fly when testing models. 
CM_AD_Test <- RxSqlServerData(  
  sqlQuery = "SELECT *   
              FROM CM_AD 
              WHERE Lead_Id NOT IN (SELECT Lead_Id from Train_Id)",
  connectionString = connection_string, colInfo = column_info)


##########################################################################################################################################

##	Specify the variables to keep for the training 

##########################################################################################################################################

# Write the formula after removing variables not used in the modeling.
variables_all <- rxGetVarNames(CM_AD_Train)
variables_to_remove <- c("Lead_Id", "Phone_No", "Country", "Comm_Id", "Time_Stamp", "Category", "Launch_Date", "Focused_Geography",
                         "Call_For_Action", "Product", "Campaign_Name")
traning_variables <- variables_all[!(variables_all %in% c("Conversion_Flag", variables_to_remove))]
formula <- as.formula(paste("Conversion_Flag ~", paste(traning_variables, collapse = "+")))


##########################################################################################################################################

##	Random Forest Training and saving the model to SQL

##########################################################################################################################################

# Set the compute context to SQL for model training. 
rxSetComputeContext(sql)

# Train the Random Forest.
forest_model <- rxDForest(formula = formula,
                          data = CM_AD_Train,
                          nTree = 40,
                          minSplit = 10,
                          minBucket = 5,
                          cp = 0.00005,
                          seed = 5)

# Save the Random Forest in SQL. The compute context is set to Local in order to export the model. 
rxSetComputeContext(local)
## Open an Odbc connection with SQL Server.
OdbcModel <- RxOdbcData(table = "Model", connectionString = connection_string)
rxOpen(OdbcModel, "w")

## Drop the Model table if it exists. 
if(rxSqlServerTableExists(OdbcModel@table, OdbcModel@connectionString)) {
  rxSqlServerDropTable(OdbcModel@table, OdbcModel@connectionString)
}

## Create an empty Model table. 
rxExecuteSQLDDL(OdbcModel, 
                sSQLString = paste(" CREATE TABLE [", OdbcModel@table, "] (",
                                   "     [id] varchar(200) not null, ",
                                   "     [value] varbinary(max), ",
                                   "     constraint unique_id3 unique (id))",
                                   sep = "")
)

## Write the model to SQL. 
rxWriteObject(OdbcModel, "RF", forest_model)

# Set back the compute context to SQL.
rxSetComputeContext(sql)


##########################################################################################################################################

##	Gradient Boosted Trees Training and saving the model to SQL

##########################################################################################################################################

# Train the GBT.
btree_model <- rxBTrees(formula = formula,
                        data = CM_AD_Train,
                        learningRate = 0.05,
                        minSplit = 10,
                        minBucket = 5,
                        cp = 0.0005,
                        nTree = 40,
                        seed = 5,
                        lossFunction = "multinomial")

# Save the GBT in SQL. The Compute Context is set to Local in order to export the model. 
rxSetComputeContext(local)

## Write the model to SQL. 
rxWriteObject(OdbcModel, "GBT", btree_model)

# Close the Obdc connection used. 
rxClose(OdbcModel)

##########################################################################################################################################

##	Binary classification model evaluation metrics

##########################################################################################################################################

# Write a function that computes the AUC, Accuracy, Precision, Recall, and F-Score.
evaluate_model <- function(observed, predicted_probability, threshold, model_name) { 
  
  # Given the observed labels and the predicted probability, plot the ROC curve and determine the AUC.
  data <- data.frame(observed, predicted_probability)
  data$observed <- as.numeric(as.character(data$observed))
  if(model_name =="RF"){
  rxRocCurve(actualVarName = "observed", predVarNames = "predicted_probability", data = data, numBreaks = 1000, title = "RF" )
  }else{
    rxRocCurve(actualVarName = "observed", predVarNames = "predicted_probability", data = data, numBreaks = 1000, title = "GBT" )
    }
  ROC <- rxRoc(actualVarName = "observed", predVarNames = "predicted_probability", data = data, numBreaks = 1000)
  auc <- rxAuc(ROC)
  
  # Given the predicted probability and the threshold, determine the binary prediction.
  predicted <- ifelse(predicted_probability > threshold, 1, 0) 
  predicted <- factor(predicted, levels = c(0, 1)) 
  
  # Build the corresponding Confusion Matrix, then compute the Accuracy, Precision, Recall, and F-Score.
  confusion <- table(observed, predicted)
  print(model_name)
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
Prediction_Table_RF <- RxSqlServerData(table = "Forest_Prediction", stringsAsFactors = T, connectionString = connection_string)
rxPredict(forest_model, data = CM_AD_Test, outData = Prediction_Table_RF, overwrite = T, type = "prob",
          extraVarsToWrite = c("Conversion_Flag"))

Prediction_RF <- rxImport(inData = Prediction_Table_RF, stringsAsFactors = T, outFile = NULL)
observed <- Prediction_RF$Conversion_Flag

# Assign the decision threshold to the median of the predicted probabilities.
threshold <- median(Prediction_RF$`1_prob`)

# Compute the performance metrics of the model.
Metrics_RF <- evaluate_model(observed = observed, predicted_probability = Prediction_RF$`1_prob`, threshold = threshold,
                             model_name = "RF")


##########################################################################################################################################

##	Gradient Boosted Trees Scoring 

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_GBT <- RxSqlServerData(table = "Boosted_Prediction", stringsAsFactors = T, connectionString = connection_string)
rxPredict(btree_model,data = CM_AD_Test, outData = Prediction_Table_GBT, overwrite = T, type="prob",
          extraVarsToWrite = c("Conversion_Flag"))

Prediction_GBT <- rxImport(inData = Prediction_Table_GBT, stringsAsFactors = T, outFile = NULL)
observed <- Prediction_GBT$Conversion_Flag

# Assign the decision threshold to the median of the predicted probabilities.
threshold <- median(Prediction_GBT$`1_prob`)

# Compute the performance metrics of the model.
Metrics_GBT <- evaluate_model(observed = observed, predicted_probability = Prediction_GBT$`1_prob`, threshold = threshold, 
                              model_name = "GBT")


##########################################################################################################################################

## Select the best model based on AUC

##########################################################################################################################################

best <- ifelse(Metrics_RF$AUC >= Metrics_GBT$AUC, "RF", "GBT")


