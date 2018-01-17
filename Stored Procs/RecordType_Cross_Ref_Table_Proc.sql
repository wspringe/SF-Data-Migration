USE [SF_Data_Migration]
GO
/****** Object:  StoredProcedure [dbo].[Create_Cross_Reference_Table]    Script Date: 12/21/2017 14:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Create_RecordType_Cross_Reference_Table] (
  @objectName VARCHAR(50),
  @uniqueIdentifier VARCHAR (50),
  @sObjectType VARCHAR (50)

  /*
    This stored procedure is used to create a cross-reference table based on the object name
    and a unique identifier field from the object data being retrieved from Salesforce.
*/
)
AS
  DECLARE @objTarget VARCHAR(50)
  DECLARE @objSource VARCHAR(50)
  DECLARE @xRefTable VARCHAR(50)
  DECLARE @SQL NVARCHAR(250)

  SET @objTarget = @objectName + '_Target'
  SET @objSource = @objectName + '_Source'
  SET @xRefTable = @sObjectType + @objectName + 'XRef'

  SET @SQL = 'IF OBJECT_ID(''' + @xRefTable + ''', ''U'') IS NOT NULL
  BEGIN
  RAISERROR (''Dropping ' + @xRefTable + ' table.'', 0, 1) WITH NOWAIT
  DROP TABLE ' + @xRefTable +
  char(10) + 'END'
  EXEC sp_executesql @SQL
  
  -- Replicate object from source org if source table does not already exist in database
  IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                 WHERE TABLE_NAME = @objSource)
  BEGIN
	  RAISERROR ( 'Retrieving table %s from source SF org...', 0, 1, @objectName) WITH NOWAIT
	  EXEC SF_Replicate 'SALESFORCE', @objectName
	  EXEC sp_rename @objectName, @objSource
	  RAISERROR ( 'Done.', 0, 1) WITH NOWAIT
  END
  ELSE
	  RAISERROR ( '%s source table already exists.', 0, 1, @objectName) WITH NOWAIT

  -- Create object cross-reference table if table does not exist
  IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
				 WHERE TABLE_NAME = @xRefTable)
  BEGIN
	  SET @SQL = 'SELECT s.Id, s.' + @uniqueIdentifier + ' 
	  INTO ' + @xRefTable + ' 
	  FROM dbo.' + @objSource + ' s
    WHERE SobjectType = ''' + @sObjectType + ''''
	  EXEC sp_executesql @SQL
	  RAISERROR ( 'Created %s cross-reference table.', 0, 1, @objectName) WITH NOWAIT
  END
  ELSE
       RAISERROR ( '%s cross-reference table already exists.', 0, 1, @objectName) WITH NOWAIT
  
  -- Replicate object table from target org
  IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
				 WHERE TABLE_NAME = @objTarget)
  BEGIN
	  RAISERROR ( 'Retrieving %s table from target SF org...', 0, 1, @objectName) WITH NOWAIT
	  EXEC SF_Replicate 'SFDC_TARGET', @objectName
	  EXEC sp_rename @objectName, @objTarget
	  RAISERROR ( 'Done.', 0, 1) WITH NOWAIT
  END
  ELSE
      RAISERROR ( '%s target table already exists.', 0, 1, @objectName) WITH NOWAIT
  
   -- Change column name to SourceID from Id if SourceID does not already exist in the table
  IF COL_LENGTH('dbo.' + @xRefTable, 'SourceID') IS NULL
  BEGIN
	  SET @SQL = 'EXEC sp_rename ''' + @xRefTable + '.Id'', ''SourceID'', ''COLUMN'''
	  EXEC sp_executesql @SQL
  END
  ELSE
      RAISERROR ( 'SourceID column already exists.', 0, 1) WITH NOWAIT
  
  -- Add new column of TargetID to cross-reference table if it does not exist in the table
  IF COL_LENGTH('dbo.' + @xRefTable, 'TargetID') IS NULL
  BEGIN
	  SET @SQL = 'ALTER TABLE ' + @xRefTable + ' add [TargetID] NCHAR(18)'
	  EXEC sp_executesql @SQL
  END
  ELSE
      RAISERROR ( 'TargetID column already exists.', 0, 1) WITH NOWAIT

  -- Fill in the TargetId column
  SET @SQL = 'UPDATE dbo.' + @xRefTable + ' 
  set TargetID = t.Id
  FROM ' + @objTarget + ' t JOIN ' + @xRefTable + ' s
    on t.' + @uniqueIdentifier + ' = s.' + @uniqueIdentifier
  EXEC sp_executesql @SQL
  RAISERROR ( 'Filled in %s cross-reference table', 0, 1, @objectName) WITH NOWAIT

  

