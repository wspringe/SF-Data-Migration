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

-- spot for inserting Area_Plan_Master_Link - have to revisit to add related list of community plan plaster which has community
EXEC Insert_AreaPlanMasterLink 'Area_Plan_Master_Link__c'
