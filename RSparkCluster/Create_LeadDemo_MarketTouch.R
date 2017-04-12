##########################################################################################################################################
## This R script is the function to generate Lead_Demography and Market_touchdown table.
## This function will be execute parallely to each splits by rxExec function

## Input : id_num_part: the data frame contain raw lead id and its corresponding partition number
##         partNum: the number of a certain partition. This parameter will be controlled by rxElemArg argument in rxExec function
##         dataDir: directory to store data
## Output: Lead_Demography and Market_Touchdown tables

##########################################################################################################################################

## Define the function
Create_LeadDemo_MarketTouch <- function(id_num_part, partNum, dataDir){
  # get one split of lead id
  Id <- id_num_part$Id_num[which(id_num_part$part == partNum)] 
  numId <- length(Id)
  
  # create Lead_Id and phone number
  Lead_Id <- paste ("ID",sprintf("%08d",Id, sep=''))
  m <- 1e+09 + Id
  Phone_No <- paste(substr(m,1,3),"-",substr(m,4,6),"-",substr(m,7,10), sep = '')
  
  table_target <- data.frame(Lead_Id, Phone_No)
  
  # Create the binary target variable Conversion_Flag by random sampling.
  table_target$Conversion_Flag <- sample(c("0","1"), numId, replace = TRUE, prob = c(0.9, 0.1))
  
  # Create variables whose values depend on the label Conversion_Flag, by random sampling with different probabilities given the label. 
  
  ## Probabilities for Labels 0 and 1
  age_list <- c("Young","Middle Age","Senior Citizen")
  age_p0 <- c(0.33, 0.33, 0.34)
  age_p1 <- c(0.33, 0.33, 0.34)
  annual_income_bucket_list <- c("<60k", "60k-120k", ">120k")  
  annual_income_bucket_p0 <- c(0.33, 0.33, 0.34)
  annual_income_bucket_p1 <- c(0.33, 0.33, 0.34)  
  credit_score_list <- c("<350", "350-700", ">700")  
  credit_score_p0 <- c(0.5, 0.2, 0.3) 
  credit_score_p1 <- c(0.2, 0.6, 0.2) 
  state_list <- c("US", "AL",	"AK",	"AZ",	"AR",	"CA",	"CO",	"CT",	"DE",	"DC",	"FL",	"GA",	"HI",	"ID",	"IL",	
                  "IN",	"IA",	"KS",	"KY",	"LA",	"ME",	"MD",	"MA",	"MI",	"MN",	"MS",	"MO",	"MT",	"NE",	"NV",	
                  "NH",	"NJ",	"NM",	"NY",	"NC",	"ND",	"OH",	"OK",	"OR",	"PA",	"RI",	"SC",	"SD",	"TN",	"TX",	
                  "UT",	"VT",	"VA",	"WA",	"WV",	"WI",	"WY",	"AS",	"GU",	"MP",	"PR",	"VI",	"UM",	"FM",	"MH", "PW")  
  state_p0 <- rep(1/61, 61)
  state_p1 <- rep(1/61, 61)
  no_of_children_list <- c(0, 1, 2, 3)
  no_of_children_p0 <- c(0.4, 0.1, 0.3, 0.2)
  no_of_children_p1 <- c(0.2, 0.3, 0.1, 0.4)
  highest_education_list <- c("High School", "Attended Vocational", "Graduate School", "College")
  highest_education_p0 <- c(0.20, 0.25, 0.3, 0.25)
  highest_education_p1 <- c(0.35, 0.3, 0.2, 0.15)
  ethnicity_list <- c("White Americans", "African American", "Hispanic", "Latino")
  ethnicity_p0 <- c(0.25, 0.25, 0.25, 0.25)
  ethnicity_p1 <- c(0.25, 0.25, 0.25, 0.25)
  gender_list <- c("M", "F")
  gender_p0 <- c(0.55, 0.45)
  gender_p1 <- c(0.45, 0.55)
  marital_status_list <- c("S", "M", "D", "W")
  marital_status_p0 <- c(0.25, 0.25, 0.25, 0.25)
  marital_status_p1 <- c(0.25, 0.25, 0.25, 0.25)
  source_list <- c("Inbound call", "SMS", "Previous Campaign")
  source_p0 <- c(1/3, 1/3, 1/3)
  source_p1<- c(1/3, 1/3, 1/3)
  
  # Define conditional probabilities for Day_Of_Week, Time_Of_Day and Channel.
  # The goal is to avoid getting the same recommendations for all Lead_Ids. 
  # Indeed, if there is no conditional sampling on other features, whatever demographic or campaign variables,
  # the probability of conversion would depend only on Day_Of_Week, Time_Of_Day and Channel. 
  
  ## Condition Day_Of_Week on Annual_Income_Bucket and Conversion_Flag
  day_of_week_list <- seq(1, 7)
  day_of_week_p0Low <- c(0.03, 0.02, 0.03, 0.05, 0.30, 0.29, 0.29)
  day_of_week_p0Middle <- c(0.1, 0.16, 0.1, 0.1, 0.10, 0.17, 0.27)
  day_of_week_p0High <- c(0.5, 0.15, 0.20, 0.1, 0.03, 0.01, 0.01)
  
  day_of_week_p1Low <- c(0.20, 0.30, 0.2, 0.14, 0.1, 0.03, 0.03)
  day_of_week_p1Middle <- c(0.05, 0.15, 0.30, 0.30, 0.1, 0.05, 0.05)
  day_of_week_p1High <- c(0.10, 0.1, 0.1, 0.12, 0.15, 0.21, 0.22)
  
  ## Condition Time_Of_Day on Age and Conversion_Flag.
  time_of_day_list <- c("Morning", "Afternoon", "Evening")
  time_of_day_p0Young <- c(0.5, 0.25, 0.25)
  time_of_day_p0Middle <- c(0.33, 0.33, 0.34)
  time_of_day_p0Senior <- c(0.2, 0.4, 0.4)
  
  time_of_day_p1Young <- c(0.2, 0.25, 0.55)
  time_of_day_p1Middle <- c(0.33, 0.33, 0.34)
  time_of_day_p1Senior <- c(0.62, 0.2, 0.18)
  
  ## Condition Channel on Age and Conversion_Flag.
  channel_list <- c("Email", "Cold Calling", "SMS")
  channel_p0Young <- c(0.15, 0.60, 0.25)
  channel_p0Middle <- c(0.40, 0.2, 0.40)
  channel_p0Senior <- c(0.25, 0.15, 0.60)
  
  channel_p1Young <- c(0.30, 0.1, 0.60)
  channel_p1Middle <- c(0.30, 0.55, 0.15)
  channel_p1Senior <- c(0.33, 0.45, 0.22)
  
  ## Sample for Conversion_Flag = 0 
  table_target0 <- table_target[table_target$Conversion_Flag == "0", ]
  n0 <- nrow(table_target0)
  
  ### Creating Various Variables by random sampling.
  table_target0$Age <- sample(c("Young", "Middle Age", "Senior Citizen"), n0, replace = TRUE, prob =  age_p0)
  table_target0$Annual_Income_Bucket <- sample(c("<60k", "60k-120k", ">120k"), n0, replace = TRUE, prob = annual_income_bucket_p0)
  table_target0$Credit_Score <- sample(c("<350", "350-700", ">700"), n0, replace = TRUE, prob = credit_score_p0)
  table_target0$Country <-  sample(c("US"), n0, replace = TRUE)
  table_target0$State <-  sample(c("US",  "AL",	"AK",	"AZ",	"AR",	"CA",	"CO",	"CT",	"DE",	"DC",	"FL",	"GA",	"HI",	
                                   "ID",	"IL",	"IN",	"IA",	"KS",	"KY",	"LA",	"ME",	"MD",	"MA",	"MI",	"MN",	"MS",	
                                   "MO",	"MT",	"NE",	"NV",	"NH",	"NJ",	"NM",	"NY",	"NC",	"ND",	"OH",	"OK",	"OR",	
                                   "PA",	"RI",	"SC",	"SD",	"TN",	"TX",	"UT",	"VT",	"VA",	"WA",	"WV",	"WI",	"WY",	
                                   "AS",	"GU",	"MP",	"PR",	"VI",	"UM",	"FM",	"MH",	"PW"), 
                                 n0, replace =  TRUE,prob =  state_p0)
  table_target0$No_Of_Children <- sample(c(0, 1, 2, 3), n0, replace = TRUE, prob = no_of_children_p0)
  table_target0$Highest_Education <- sample(c("High School", "Attended Vocational", "Graduate School", "College"),
                                            n0, replace = TRUE, prob = highest_education_p0)
  table_target0$Ethnicity <- sample(c("White Americans", "African American", "Hispanic", "Latino"), n0, replace = TRUE, prob = ethnicity_p0)
  table_target0$No_Of_Dependents <- round(runif(n0, 0, table_target0$No_Of_Children), digits =  0)
  table_target0$Household_Size <- round(runif(n0, 1, table_target0$No_Of_Children + 1), digits =  0)
  table_target0$Gender <- sample(c("M", "F"), n0, replace = TRUE, prob = gender_p0)
  table_target0$Marital_Status <- sample(c("S", "M", "D", "W"), n0, replace = TRUE, prob = marital_status_p0)
  table_target0$Source <- sample(c("Inbound call", "SMS", "Previous Campaign"), n0, replace = TRUE, prob = source_p0)
  table_target0$Campaign_Id <- sample(c("2", "3", "4", "5", "6"), n0, replace = TRUE)
  
  ### Creating Time_Stamp, Day_Of_Week, Time_Of_Day and Channel by conditional random sampling.
  table_target0$Day_Of_Week <-  
    ifelse(table_target0$Annual_Income_Bucket  == "<60k", sample(seq(1, 7), n0, replace = T, prob = day_of_week_p0Low),
           ifelse(table_target0$Annual_Income_Bucket  == "60k-120k", sample(seq(1, 7), n0, replace = T, prob = day_of_week_p0Middle),
                  sample(seq(1, 7), n0, replace = T, prob = day_of_week_p0High)))
  
  
  table_target0$Time_Of_Day <- 
    ifelse(table_target0$Age == "Young", sample(c("Morning", "Afternoon", "Evening"), n0, replace = T, prob = time_of_day_p0Young),
           ifelse(table_target0$Age == "Middle Age", sample(c("Morning", "Afternoon", "Evening"), n0, replace = T, prob = time_of_day_p0Middle),
                  sample(c("Morning", "Afternoon", "Evening"), n0, replace = T, prob = time_of_day_p0Senior)))
  
  table_target0$Channel <- 
    ifelse(table_target0$Age  == "Young", sample(c("Email", "Cold Calling", "SMS"), n0, replace = T, prob = channel_p0Young),
           ifelse(table_target0$Age  == "Middle Age", sample(c("Email", "Cold Calling", "SMS"), n0, replace = T, prob = channel_p0Middle),
                  sample(c("Email", "Cold Calling", "SMS"), n0, replace = T, prob = channel_p0Senior)))  
  
  
  
  ## Sample for Conversion_Flag = 1 
  table_target1 <- table_target[table_target$Conversion_Flag == "1", ]
  n1 <- nrow(table_target1)
  
  ### Creating Various Variables by random sampling.
  table_target1$Age <- sample(c("Young", "Middle Age", "Senior Citizen"), n1, replace = TRUE, prob =  age_p1)
  table_target1$Annual_Income_Bucket <-   sample(c("<60k", "60k-120k", ">120k"), n1, replace = TRUE, prob = annual_income_bucket_p1)
  table_target1$Credit_Score <- sample(c("<350", "350-700", ">700"), n1, replace = TRUE, prob = credit_score_p1)
  table_target1$Country <- sample(c("US"), n1, replace = TRUE)
  table_target1$State <- sample(c("US", "AL",	"AK",	"AZ",	"AR",	"CA",	"CO",	"CT",	"DE",	"DC",	"FL",	"GA",	"HI",	
                                  "ID",	"IL",	"IN",	"IA",	"KS",	"KY",	"LA",	"ME",	"MD",	"MA",	"MI",	"MN",	"MS",
                                  "MO",	"MT",	"NE",	"NV",	"NH",	"NJ",	"NM",	"NY",	"NC",	"ND",	"OH",	"OK",	"OR",	
                                  "PA",	"RI",	"SC",	"SD",	"TN",	"TX",	"UT",	"VT",	"VA",	"WA",	"WV",	"WI",	"WY",	
                                  "AS",	"GU",	"MP",	"PR",	"VI",	"UM",	"FM",	"MH",	"PW"),
                                n1, replace =  TRUE,prob =  state_p1)
  table_target1$No_Of_Children <- sample(c(0, 1, 2, 3), n1, replace = TRUE, prob = no_of_children_p1)
  table_target1$Highest_Education <-  sample(c("High School", "Attended Vocational", "Graduate School", "College"), n1, replace = TRUE,
                                             prob = highest_education_p1)
  table_target1$Ethnicity <- sample(c("White Americans", "African American", "Hispanic", "Latino"), n1, replace = TRUE, prob = ethnicity_p1)
  table_target1$No_Of_Dependents <- round(runif(n1, 0, table_target1$No_Of_Children), digits =  0)
  table_target1$Household_Size <- round(runif(n1, 1, table_target1$No_Of_Children + 1), digits =  0)
  table_target1$Gender <-  sample(c("M", "F"), n1, replace = TRUE, prob = gender_p1)
  table_target1$Marital_Status <- sample(c("S", "M", "D", "W"), n1, replace = TRUE, prob = marital_status_p1)
  table_target1$Source <- sample(c("Inbound call", "SMS", "Previous Campaign"), n1, replace = TRUE, prob = source_p1)
  table_target1$Campaign_Id <-  sample(c("2", "3", "4", "5", "6"), n1, replace = TRUE)
  
  
  ### Creating Time_Stamp, Day_Of_Week, Time_Of_Day and Channel by conditional random sampling.
  table_target1$Day_Of_Week <-  
    ifelse(table_target1$Annual_Income_Bucket  == "<60k", sample(seq(1, 7), n1, replace = TRUE, prob = day_of_week_p1Low),
           ifelse(table_target1$Annual_Income_Bucket  == "60k-120k", sample(seq(1, 7), n1, replace = TRUE, prob = day_of_week_p1Middle),
                  sample(seq(1, 7), n1, replace = TRUE, prob = day_of_week_p1High)))
  
  table_target1$Time_Of_Day <- 
    ifelse(table_target1$Age == "Young", sample(c("Morning", "Afternoon", "Evening"), n1, replace = T, prob = time_of_day_p1Young),
           ifelse(table_target1$Age == "Middle Age", sample(c("Morning", "Afternoon", "Evening"), n1, replace = T, prob = time_of_day_p1Middle),
                  sample(c("Morning", "Afternoon", "Evening"), n1, replace = T, prob = time_of_day_p1Senior)))
  
  table_target1$Channel <- 
    ifelse(table_target1$Age  == "Young", sample(c("Email", "Cold Calling", "SMS"), n1, replace = T, prob = channel_p1Young),
           ifelse(table_target1$Age  == "Middle Age", sample(c("Email", "Cold Calling", "SMS"), n1, replace = T, prob = channel_p1Middle),
                  sample(c("Email", "Cold Calling", "SMS"), n1, replace = T, prob = channel_p1Senior)))      
  
  # Merge the data sets. 
  table_target <- rbind(table_target0, table_target1)
  
  # Separate in two: Lead_demography and campaign_table1
  Lead_Demography <- table_target[c("Lead_Id", "Age", "Phone_No", "Annual_Income_Bucket", "Credit_Score", "Country", "State",
                                    "No_Of_Dependents", "Highest_Education", "Ethnicity", "No_Of_Children", "Household_Size",
                                    "Gender", "Marital_Status" )]
  campaign_table1 <- table_target[c("Lead_Id", "Channel", "Time_Of_Day", "Day_Of_Week", "Campaign_Id", "Conversion_Flag", 
                                    "Source", "Annual_Income_Bucket", "Age" )]
  
  ### Creating Time_Stamp.
  campaign_table1$Time_Stamp <-  
    ifelse(campaign_table1$Campaign_Id == "2", format(sample(seq(ISOdate(2014, 3, 21), ISOdate(2014, 5, 24), by = "day"), (n0+n1), replace = T),"%D"), 
           ifelse(campaign_table1$Campaign_Id == "3", format(sample(seq(ISOdate(2014, 5, 25), ISOdate(2014, 6, 30), by = "day"), (n0+n1), replace = T),"%D"), 
                  ifelse(campaign_table1$Campaign_Id == "4", format(sample(seq(ISOdate(2014, 7, 1), ISOdate(2014, 9, 26), by = "day"), (n0+n1), replace = T),"%D"), 
                         ifelse(campaign_table1$Campaign_Id == "5", format(sample(seq(ISOdate(2014, 9, 27), ISOdate(2014, 12, 4), by = "day"), (n0+n1), replace = T),"%D"), 
                                format(sample(seq(ISOdate(2014, 12, 5), ISOdate(2014, 12, 31), by = "day"), (n0+n1), replace =T),"%D") 
                         ))))
  
  
  # Insert NA values in No_Of_Children, Household_Size, No_Of_Dependents and Highest_Education.
  Lead_Demography$No_Of_Children <- ifelse(sample(c(1, 2), numId,replace = TRUE, prob = c(0.99, 0.01)) == 1, 
                                           Lead_Demography$No_Of_Children, NA)
  Lead_Demography$Household_Size <- ifelse(sample(c(1, 2), numId,replace = TRUE, prob = c(0.99, 0.01)) == 1, 
                                           Lead_Demography$Household_Size, NA)
  Lead_Demography$No_Of_Dependents <- ifelse(sample(c(1, 2), numId,replace = TRUE, prob = c(0.99, 0.01)) == 1, 
                                             Lead_Demography$No_Of_Dependents, NA)
  Lead_Demography$Highest_Education <- ifelse(sample(c(1, 2), numId,replace = TRUE, prob = c(0.99, 0.01)) == 1, 
                                              Lead_Demography$Highest_Education, NA)
  
  # Drop intermediate data sets.
  rm(table_target)
  rm(table_target0)
  rm(table_target1)
  
  # export as .csv file
  Lead_Demography_Txt <- RxTextData(file.path(dataDir, "Lead_Demography", paste0("Lead_Demography", partNum, ".csv")), 
                                    firstRowIsColNames = T
                                    ,fileSystem = RxHdfsFileSystem()
  )
  rxDataStep(inData = Lead_Demography, 
             outFile = Lead_Demography_Txt,
             overwrite = TRUE,
             reportProgress = 0)
  
  ## generate market touchdown table
  # We form campaign_table2 obtained by taking campaign_table1, setting Conversion_Flag to 0 and Campaing_Id to 1, and resampling variables.
  # The goal is to create synthetic data corresponding to unfruitful attempts of conversion for every Lead_Id. 
  # It assumes that there were no conversions during the first campaign. 
  campaign_table2 <- campaign_table1
  campaign_table2$Conversion_Flag <- rep("0", numId)
  campaign_table2$Campaign_Id <- rep("1", numId)
  
  campaign_table2$Channel <- 
    ifelse(campaign_table2$Age  == "Young", sample(c("Email", "Cold Calling", "SMS"), numId, replace = T, prob = channel_p0Young),
           ifelse(campaign_table2$Age  == "Middle Age", sample(c("Email", "Cold Calling", "SMS"), numId, replace = T, prob = channel_p0Middle),
                  sample(c("Email", "Cold Calling", "SMS"), numId, replace = T, prob = channel_p0Senior)))  
  
  campaign_table2$Day_Of_Week <- 
    ifelse(campaign_table2$Annual_Income_Bucket  == "<60k", sample(seq(1, 7), numId, replace = T, prob = day_of_week_p0Low),
           ifelse(campaign_table2$Annual_Income_Bucket  == "60k-120k", sample(seq(1, 7), numId, replace = T, prob = day_of_week_p0Middle),
                  sample(seq(1, 7), numId, replace = T, prob = day_of_week_p0High)))
  
  tod_list <- c("Morning", "Afternoon", "Evening")
  campaign_table2$Time_Of_Day <- 
    ifelse(campaign_table2$Age == "Young", sample(tod_list, numId, replace = T, prob = time_of_day_p0Young),
           ifelse(campaign_table2$Age == "Middle Age", sample(tod_list, numId, replace = T, prob = time_of_day_p0Middle),
                  sample(tod_list, numId, replace = T, prob = time_of_day_p0Senior)))
  
  campaign_table2$Time_Stamp <-  
    format(sample(seq(ISOdate(2014, 1, 1), ISOdate(2014, 3, 20), by="day"), numId, replace=T), "%D")
  
  # We form campaign_table3 obtained by creating a random number (1-3) of communications for each lead and resampling variables.
  # The goal is to create synthetic data corresponding to unfruitful attempts of conversion for every Lead_Id. 
  
  ## Create a random number of communications (1-3) per Lead_Id.
  campaign_table3 <- campaign_table1[rep(1:nrow(campaign_table1),sapply(1:nrow(campaign_table1), function(x) sample(2:4,1))),]
  n3 <- nrow(campaign_table3)
  
  ## Resample variables.
  campaign_table3$Conversion_Flag <- rep("0", n3)
  
  campaign_table3$Campaign_Id <- 
    ifelse(campaign_table3$Campaign_Id == "2", "1", as.character(floor(runif(n = n3, min = 2, max = as.numeric(campaign_table3$Campaign_Id)))))
  
  
  campaign_table3$Channel <- 
    ifelse(campaign_table3$Age  == "Young", sample(c("Email", "Cold Calling", "SMS"), n3, replace = T, prob = channel_p0Young),
           ifelse(campaign_table3$Age  == "Middle Age", sample(c("Email", "Cold Calling", "SMS"), n3, replace = T, prob = channel_p0Middle),
                  sample(c("Email", "Cold Calling", "SMS"), n3, replace = T, prob = channel_p0Senior)))
  
  campaign_table3$Day_Of_Week <- 
    ifelse(campaign_table3$Annual_Income_Bucket  == "<60k", sample(seq(1, 7), n3, replace = TRUE, prob = day_of_week_p0Low),
           ifelse(campaign_table3$Annual_Income_Bucket  == "60k-120k", sample(seq(1, 7), n3, replace = TRUE, prob = day_of_week_p0Middle),
                  sample(seq(1, 7), n3, replace = TRUE, prob = day_of_week_p0High)))
  
  campaign_table3$Time_Of_Day <- 
    ifelse(campaign_table3$Age  == "Young", sample(tod_list, n3, replace = TRUE, prob = time_of_day_p0Young),
           ifelse(campaign_table3$Age  ==  "Middle Age", sample(tod_list, n3, replace = TRUE, prob = time_of_day_p0Middle),
                  sample(tod_list, n3, replace = TRUE, prob = time_of_day_p0Senior)))
  
  campaign_table3$Time_Stamp <-  
    ifelse(campaign_table3$Campaign_Id == "1", format(sample(seq(ISOdate(2014, 1, 1), ISOdate(2014, 3, 20), by = "day"), n3, replace = T),"%D"), 
           ifelse(campaign_table3$Campaign_Id == "2", format(sample(seq(ISOdate(2014, 3, 21), ISOdate(2014, 5, 24), by = "day"), n3, replace = T),"%D"), 
                  ifelse(campaign_table3$Campaign_Id == "3", format(sample(seq(ISOdate(2014, 5, 25), ISOdate(2014, 6, 30), by = "day"), n3, replace = T),"%D"), 
                         ifelse(campaign_table3$Campaign_Id == "4", format(sample(seq(ISOdate(2014, 7, 1), ISOdate(2014, 9, 26), by = "day"), n3, replace = T),"%D"), 
                                ifelse(campaign_table3$Campaign_Id == "5", format(sample(seq(ISOdate(2014, 9, 27), ISOdate(2014, 12, 4), by = "day"), n3, replace = T),"%D"), 
                                       format(sample(seq(ISOdate(2014, 12, 5), ISOdate(2014, 12, 31), by = "day"), n3, replace =T),"%D") 
                                ))))) 
  
  # Finally, form a data set by taking the union of the three data sets created. 
  Market_Touchdown <- rbind(campaign_table1, campaign_table2, campaign_table3)
  
  rm(campaign_table1)
  rm(campaign_table2)
  rm(campaign_table3)
  
  # Remove unnecessary variables.
  Market_Touchdown$Age <- NULL
  Market_Touchdown$Annual_Income_Bucket <- NULL
  
  # Add a counter, Comm_Id, that gives an ID to every communication made during the campaign for a given Lead_Id. 
  Market_Touchdown <- Market_Touchdown[order(Market_Touchdown$Lead_Id, Market_Touchdown$Conversion_Flag, Market_Touchdown$Time_Stamp),] 
  Comm_Id <- sequence(unname(table(Market_Touchdown$Lead_Id)))
  rownames(Market_Touchdown) <- NULL
  Market_Touchdown$Comm_Id <- Comm_Id
  
  # export as .csv file
  Market_Touchdown_Txt <- RxTextData(file.path(dataDir, "Market_Touchdown", paste0("Market_Touchdown", partNum, ".csv")), 
                                     firstRowIsColNames = T
                                     ,fileSystem = RxHdfsFileSystem()
  )
  rxDataStep(inData = Market_Touchdown, 
             outFile = Market_Touchdown_Txt,
             overwrite = TRUE,
             reportProgress = 0)
}