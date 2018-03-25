USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_BrontoCampaignResponse] (
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
  declare @SQL NVARCHAR(4000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = @objectName + '_Stage'
  SET @targetOrgTable = @objectName + '_FromTarget'

  RAISERROR ('Dropping %s if table exists.', 0, 1, @stagingTable) WITH NOWAIT
  -- Dropping table if table exists
  SET @SQL = 'IF OBJECT_ID(''' + @stagingTable + ''', ''U'') IS NOT NULL
    DROP TABLE ' + @stagingTable
  EXEC sp_executesql @SQL

  RAISERROR('Dropping all related split tables', 0 , 1) WITH NOWAIT
  -- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
  SET @SQL = ''
  SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '_Split_%'
  EXEC sp_executeSQL @SQL

  RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  SELECT * INTO Bronto_Campaign_Response__c_Stage FROM OPENQUERY(salesforce, 'SELECT * FROM Bronto_Campaign_Response__c WHERE Year_Received__c = 2018')

  RAISERROR ('Creating Old SF ID column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Bronto_Messages__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Bronto_Deliveries__c', @targetLinkedServerName, @sourceLinkedServerName

   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Bronto_Messages__cxRef', 'Bronto_Campaign__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Bronto_Deliveries__cxRef', 'Campaign_Delivery__c'

  --Basically adding rowcount to keep track of number of records in a table
  SET @SQL = 'ALTER TABLE '+ @stagingTable +' ADD [Sort] INT IDENTITY (1,1)'
  EXEC SP_EXECUTESQL @SQL

  -- Creating tables split from the original so it can fit in upsert statements
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Sort) FROM Account_Stage
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT *
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable +
    char(10) + 'WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 200000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10))
    SET @count = @count + 1
    RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
    EXEC sp_executeSQL @sql
  END

  -- Upserting the split tables
  RAISERROR('Upserting split tables...', 0, 1) WITH NOWAIT
  SET @i = 0
  WHILE @i < @count
  BEGIN
      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailure(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO