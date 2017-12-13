USE SF_Data_Migration
GO
CREATE PROCEDURE [dbo].[Upsert_Users] (
  @objectName VARCHAR(50)

  /*
    This stored procedure is used for inserting roles into the new Salesforce org from the old Salesforce org.

    Circular definition fields: DelegateApproverID, ManagerId, ContactId, AccountId, CallCenterId, 

    Need: Call_Center__c, Contacts

    Cross-Reference: Profiles and Roles
*/
)
AS
  declare @SQL NVARCHAR(250)
  DECLARE @stagingTable VARCHAR(50)
  SET @stagingTable = @objectName + '_UpsertStage' 
  
  RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_Replicate 'SALESFORCE', @objectName
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Profile_Source')
    DROP TABLE Profile_Source
  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Profile_Target')
    DROP TABLE Profile_Target
  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProfileXRef')
    DROP TABLE ProfileXRef
  EXEC dbo.Create_Cross_Reference_Table @objectName = 'Profile', -- varchar(50)
     @uniqueIdentifier = 'Name' -- varchar(50)

  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserRole_Source')
    DROP TABLE Profile_Source
  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserRole_Target')
    DROP TABLE Profile_Target
  IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserRoleXRef')
    DROP TABLE ProfileXRef
  EXEC dbo.Create_Cross_Reference_Table @objectName = 'UserRole', -- varchar(50)
      @uniqueIdentifier = 'Name' -- varchar(50)
  
  -- rename isActive column to PreviouslyActive to keep track of if User was active before
  RAISERROR ('Renaming IsActive column to PreviouslyActive', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'sp_rename ''User_Stage.IsActive'', ''PreviouslyActive'', ''COLUMN'''
  
  -- Create a new IsActive column and set it to false so no users are active when inserted
  RAISERROR ('Creating new IsActive column with all users set to inactive.', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'ALTER TABLE User_Stage add [IsActive] NCHAR(5)'
  EXEC sp_executesql N'UPDATE User_Stage set IsActive = ''False'''
  
  RAISERROR ('Dropping unnecessary columns.', 0, 1) WITH NOWAIT
  EXEC sp_executeSQL N'ALTER TABLE User_Stage DROP COLUMN
						BMCServiceDesk__Account__c,
						BMCServiceDesk__Account_ID__c,
						BMCServiceDesk__Account_Name__c,
						BMCServiceDesk__AssetManagementView__c,
						BMCServiceDesk__AssignRemedyforceLic__c,
						BMCServiceDesk__Broadcast_ticker_speed__c,
						BMCServiceDesk__Building__c,
						BMCServiceDesk__Business_Hours__c,
						BMCServiceDesk__Business_Hours_ID__c,
						BMCServiceDesk__ChatStatus__c,
						BMCServiceDesk__CIManagementView__c,
						BMCServiceDesk__ContactId__c,
						BMCServiceDesk__EnableChat__c,
						BMCServiceDesk__Extension__c,
						BMCServiceDesk__FP_Login_Validated__c,
						BMCServiceDesk__FPLoginID__c,
						BMCServiceDesk__ImageName__c,
						BMCServiceDesk__IsOutOfOffice__c,
						BMCServiceDesk__IsRemedyforceAdministrator__c,
						BMCServiceDesk__IsStaffUser__c,
						BMCServiceDesk__LastAvailableTime__c,
						BMCServiceDesk__LastChatEndTime__c,
						BMCServiceDesk__Manage_ServiceDesk_Staff_Member__c,
						BMCServiceDesk__Note__c,
						BMCServiceDesk__pager__c,
						BMCServiceDesk__Picture__c,
						BMCServiceDesk__remarks__c,
						BMCServiceDesk__Remedyforce_Casual_User__c,
						BMCServiceDesk__Remedyforce_Knowledge_User__c,
						BMCServiceDesk__Room__c,
						BMCServiceDesk__SelfService_Preferences__c,
						BMCServiceDesk__skipQVWizIntro__c,
						BMCServiceDesk__UniqueUserIDInSource__c,
						BMCServiceDesk__VIP__c'
  ------------------------------------------------------
  -- Set the following fields in the table to empty, and will have to update these fields later; this will have to be changed for each object
  
  RAISERROR ('Setting circular definition fields in %s table to NULL.', 0, 1, @objectName) WITH NOWAIT
  set @SQL = 'UPDATE ' + @stagingTable + ' set DelegatedApproverId = NULL, ManagerId = NULL, ContactId = NULL, AccountId = NULL, CallCenterId = NULL'
  exec sp_executesql @SQL
  ------------------------------------------------------

  -- Update User_Stage with new ProfileIds from the cross-reference table
  RAISERROR ('Updating Profile and UserRole columns with IDs from target org...', 0, 1) WITH NOWAIT
  set @SQL = 'update ' + @stagingTable +
  ' set ProfileId = x.TargetID
  FROM ProfileXRef x 
  WHERE x.SourceID = ' + @stagingTable + '.ProfileId'

  exec sp_executesql @SQL

  -- Update User_Stage with new UserRoleIds from the cross-reference table
  set @SQL = 'update ' + @stagingTable +
  ' set UserRoleId = x.TargetID
  FROM UserRoleXRef x 
  WHERE x.SourceID = ' + @stagingTable + '.UserRoleId'

  exec sp_executesql @SQL
  
  RAISERROR ('Done.', 0, 1) WITH NOWAIT

	--EXEC dbo.SF_BulkOps @operation = 'Upsert', SFDC_Target, @stagingTable, 'Email__c'

  GO