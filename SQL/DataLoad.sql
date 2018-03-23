-- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
DECLARE @SQL VARCHAR(1000)
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Source'
EXEC sp_executeSQL @SQL
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Target'
EXEC sp_executeSQL @SQL

EXEC Insert_Users 'User', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Region 'Region__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Division 'Division__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_MarketingArea 'Marketing_Area__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Account 'Account', 'SFDC_TARGET', 'SALESFORCE' --works
EXEC Insert_Contact 'Contact', 'SFDC_Target', 'SALESFORCE' -- works
EXEC User_FollowUp 'User', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_LoanType 'Loan_Type__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_CommunitySheet 'Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --Done, turned off filter on Division__c field.
EXEC Insert_Community 'Community__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE, turned off filter on Sales_Manager__c since user has to be active.
EXEC Insert_CommunityPlanMaster 'Community_Plan_Master__c', 'SFDC_Target', 'SALESFORCE' -- Done had to turn off validation rule on master_bedroom_location__c
EXEC Insert_Plan 'Plan__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE
EXEC Insert_Lot 'Lot__c', 'SFDC_Target', 'SALESFORCE' -- blocked due to QA envioronment data storage limits
EXEC Insert_Option 'Option__c', 'SFDC_Target', 'SALESFORCE'
EXEC CommunitySheet_FollowUp 'Community_Sheet__c', 'Name', 'Master_Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --works (nice)
EXEC Insert_Lead 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW'
EXEc Insert_Opportunity 'Opportunity__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Sales 'Sale__c', 'SFDC_Target', 'SALESFORCE'

EXEC SF_TableLoader 'Upsert', 'SFDC_Target', 'Option__c_Stage_Split0', 'jdeOptionKey__c'

NEED: 
Sale__c
Cobuyer__c
Deposit__c
Quote?
Realtor_Registration__c
Sale_Note__c
Sale_Related_Contact__c
Survey__c
Contract_Note__c
Attachments?
contract_Data__c
Private_Wall_User_Access__c
Activities
Tasks


SELECT * FROM Lead_Stage_Split0_Result WHERE Error != 'Operation Successful.'

EXEC SF_Tableloader 'Upsert', 'SFDC_Target', 'Lead_Stage_Split0', 'Old_SF_ID__c'
ALTER TABLE Lead_Stage_Split0 ADD [Company] VARCHAR(255)

UPDATE Lead_Stage_Split0
SET Company = 'Meritage Homes'

UPDATE Lead_Stage_Split0
SET What_is_your_current_housing_status__c = 'Yes'
WHERE What_is_your_current_housing_status__c = 'Rent' OR What_is_your_current_housing_status__c = 'Rent Apartment' OR
What_is_your_current_housing_status__c = 'Rent House' OR
What_is_your_current_housing_status__c = 'Rent'

UPDATE Lead_Stage_Split0
SET What_is_your_current_housing_status__c = 'No'
WHERE What_is_your_current_housing_status__c = 'Own' OR What_is_your_current_housing_status__c = 'Own – Need to Sell' OR
What_is_your_current_housing_status__c = 'Own – No Need to Sell' OR
What_is_your_current_housing_status__c = 'Homeowner' OR
What_is_your_current_housing_status__c = 'Other'

UPDATE LEad_Stage_Split0
SET Fears_of_Moving__c = ''

UPDATE LEad_Stage_Split0
SET OwnerId = '0054D000000EC1ZQAW'
WHERE OwnerId = '' OR OwnerId IS NULL

-- ignore this
UPDATE LEad_Stage_Split0
SET Realtor_Name__c = ''

UPDATE LEad_Stage_Split0
SET How_did_you_learn_about_Meritage_Homes__c = 'Realtor recommendation'
WHERE How_did_you_learn_about_Meritage_Homes__c = 'Realtor'

UPDATE LEad_Stage_Split0
SET How_did_you_learn_about_Meritage_Homes__c = 'MeritageHomes.com'
WHERE How_did_you_learn_about_Meritage_Homes__c = 'MH.com'

EXEC sp_rename 'Lead_Stage_Split0.lender_name__c', 'Lender_Company__c', 'COLUMN'

EXEC Replace_NewIds_With_OldIds 'Lead_Stage_Split0', 'AccountXref', 'Lender_Company__c'

-- xref for Original_OSC__c and Primary_Sales_Associate__c
-- turned off fileter on Primary_Sales_Associate__c
-- ETL for lender_name__c from account to contact.... lol