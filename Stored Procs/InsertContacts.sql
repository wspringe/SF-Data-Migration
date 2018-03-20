USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Contacts] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

  /*
    This stored procedure is used for inserting and upserting data for the Contacts object.

    Circular definition fields: Reports To.

    Need:

    Cross-Reference: Owner, Division, RecordType
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
  RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Error] NVARCHAR(2000) NULL'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  -- Dropping object table from source if already have it
  RAISERROR('Dropping %s_FromTarget table if have it.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NOT NULL'
             + char(10) + 'DROP TABLE ' + @targetOrgTable
  EXEC sp_executesql @SQL

  --Replicating object table from target
  RAISERROR('Replicating %s table from target org...', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_REPLICATE 'SFDC_TARGET', @objectName
  -- Rename table to add _FromTarget
  EXEC sp_rename @objectName, @targetOrgTable
  RAISERROR('Done.', 0, 1) WITH NOWAIT

  RAISERROR('Setting columns to NULL that cannot be used yet.', 0, 1)
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET ReportsToId = '''''
  EXEC sp_executesql @SQL

  EXEC Create_Id_Based_Cross_Reference_Table 'Marketing_Area__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_RecordType_Cross_Reference_Table 'RecordType', 'Name', 'Contact'


   -- Update stage table with new UserIds for Owner'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactRecordTypeXRef', 'RecordTypeId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'AccountId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'Related_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXRef', 'Related_Customer__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'User_ID__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Marketing_Area__cXRef', 'Marketing_Area__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'OSC_Assignment__c'

  RAISERROR('Setting null record types and person record types to a customer accont', 0 ,1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + ' SET RecordTypeID = ''0124D0000008nOYQAY'' WHERE RecordTypeID IS NULL'
  EXEC sp_executesql @SQL

  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Contact_Stage --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT [AccountId]
      ,[Alternate_Address__c]
      ,[Alternate_City__c]
      ,[Alternate_Country__c]
      ,[Alternate_State__c]
      ,[Alternate_Zip_Code__c]
      ,[AssistantName]
      ,[AssistantPhone]
      ,[Birthdate]
      ,[Bronto_Implementation_Group__c]
      ,[Bronto_Integration__c]
      ,[Business_Fax__c]
      ,[Business_Phone_2__c]
      ,[California_Data_Conversion__c]
      ,[CreatedById]
      ,[CreatedDate]
      ,[CSales_ID__c]
      ,[CSales_Int_ID__c]
      ,[Department]
      ,[Description]
      ,[Designated_Broker_Web__c]
      ,[DoNotCall]
      ,[Email]
      ,[EmailBouncedDate]
      ,[EmailBouncedReason]
      ,[Fax]
      ,[FirstName]
      ,[HasOptedOutOfEmail]
      ,[Historic_Data__c]
      ,[HomePhone]
      ,[Inspector_Entity_Type__c]
      ,[jdeWhosWhoKey__c]
      ,[Jigsaw]
      ,[LastModifiedById]
      ,[LastModifiedDate]
      ,[LastName]
      ,[LeadSource]
      ,[License_Number__c]
      ,[MailingCity]
      ,[MailingCountry]
      ,[MailingGeocodeAccuracy]
      ,[MailingLatitude]
      ,[MailingLongitude]
      ,[MailingPostalCode]
      ,[MailingState]
      ,[MailingStreet]
      ,[Marketing_Area__c]
      ,[Merged_Record_Flag__c]
      ,[Merged_Record_Ids__c]
      ,[MetroID__c]
      ,[MH_com_Contact__c]
      ,[MH_com_URI__c]
      ,[MHCom_Best_Way_To_Contact__c]
      ,[Mobile_Phone__c]
      ,[MobilePhone]
      ,[New_Client_Registration__c]
      ,[Notes__c]
      ,[Office_Name_Web__c]
      ,[OSC_Assignment__c]
      ,[OtherCity]
      ,[OtherCountry]
      ,[OtherGeocodeAccuracy]
      ,[OtherLatitude]
      ,[OtherLongitude]
      ,[OtherPhone]
      ,[OtherPostalCode]
      ,[OtherState]
      ,[OtherStreet]
      ,[OwnerId]
      ,[Phone]
      ,[Portal_Username__c]
      ,[Primary_Address__c]
      ,[Primary_Address_Line_2__c]
      ,[Primary_City__c]
      ,[Primary_Country__c]
      ,[Primary_State__c]
      ,[Primary_Zip_Code__c]
      ,[Reach_ID__c]
      ,[Record_Type__c]
      ,[RecordTypeId]
      ,[Related_Company__c]
      ,[Related_Customer__c]
      ,[Relationship__c]
      ,[ReportsToId]
      ,[Salutation]
      ,[Secondary_Email__c]
      ,[Send_Welcome_Email__c]
      ,[Title]
      ,[User_ID__c]
      ,[Web_Inquiry_Date__c]
      ,[Old_SF_ID__c]
      ,[Id]
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 200000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10)) + ' ORDER BY AccountId'
    SET @count = @count + 1
    RAISERROR('%d iteration of loop', 0, 1, @count) WITH NOWAIT
    EXEC sp_executeSQL @sql
  END

  RAISERROR('Upserting split tables...', 0, 1) WITH NOWAIT
  SET @i = 0
  WHILE @i < @count
  BEGIN
      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailures(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO