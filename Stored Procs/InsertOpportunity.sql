USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Opportunity] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50),
  @systemUserId VARCHAR(18)

  /*
    This stored procedure is used for inserting and upserting data for the Marketing Area object.

    Circular definition fields: Community_Sheet

    Need: None

    Cross-Reference: OWner, Division
*/
)
AS
  declare @SQL NVARCHAR(1000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = 'Lead_Stage'
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
  RAISERROR ('Done', 0, 1) WITH NOWAIT
  EXEC sp_rename @objectName, @stagingTable -- rename table to add _Stage at the end of it

  RAISERROR ('Creating Error column.', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [X7_Desired_Monthly_Payment__c] NVARCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Status] NVARCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL

  -- Dropping object table from source if already have it
  RAISERROR('Creating %s_FromTarget table if it does not already exist.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
             + char(10) + 'BEGIN'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''' + @objectName + ''''
             + char(10) + 'EXEC sp_rename ''' + @objectName + ''',  ''' + @targetOrgTable +  ''''
             + char(10) + 'END'
  EXEC sp_executesql @SQL

  RAISERROR('Creating XRef tables', 0 ,1) WITH NOWAIT
  EXEC Create_Id_Based_Cross_Reference_Table 'User', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Contact', @targetLinkedServerName, @sourceLinkedServerName

  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Primary_Sales_Associate__c'

  RAISERROR('Deleting records that will not be leads', 0 ,1) WITH NOWAIT
  SET @SQL = 'DELETE FROM ' + @stagingTable + '
              WHERE Customer_Status__c != ''A - Prospect'' AND Customer_Status__c != ''B - Prospect'''
  EXEC sp_executesql @SQL

  RAISERROR('Renaming columns to fit into Leads', 0 ,1) WITH NOWAIT
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Address__c'', ''Address'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Primary_City__c'', ''City'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Contingency_Type__c'', ''Contingency__c'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_First_Name__c, ''FirstName'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Web_Lead__c'', ''IsWebLead__c'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Last_Name__c, ''LastName'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Cell_Phone__c, ''MobilePhone'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Primary_Zip_Code__c, ''PostalCode'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Primary_State__c, ''State'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Primary_Media_Source__c, ''LeadSource'', ''COLUMN'''
  EXEC sp_executesql @SQL
 
  -- Data transformation on leadSource
  RAISERROR('Performing data transformation...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Web Feed mh.com''
              WHERE LeadSource = ''www.MeritageHomes.com'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Web Feed - Non mh.com''
              WHERE LeadSource = ''Other Websites'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Chat/Phone Call''
              WHERE LeadSource = ''Meritage Online Sales Consultant'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Other''
              WHERE LeadSource = "Human Signs"'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Signage''
              WHERE LeadSource = ''Billboards/Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Friend/Family Referral''
              WHERE LeadSource = ''Referral/Friend/Relative'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Email''
              WHERE LeadSource = ''E-Mail'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Other''
              WHERE LeadSource = ''Radio'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''TV''
              WHERE LeadSource = ''Television'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Flyer''
              WHERE LeadSource = ''Flyers Through US Mail'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET LeadSource = ''Email''
              WHERE LeadSource = ''E-Mail'''
  EXEC sp_executesql @SQL
  
  -- Data transformation on Desired_Monthly_Payment__c to X7_Desired_Monthly_Payment__c
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''Less than $1000''
              WHERE Desired_Monthly_Payment__c < 1001'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''$1001 - 2000''
              WHERE Desired_Monthly_Payment__c > 1000 AND Desired_Monthly_Payment__c < 2001'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''$2001 - 2500''
              WHERE Desired_Monthly_Payment__c > 2000 AND Desired_Monthly_Payment__c < 2501'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''$2501 - 3000''
              WHERE Desired_Monthly_Payment__c > 2500 AND Desired_Monthly_Payment__c < 3001'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''$3001 - 3500''
              WHERE Desired_Monthly_Payment__c > 3000 AND Desired_Monthly_Payment__c < 3501'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET X7_Desired_Monthly_Payment__c = ''Above $3500''
              WHERE Desired_Monthly_Payment__c > 3500'
  EXEC sp_executesql @SQL

  -- Data transformation to Lead status based on provided picture
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET Status = ''Working'', OwnerID = Primary_Sales_Associate__c
              WHERE Customer_Status__c = ''A – Prospect'' AND Opportunity_Status__c = ''Active'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  -- SET @SQL = 'UPDATE ' + @stagingTable + ' 
  --             SET Status = ''Nurturing'', OwnerID = ''' + @systemUserId + '''
  --             WHERE Customer_Status__c = ''A – Prospect'' AND Opportunity_Status__c = ''Inactive'' AND Months_Since_Last_Update__c < 18'
  -- EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET Status = ''Working'', OwnerId = Primary_Sales_Associate__c
              WHERE Customer_Status__c = ''B – Prospect'' AND Opportunity_Status__c = ''Active'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  -- SET @SQL = 'UPDATE ' + @stagingTable + ' 
  --             SET Status = ''Nurturing'', OwnerId = ''' + @systemUserId + '''
  --             WHERE Customer_Status__c = ''E - Lead'' AND Opportunity_Status__c = ''Inactive'' AND Months_Since_Last_Update__c < 18'
  -- EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET Status = ''Nurturing'', OwnerId = Primary_Sales_Associate__c
              WHERE Months_Since_Last_Update__c > 18 AND Primary_Sales_Associate = '''''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET Status = ''Nurturing'', OwnerId = ''' + @systemUserId + '''
              WHERE Months_Since_Last_Update__c > 18 And Primary_Sales_Associate__c != '''''
  EXEC sp_executesql @SQL


  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Ids from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Lender_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXref', 'Lender_Name__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Secondary_Sales_Associate__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Realtor_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Realtor_Name__c'

  SET @SQL = 'UPDATE ' + @stagingTable + ' 
              SET OwnerId = Primary_Sales_Associate__c
              WHERE Customer_Status__c = ''E - Lead'' AND Opportunity_Status__c = ''Active'''
  EXEC sp_executesql @SQL


  SET @SQL = 'DECLARE @ret_code Int' +
        char(10) + 'IF EXISTS (select 1 from ' + @targetOrgTable + ')
        BEGIN' +
          char(10) + 'RAISERROR(''Upserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC @ret_code = SF_TableLoader ''Upsert'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable +''', ''Old_SF_ID__c''' +
          char(10) + 'IF @ret_code != 0' +
          char(10) + 'RAISERROR(''Upsert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT' +
        char(10) + 'END
      ELSE
        BEGIN' +
        char(10) + 'RAISERROR(''Inserting table...'', 0, 1) WITH NOWAIT' +
          char(10) + 'EXEC ' + '@ret_code' + '= dbo.SF_TableLoader ''Insert'', ''' + @targetLinkedServerName +''', ''' + @stagingTable + '''' +
          char(10) + 'IF ' + '@ret_code' + ' != 0' +
            char(10) + 'RAISERROR(''Insert unsuccessful. Please investigate.'', 0, 1) WITH NOWAIT
        END'
  EXEC SP_ExecuteSQL @SQL
  GO