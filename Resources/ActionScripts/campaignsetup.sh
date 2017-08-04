#!/usr/bin/env bash

# put R code in user's home directory
git clone  https://github.com/Microsoft/r-server-campaign-optimization.git  campaign
cp campaign/RSparkCluster/* /home/$1
rm -rf campaign

chmod 777 /home/$1/*.R

