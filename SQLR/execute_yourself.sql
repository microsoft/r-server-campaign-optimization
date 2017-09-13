-- Script to execute yourself the SQL Stored Procedures instead of using PowerShell. 

-- Pre-requisites: 
-- 1) The data should be already loaded with step 0 from PowerShell. 
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3,4 and run "Execute". 
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: rdemo (if you did not change it)
-- - password: D@tascience (if you did not change it)

/* Step 1 */ 
exec [dbo].[merging_raw_tables]
exec [dbo].[fill_NA_all] 

/* Step 2 */ 
exec [dbo].[feature_engineering]  

/* Step 3 */ 
exec [dbo].[normalization]
exec [dbo].[splitting] @splitting_percent = 70
exec [dbo].[train_model] @modelName ='RF'
exec [dbo].[train_model] @modelName ='GBT'
exec [dbo].[test_evaluate_models] 
/* Step 4 */
exec [dbo].[campaign_recommendation] @bestModel = 'RF'
					
