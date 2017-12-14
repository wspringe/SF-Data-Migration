/*
    This stored procedure is used for inserting roles into the new Salesforce org from the old Salesforce org.
    Circular definition fields: ParentRoleId, PortalAccountId, PortalAccountOwnerId
    Need: Roles, Accounts, Users
*/

USE [SF_Data_Migration]
GO
/****** Object:  StoredProcedure [dbo].[Insert_UserRole]    Script Date: 12/14/2017 09:14:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_UserRole] (
  @objectName VARCHAR(50)
)
AS
  DECLARE @stagingTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage' 
  
  RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- Dropping table if table exists
  IF OBJECT_ID('dbo.UserRole_Stage', 'U') IS NOT NULL
    DROP TABLE dbo.UserRole_Stage
  
  RAISERROR ('Replicating table from source org...', 0, 1) WITH NOWAIT
  -- getting table from source prod org
  EXEC SF_Replicate 'SALESFORCE', @objectName
  --Err handling:
  if @@ERROR != 0 
	print 'Error replicating ' + @objectName
  RAISERROR ('Done.', 0, 1) WITH NOWAIT
  
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it
  
  -- Deleting Customer Portal roles
  RAISERROR ('Deleting rows that are unneeded...', 0, 1) WITH NOWAIT
  EXEC sp_executesql N'DELETE FROM UserRole_Stage WHERE UPPER(PortalType) LIKE ''CustomerPortal'''

  ------------------------------------------------------
  -- Set the following fields in the table to empty, and will have to update these fields later; this will have to be changed for each object
  
  declare @SQL NVARCHAR(200)
  
  RAISERROR ('Setting circular definition fields to NULL.', 0, 1) WITH NOWAIT
  set @SQL =   'UPDATE ' + @stagingTable  + ' set ParentRoleId = NULL, PortalAccountId = NULL, PortalAccountOwnerId = NULL '
  exec sp_executesql @sql 
  
  EXEC sp_executesql N'ALTER TABLE UserRole_Stage ADD Error NVARCHAR(255) NULL'
   

  ------------------------------------------------------
  -- Trying to upsert to target org
  RAISERROR ('Upserting to target org...', 0, 1) WITH NOWAIT
  EXEC dbo.SF_BulkOps 'Insert', 'SFDC_TARGET', 'UserRole_Stage'
  EXEC dbo.SF_BulkOps 'Update', 'SFDC_TARGET', 'UserRole_Stage'
  RAISERROR ('Done.', 0, 1) WITH NOWAIT