USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Option] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Option object.

    Circular definition fields: None.

    Need: None

    Cross-Reference: Owner
*/
)
AS
  declare @SQL NVARCHAR(4000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage' 
  SET @targetOrgTable = @objectName + '_FromTarget'
  
  -- RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- -- Dropping table if table exists
  -- SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL
  --   DROP TABLE ' + @stagingTable
  -- EXEC sp_executesql @SQL

  -- SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NOT NULL
  --   DROP TABLE ' + @targetOrgTable
  -- EXEC sp_executesql @SQL

  RAISERROR('Dropping all related split tables', 0 , 1) WITH NOWAIT
  -- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
  SET @SQL = ''
  SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '_Split_%'
  EXEC sp_executeSQL @SQL
  
  -- RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  -- EXEC SF_Replicate @sourceLinkedServerName, @objectName, 'pkchunk'
  -- IF @@Error != 0
  --   print 'Error replicating ' + @objectName
  -- RAISERROR ('Done', 0, 1) WITH NOWAIT
  -- EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  -- RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  -- SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  -- EXEC sp_executesql @SQL
  -- SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  -- EXEC sp_executesql @SQL

  -- -- Dropping object table from source if already have it
  -- RAISERROR('Creating %s_FromTarget table if it does not already exist.', 0, 1, @objectName) WITH NOWAIT
  -- SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
  --            + char(10) + 'BEGIN'
  --            + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + ''''
  --            + char(10) + 'EXEC sp_rename ''' + @objectName + ''',  ''' + @targetOrgTable +  ''''
  --            + char(10) + 'END'
  -- EXEC sp_executesql @SQL

  -- RAISERROR('Creating XRef tables', 0 ,1) WITH NOWAIT
  -- EXEC Create_Cross_Reference_Table 'User', 'Username', 'SFDC_Target', 'SALESFORCE'

  -- -- Update stage table with new Ids for Region lookup
  -- RAISERROR('Replacing Division__c from target org...', 0, 1) WITH NOWAIT
  -- EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'OwnerId'


  -- RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  -- SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  -- EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Option__c_Stage --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT [Area__c]
      ,[Community_Name__c]
      ,[Community_Number__c]
      ,[CreatedById]
      ,[CreatedDate]
      ,[Effective_Date__c]
      ,[Elevation__c]
      ,[Expiration_Date__c]
      ,[Id]
      ,[IsDeleted]
      ,[jdeOptionKey__c]
      ,[LastActivityDate]
      ,[LastModifiedById]
      ,[LastModifiedDate]
      ,[LastReferencedDate]
      ,[LastViewedDate]
      ,[Name]
      ,[Option_Category__c]
      ,[Option_Description__c]
      ,[Option_Description_Extended_Text__c]
      ,[Option_Extended_Text__c]
      ,[Option_Number__c]
      ,[Option_Type__c]
      ,[OptionType__c]
      ,[OwnerId]
      ,[Phase__c]
      ,[Plan_Elevation__c]
      ,[Plan_Number__c]
      ,[Previous_Sales_Price__c]
      ,[Price_Effective__c]
      ,[Price_Expiration__c]
      ,[Sales_Price__c]
      ,[Source_ID__c]
      ,[Status__c]
      ,[Status_Cutoff_After__c]
      ,[Status_Cutoff_Before__c]
      ,[SystemModstamp]
      ,[Old_SF_ID__c]
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 300000
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
      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailures(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''jdeOptionKey__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO