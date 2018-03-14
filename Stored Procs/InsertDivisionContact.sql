USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Insert_DivisionContact] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Marketing Area object.

    Circular definition fields: Community_Sheet

    Need: None

    Cross-Reference: OWner, Division
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
  RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  -- Dropping object table from source if already have it
  RAISERROR('Creating %s_FromTarget table if it does not already exist.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
             + char(10) + 'BEGIN'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + ''''
             + char(10) + 'EXEC sp_rename ''' + @objectName + ''',  ''' + @targetOrgTable +  ''''
             + char(10) + 'END'
  EXEC sp_executesql @SQL

  RAISERROR('Creating XRef tables', 0 ,1) WITH NOWAIT
  EXEC Create_Id_Based_Cross_Reference_Table 'Division__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'User', @targetLinkedServerName, @sourceLinkedServerName


  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Ids from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Division__cXref', 'Division__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'User__c'


  SET @SQL = 'DECLARE @ret_code Int' +
        char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
        BEGIN' +
          char(10) + 'RAISERROR(''Upserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC @ret_code = SF_TableLoader ''Upsert'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable +''', ''Old_SF_ID__c''' +
          char(10) + 'IF @ret_code != 0' +
          char(10) + 'RAISERROR(''Upsert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT' +
        char(10) + 'END
      ELSE
        BEGIN' +
        char(10) + 'RAISERROR(''Inserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC ' + '@ret_code' + '= dbo.SF_TableLoader ''Insert'', ''' + @targetLinkedServerName +''', ''' + @stagingTable + '''' +
          char(10) + 'IF ' + '@ret_code' + ' != 0' +
            char(10) + 'RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
        END'
  EXEC SP_ExecuteSQL @SQL

  GO