/*
    This stored procedure is used for inserting custom settings/metadata
*/

USE SF_Data_Migration
GO
CREATE PROCEDURE Insert_CustomSettings (
  @objectName VARCHAR(50)
)
AS
  DECLARE @stagingTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage'
	EXEC SF_Replicate 'SFDC_SOURCE', @objectName
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

	EXEC dbo.SF_BulkOps @operation = 'Insert', -- nvarchar(200)
	    @table_server = 'SFDC_Target', -- sysname
	    @table_name = @stagingTable -- sysname

GO