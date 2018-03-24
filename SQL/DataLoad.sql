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
EXEC Insert_Accounts 'Account', 'SFDC_TARGET', 'SALESFORCE' --works
EXEC Insert_Contacts 'Contact', 'SFDC_Target', 'SALESFORCE' -- works
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
EXEc Insert_Opportunity 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW'
EXEC Insert_Sales 'Sale__c', 'SFDC_Target', 'SALESFORCE'

EXEC SF_TableLoader 'Upsert', 'SFDC_Target', 'Option__c_Stage_Split0', 'jdeOptionKey__c'

EXEC SF_Replicate 'SFDC_Target', 'Lead', 'pkchunk'
EXEC SF_Replicate 'SFDC_Target', 'Opportunity', 'pkchunk'

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
