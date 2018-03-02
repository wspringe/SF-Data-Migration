USE [SF_Data_Migration]
EXEC Insert_Region 'Region__c', 'SALESFORCE_QA', 'SALESFORCE' --DONE
DROP TABLE Region__c_Target
EXEC Insert_Division 'Division__c', 'SALESFORCE_QA', 'SALESFORCE' --DONE
DROP TABLE Division__c_Target
EXEC Insert_CommunitySheet 'Community_Sheet__c', 'SALESFORCE_QA', 'SALESFORCE' -- DONE
EXEC Insert_Community 'Community__c', 'SALESFORCE_QA', 'SALESFORCE' -- DONE
