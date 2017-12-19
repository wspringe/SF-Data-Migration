USE SF_Data_Migration
GO
ALTER PROCEDURE Insert_CustomSettings (
  @objectName VARCHAR(50)
  /*
    This stored procedure is used for inserting custom settings/metadata
*/

)
AS
  DECLARE @SQL NVARCHAR(1000), @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50) 
  SET @stagingTable = @objectName + '_Stage'
  SET @targetOrgTable = @objectName + '_FromTarget'

  --Dropping Staging table if table exists
  RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL DROP TABLE ' + @stagingTable
  Print @SQL
  EXEC sp_executesql @SQL

  -- Replicating object table from source org
  RAISERROR('Replicating %s table from source org...', 0, 1, @objectName) WITH NOWAIT
	EXEC SF_Replicate 'SALESFORCE', @objectName
  RAISERROR('Done.', 0, 1) WITH NOWAIT

  -- Rename table to add _Stage at end of name
  EXEC sp_rename @objectName, @stagingTable

  -- Adding necessary Error column to table
  RAISERROR('Adding Error column to %s table', 0, 1, @stagingTable) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Error] NVARCHAR(2000) NULL'
  EXEC sp_executesql @SQL
  RAISERROR('Done.', 0, 1) WITH NOWAIT
  
  -- Need Organization ID for SetupOwnderID, getting it if don't already have it and filling column with ID
  IF OBJECT_ID('dbo.Organization', 'U') IS NULL
  BEGIN
    RAISERROR('Replicating Organization table from target org.', 0, 1, @objectName) WITH NOWAIT
    EXEC SF_REPLICATE 'SFDC_TARGET', 'Organization'
  END
  
  IF @objectName != 'CallCenter'
    BEGIN
      RAISERROR('Setting SetupOwnerId to Organization.Id', 0, 1) WITH NOWAIT
      SET @SQL = 'UPDATE ' + @stagingTable + ' SET SetupOwnerId = Organization.Id FROM Organization'
      EXEC SP_EXECUTESQL @SQL -- update SetupOwnderID column with Organization.Id
      RAISERROR('Done', 0, 1) WITH NOWAIT
    END

  -- Dropping object table from source if already have it
  RAISERROR('Dropping %s_FromTarget table if have it.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NOT NULL'
             + char(10) + 'DROP TABLE ' + @targetOrgTable
  EXEC sp_executesql @SQL

  -- Replicating object table from target
  RAISERROR('Replicating %s table from target org...', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_REPLICATE 'SFDC_TARGET', @objectName
  -- Rename table to add _FromTarget
  EXEC sp_rename @objectName, @targetOrgTable
  RAISERROR('Done.', 0, 1) WITH NOWAIT

  -- Ugly statement, but most elegant way to do the task :(
  -- Following @SQL checks if there is any data in object table replicated from source. If there is,
  -- then an upsert can be performed. Grabs ID from the _FromTarget table and puts ID in the ID column in
  -- the staging table. If no data currently exists in target org, then do an insert instead.
  RAISERROR('Upserting table if we can. Otherwise, inserting.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'DECLARE @ret_code Int' +
     char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
     BEGIN
      UPDATE ' + @stagingTable + ' SET ' + @stagingTable + '.Id = 
       ' + @targetOrgTable + '.Id FROM ' + @stagingTable + ' INNER JOIN ' + @targetOrgTable +
       char(10) + 'ON ' + @stagingTable + '.Name = ' + @targetOrgTable + '.Name' +
       char(10) + 'EXEC dbo.SF_BulkOps ''Upsert'', ''SFDC_TARGET'', ''' + @stagingTable + ''', ''Id''' +
     char(10) + 'END
   ELSE
    BEGIN' +
      char(10) + 'EXEC ' + '@ret_code' + '= dbo.SF_BulkOps ''Insert'', ''SFDC_TARGET'', ''' + @stagingTable + '''' +
      char(10) + 'IF ' + '@ret_code' + ' != 0' +
        char(10) + 'RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
    END'
  EXEC SP_ExecuteSQL @SQL
  -------------------------------------
  -- RAISERROR('Attempting to insert...', 0, 1) WITH NOWAIT
	-- EXEC @ret_code = dbo.SF_BulkOps 'Insert', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
  -- IF @ret_code != 0
  --   BEGIN
  --     RAISERROR('Insert failed (which means data already exists in org). Upserting instead...', 0, 1) WITH NOWAIT
  --     EXEC SF_REPLICATE 'SFDC_TARGET', @objectName
  --     SET @SQL = 'UPDATE ' + @stagingTable + ' SET ' + @stagingTable + '.Id = 
  --     ' + @objectName + '.Id FROM ' + @stagingTable + ' INNER JOIN ' + @objectName +
  --     char(10) + 'ON ' + @stagingTable + '.Name = ' + @objectName + '.Name'
  --     EXEC sp_executeSQL @SQL
  --     print @SQL
  --     EXEC @ret_code = dbo.SF_BulkOps 'Upsert', 'SFDC_TARGET', @stagingTable, 'Id'
  --     IF @ret_code != 0
  --       RAISERROR('Upsert unsuccessful. Please investigate.', 0, 1) WITH NOWAIT
  --   END
  RAISERROR('Done with %s.', 0, 1, @objectName) WITH NOWAIT

GO