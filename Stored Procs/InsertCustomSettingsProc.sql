USE SF_Data_Migration
GO
ALTER PROCEDURE Insert_CustomSettings (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)
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
  EXEC sp_executesql @SQL

  -- Replicating object table from source org
  RAISERROR('Replicating %s table from source org...', 0, 1, @objectName) WITH NOWAIT
	EXEC SF_Replicate @sourceLinkedServerName, @objectName
  RAISERROR('Done.', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable
  
  -- Need Organization ID for SetupOwnderID, getting it if don't already have it and filling column with ID
  IF OBJECT_ID('dbo.Organization', 'U') IS NULL
  BEGIN
    RAISERROR('Replicating Organization table from target org.', 0, 1, @objectName) WITH NOWAIT
    EXEC SF_REPLICATE @targetLinkedServerName, 'Organization'
  END
  
  RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  RAISERROR('Setting SetupOwnerId to Organization.Id', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET SetupOwnerId = Organization.Id FROM Organization'
  EXEC SP_EXECUTESQL @SQL -- update SetupOwnderID column with Organization.Id
  RAISERROR('Done', 0, 1) WITH NOWAIT

  RAISERROR('Upserting table...', 0, 1) WITH NOWAIT
  SET @SQL = 'EXEC SF_Tableloader ''Upsert'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + ''', ''Old_SF_ID__c'''
  EXEC SP_executesql @SQL

GO