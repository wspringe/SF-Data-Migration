USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Contacts] (
  @objectName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Contacts object.

    Circular definition fields: Reports To.

    Need:

    Cross-Reference: Owner, Division, RecordType
*/
)
AS
  declare @SQL NVARCHAR(1000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage' 
  SET @targetOrgTable = @objectName + '_FromTarget'
  
  -- RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- -- Dropping table if table exists
  -- SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL
  --   DROP TABLE ' + @stagingTable
  -- EXEC sp_executesql @SQL
  
  -- RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  -- EXEC SF_Replicate 'SALESFORCE', @objectName
  -- IF @@Error != 0
  --   print 'Error replicating ' + @objectName
  -- RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Error] NVARCHAR(2000) NULL'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

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

  RAISERROR('Setting columns to NULL that cannot be used yet.', 0, 1)
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET ReportsTo = '''''
  EXEC sp_executesql @SQL

  EXEC Create_Cross_Reference_Table 'Marketing_Area__c', 'Name'
  EXEC Create_Cross_Reference_Table 'Account', 'Name' 
  EXEC Create_Cross_Reference_Table 'User', 'Username'
  EXEC Create_Cross_Reference_Table 'Division__c', 'Name'
  EXEC Create_RecordType_Cross_Reference_Table 'RecordType', 'Name', 'Contact'


   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Division__cXRef', 'Division__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactRecordTypeXRef', 'RecordTypeId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'AccountId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'Related_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'Related_Customer__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'User_ID__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Marketing_Area__cXRef', 'Marketing_Area__c'

  SET @SQL = 'DECLARE @ret_code Int' +
        char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
        BEGIN' +
          char(10) + 'RAISERROR(''Upserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC @ret_code = SF_BulkOps ''Upsert:BulkAPI'', ''SFDC_Target'', ''' + @stagingTable +''', ''Old_SF_ID__c''' +
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