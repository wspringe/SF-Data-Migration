/*
    This stored procedure is used for inserting roles into the new Salesforce org from the old Salesforce org.
    Circular definition fields: ParentRoleId, PortalAccountId, PortalAccountOwnerId
    Need: Roles, Accounts, Users
*/

USE SF_Data_Migration
GO
CREATE PROCEDURE Insert_UserRole (
  @objectName VARCHAR(50)
)
AS
  DECLARE @stagingTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage' 
	EXEC SF_Replicate 'SALESFORCE', @objectName
  -- Error handling
  if @@ERROR != 0
    print 'Error replicating ' + @objectName
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  ------------------------------------------------------
  -- Set the following fields in the table to empty, and will have to update these fields later; this will have to be changed for each object
  declare @SQL NVARCHAR(200)
  set @SQL = 'UPDATE ' + @stagingTable + ' set ParentRoleId = NULL, PortalAccountId = NULL, PortalAccountOwnerId = NULL'
  exec sp_executesql @SQL
  ------------------------------------------------------

	-- EXEC dbo.SF_BulkOps @operation = 'Insert', -- nvarchar(200)
	--     @table_server = 'SFDC_Target', -- sysname
	--     @table_name = @stagingTable -- sysname

GO