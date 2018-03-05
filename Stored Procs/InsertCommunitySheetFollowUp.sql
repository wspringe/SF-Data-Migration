USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CommunitySheet_FollowUp] (
  @objectName VARCHAR(50),
  @uniqueIdentifier VARCHAR(50),
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
  DECLARE @updateTable VARCHAR(50), @targetOrgTable VARCHAR(50), @XrefTable VARCHAR(50)
  SET @updateTable = @objectName + '_Update' 
  SET @targetOrgTable = @objectName + '_FromTarget'
  SET @XrefTable = @objectName + 'Xref'

  SET @SQL = 'IF OBJECT_ID(''' + @updateTable + ''', ''U'') IS NOT NULL' +
    char(10) + 'DROP TABLE ' + @updateTable
  EXEC sp_executesql @SQL
  
  RAISERROR ('Creating %s table', 0, 1, @updateTable) WITH NOWAIT
  SET @SQL = 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + '''' +
    char(10) + 'EXEC sp_rename ''' + @objectName + ''', ''' + @updateTable + ''''
  EXEC sp_executesql @SQL
  

  EXEC Create_Cross_Reference_Table @objectName, @uniqueIdentifier, @targetLinkedServerName, @sourceLinkedServerName
  -- idea: update field on stage table, then copy column over to update table
  EXEC Replace_NewIds_With_OldIds @updateTable,  @XrefTable,  @fieldToUpdate 

  SET @SQL = 'DECLARE @ret_code Int ' +
          char(10) + 'RAISERROR(''Updating table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC @ret_code = SF_TableLoader ''Update'', ''' + @targetLinkedServerName + ''', ''' + @objectName + '''' +
          char(10) + 'IF @ret_code != 0' +
          char(10) + 'RAISERROR(''Update unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT'
  EXEC SP_ExecuteSQL @SQL

  GO