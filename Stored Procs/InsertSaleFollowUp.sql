USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Sale_FollowUp] (
  @objectName VARCHAR(50),
  @fieldToUpdate VARCHAR(50),
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
  DECLARE @updateTable VARCHAR(50), @targetOrgTable VARCHAR(50), @XrefTable VARCHAR(50), @stagingTable VARCHAR(50)
  SET @updateTable = @objectName + '_Update'
  SET @targetOrgTable = @objectName + '_FromTarget'
  SET @XrefTable = @objectName + 'Xref'
  SET @stagingTable = @objectName + '_Stage'

  SET @SQL = 'IF OBJECT_ID(''' + @updateTable + ''', ''U'') IS NOT NULL' +
    char(10) + 'DROP TABLE ' + @updateTable
  EXEC sp_executesql @SQL

  RAISERROR ('Creating %s table', 0, 1, @updateTable) WITH NOWAIT
  SET @SQL = 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + '''' +
    char(10) + 'EXEC sp_rename ''' + @objectName + ''', ''' + @updateTable + ''''
  EXEC sp_executesql @SQL

  SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL' +
    char(10) + 'DROP TABLE ' + @stagingTable
  EXEC sp_executesql @SQL

  RAISERROR ('Creating %s table', 0, 1, @updateTable) WITH NOWAIT
  SET @SQL = 'EXEC SF_Replicate ''' + @sourceLinkedServerName + ''', ''' + @objectName + ''''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @objectName + ''', ''' + @stagingTable + ''''
  EXEC sp_executesql @sql

  EXEC Create_Id_Based_Cross_Reference_Table @objectName, @targetLinkedServerName, @sourceLinkedServerName
  -- idea: update field on stage table, then copy column over to update table
  EXEC Replace_NewIds_With_OldIds @stagingTable,  @XrefTable,  @fieldToUpdate

  SET @SQL = 'UPDATE ' + @updateTable +
            char(10) + 'SET ' + @fieldToUpdate + ' = ' + @stagingTable + '.' + @fieldToUpdate +
            char(10) + 'FROM ' + @updateTable +
            char(10) + 'JOIN ' + @stagingTable +
            char(10) + 'ON ' + @updateTable + '.Old_SF_ID__c = ' + @stagingTable + '.Id'
  EXEC sp_executesql @SQL

  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @updateTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Sale__c_Update --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT *
    INTO ' + @updateTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @updateTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 50000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10)) + ''
    SET @count = @count + 1
    RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
    EXEC sp_executeSQL @sql
  END

  RAISERROR('Upserting split tables...', 0, 1) WITH NOWAIT
  SET @i = 0
  WHILE @i < @count
  BEGIN
      SET @SQL = 'EXEC SF_Tableloader ''Update'', ''' + @targetLinkedServerName + ''', ''' + @updateTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO