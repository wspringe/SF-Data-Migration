USE SF_Data_Migration
GO
CREATE PROCEDURE Create_Cross_Reference_Table (
  @objectName VARCHAR(50),
  @uniqueIdentifier VARCHAR (50)

  /*
    This stored procedure is used for inserting roles into the new Salesforce org from the old Salesforce org.

    Circular definition fields: DelegateApproverID, ManagerId, ContactId, AccountId, CallCenterId, 

    Need: Call_Center__c, Contacts

    Cross-Reference: Profiles and Roles
*/
)
AS
  DECLARE @objTarget VARCHAR(50)
  DECLARE @objSource VARCHAR(50)
  DECLARE @SQL NVARCHAR(250)

  SET @objTarget = @objectName + '_Target'
  SET @objSource = @objectName + '_Source'

  -- Replicate UserRole object from target org and rename it to UserRole_Target
  EXEC SF_Replicate 'SALESFORCE', @objectName
  EXEC sp_rename @objectName, @objSource

  -- Create UserRole cross-reference table
  SET @SQL = 'SELECT s.Id, s.' + @uniqueIdentifier + ' 
  INTO ' + @objectName + 'XRef 
  FROM dbo.' + @objSource

  EXEC sp_executesql @SQL

    -- Replicate UserRole object from target org and rename it to UserRole_Target
  EXEC SF_Replicate 'SFDC_TARGET', @objectName
  EXEC sp_rename @objectName, @objTarget
  
   -- Change column name to SourceID from Id
  SET @SQL = 'sp_rename ' + @objectName + 'XRef.Id, ''SourceID'', ''COLUMN'''
  EXEC sp_executesql @SQL
  
  -- Add new column of TargetID to UserRoleXRef table
  SET @SQL = 'ALTER TABLE ' + @objectName + 'XRef add [TargetID] NCHAR(18)'
  EXEC sp_executesql @SQL

  -- Fill in the TargetId column
  SET @SQL = 'UPDATE dbo.' + @objectName + 'XRef
  set TargetID = t.Id
  FROM ' + @objTarget + 't JOIN ' + @objectName + 'XRef s
    on t.Name = s.Name'
  EXEC sp_executesql @SQL

  

  GO