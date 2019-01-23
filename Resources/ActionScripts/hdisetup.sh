#!/usr/bin/env bash

# This script used to setup an HDInsight Cluster deployed from Cortana Analytics Gallery
# WARNING: This script is only meant to be run from the solution template deployment process.
# This should be run on the edge node of the cluster!
# put R code in users home directory
# XXX SWITCH to master branch when ready to publish!! XXX
git clone  --branch master --single-branch  https://github.com/Microsoft/r-server-campaign-optimization.git  campaign
cp campaign/RSparkCluster/* /home/$1
chmod 777 /home/$1/*.R
rm -rf campaign
sed -i "s/XXYOURPW/$2/g" /home/$1/*.R

# Configure edge node as one-box setup for R Server Operationalization
az extension add --source /opt/microsoft/mlserver/9.3.0/o16n/azure_ml_admin_cli-0.0.1-py2.py3-none-any.whl --yes
az ml admin node setup --onebox --admin-password $2 --confirm-password $2

#Run R scripts
cd /home/$1

#run step0_data_generation.R
Rscript step0_data_generation.R

#run campaign_main.R
Rscript campaign_main.R

#run other scripts as well?
#Rscript campaign_deployment.R

#Rscript campaign_web_scoring.R

#Rscript campaign_scoring.R