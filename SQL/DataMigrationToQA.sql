USE [SF_Data_Migration]
EXEC Insert_Region 'Region__c', 'SALESFORCE_QA', 'SALESFORCE' --DONE
DROP TABLE Region__c_Target
EXEC Insert_Division 'Division__c', 'SALESFORCE_QA', 'SALESFORCE' --DONE
DROP TABLE Division__c_Target
EXEC Insert_CommunitySheet 'Community_Sheet__c', 'SALESFORCE_QA', 'SALESFORCE' -- DONE
EXEC Insert_Community 'Community__c', 'SALESFORCE_QA', 'SALESFORCE' -- DONE
EXEC Insert_Plan 'Plan__c', 'SALESFORCE_QA', 'SALESFORCE' -- DONE
EXEC Insert_Lot 'Lot__c', 'SALESFORCE_QA', 'SALESFORCE' -- blocked due to QA envioronment data storage limits
SELECT * FROM Lot__c_Stage_result WHERE Error != 'Operation Successful.'
EXEC Insert_Option 'Option__c', 'SALESFORCE_QA', 'SALESFORCE'
EXEC CommunitySheet_FollowUp 'Community_Sheet__c', 'Name', 'Master_Community_Sheet__c', 'SALESFORCE_QA', 'SALESFORCE' --works (nice)