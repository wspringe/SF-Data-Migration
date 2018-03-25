USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Lead] (
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
  declare @SQL NVARCHAR(4000)
  DECLARE @stagingTable VARCHAR(50), @targetOrgTable VARCHAR(50)
  SET @stagingTable = 'Lead_Stage'
  SET @targetOrgTable = 'Lead' + '_FromTarget'

  RAISERROR('Dropping all related split tables', 0 , 1) WITH NOWAIT
  -- taken from http://www.sqlservercurry.com/2012/12/drop-all-tables-in-database-whose-name.html
  SET @SQL = ''
  SELECT @sql=@sql + ' DROP TABLE '+table_name from INFORMATION_SCHEMA.TABLES where table_name like @stagingTable + '_Split_%'
  EXEC sp_executeSQL @SQL

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

  RAISERROR ('Creating columns...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Old_SF_ID__c] NCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [X7_Desired_Monthly_Payment__c] NVARCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' add [Status] NVARCHAR(18)'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE '+ @stagingTable + ' SET Old_SF_ID__c = Id'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Company] VARCHAR(255)'
  EXEC sp_executesql @SQL
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [OwnerID] NCHAR(18)'
  EXEC sp_executesql @SQL

  -- Dropping object table from source if already have it
  RAISERROR('Creating %s_FromTarget table if it does not already exist.', 0, 1, @objectName) WITH NOWAIT
  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NULL'
             + char(10) + 'BEGIN'
             + char(10) + 'EXEC SF_Replicate ''' + @targetLinkedServerName + ''', ''Lead'', ''pkchunk'''
             + char(10) + 'EXEC sp_rename ''Lead'',  ''' + @targetOrgTable +  ''''
             + char(10) + 'END'
  EXEC sp_executesql @SQL

  RAISERROR('Creating XRef tables', 0 ,1) WITH NOWAIT
  EXEC Create_Id_Based_Cross_Reference_Table 'User', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Account', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Contact', @targetLinkedServerName, @sourceLinkedServerName

  RAISERROR('Replacing UserIds on Primary_Sales_Associate__c before OwnerId is touched...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Primary_Sales_Associate__c'

  RAISERROR('Deleting records that will not be leads', 0 ,1) WITH NOWAIT
  SET @SQL = 'DELETE FROM ' + @stagingTable + '
              WHERE Customer_Status__c = ''A – Prospect'' OR Customer_Status__c = ''B – Prospect'' OR Total_Sale_Count__C > 0'
  EXEC sp_executesql @SQL

  RAISERROR('Renaming columns to fit into Leads...', 0 ,1) WITH NOWAIT
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Address__c'', ''Address'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Primary_City__c'', ''City'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Contingency__c'', ''Contingency_Type__c'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_First_Name__c'', ''FirstName'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Web_Lead__c'', ''IsWebLead__c'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Last_Name__c'', ''LastName'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Cell_Phone__c'', ''MobilePhone'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Primary_Zip_Code__c'', ''PostalCode'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Customer_Primary_State__c'', ''State'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Primary_Media_Source__c'', ''LeadSource'', ''COLUMN'''
  EXEC sp_executesql @SQL
  SET @SQL = 'EXEC sp_rename ''' + @stagingTable + '.Lender_Name__c'' , ''Lender_Company__c'', ''COLUMN'''
   EXEC sp_executesql @SQL

  -- Data transformation on leadSource
  RAISERROR('Performing data transformation on LeadSource...', 0, 1) WITH NOWAIT
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
              WHERE LeadSource = ''''Human Signs'''''
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
  RAISERROR('Performing data transformation on Desired_Monthly_Payment__c...', 0, 1) WITH NOWAIT
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
              SET X7_Desired_Monthly_Payment__c = ''$3001 - $3500''
              WHERE Desired_Monthly_Payment__c > 3000 AND Desired_Monthly_Payment__c < 3501'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET X7_Desired_Monthly_Payment__c = ''Above $3500''
              WHERE Desired_Monthly_Payment__c > 3500'
  EXEC sp_executesql @SQL

  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_Did_You_learn_About_Meritage_Homes__c = ''MeritageHomes.com''
              WHERE How_Did_You_learn_About_Meritage_Homes__c = ''www.MeritageHomes.com'''
  EXEC sp_executesql @SQL

  -- Data transformation to Lead status and Lead Owner based on provided pictur
  RAISERROR('Performing data transformation on Lead Status and Lead Owner...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Working'', OwnerID = Primary_Sales_Associate__c
              WHERE Customer_Status__c = ''C – Lead'' AND Opportunity_Status__c = ''Active'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Nurturing'', OwnerID = ''' + @systemUserId + '''
              WHERE Customer_Status__c = ''C – Lead'' AND Opportunity_Status__c = ''Inactive'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Working'', OwnerId = Primary_Sales_Associate__c
              WHERE Customer_Status__c = ''E – Lead'' AND Opportunity_Status__c = ''Active'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Nurturing'', OwnerId = ''' + @systemUserId + '''
              WHERE Customer_Status__c = ''E – Lead'' AND Opportunity_Status__c = ''Inactive'' AND Months_Since_Last_Update__c < 18'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Nurturing'', OwnerId = Primary_Sales_Associate__c
              WHERE Months_Since_Last_Update__c > 18 AND Primary_Sales_Associate__c = '''''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Nurturing'', OwnerId = ''' + @systemUserId + '''
              WHERE Months_Since_Last_Update__c > 18 And Primary_Sales_Associate__c != '''''
  EXEC sp_executesql @SQL

  -- Placeholder
  RAISERROR('Placeholder for what to do when OwnerId is null...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET OwnerId = ''' + @systemUserId + '''
              WHERE OwnerId = '''' OR OwnerId IS NULL'
  EXEC sp_executesql @SQL
  ------------

  -- Company is a required field (?) so setting it to MH if null
  RAISERROR('Setting Company field to Meritage Homes if null...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET Company = ''Meritage Homes'''
  EXEC sp_executesql @SQL

  RAISERROR('Performing data transformation on What_Is_Your_Current_Housing_Status__c...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET What_is_your_current_housing_status__c = ''Yes''
              WHERE What_is_your_current_housing_status__c = ''Rent'' OR What_is_your_current_housing_status__c = ''Rent Apartment'' OR
              What_is_your_current_housing_status__c = ''Rent House'' OR
              What_is_your_current_housing_status__c = ''Rent'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
          SET What_is_your_current_housing_status__c = ''No''
          WHERE What_is_your_current_housing_status__c = ''Own'' OR What_is_your_current_housing_status__c = ''Own – Need to Sell'' OR
          What_is_your_current_housing_status__c = ''Own – No Need to Sell'' OR
          What_is_your_current_housing_status__c = ''Homeowner'' OR
          What_is_your_current_housing_status__c = ''Other'''
  EXEC sp_executesql @SQL

  -- Setting Fears_Of_Moving__c to empty because field changed from long text area to picklist
  RAISERROR('Setting Fears_Of_Moving__c to null as data type changed...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable  + '
              SET Fears_of_Moving__c = '''''
  EXEC sp_executesql @SQL

  -- Jesus Christ there are like 100 inactive picklist values that have to be changed
  RAISERROR('Performing data transformation on How_did_you_learn_about_Meritage_Homes__c...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Realtor recommendation''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Realtor'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''MH.com'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''FriendMorMRelative'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Other'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Billboards''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Driveby/Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Newspaper or magazine''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Local Newspaper'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Human Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Realtor Recommendation''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Real Estate Agent(s)'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Radio Ads''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Radio'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Billboards''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Billboards/Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Hometown heroes campaign''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Hometown Heroes'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Other Website'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Warranty Self Registration'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET How_did_you_learn_about_Meritage_Homes__c = ''Newspaper or magazine''
              WHERE How_did_you_learn_about_Meritage_Homes__c = ''Newspaper'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Other Websites'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Referral/Friend/Relative'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Direct Mail''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Flyers Through US Mail'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''eBlast'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human Directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c LIKE ''%Human signs%'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Meritage emails''
  WHERE How_did_you_learn_about_Meritage_Homes__c =  ''E-Mail'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c =  ''Meritage Online Sales Consultant'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Friends/Family'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Internet'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Google''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Movenewhome.com'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Friend or Family'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Billboards''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Billboards''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Neighborhood Signs'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Newhomesource.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''NewHomesSource.com'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Be Back'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Be-back'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''BeBack'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Employee'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Television''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''TV/Radio'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Meritage emails''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Email'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''HumanMSigns'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Realtor recommendation''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Realtor Preview'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Realtor recommendation''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Self Generated/ Realtor Relations'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Meritage H/O Refer'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Self Generated/ Customer Referral'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Prev Meritage H/O'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Driveby'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Self Generated'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Newspaper or magazine''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Magazine'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com,MLS'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Direct Mail''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''DirectMMail'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Human Directional'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''MeritageHomes.com''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Meritage Website'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Event''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Parade of Homes'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Human directionals''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Self Generated/ Networking'''
  EXEC sp_executesql @SQL
    SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Friends or Relative'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Community directional signs''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Another Community'''
  EXEC sp_executesql @SQL
    SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Realtor recommendation''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Realtor w Client'''
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
  SET How_did_you_learn_about_Meritage_Homes__c = ''Friends and Family''
  WHERE How_did_you_learn_about_Meritage_Homes__c = ''Friend or Relative'''
  EXEC sp_executesql @SQL



  RAISERROR('Performing data transformation on required or too long fields from old prod...', 0, 1) WITH NOWAIT
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET LastName = ''None Provided''
              WHERE LastName IS NULL'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET Status = ''Nurturing''
              WHERE Status IS NULL'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET City = ''''
              WHERE LEN(City) > 40'
  EXEC sp_executesql @SQL
  SET @SQL = 'UPDATE ' + @stagingTable + '
              SET PostalCode = ''''
              WHERE LEN(PostalCode) > 5'
  EXEC sp_executesql @SQL

  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Ids from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'OwnerId'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Lender_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Secondary_Sales_Associate__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'AccountXref', 'Realtor_Company__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'ContactXref', 'Realtor_Name__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXRef', 'Original_OSC__c'


  RAISERROR('Adding row numbers to table in order to split it...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table into ~200,000 record tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Lead_Stage --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT [Anticipated_time_to_move_into_new_home__c]
      ,[MobilePhone]
      ,[FirstName]
      ,[LastName]
      ,[State]
      ,[PostalCode]
      ,[Describe_Back_Story__c]
      ,[Fears_of_Moving__c]
      ,[How_did_you_learn_about_Meritage_Homes__c]
      ,[Lender_Company__c]
      ,[Loan_Pre_Qualification_Date__c]
      ,[Original_OSC__c]
      ,[City]
      ,[LeadSource]
      ,[Primary_Sales_Associate__c]
      ,[Realtor_Company__c]
      ,[Realtor_Name__c]
      ,[Realtor_Representing__c]
      ,[Secondary_Sales_Associate__c]
      ,[Strongest_Considerations_for_new_home_se__c]
      ,[Walk_In_Date__c]
      ,[IsWebLead__c]
      ,[What_is_your_current_housing_status__c]
      ,[Old_SF_ID__c]
      ,[X7_Desired_Monthly_Payment__c]
      ,[Status]
      ,[Company]
      ,[OwnerID]
      ,[Id]
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 200000
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
      SET @SQL = 'EXEC SF_Tableloader ''Upsert:IgnoreFailures(5)'', ''' + @targetLinkedServerName + ''', ''' + @stagingTable + '_Split' + CAST(@i AS NVARCHAR(2)) + ''', ''Old_SF_ID__C'''
      SET @i = @i + 1
      EXEC sp_executeSQL @SQL
  END

  GO