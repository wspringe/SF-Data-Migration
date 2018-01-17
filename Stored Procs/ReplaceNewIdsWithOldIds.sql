USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Replace_NewIds_With_OldIds] (
  @stagingTable VARCHAR(50),
  @xRefTableName VARCHAR(50),
  @fieldNameToReplace VARCHAR(50)

  /*
    This stored procedure is used for replacing Old SF Ids with new SF Ids in tables.
*/
)
AS
  declare @SQL NVARCHAR(1000)
  RAISERROR('Replacing %s old SF ID with new SF ID in %s', 0, 1, @fieldNameToReplace, @stagingTable) WITH NOWAIT
  SET @SQL = 'update ' + @stagingTable +
  ' set ' + @fieldNameToReplace + ' = x.TargetID
  FROM ' + @xRefTableName + ' x 
  WHERE x.SourceID = ' + @stagingTable + '.' + @fieldNameToReplace
  EXEC sp_executeSQL @SQL