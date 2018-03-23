USE [SF_Data_Migration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Insert_Lot] (
  @objectName VARCHAR(50),
  @targetLinkedServerName VARCHAR(50),
  @sourceLinkedServerName VARCHAR(50)

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
  SET @stagingTable = @objectName + '_Stage' 
  SET @targetOrgTable = @objectName + '_FromTarget'

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

  SET @SQL = 'IF OBJECT_ID(''' + @targetOrgTable + ''', ''U'') IS NOT NULL
    DROP TABLE ' + @targetOrgTable
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
  EXEC Create_Id_Based_Cross_Reference_Table 'Community__c', @targetLinkedServerName, @sourceLinkedServerName
  EXEC Create_Id_Based_Cross_Reference_Table 'Plan__c', @targetLinkedServerName, @sourceLinkedServerName

  -- Update stage table with new Ids for Region lookup
  RAISERROR('Replacing Division__c from target org...', 0, 1) WITH NOWAIT
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Community__cXref', 'Community__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'Plan__cXref', 'Plan__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Approver_1__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Approver_2__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Approver_3__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Approver_4__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Approver_5__c'
  EXEC Replace_NewIds_With_OldIds @stagingTable, 'UserXref', 'Builder_Superintendent__c'

  RAISERROR('Adding row numbers to table...', 0, 1) WITH NOWAIT
  SET @SQL = 'ALTER TABLE ' + @stagingTable + ' ADD [Sort] int IDENTITY (1,1)'
  EXEC sp_executesql @SQL

  RAISERROR('Splitting %s table in 2 tables', 0, 1, @stagingTable) WITH NOWAIT
  DECLARE @maxRows INT
  DECLARE @i INT = 1
  DECLARE @count INT = 0
  SELECT @maxRows = COUNT(Id) FROM Lot__c_Stage --don't forget to change this
  WHILE @i < @maxRows
  BEGIN
    SET @SQL = 'SELECT [Accessories__c]
      ,[Address_Last_Verified_Date__c]
      ,[Address_Return_Code__c]
      ,[Address_Verified__c]
      ,[Apply_Approvers__c]
      ,[Approval_Date__c]
      ,[Approval_Initial_Submitter_Email__c]
      ,[Approval_OK__c]
      ,[Approval_Status__c]
      ,[Approval_Type__c]
      ,[Approver_1__c]
      ,[Approver_2__c]
      ,[Approver_3__c]
      ,[Approver_4__c]
      ,[Approver_5__c]
      ,[Bar_Countertop__c]
      ,[Base_House_Price__c]
      ,[BDX_Hot_Home_Description__c]
      ,[BDX_Hot_Home_Title__c]
      ,[Bedrooms__c]
      ,[Block__c]
      ,[Brick_Color__c]
      ,[Builder__c]
      ,[Builder_Superintendent__c]
      ,[Builder_Superintendent_Email__c]
      ,[Builder_Superintendent_Name__c]
      ,[Builder_Superintendent_Phone__c]
      ,[Builder_Superintendent_Title__c]
      ,[Building__c]
      ,[Cabinet_Style__c]
      ,[City__c]
      ,[Close_Date__c]
      ,[CMS_ID__c]
      ,[Color_Hold__c]
      ,[Color_Package__c]
      ,[Community__c]
      ,[Construction_Completed_Date__c]
      ,[Construction_Stage__c]
      ,[Construction_Start__c]
      ,[Construction_Status_Last__c]
      ,[Country__c]
      ,[Custom_Color__c]
      ,[Division_Name__c]
      ,[DocuSign_Delivery__c]
      ,[Estimated_Completion_Date__c]
      ,[Estimated_Completion_Month_Change__c]
      ,[Exclude_Inventory_Pricing_Update__c]
      ,[Exterior_Stone__c]
      ,[Flooring_Installed__c]
      ,[Force_Integration__c]
      ,[Front_Door__c]
      ,[Full_Bathrooms__c]
      ,[Garage_Type__c]
      ,[Garages__c]
      ,[Geolocation__Latitude__s]
      ,[Geolocation__Longitude__s]
      ,[Half_Bathrooms__c]
      ,[Headline__c]
      ,[Historic_Data__c]
      ,[Homesite_Available__c]
      ,[Incentive1__c]
      ,[Interior_Door_Hardware__c]
      ,[Interior_Door_Style__c]
      ,[Interior_Paint_Color__c]
      ,[IsStarted__c]
      ,[jdeLotMasterKey__c]
      ,[Kitchen_Countertop_Edge__c]
      ,[Kitchen_Faucet__c]
      ,[Kitchen_Sink__c]
      ,[Laundry_Countertop__c]
      ,[Legal_Description__c]
      ,[Lighting__c]
      ,[Linen_Countertop__c]
      ,[Living_Areas__c]
      ,[Lot_Address__c]
      ,[Lot_Number__c]
      ,[Lot_Premium__c]
      ,[Lot_Premium_Change_Date__c]
      ,[Lot_Release_Date__c]
      ,[Lot_Size__c]
      ,[Lot_Text__c]
      ,[MHDC_Published_Sales_Price__c]
      ,[MHDC_Published_Sales_Price_Lock__c]
      ,[MLS_Date__c]
      ,[MLS_Last_Price_Change__c]
      ,[MLS_Number__c]
      ,[MLS_Price_override__c]
      ,[MLS_URL__c]
      ,[Model__c]
      ,[Model_Status__c]
      ,[Name]
      ,[Permit_Number__c]
      ,[Permit_Received__c]
      ,[Permit_Submitted__c]
      ,[Plan__c]
      ,[Postal_Zip_Code__c]
      ,[Previous_Lot_Premium__c]
      ,[Previous_MLS_price__c]
      ,[QMI_Description__c]
      ,[Released_for_Construction__c]
      ,[Roof_Tile__c]
      ,[Section__c]
      ,[Snipe__c]
      ,[Snipe_Variable__c]
      ,[Solar_Addendum__c]
      ,[SourceID__c]
      ,[Spec__c]
      ,[Square_Feet__c]
      ,[Stair_Rail_Stain__c]
      ,[State__c]
      ,[Status__c]
      ,[Status_Before_Sale_or_Transfer__c]
      ,[Stories__c]
      ,[Swing__c]
      ,[Tax_Parcel_Number__c]
      ,[Tract__c]
      ,[Unit__c]
      ,[Verified_Address_Line_1__c]
      ,[Verified_Address_Line_2__c]
      ,[Verified_City__c]
      ,[Verified_Geolocation__Latitude__s]
      ,[Verified_Geolocation__Longitude__s]
      ,[Verified_Postal_Code__c]
      ,[Verified_State__c]
      ,[Warranty_Orientation_Complete__c]
      ,[Warranty_Record_Created_E1__c]
      ,[Window_Treatment_Detail__c]
      ,[Old_SF_ID__c]
      ,[Id]
    INTO ' + @stagingTable + '_Split' + CAST(@count AS NVARCHAR(10)) +
    CHAR(10) + 'FROM ' + @stagingTable + '
    WHERE Sort >= '  + CAST(@i AS NVARCHAR(10)) + ' AND Sort <= '
    SET @i = @i + 60000
    IF @i > @maxRows
      SET @i = @maxRows
    SET @SQL = @SQL + CAST(@i AS NVARCHAR(10)) + ' ORDER BY Community__c'
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