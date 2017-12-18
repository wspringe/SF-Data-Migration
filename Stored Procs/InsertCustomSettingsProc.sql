USE SF_Data_Migration
GO
ALTER PROCEDURE Insert_CustomSettings (
  @objectName VARCHAR(50)
  /*
    This stored procedure is used for inserting custom settings/metadata
*/

)
AS
  DECLARE @SQL NVARCHAR(250)
  DECLARE @stagingTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage'
    RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- Dropping table if table exists
  IF OBJECT_ID('dbo.Bronto_Required_Fields__c_Stage', 'U') IS NOT NULL
    DROP TABLE dbo.Bronto_Required_Fields__c_Stage

  RAISERROR('Replicating %s table from source org...', 0, 1, @objectName) WITH NOWAIT
	EXEC SF_Replicate 'SALESFORCE', @objectName
  RAISERROR('Done.', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Error] NVARCHAR(2000) NULL'
  EXEC sp_executesql @SQL -- add Error columns

  RAISERROR('Replicating Organization table from target org.', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_REPLICATE 'SFDC_TARGET', 'Organization'

  SET @SQL = 'UPDATE ' + @stagingTable + ' SET SetupOwnerId = Organization.Id FROM Organization'
  EXEC SP_EXECUTESQL @SQL -- update SetupOwnderID column with Organization.Id

  RAISERROR('Upserting data into target org...', 0, 1) WITH NOWAIT 
	EXEC dbo.SF_BulkOps 'Insert', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
  EXEC dbo.SF_BulkOps 'Update', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
  RAISERROR('Done.', 0, 1) WITH NOWAIT

GO