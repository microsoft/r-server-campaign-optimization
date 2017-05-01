##########################################################################################################################################
## This R script will do the following:
## 1. Specify parameters: data size, directories, compute context.
## 2. Create Lead_Demography and Market_Touchdown tables parallely using rxExec function
## 3. Create Campaign_Detail and Product table

## Input : Number of data size (unique lead id).
## Output: Four tables: Lead_Demography, Market_Touchdown, Campaign_Detail, Product.

##########################################################################################################################################

##########################################################################################################################################

## Set Compute and Data Contexts

##########################################################################################################################################

# choose data set size
dataSet <- 1000
#dataSet <- 100000
#dataSet <- 1000000
#dataSet <- 10000000

# automatically determine the number of splits based on the number of unique lead id.
num_lead_id <- dataSet
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

## print out the parameter
print(paste("The data size is ",dataSet, sep=""))
print(paste("The number of splits is ",numSplits, sep=""))

# Compute Contexts
myHadoopCluster <- RxSpark()

# The directory to export data
dataDir <- "/CampaignManagement/data"

# generate raw Lead Id and corresponding partition
no_of_unique_leads <- as.numeric(dataSet)
Id_num <- 1:no_of_unique_leads
part <-  Id_num %% numSplits
id_num_part <- data.frame(Id_num, part)

##############################################################################################################################################################

## The block below mainly will do the following:
## 1. Load the function to generate Lead_Demography and Market_Touchdown table
## 2. Use rxExec function to invoke the loaded function parallely, so that a series of subset of Lead_Demography and Market_Touchdown table will be generated
## 3. Combine those subsets into one 

## This is a simple example demonstrating how to use rxExec function to generate data chunk by chunk:
## 1. Assume we want to generate a whole data set with 100 unique ID: ID_1, ID_2, ..., ID_100.
## 2. We group the IDs into five groups: G_1, G_2, ..., G_5. Each group roughly contains same number of ID. In this example, roughly 20.
## 3. We define a function called "Data_Generate" which will generate columns for each ID:
##    Data_Generate: input: vector of IDs, output:  a dataframe containing new created columns for each ID:
##    
##          ID_1                               ID_1, Col_1, Col_2, ..., Col_p
##          ID_2                               ID_2, Col_1, Col_2, ..., Col_p
##    G_i = ...       --> Data_Generate -- >      ....
##          ID_n                               ID_n, Col_1, Col_2, ..., Col_p

## 4. We apply Data_Generate function from G_1 to G_5 using rxExec function as:
##    rxExec(Data_Generate, G_i, i = rxElemArg(0:4))
##    rxElemArg can be used to control the number of iteration. It's like a for loop but will be executed across nodes and cores.

##############################################################################################################################################################

# load the function to generate Lead_Demography table
source("Create_LeadDemo_MarketTouch.R")

# Create_LeadDemo_MarketTouch(id_num_part = id_num_part, partNum = 0, dataDir = dataDir)

# remove previous temp directory if exists
rxHadoopRemoveDir(file.path(dataDir,"Lead_Demography"))
rxHadoopRemoveDir(file.path(dataDir,"Market_Touchdown"))

# generate Lead_Demography table
rxSetComputeContext("localpar")
info1 <- rxExec(Create_LeadDemo_MarketTouch, id_num_part, partNum = rxElemArg(0:(numSplits-1)), dataDir)

# combine data
Lead_Demography <- RxTextData(file.path(dataDir, "Lead_Demography"), 
                              fileSystem = RxHdfsFileSystem())
Lead_Demography_Combine <- RxTextData(paste(dataDir, "/Lead_Demography", no_of_unique_leads, ".csv",sep=""), 
                                      fileSystem = RxHdfsFileSystem())
rxDataStep(inData = Lead_Demography, 
           outFile = Lead_Demography_Combine,
           overwrite = TRUE,
           reportProgress = 0)

Market_Touchdown <- RxTextData(file.path(dataDir, "Market_Touchdown"), 
                               fileSystem = RxHdfsFileSystem())
Market_Touchdown_Combine <- RxTextData(paste(dataDir, "/Market_Touchdown", no_of_unique_leads, ".csv",sep=""), 
                                       fileSystem = RxHdfsFileSystem())
rxDataStep(inData = Market_Touchdown, 
           outFile = Market_Touchdown_Combine,
           overwrite = TRUE,
           reportProgress = 0)

# remove temp directory
rxHadoopRemoveDir(file.path(dataDir,"Lead_Demography"))
rxHadoopRemoveDir(file.path(dataDir,"Market_Touchdown"))

############################################################################################################

## Create Campaign_Detail table

######################################################################################################
# Create various variables.
Campaign_Id <- c("1", "2", "3", "4", "5", "6")
Campaign_Detail <- data.frame(Campaign_Id)

Campaign_Detail$Campaign_Name <- c("Above all in service", "All your protection under one roof", "Be life full confident", 
                                   "Together we are stronger", "The power to help you succeed", "Know Money")
Campaign_Detail$Category <- rep("Acquisition", 6)

Campaign_Detail$Launch_Date <- format(c(ISOdate(2014,1,1), ISOdate(2014,3,21), ISOdate(2014,5,25), ISOdate(2014,7,1), ISOdate(2014,9,27),  
                                        ISOdate(2014,12,5)), "%D") 

Campaign_Detail$Sub_Category <- sample(c("Branding", "Penetration", "Seasonal"), 6, replace=T)
Campaign_Detail$Campaign_Drivers <- sample(c("Discount offer", "Additional Coverage", "Extra benefits"), 6, replace=T)
Campaign_Detail$Product_Id <- sample(c("1", "2", "3", "4", "5", "6"), 6, replace = F)
Campaign_Detail$Call_For_Action <- as.character(rbinom(6, 1, 0.7))
Campaign_Detail$Focused_Geography <- rep("Nation Wide", 6)
Campaign_Detail$Tenure_Of_Campaign <-  as.character(c(rep(1, 4), rep(2, 2)))


Campaign_Detail_Txt <- RxTextData(paste(dataDir, "/Campaign_Detail", no_of_unique_leads, ".csv",sep=""), 
                                  fileSystem = RxHdfsFileSystem())
rxDataStep(inData = Campaign_Detail, 
           outFile = Campaign_Detail_Txt,
           overwrite = TRUE,
           reportProgress = 0)

####################################################################################################################################

## Create Product table

#####################################################################################################################################
# Create and Assign various Product variables.
Product_Id <- c("1", "2", "3", "4", "5", "6")
Product <- data.frame(Product_Id)

Product$Product <- c("Protect Your Future", "Live Free", "Secured Happiness", "Making Tomorrow Better", "Secured Life", "Live Happy")

Product$Category <- 
  ifelse(Product$Product == "Protect Your Future", "Long Term Care",
         ifelse(Product$Product == "Live Free", "Life",
                ifelse(Product$Product == "Secured Happiness", "Health",
                       ifelse(Product$Product == "Making Tomorrow Better", "Disability",
                              ifelse(Product$Product == "Secured Life", "Health","Life")))))

Product$Term <- c(10, 15, 20, 30, 24, 16)
Product$No_of_people_covered <- c(4, 2, 1, 4, 2, 5)
Product$Premium <- c(1000, 1500, 2000, 700, 900, 2000)
Product$Payment_frequency <- c(rep("Monthly", 3), rep("Quarterly", 2), "Yearly")
Product$Net_Amt_Insured <- c(100000, 200000, 150000, 100000, 200000, 150000)

Product$Amt_on_Maturity <- 
  ifelse(Product$Payment_frequency == "Monthly", 12*Product$Premium*Product$Term*1.5,
         ifelse(Product$Payment_frequency == "Quarterly", 4*Product$Premium*Product$Term*1.5, 1*Product$Premium*Product$Term*1.5))

Product$Amt_on_Maturity_Bin <- 
  ifelse(Product$Amt_on_Maturity < 200000, "<200000",
         ifelse((Product$Amt_on_Maturity >= 200000) & (Product$Amt_on_Maturity < 250000), "200000-250000",
                ifelse((Product$Amt_on_Maturity >= 250000) & (Product$Amt_on_Maturity < 300000), "250000-300000",
                       ifelse((Product$Amt_on_Maturity >= 300000) & (Product$Amt_on_Maturity < 350000), "300000-350000",
                              ifelse((Product$Amt_on_Maturity >= 350000) & (Product$Amt_on_Maturity < 400000), "350000-400000",
                                     "<400000")))))

Product_Txt <- RxTextData(paste(dataDir, "/Product", no_of_unique_leads, ".csv",sep=""), 
                          fileSystem = RxHdfsFileSystem())
Product$Term <- as.factor(as.character(Product$Term))
rxDataStep(inData = Product, 
           outFile = Product_Txt,
           overwrite = TRUE,
           reportProgress = 0)
