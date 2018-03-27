-- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
DECLARE @SQL VARCHAR(1000)
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Source'
EXEC sp_executeSQL @SQL
SET @SQL = ''
SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '%_Target'
EXEC sp_executeSQL @SQL


-- Accounts and Contacts
EXEC Insert_Users 'User', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Region 'Region__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Division 'Division__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_MarketingArea 'Marketing_Area__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_Accounts 'Account', 'SFDC_TARGET', 'SALESFORCE2' --works
EXEC Insert_Contacts 'Contact', 'SFDC_Target', 'SALESFORCE' -- works
EXEC User_FollowUp 'User', 'SFDC_Target', 'SALESFORCE'


-- Community and Community Sheet
EXEC Insert_LoanType 'Loan_Type__c', 'SFDC_Target', 'SALESFORCE' -- works
EXEC Insert_CommunitySheet 'Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --Done, turned off filter on Division__c field.
EXEC Insert_Community 'Community__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE, turned off filter on Sales_Manager__c since user has to be active.
EXEC Insert_CommunityPlanMaster 'Community_Plan_Master__c', 'SFDC_Target', 'SALESFORCE' -- Done had to turn off validation rule on master_bedroom_location__c


-- Important Sale and Sale prereqs
EXEC Insert_Plan 'Plan__c', 'SFDC_TARGET', 'SALESFORCE' -- DONE
EXEC Insert_Lot 'Lot__c', 'SFDC_Target', 'SALESFORCE' -- blocked due to QA envioronment data storage limits
EXEC Insert_Option 'Option__c', 'SFDC_Target', 'SALESFORCE'
EXEC CommunitySheet_FollowUp 'Community_Sheet__c', 'Name', 'Master_Community_Sheet__c', 'SFDC_Target', 'SALESFORCE' --works (nice)
EXEC Insert_Lead 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW'
EXEc Insert_Opportunity 'Opportunity__c', 'SFDC_Target', 'SALESFORCE', '0054D000000EC1ZQAW' -- turned off filter on Realtor_Name__c and Lender_Name__c
EXEC Insert_Sales 'Sale__c', 'SFDC_Target', 'SALESFORCE'
EXEC Sale_FollowUp 'Sale__c', 'Transfer_From_Sale__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Sale_FollowUp 'Sale__c', 'Transfer_To_Sale__c', 'SFDC_Target', 'SALESFORCE2'


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
EXEC Insert_CommunitySheetDescription 'Community_Sheet_Description__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Freeway 'Freeway__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetFreeway 'Community_Sheet_Freeway__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetHours 'Community_Sheet_Hours__c', 'SFDC_Target', 'SALESFORCE'
--EXEC Insert_CommunitySheetIntegration 'Community_Sheet_Integration__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetMarketingArea 'Community_Sheet_Marketing_Area__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetMTHContacts 'Community_Sheet_MTH_Contacts__c', 'SFDC_Target', 'SALESFORCE2' -- Ask about putting back in linked server SALESFORCE, figure out why type isnt going through on accounts or contacts because i turned off filters on MTH__c and MTH_Contact__c
EXEC Insert_NearbyLocation 'Nearby_Location__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetNearbyLocation 'Community_Sheet_Nearby_Location__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetNeighborhood 'Community_Sheet_Neighborhood__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetSalesContact 'Community_Sheet_Sales_Contact__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetSchool 'Community_Sheet_School__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_PublicTransportation 'Public_Transportation__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunitySheetTransportation 'Community_Sheet_Transportation__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_AreaPlanMasterLink 'Area_Plan_Master_Link__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunityPlanMaster 'Community_Plan_Master__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Feature 'Feature__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_CommunityPlanMasterFeature 'Community_Plan_Master_Feature__c', 'SFDC_Target', 'SALESFORCE'


-- More items that depended on Sale
EXEC Insert_Cobuyer 'Cobuyer__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Insert_Addendum 'Addendum__c', 'SFDC_Target', 'SALESFORCE2' -- done
EXEC Insert_BudgetTracker 'Budget_Maintenance_Tracker__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Insert_WarrantyHomeOwner 'Warranty_Home_Owner__c', 'SFDC_Target', 'SALESFORCE2', '0054D000000EC1ZQAW' --done lol, made oownerid nullable
EXEC Insert_E1LegalCodes 'E1_Legal_Codes__c', 'SFDC_Target', 'SALESFORCE'
EXEC Insert_Group 'Group', 'SFDC_Target', 'SALESFORCE', '00D4D0000008fi3'


-- Warranty items and their prereqs
EXEC Insert_Case 'Case', 'SFDC_Target', 'SALESFORCE2', '0054D000000EC1ZQAW'
EXEC Insert_CCPrivateChatterWall 'CC_Private_Chatter_Wall__c', 'SFDc_Target', 'SALESFORCE2' --untested
EXEC Insert_MobileWhiteList 'MobileWhiteList__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_GiftCardTracking 'Gift_Card_Tracking__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_ClientRegistration 'Client_Registration__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_CommissionAssumption 'Commission_Assumption__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_CustomOptionTracker 'Custom_Option_Tracker__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_WorkOrder 'WorkOrder', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC WorkOrder_FollowUp 'WorkOrder', 'RootWorkOrderId', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC WorkOrder_FollowUp 'WorkOrder', 'ParentWorkOrderId', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_WarrantyVendor 'Warranty_Vendor__c', 'SFDC_Target', 'SALESFORCE2' --untested
EXEC Insert_WarrantyAppointment 'Warranty_Appointment__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Insert_WarrantyConfirmation 'Warranty_Confirmation__c', 'SFDC_Target', 'SALESFORCE2'
EXEC Insert_MHWorkOrder 'MH_Work_Order__c', 'SFDC_Target', 'SALESFORCE2'


SELECT * FROM Opportunity_Stage_Result WHERE Error != 'Operation Successful.'

DROP TABLE Opportunity_Source
DROP TABLE opportunity_TARGEt

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