USE SF_Data_Migration
GO
ALTER PROCEDURE Insert_CustomSettings (
  @objectName VARCHAR(50)
  /*
    This stored procedure is used for inserting custom settings/metadata
*/

)
AS
  DECLARE @SQL NVARCHAR(1000), @stagingTable VARCHAR(50), @ret_code int, @tableName VARCHAR(50)
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
 ---------------------------------------- Attempt at inserting then upserting more elegantly, recieved conversion to int error?
  -- EXEC SF_REPLICATE 'SFDC_TARGET', @objectName
  -- SET @tableName = @objectName
  -- SET @SQL = N'IF EXISTS (select 1 from ' + @objectName + ')
  --   BEGIN
  --     UPDATE ' + @stagingTable + ' SET ' + @stagingTable + '.Id = 
  --     ' + @objectName + '.Id FROM ' + @stagingTable + ' INNER JOIN ' + @objectName +
  --     char(10) + 'ON ' + @stagingTable + '.Name = ' + @objectName + '.Name' +
  --     char(10) + 'EXEC dbo.SF_BulkOps ''Upsert'', ''SFDC_TARGET'', ''' + @stagingTable + ''', ''Id''' +
  --   char(10) + 'END
  -- ELSE
  --  BEGIN' +
  --    char(10) + 'EXEC ' + @ret_code + '= dbo.SF_BulkOps ''Insert'', ''SFDC_TARGET'', ''' + @objectName + '''' + 
  --    char(10) + 'IF ' + @ret_code + ' != 0
  --      RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
  --  END'
  --  EXEC SP_ExecuteSQL @SQL
  -------------------------------------
  RAISERROR('Attempting to insert...', 0, 1) WITH NOWAIT
	EXEC @ret_code = dbo.SF_BulkOps 'Insert', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
  IF @ret_code != 0
    BEGIN
      RAISERROR('Insert failed (which means data already exists in org). Upserting instead...', 0, 1) WITH NOWAIT
      EXEC SF_REPLICATE 'SFDC_TARGET', @objectName
      SET @SQL = 'UPDATE ' + @stagingTable + ' SET ' + @stagingTable + '.Id = 
      ' + @objectName + '.Id FROM ' + @stagingTable + ' INNER JOIN ' + @objectName +
      char(10) + 'ON ' + @stagingTable + '.Name = ' + @objectName + '.Name'
      EXEC sp_executeSQL @SQL
      print @SQL
      EXEC @ret_code = dbo.SF_BulkOps 'Upsert', 'SFDC_TARGET', @stagingTable, 'Id'
      IF @ret_code != 0
        RAISERROR('Upsert unsuccessful. Please investigate.', 0, 1) WITH NOWAIT
    END
  RAISERROR('Done.', 0, 1) WITH NOWAIT

GO