##########################################################################################################################################
## This R script will do the following:

## Copy model related objects from dev/model folder to prod/model folder
## Run this part for the following two situations:
#     1. The first time running all the scripts, which means there is nothing in prod/model folder for scoring
#     2. Want to overwrite the existing model objects in prod/model folder

## Input: 1. Dev directory stores model related objects
##        2. Prod directory stores model related objects
## Output: Model related objects will be copied from dev directory to prod directory

##########################################################################################################################################

# Define the function to copy model related objects from dev/model folder to prod/model folder
CopyFromDev2Prod <- function(DevModelDir,
                             ProdModellDir){
  
  # check the prod folder stores model related objexts if exists
  # if exists, remove and create a new one
  # if not exists, create a new one
  if(dir.exists(ProdModellDir)){
    system(paste("rm -rf ",ProdModellDir, sep="")) # remove the directory if exists
    system(paste("mkdir -p -m 777 ", ProdModellDir, sep="")) # create a new directory
  } else {
    system(paste("mkdir -p -m 777 ", ProdModellDir, sep="")) # make new directory if doesn't exist
  }
  
  # copy files from dev folder to prod folder
  system(paste("cp ", DevModelDir, "*.rds ", ProdModellDir, sep = ""))
}


# Specify the source folder and destination folder
DevModelDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/Campaign/dev/model/", sep="" )
ProdModellDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/Campaign/prod/model/", sep="" )

# Invoke the function
CopyFromDev2Prod (DevModelDir = DevModelDir,
                  ProdModellDir = ProdModellDir)
