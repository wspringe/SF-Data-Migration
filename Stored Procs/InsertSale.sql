USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Insert_Sales] (
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
  EXEC SF_Replicate @sourceLinkedServerName, @objectName, 'pkchunk'
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  RAISERROR ('Renaming table', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Old SF ID column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id, PersonContact__c = '''''
  EXEC sp_executesql @SQL


  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Plan__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Lot__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Contact', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Opportunity_Cross_Reference_Table 'Opportunity', @targetLinkedServerName, @sourceLinkedServerName


   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Approver_1__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Approver_2__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Approver_3__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Approver_4__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Approver_5__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Plan__cXRef', 'Change_Plan__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Closing_Coordinator__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'Customer_Name_Lookup__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Lot__cXRef', 'Lot__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXRef', 'Cobuyer__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Plan__cXRef', 'Plan__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Plan__cXRef', 'Previous_Plan__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Primary_Sales_Associate__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Sales_Associate_2__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Sales_Associate_3__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Sales_Associate_4__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'OpportunityXRef', 'Opportunity__c'
  
  

  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Sale__c_Stage
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT *
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 200000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10)) + ' ORDER By Opportunity__c'
    SET @count = @count + 1
    RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
    EXEC sp_executeSQL @sql
  END

  RAISERROR('Uupserting split tables...', 0, 1) WITH NOWAIT
  SET @i = 0
  WHILE @i < @count
  BEGIN
      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailures(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END
  GO