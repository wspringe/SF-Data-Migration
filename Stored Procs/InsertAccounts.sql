USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Accounts] (
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
  EXEC Create_Cross_Reference_Table 'Division__c', 'Name', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_RecordType_Cross_Reference_Table 'RecordType', 'Name', 'Account', @targetLinkedServerName, @sourceLinkedServerName


   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Division__cXRef', 'Division__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountRecordTypeXRef', 'RecordTypeId'

  RAISERROR('Setting null record types and person record types to a customer accont', 0 ,1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET RecordTypeID = ''0124D0000008nCvQAI'' WHERE RecordTypeID IS NULL OR RecordTypeID = ''012C0000000Q4kiIAC'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET Primary_Email__c = ''28mo@yahoo.com'' WHERE Primary_Email__c = ''_28mo@yahoo.comjme-'''
  EXEC sp_executesql @SQL

  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Account_Stage
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT [AccountSource]
        ,[Alternate_Address__c]
        ,[Alternate_City__c]
        ,[Alternate_Country__c]
        ,[Alternate_State__c]
        ,[Alternate_Zip_Code__c]
        ,[BDX_File_Name__c]
        ,[BillingCity]
        ,[BillingCountry]
        ,[BillingGeocodeAccuracy]
        ,[BillingLatitude]
        ,[BillingLongitude]
        ,[BillingPostalCode]
        ,[BillingState]
        ,[BillingStreet]
        ,[Bronto_Implementation_Group__c]
        ,[Bronto_Integration__c]
        ,[Business_Entity_Type__c]
        ,[Business_Fax__c]
        ,[Business_Phone_2__c]
        ,[Business_Phone__c]
        ,[Business_Type__c]
        ,[California_Data_Conversion__c]
        ,[Cell_Phone__c]
        ,[COPPORTUNITY_OPPORTUNITY_ID__c]
        ,[CSales_ID__c]
        ,[Description]
        ,[Designated_Broker__c]
        ,[Division__c]
        ,[E1_Vendor_Type__c]
        ,[Email_Opt_Out__c]
        ,[Entity_Type__c]
        ,[Federal_Tax_ID__c]
        ,[Historic_Data__c]
        ,[Home_Owner_Insurance_Opt_Out__c]
        ,[Industry]
        ,[InsertForceUpdate__c]
        ,[jdeAddressBookKey__c]
        ,[Jigsaw]
        ,[Legal_Company_Name__c]
        ,[Legal_Entity__c]
        ,[Merged_Record_Flag__c]
        ,[Merged_Record_Ids__c]
        ,[MetroID__c]
        ,[MH_com_URI__c]
        ,[MHCom_Best_Way_To_Contact__c]
        ,[MHCom_Opt_In__c]
        ,[Name]
        ,[NumberOfEmployees]
        ,[OwnerId]
        ,[PersonContact__c]
        ,[Phone]
        ,[Primary_Address__c]
        ,[Primary_Address_Line_2__c]
        ,[Primary_City__c]
        ,[Primary_Country__c]
        ,[Primary_Email__c]
        ,[Primary_State__c]
        ,[Primary_Zip_Code__c]
        ,[Realty_License__c]
        ,[RecordTypeId]
        ,[Secondary_Email__c]
        ,[ShippingCity]
        ,[ShippingCountry]
        ,[ShippingGeocodeAccuracy]
        ,[ShippingLatitude]
        ,[ShippingLongitude]
        ,[ShippingPostalCode]
        ,[ShippingState]
        ,[ShippingStreet]
        ,[SicDesc]
        ,[Trade_Code_E1__c]
        ,[Type]
        ,[Web_Lead__c]
        ,[Web_Lead_Create_Update_Time__c]
        ,[Web_Source__c]
        ,[Website]
        ,[Westwood_Insurance_Choices__c]
        ,[Old_SF_ID__c]
        ,[Id]
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 200000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10))
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