USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_ClientRegistration] (
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
  EXEC Create_Id_Based_Cross_Reference_Table 'Community__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Gift_Card_Tracking__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'MobileWhiteList__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Opportunity_Cross_Reference_Table 'Opportunity', @targetLinkedServerName, @sourceLinkedServerName


  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Ids from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Community__cXref', 'Community__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Customer__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Gift_Card_Tracking__cXref', 'Gift_Card__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'MobileWhiteList__cXref', 'MobileWhiteList__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'OpportunityXref', 'Opportunity__c'



  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Client_Registration__c_Stage --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT *
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 10000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10)) + ' ORDER BY Community__c'
    SET @count = @count + 1
    RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
    EXEC sp_executeSQL @sql
  END

  RAISERROR('Upserting split tables...', 0, 1) WITH NOWAIT
  SET @i = 0
  WHILE @i < @count
  BEGIN
      SET @SQL = 'EXEC SF_Tableloader ''Upsert'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO