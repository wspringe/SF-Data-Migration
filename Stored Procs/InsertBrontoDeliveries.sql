USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Insert_BrontoDeliveries] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Bronto Deliveries object.

    Circular definition fields: None.

    Need:

    Cross-Reference: Owner, Bronto MEssages
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
  EXEC SF_Replicate @sourceLinkedServerName, @objectName, 'pkchunk'
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  RAISERROR ('Renaming table', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Old SF ID column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  -- Replicating object table from target
  RAISERROR('Creating FromTarget table if does not exist.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL
              BEGIN'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', '+ @targetOrgTable + ''', ''pkchunk'''
             + char(10) + 'EXEC sp_rename ''' + @objectName + ''', ''' + @targetOrgTable + '''
             END'
  EXEC sp_executesql @SQL
  RAISERROR('Done.', 0, 1) WITH NOWAIT

  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Cross_Reference_Table 'Bronto_Messages__c', 'Name', @targetLinkedServerName, @sourceLinkedServerName

   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Bronto_Messages__cxRef', 'Division__c'

  -- -- Basically adding rowcount to keep track of number of records in a table
  -- SET @SQL = 'ALTER TABLE '+ @stagingTable +' ADD [Sort] INT IDENTITY (1,1)'
  -- EXEC SP_EXECUTESQL @SQL

  -- -- Drop all tables with staging table name + split
  -- SELECT 'IF OBJECT_ID(''' + TABLE_NAME + ''') IS NOT NULL BEGIN DROP TABLE [' + TABLE_NAME + '] END;' 
  -- FROM INFORMATION_SCHEMA.TABLES 
  -- WHERE TABLE_NAME LIKE '[' + @stagingTable + '_Split]%'
  
  -- Creating tables split from the original so it can fit in upsert statements
  -- DECLARE @maxRows INT 
  -- DECLARE @i INT = 1
  -- DECLARE @count INT = 0
  -- DECLARE @SQL NVARCHAR(4000)
  -- SELECT @maxRows = COUNT(*) FROM Account_Stage
  -- WHILE @i < @maxRows
  -- BEGIN
  --   SET @SQL = 'SELECT *
  --   INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
  --   CHAR(10) + 'FROM ' + @stagingTable +
  --   char(10) + 'WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
  --   SET @i = @i + 200000
  --   IF @i > @maxRows
  --     SET @i = @maxRows
  --   SET @SQL = @SQL + CAST(@i AS NVARCHAR(10))
  --   SET @count = @count + 1
  --   RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
  --   EXEC sp_executeSQL @sql
  -- END

  -- -- Upserting the split tables
  -- SET @i = 0
  -- WHILE @i < @count
  -- BEGIN
  --     SET @SQL = 'EXEC SF_Tableloader ''Upsert'', ''SFDC_Target'', ''' + @stagingTable + '_Split''' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
  --     SET @i = @i + 1
  --     EXEC sp_executeSQL @SQL
  -- END

  SET @SQL = 'DECLARE @ret_code Int' +
        char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
        BEGIN' +
          char(10) + 'RAISERROR(''Upserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC @ret_code = SF_TableLoader ''Upsert'', ''' + @targetLinkedServerName + ''', + @stagingTable +'', ''Old_SF_ID__c''' +
          char(10) + 'IF @ret_code != 0' +
          char(10) + 'RAISERROR(''Upsert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT' +
        char(10) + 'END
      ELSE
        BEGIN' +
        char(10) + 'RAISERROR(''Inserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC ' + '@ret_code' + '= dbo.SF_BulkOps ''Insert'', ''SFDC_TARGET'', ''' + @stagingTable + '''' +
          char(10) + 'IF ' + '@ret_code' + ' != 0' +
            char(10) + 'RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
        END'
  EXEC SP_ExecuteSQL @SQL
  GO