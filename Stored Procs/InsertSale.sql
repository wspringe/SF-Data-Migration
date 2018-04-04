USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter PROCEDURE [dbo].[Insert_Sales] (
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

  RAISERROR ('Retrieving %s table from source org...', 0, 1, @objectName) WITH NOWAIT
  EXEC SF_Replicate @sourceLinkedServerName, @objectName, 'pkchunk'
  IF @@Error != 0
    print 'Error replicating ' + @objectName
  RAISERROR ('Renaming table', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Old SF ID column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Transfer_From_Sale__C = '''''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Transfer_To_Sale__C = '''''
  EXEC sp_executesql @SQL

    RAISERROR('Fixing one-off emails...', 0, 1) WITH NOWAIT
    SET @SQL = 'UPDATE ' + @stagingTable + '
    SET Customer_Email_Address__c  = ''delaine.gaston@gmail.com''
    WHERE Customer_Email_Address__c  LIKE ''%delaine.gaston@gmail.com%'''
    EXEC sp_executesql @SQL
    SET @SQL = 'UPDATE ' + @stagingTable + '
    SET Customer_Email_Address__c  = ''susanb7@ymail.com''
    WHERE Customer_Email_Address__c  LIKE ''%susanb7@ymail.com%'''
    EXEC sp_executesql @SQL
    SET @SQL = 'UPDATE ' + @stagingTable + '
    SET Customer_Email_Address__c  = ''philromah@yahoo.com''
    WHERE Customer_Email_Address__c  LIKE ''%philromah@yahoo.com%'''
    EXEC sp_executesql @SQL
    SET @SQL = 'UPDATE ' + @stagingTable + '
    SET Customer_Email_Address__c  = ''thuzar77@gmail.com''
    WHERE Customer_Email_Address__c  LIKE ''%thuzar77@gmail.com%'''
    EXEC sp_executesql @SQL


  EXEC Create_Cross_Reference_Table 'User', 'Username', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Plan__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Lot__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Contact', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Opportunity_Cross_Reference_Table 'Opportunity', @targetLinkedServerName, @sourceLinkedServerName


   -- Update stage table with new UserIds for Owner'
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

  SET @SQL = 'SELECT * INTO ' + @stagingTable + '2 FROM ' + @stagingTable + ' ORDER BY Opportunity__c'
  EXEC sp_executeSQL @SQL
  SET @SQL = 'DROP TABLE ' + @stagingTable
  EXEC sp_Executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '2'', ''' + @stagingTable + ''''
  EXEC sp_executeSQL @SQL

      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailures(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + ''', ''Old_SF_ID__C'''

      EXEC sp_executeSQL @SQL

  GO