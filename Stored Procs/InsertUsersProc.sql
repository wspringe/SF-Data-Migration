USE SF_Data_Migration
GO
CREATE PROCEDURE [dbo].[Insert_Users] (
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
  SET @stagingTable = @objectName + '_Stage' 
	EXEC SF_Replicate 'SALESFORCE', @objectName
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  -- Replicate profile object from current org and rename it to Profile_Source
  EXEC SF_Replicate 'SALESFORCE', 'Profile'
  EXEC sp_rename 'Profile', 'Profile_Source'

  -- Replicate profile object from target org and rename it to Profile_Target
  EXEC SF_Replicate 'SFDC_Target', 'Profile'
  EXEC sp_rename 'Profile', 'Profile_Target'

  -- Create a table for Profile cross-referencing
  EXEC sp_executesql N'SELECT s.Id, s.NAME
	INTO ProfileXRef
  FROM dbo.Profile_Source s'
  
  -- Change column name to SourceID from Id
  EXEC sp_executesql N'sp_rename ''ProfileXRef.Id'', ''SourceID'', ''COLUMN'''
  
  -- Add a new column of Target Id to ProfileXRef 
  EXEC sp_executesql N'ALTER TABLE ProfileXRef add [TargetID] NCHAR(18)'
  
  -- Set TargetID column to Ids of Profile_Source
  EXEC sp_executesql N'UPDATE dbo.ProfileXRef
	set TargetID = t.Id
	FROM Profile_Target t JOIN ProfileXRef s
		on t.Name = s.Name'

  -- Replicate UserRole object from current org and rename it to UserRole_Source
  EXEC SF_Replicate 'SALESFORCE', 'UserRole'
  EXEC sp_rename 'UserRole', 'UserRole_Source'

  -- Replicate UserRole object from target org and rename it to UserRole_Target
  EXEC SF_Replicate 'SFDC_Target', 'UserRole'
  EXEC sp_rename 'UserRole', 'UserRole_Target'

  -- Create UserRole cross-reference table
  EXEC sp_executesql N'SELECT s.Id, s.NAME
	INTO UserRoleXRef
  FROM dbo.UserRole_Source s'
  
   -- Change column name to SourceID from Id
  EXEC sp_executesql N'sp_rename ''UserRoleXRef.Id'', ''SourceID'', ''COLUMN'''
  
  -- Add new column of TargetID to UserRoleXRef table
  EXEC sp_executesql N'ALTER TABLE UserRoleXRef add [TargetID] NCHAR(18)'

  -- Fill in the TargetId column
  EXEC sp_executesql N'UPDATE dbo.UserRoleXRef
	set TargetID = t.Id
	FROM UserRole_Target t JOIN UserRoleXRef s
		on t.Name = s.Name'

  ------------------------------------------------------
  -- Set the following fields in the table to empty, and will have to update these fields later; this will have to be changed for each object
  
  set @SQL = 'UPDATE ' + @stagingTable + ' set DelegatedApproverId = NULL, ManagerId = NULL, ContactId = NULL, AccountId = NULL, CallCenterId = NULL'
  exec sp_executesql @SQL
  ------------------------------------------------------

  -- Update User_Stage with new ProfileIds from the cross-reference table
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

	-- EXEC dbo.SF_BulkOps @operation = 'Insert', -- nvarchar(200)
	--     @table_server = 'SFDC_Target', -- sysname
	--     @table_name = @stagingTable -- sysname

  GO
