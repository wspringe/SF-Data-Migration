USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Accounts] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Accounts object.

    Circular definition fields: None.

    Need:

    Cross-Reference: Owner, Division
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
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', '+ @targetOrgTable + ''', ''pkchunk'''
             + char(10) + 'EXEC sp_rename ''' + @objectName + ''', ''' + @targetOrgTable + ''''
  EXEC sp_executesql @SQL
  RAISERROR('Done.', 0, 1) WITH NOWAIT

  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Cross_Reference_Table 'Division__c', 'Name', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_RecordType_Cross_Reference_Table 'RecordType', 'Name', 'Account'


   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Division__cXRef', 'Division__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountRecordTypeXRef', 'RecordTypeId'

  SET @SQL = 'UPDATE ' + @stagingTable + ' SET RecordTypeID = ''0124D0000008nCvQAI'' WHERE RecordTypeID IS NULL OR RecordTypeID = ''012C0000000Q4kiIAC'''
  EXEC sp_executesql @SQL

  DECLARE @i INT = 0
  WHILE @i < 4
  BEGIN
      SET @SQL = 'SELECT * 
      INTO ' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + '
      FROM (SELECT *, ROW_NUMBER() OVER (ORDER BY Id) AS rn FROM ' + @stagingTable +') T1
      WHERE rn % 4 = ' + CAST(@i AS NVARCHAR(2))
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

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
  --EXEC SP_ExecuteSQL @SQL
  GO