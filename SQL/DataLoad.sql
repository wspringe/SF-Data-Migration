-- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
DECLARE @SQL VARCHAR(1000)
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Source'
EXEC sp_executeSQL @SQL
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Target'
EXEC sp_executeSQL @SQL

-- Custom settings
EXEC Insert_CustomSettings 'Bronto_Required_Fields__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Bronto_SubAccounts__c', 'SFDC_Target', 'SALESFORCE'
--EXEC Insert_CustomSettings 'CallCenter'
EXEC Insert_CustomSettings 'CalloutKeys__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'CC_Area_To_Process__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'CM_Trigger_Mapping__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Community_System_Settings__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'DefaultComms__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'ds_integrator_keys__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Electronic_Payment_Control__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Email_Artifacts__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'EnvisionDivisionSetup__c', 'SFDC_Target', 'SALESFORCE'
-- SetupOwnerID is Eric Peterson...? 
EXEC Insert_CustomSettings 'EPH_Approval_Hierarchical__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'FICR__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'MHDC_Integration_Keys__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Process_Bypass_Admins__c', 'SFDC_Target', 'SALESFORCE'
  -- Setup owner ID are profiles
  -- add external id of old id value to Process_Bypass_Admins__c
EXEC Insert_CustomSettings 'Process_Bypass_Case__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Process_Bypass_Contact__c', 'SFDC_Target', 'SALESFORCE'
  -- Setup owner ID are profiles
  -- add external id of old id
EXEC Insert_CustomSettings 'SaleTaskGeneration__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'SubsReqs__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'TestSkipping__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'TPSTriggerMapping__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Trigger_Bypass__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Warranty_Division_Filter__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CustomSettings 'Warranty_Vendor_Lookup__c', 'SFDC_Target', 'SALESFORCE'
-- Accounts and Contacts
EXEC Insert_Users 'User', 'SFDC_Target', 'SALESFORCE' -- works? Cant update user records though I guess... at least not contactId (test this again)
EXEC Insert_Region 'Region__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Division 'Division__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_MarketingArea 'Marketing_Area__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Accounts 'Account', 'SFDC_TARGET', 'SALESFORCE2' --works
EXEC Insert_Contacts 'Contact', 'SFDC_Target', 'SALESFORCE' -- works
EXEC User_FollowUp 'User', 'SFDC_Target', 'SALESFORCE' -- cant do


-- Community and Community Sheet
EXEC Insert_LoanType 'Loan_Type__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_CommunitySheet 'Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --Done, turned off filter on Division__c field.
EXEC Insert_Community 'Community__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE, turned off filter on Sales_Manager__c since user has to be active.
EXEC Insert_CommunityPlanMaster 'Community_Plan_Master__c', 'SFDC_Target', 'SALESFORCE' -- Done had to turn off validation rule on master_bedroom_location__c


-- Important Sale and Sale prereqs
EXEC Insert_Plan 'Plan__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE
EXEC Insert_Lot 'Lot__c', 'SFDC_Target', 'SALESFORCE' -- blocked due to QA envioronment data storage limits
EXEC Insert_Option 'Option__c', 'SFDC_Target', 'SALESFORCE' -- done
EXEC CommunitySheet_FollowUp 'Community_Sheet__c', 'Name', 'Master_Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --works (nice)
EXEC Insert_Lead 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW' --good
EXEc Insert_Opportunity 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW' -- turned off filter on Realtor_Name__c and Lender_Name__c
EXEC Insert_Sales 'Sale__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Sale_FollowUp 'Sale__c', 'Transfer_From_Sale__c', 'SFDC_Target', 'SALESFORCE2' --good
EXEC Sale_FollowUp 'Sale__c', 'Transfer_To_Sale__c', 'SFDC_Target', 'SALESFORCE2' --good


-- things that depended on Sale
EXEC Insert_ApprovalActor 'Approval_Actor__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_BrontoMessages 'Bronto_Messages__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_BrontoDeliveries 'Bronto_Deliveries__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_BrontoCampaignResponse 'Bronto_Campaign_Response__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_CampaignTracker 'Campaign_Tracker__c', 'SFDC_Target', 'SALESFORCE' -- works, turn off filter on division__c
EXEC Insert_CampaignTrackerMediaSource 'Campaign_Tracker_Media_Source__c', 'SFDC_Target', 'SALESFORCE' -- works, turn off filter on division__c
EXEC Insert_CommunityUsersContacts 'Community_Users_Contacts__c', 'SFDC_Target', 'SALESFORCE' -- issue in that Users in it have the odd profiles and roles
EXEC Insert_ContractManagementTracker 'Contract_Management_Tracker__c', 'SFDC_Target', 'SALESFORCE' -- works!
EXEC Insert_ContractManagementAttachment 'Contract_Management_Attachment__c', 'SFDC_Target', 'SALESFORCE' --done
EXEC Insert_DivisionAttachment 'Division_Attachment__c', 'SFDC_Target', 'SALESFORCE' -- done
EXEC Insert_DivisionContact 'Division_Contact__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c


-- Community_Sheet_X objects and their prereqs 
EXEC Insert_Neighborhood 'Neighborhood__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c
EXEC Insert_School 'School__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c
EXEC School_FollowUp 'School__c', 'Name', 'School_District__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_TradePartnerSetup 'Trade_Partner_Setup__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c
EXEC Insert_TPSAttachment 'TPSAttachment__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c
EXEC Insert_UserDefinedCodeValue 'User_Defined_Code_Value__c', 'SFDC_Target', 'SALESFORCE' -- done, turned off filter on division__c
EXEC Insert_CommunitySheetDescription 'Community_Sheet_Description__c', 'SFDC_Target', 'SALESFORCE' -- done
EXEC Insert_Freeway 'Freeway__c', 'SFDC_Target', 'SALESFORCE' -- good
EXEC Insert_CommunitySheetFreeway 'Community_Sheet_Freeway__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetHours 'Community_Sheet_Hours__c', 'SFDC_Target', 'SALESFORCE' --good
--EXEC Insert_CommunitySheetIntegration 'Community_Sheet_Integration__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetMarketingArea 'Community_Sheet_Marketing_Area__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetMTHContacts 'Community_Sheet_MTH_Contacts__c', 'SFDC_Target', 'SALESFORCE2' -- Ask about putting back in linked server SALESFORCE, figure out why type isnt going through on accounts or contacts because i turned off filters on MTH__c and MTH_Contact__c
EXEC Insert_NearbyLocation 'Nearby_Location__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetNearbyLocation 'Community_Sheet_Nearby_Location__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetNeighborhood 'Community_Sheet_Neighborhood__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetSalesContact 'Community_Sheet_Sales_Contact__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetSchool 'Community_Sheet_School__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_PublicTransportation 'Public_Transportation__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunitySheetTransportation 'Community_Sheet_Transportation__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_AreaPlanMasterLink 'Area_Plan_Master_Link__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunityPlanMaster 'Community_Plan_Master__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_Feature 'Feature__c', 'SFDC_Target', 'SALESFORCE' --good
EXEC Insert_CommunityPlanMasterFeature 'Community_Plan_Master_Feature__c', 'SFDC_Target', 'SALESFORCE' --good


-- More items that depended on Sale
EXEC Insert_Cobuyer 'Cobuyer__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Insert_Addendum 'Addendum__c', 'SFDC_Target', 'SALESFORCE2' -- done
EXEC Insert_BudgetTracker 'Budget_Maintenance_Tracker__c', 'SFDC_Target', 'SALESFORCE2' --works
EXEC Insert_WarrantyHomeOwner 'Warranty_Home_Owner__c', 'SFDC_Target', 'SALESFORCE2', '0054D000000EC1ZQAW' --done lol, made oownerid nullable
EXEC Insert_E1LegalCodes 'E1_Legal_Codes__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Group 'Group', 'SFDC_Target', 'SALESFORCE', '00D4D0000008fi3' --good


-- Warranty items and their prereqs
EXEC Insert_Case 'Case', 'SFDC_Target', 'SALESFORCE2', '0054D000000EC1ZQAW' --good
EXEC Insert_CCPrivateChatterWall 'CC_Private_Chatter_Wall__c', 'SFDc_Target', 'SALESFORCE2' --Done, tested
EXEC Insert_MobileWhiteList 'MobileWhiteList__c', 'SFDC_Target', 'SALESFORCE2' --Done, tested
EXEC Insert_GiftCardTracking 'Gift_Card_Tracking__c', 'SFDC_Target', 'SALESFORCE2' --Done, tested
EXEC Insert_ClientRegistration 'Client_Registration__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_CommissionAssumption 'Commission_Assumption__c', 'SFDC_Target', 'SALESFORCE2' -- Done, tested
EXEC Insert_CustomOptionTracker 'Custom_Option_Tracker__c', 'SFDC_Target', 'SALESFORCE2' -- turned off filters on all fields, tested and works
EXEC Insert_WorkOrder 'WorkOrder', 'SFDC_Target', 'SALESFORCE2' --Works, gonna need another test
EXEC WorkOrder_FollowUp 'WorkOrder', 'RootWorkOrderId', 'SFDC_Target', 'SALESFORCE2' --Works
EXEC WorkOrder_FollowUp 'WorkOrder', 'ParentWorkOrderId', 'SFDC_Target', 'SALESFORCE2' --Works
EXEC Insert_WarrantyVendor 'Warranty_Vendor__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_WarrantyAppointment 'Warranty_Appointment__c', 'SFDC_Target', 'SALESFORCE2' --works
EXEC Insert_WarrantyConfirmation 'Warranty_Confirmation__c', 'SFDC_Target', 'SALESFORCE2' --works well
EXEC Insert_MHWorkOrder 'MH_Work_Order__c', 'SFDC_Target', 'SALESFORCE2' -- works!


-- Depended on having Case/MH Work Order
EXEC Insert_DataStagingHeader 'Data_Staging_Header__c', 'SFDC_Target', 'SALESFORCE2' -- works
EXEC Insert_DataStagingDetailWarranty 'Data_Staging_Detail_Warranty__c', 'SFDC_Target', 'SALESFORCE2' -- works
EXEC Insert_DataStagingDetail 'Data_Staging_Detail__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_Deposit 'Deposit__c', 'SFDC_Target', 'SALESFORCE2' -- works
EXEC Insert_EnvisionDCMDSD 'EnvisionDCM_DSD__c', 'SFDC_Target', 'SALESFORCE2' --good
EXEC Insert_GoogleAdwordsTracking 'Google_Adwords_Tracking__c', 'SFDC_target', 'SALESFORCE2' -- works



-- Old, forgotten objects that should be moved highr on the list 
EXEC Insert_IncentiveMaster 'Incentive_Master__c', 'SFDC_Target', 'SALESFORCE2' --works
EXEC Insert_Incentive 'Incentive__c', 'SFDC_target', 'SALESFORCE2' -- unable to lock row
EXEC Insert_LandTracker 'Land_Tracker__c', 'SFDC_target', 'SALESFORCE2' --good
EXEC Insert_LotFeature 'Lot_Feature__c', 'SFDC_target', 'SALESFORCE2' -- good
EXEC Insert_LotOptionNote 'Lot_Option_Note__c', 'SFDC_target', 'SALESFORCE2' --good
EXEC Insert_LotStarts 'Lot_Starts__c', 'SFDC_target', 'SALESFORCE2' -- turned off filter on lot__c --turned off all validated rules and all filters
EXEC Insert_OptionSelection 'Option_Selection__c', 'SFDC_target', 'SALESFORCE2'
EXEC Insert_Incentive 'Incentive__c', 'SFDC_target', 'SALESFORCE2' -- works
EXEC Insert_RealtorRegistration 'Realtor_Registration__c', 'SFDC_target', 'SALESFORCE2' --good
EXEC Insert_SaleNote 'Sale_Note__c', 'SFDC_target', 'SALESFORCE2' -- works
EXEC Insert_SaleRelatedContact 'Sale_Related_Contact__c', 'SFDC_target', 'SALESFORCE2' --gud
EXEC Insert_SalesKiosk 'Sales_Kiosk__c', 'SFDC_target', 'SALESFORCE2' --gud
EXEC Insert_Subscription 'Subscription__c', 'SFDC_target', 'SALESFORCE2' --good
EXEC Insert_Traffic 'Traffic__c', 'SFDC_target', 'SALESFORCE2' --good
EXEC Insert_WarrantyEmail 'Warranty_Email__c', 'SFDC_target', 'SALESFORCE2' -- werks

-- Events and Tasks
EXEC Insert_Task 'Task', 'SFDC_Target', 'SALESFORCE2' --good, but takes a cery long time, need to test how big tables can be to upload
EXEC Insert_Event 'Event', 'SFDC_Target', 'SALESFORCE2' --good


SELECT * FROM Event_Stage_Split0_Result WHERE Error != 'Operation Successful.'


DROP TABle data_staging_Header__c_Source
DROP TABLE data_staging_header__C_TARGEt

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

EXEC Replace_NewIds_With_OldIds 'Warranty_Vendor__c_Stage_Split0', 'Lot__cXref', 'Lot__c'
/* NEED TO DO:
A-Prospect and B-Prospect Active now owned by an SA can be moved to C-Inactive = Lead Nurturing
Active Leads without a PSA assign to IS
A-Prospect inavtive and B-Prospect Inactive can be moved to nurturing lead
C-Active not owned by an IS can be moved to lead nurturing
E- Active not owned by SA or IS can be mobed to Nurturing LEad