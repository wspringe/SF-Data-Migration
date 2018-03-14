EXEC Insert_CustomSettings 'Bronto_Required_Fields__c'
EXEC Insert_CustomSettings 'Bronto_SubAccounts__c'
--EXEC Insert_CustomSettings 'CallCenter'
EXEC Insert_CustomSettings 'CalloutKeys__c'
EXEC Insert_CustomSettings 'CC_Area_To_Process__c'
EXEC Insert_CustomSettings 'CM_Trigger_Mapping__c'
EXEC Insert_CustomSettings 'Community_System_Settings__c'
EXEC Insert_CustomSettings 'DefaultComms__c'
EXEC Insert_CustomSettings 'ds_integrator_keys__c'
EXEC Insert_CustomSettings 'Electronic_Payment_Control__c'
EXEC Insert_CustomSettings 'Email_Artifacts__c'
EXEC Insert_CustomSettings 'EnvisionDivisionSetup__c'
-- SetupOwnerID is Eric Peterson...? EXEC Insert_CustomSettings 'EPH_Approval_Hierarchical__c'
EXEC Insert_CustomSettings 'FICR__c'
EXEC Insert_CustomSettings 'MHDC_Integration_Keys__c'
EXEC Insert_CustomSettings 'Process_Bypass_Admins__c' 
  -- Setup owner ID are profiles
  -- add external id of old id value to Process_Bypass_Admins__c
EXEC Insert_CustomSettings 'Process_Bypass_Case__c'
EXEC Insert_CustomSettings 'Process_Bypass_Contact__c'
  -- Setup owner ID are profiles
  -- add external id of old id
EXEC Insert_CustomSettings 'SaleTaskGeneration__c'
EXEC Insert_CustomSettings 'SubsReqs__c'
EXEC Insert_CustomSettings 'TestSkipping__c'
EXEC Insert_CustomSettings 'TPSTriggerMapping__c'
EXEC Insert_CustomSettings 'Trigger_Bypass__c'
EXEC Insert_CustomSettings 'Warranty_Division_Filter__c'
EXEC Insert_CustomSettings 'Warranty_Vendor_Lookup__c'

-- spot for inserting Area_Plan_Master_Link - have to revisit to add related list of community plan master which has community
EXEC Insert_AreaPlanMasterLink 'Area_Plan_Master_Link__c'
EXEC Insert_CastIronLastRunTime 'CastIronLastRunTime__c'
EXEC Insert_CostCode 'Cost_Code__c'
EXEC Insert_DesignCenter 'Design_Center__c'
EXEC Insert_E1LegalCodes 'E1_Legal_Codes__c'
EXEC Insert_Employee 'Employee__c'
EXEC Insert_Feature 'Feature__c'
EXEC Insert_Freeway 'Freeway__c'
EXEC Insert_GiftCardTracking 'Gift_Card_Tracking__c'
EXEC Insert_LoanType 'Loan_Type__c'
EXEC Insert_MarketingIntegrationNextNumber 'Marketing_Integration_Next_Number__c'
EXEC Insert_MHDCIntegration 'MHDC_Integration__c' -- over 300k records
EXEC Insert_NearbyLocation 'Nearby_Location__c'-- NOTE TURN OFF URL VALIDATION RULE BEFORE MIGRATING, THEN TURN BACK ON
EXEC Insert_Option 'Option__c' -- over 3 million records
EXEC Insert_PublicTransportation 'Public_Transportation__c'
EXEC Insert_Region 'Region__c'
EXEC Insert_SolarAddendum 'Solar_Addendum__c'
EXEC Insert_SolarAddendumDetail 'Solar_Addedum_Detail__c' -- Misspelled object name
EXEC Insert_UserDefinedCodeTypes 'User_Defined_Code_Types__c'
EXEC Insert_Division 'Division__c' -- loop back to update Design_center__c and title_company__c with accounts once accounts is done
EXEC Insert_Accounts 'Account', 'SFDC_Target', 'SALESFORCE' -- wprk on this
EXEC Insert_MarketingArea 'Marketing_Area__c'
EXEC Insert_Contacts 'Contact', 'SFDC_Target', 'SALESFORCE' -- work on this
EXEC Insert_SunPowerRecord 'Sun_Power_record__c', 'SFDC_Target', 'Salesforce' -- look at this when get more than 3GB of fucking RAM
EXEC Insert_BrontoMessages 'Bronto_Messages__c', 'SFDC_Target', 'Salesforce' -- not tested yet, add only records from 2018
EXEC Insert_ApprovalActor 'Approval_Actor__c', 'SFDC_Target', 'Salesforce' -- not tested yet
EXEC Insert_BrontoDeliveries 'Bronto_Deliveries__c', 'SFDC_Target', 'Salesforce' -- not tested yet
EXEC Insert_BrontoCampaignResponse 'Bronto_Campaign_Response__c', 'SFDC_Target', 'SALESFORCE' -- not tested yet, will take a while cuz over 17 mill records
EXEC Insert_CampaignTracker 'Campaign_Tracker__c', 'SFDC_Target', 'SALESFORCE' -- not tested yet
EXEC Insert_CampaignTrackerMediaSource 'Campaign_Tracker_Media_Source__c', 'SFDC_Target', 'SALESFORCE' --not tested yet
EXEC Insert_Communitysheet 'Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' -- not tested yet
EXEC Insert_CommunitySheet_FollowUp 'Community_Sheet__c', 'Name', 'Master_Community_Sheet__c', 'SFDC_Target', 'Salesforce' -- not tested yet
EXEC Insert_Community 'Community__c', 'SFDC_Target', 'Salesforce' -- not edited yet
EXEC Insert_Plan 'Plan__c', 'SFDC_Target', 'Salesforce'
EXEC Insert_CommunityUsersContacts 'Community_Users_Contacts__s', 'SFDC_Target', 'SALESFORCE'







 ----------------------------------- TESTING AREA  -----------------------------------
IF (SELECT IsPersonAccount FROM Contact_Stage) = 'True'
print('hello')

UPDATE Contact_Stage
SET RecordTypeId = '0124D0000008nOYQAY'
WHERE IsPersonAccount = 'true' OR RecordTypeID IS NULL


EXEC SF_Tableloader 'Upsert', 'SFDC_Target', 'Contact_Stage', 'Old_SF_ID__c'

-- following takes 15 minutes to complete on 1,000,000 rows
DECLARE @SQL NVARCHAR(1000)
DECLARE @i INT = 0
WHILE @i < 10
BEGIN
    SET @SQL = 'SELECT * 
    INTO Contact_Stage_Split' + CAST(@i AS NVARCHAR(2)) + '
    FROM (SELECT *, ROW_NUMBER() OVER (ORDER BY Id) AS rn FROM Contact_Stage) T1
    WHERE rn % 5 = ' + CAST(@i AS NVARCHAR(2))
    SET @i = @i + 1
    EXEC sp_executeSQL @SQL
END

DECLARE @SQL NVARCHAR(1000)
DECLARE @i INT = 0
WHILE @i < 10
BEGIN
    SET @SQL = 'EXEC SF_Tableloader ''Upsert'', ''SFDC_Target'', ''Contact_Stage_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
    SET @i = @i + 1
    EXEC sp_executeSQL @SQL
END

ALTER TABLE Account_Stage DROP COLUMN Sort

SELECT rn = Row_Number() OVER (Order by Id), * INTO Bronto_Campaign_Response__c_Stage FROM Bronto_Campaign_Response__c --takes 24 min
SELECT * FROM Bronto_Campaign_Response__c_Stage
SELECT MAX(Rownum) FROM Account_Stage
SELECT ROW FROM Account_Stage
ALTER TABLE Bronto_Campaign_Response__c ADD [Sort] INT IDENTITY (1,1)

EXEC SF_Replicate 'SALESFORCE', 'Bronto_Campaign_Response__c', 'pkchunk'
EXEC Create_Id_Based_Cross_Reference_Table 'Account', 'SFDC_Target', 'SALESFORCE'
DROP TABLE Account_Source, Account_Target
SELECT * FROM AccountXref

DROP TABLE Contact_Source, Contact_Target
EXEC SF_Replicate 'Salesforce', 'Community__c', 'pkchunk'
EXEC sp_rename 'Community__c', 'Community__c_Stage'

DECLARE @stagingTable VARCHAR(50) = 'Community__c_Stage'
DECLARE @targetLinkedServerName VARCHAR(50) = 'SFDC_Target'
DECLARE @sourceLinkedServerName VARCHAR(50) = 'SALESFORCE'
EXEC Create_Cross_Reference_Table 'Division__c', 'Name', @targetLinkedServerName, @sourceLinkedServerName
EXEC Create_Cross_Reference_Table 'Community_Sheet__c', 'Name', @targetLinkedServerName, @sourceLinkedServerName
EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
EXEC Create_Id_Based_Cross_Reference_Table 'Contact', @targetLinkedServerName, @sourceLinkedServerName
EXEC Replace_NewIds_With_OldIds @stagingTable, 'Division__cXref', 'Division__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'Community_Sheet__cXref', 'Community_Sheet__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Design_Center__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'DocuSign_Carbon_Copy_1__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'DocuSign_Carbon_Copy_2__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Escrow_Coordinator__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Homeowners_Association__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXref', 'Preferred_Lender_Contact__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXref', 'Preferred_Lender_Contact_Alternate__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Sales_Manager__c'
EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXref', 'Title_Contact__c'