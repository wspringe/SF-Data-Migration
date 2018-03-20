USE [SF_Data_Migration]
GO
/****** Object:  StoredProcedure [dbo].[Insert_Users]    Script Date: 12/14/2017 09:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Users] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting roles into the new Salesforce org from the old Salesforce org.

    Circular definition fields: DelegateApproverID, ManagerId, ContactId, AccountId, CallCenterId, 

    Need: Call_Center__c, Contacts

    Cross-Reference: Profiles and Roles
*/
)
AS
  declare @SQL NVARCHAR(1000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage'
  SET @targetOrgTable = @objectName + '_FromTarget'
  
  RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- Dropping table if table exists
  SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL
    DROP TABLE ' + @stagingTable
  EXEC sp_executesql @SQL
  
  RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_Replicate 'SALESFORCE', @objectName
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it
  
  RAISERROR ('Deleting customer users and User Wesley from table', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'DELETE FROM User_Stage WHERE UPPER(UserType) LIKE ''PowerCustomerSuccess'''
  EXEC sp_executesql N'DELETE FROM User_Stage WHERE UPPER(Email) LIKE ''wesley.springer@meritagehomes.com'''

  RAISERROR ('Creating Cross-Ref table for profile...', 0, 1) WITH NOWAIT
  EXEC dbo.Create_Cross_Reference_Table 'Profile', -- varchar(50)
     'Name', @targetLinkedServerName, @sourceLinkedServerName -- varchar(50)

  RAISERROR ('Creating Cross-Ref table for UserRole...', 0, 1) WITH NOWAIT
  EXEC dbo.Create_Cross_Reference_Table 'UserRole', -- varchar(50)
      'Name', @targetLinkedServerName, @sourceLinkedServerName -- varchar(50)
  
  -- rename isActive column to PreviouslyActive to keep track of if User was active before
  RAISERROR ('Renaming IsActive column to Old_SF_User_isActive__c', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'sp_rename ''User_Stage.IsActive'', ''Old_SF_User_isActive__c'', ''COLUMN'''
  
  -- Create a new IsActive column and set it to false so no users are active when inserted
  RAISERROR ('Creating new IsActive column with all users set to inactive, and creating Error column.', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'ALTER TABLE User_Stage add [IsActive] NCHAR(5)'
  EXEC sp_executesql N'UPDATE User_Stage set IsActive = ''False'''

  RAISERROR('Adding Old_SF_User_ID__c column and setting it equal to Id.', 0, 1) WITH NOWAIT
  EXEC sp_executeSQL N'ALTER TABLE User_Stage add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql N'UPDATE User_Stage SET Old_SF_ID__c = Id'
  
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

  SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL
    DROP TABLE ' + @stagingTable
  EXEC sp_executesql @SQL
  
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

  RAISERROR('Creating %s_FromTarget table if it does not already exist.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
             + char(10) + 'BEGIN'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + ''''
             + char(10) + 'EXEC sp_rename ''' + @objectName + ''',  ''' + @targetOrgTable +  ''''
             + char(10) + 'END'
  EXEC sp_executesql @SQL
  

  SET @SQL = 'DECLARE @ret_code Int' +
          char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
          BEGIN' +
            char(10) + 'RAISERROR(''Upserting table...'', 0, 1) WITH NOWAIT' +
            char(10) + 'EXEC @ret_code = SF_TableLoader ''Upsert'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable +''', ''Old_SF_ID__c''' +
            char(10) + 'IF @ret_code != 0' +
            char(10) + 'RAISERROR(''Upsert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT' +
          char(10) + 'END
        ELSE
          BEGIN' +
          char(10) + 'RAISERROR(''Inserting table...'', 0, 1) WITH NOWAIT' +
            char(10) + 'EXEC ' + '@ret_code' + '= dbo.SF_TableLoader ''Insert'', ''' + @targetLinkedServerName +''', ''' + @stagingTable + '''' +
            char(10) + 'IF ' + '@ret_code' + ' != 0' +
              char(10) + 'RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
          END'
  EXEC SP_ExecuteSQL @SQL
  GO
  


