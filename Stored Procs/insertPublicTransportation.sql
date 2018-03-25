USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_PublicTransportation] (
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


  RAISERROR('Creating XRef tables', 0 ,1) WITH NOWAIT
  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName


  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Ids from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'OwnerId'


  SET @SQL = 'EXEC SF_Tableloader ''Upsert'', ''' + @targetLinkedServerName +  ''', ''' + @stagingTable + ''', ''Old_SF_ID__c'''
  EXEC SP_ExecuteSQL @SQL

  GO