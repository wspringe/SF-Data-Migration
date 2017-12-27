USE [SF_Data_Migration]
EXEC dbo.Insert_Users 'User'

EXEC SF_REPLICATE 'SALESFORCE', 'Bronto_Required_Fields__c_Stage'

SELECT * FROM Bronto_Required_Fields__c_Stage
EXEC Insert_CustomSettings 'Bronto_Required_Fields__c'


FIELD_INTEGRITY_EXCEPTION: field integrity exception: unknown (CreatedByID(005C0000003FpMN) is not in org.)

FIELD_INTEGRITY_EXCEPTION: field integrity exception: SetupOwnerId (id value of incorrect type)

FIELD_INTEGRITY_EXCEPTION: field integrity exception: unknown (id value of incorrect type)


UPDATE Bronto_Required_Fields__c_Stage SET SetupOwnerId = Organization.Id FROM Organization
EXEC dbo.SF_BulkOps 'Insert', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
EXEC dbo.SF_BulkOps 'Update', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
EXEC dbo.SF_BulkOps 'Upsert', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage', 'Id'

EXEC dbo.SF_BulkOps 'Delete', 'SFDC_Target', 'Bronto_Required_Fields__c_Stage'
00D4D0000008fi3UAA
-- Take ids from target org, update stage table, and upsert on id?
EXEC SF_REPLICATE 'SFDC_TARGET', 'Bronto_Required_Fields__c'
UPDATE Bronto_Required_Fields__c_Stage SET Bronto_Required_Fields__c_Stage.Id = Bronto_Required_Fields__c.Id FROM Bronto_Required_Fields__c_Stage INNER JOIN Bronto_Required_Fields__c ON
Bronto_Required_Fields__c_Stage.Name = Bronto_Required_Fields__c.Name
SELECT * FROM Organization

UPDATE Bronto

SELECT * FROM CallCenter_Stage
CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY: entity type cannot be updated: Call Center

SELECT * FROM EPH_Approval_Hierarchical__c_Stage
DUPLICATE_VALUE: duplicate value found: SetupOwnerId duplicates value on record with id: 00D4D0000008fi3

SELECT * FROM Process_Bypass_Admins__c_FromTarget
SELECT * FROM Process_Bypass_Admins__c_stage
UPDATE Process_Bypass_Admins__c_Stage SET Id = x.Id FROM Process_Bypass_Admins__c_FromTarget x
WHERE x.Name = Process_Bypass_Admins__c_Stage.Name

Process Bypass - Admins (Organization)
Process Bypass - Admins (Profile)
Process Bypass - Admins (Profile)

EXEC SF_Replicate 'SALESFORCE', 'Process_Bypass_Admins__c'

UPDATE Process_Bypass_Admins__c SET SetupOwnerId = x.TargetID
  FROM ProfileXRef x
  WHERE x.SourceID = SetupOwnerID
--IF @objectName = 'Process_Bypass_Admins__c'
ALTER TABLE Process_Bypass_Admins__c ADD [ERROR] NVARCHAR(1000) NULL

UPDATE Process_Bypass_Admins__c_Stage SET Id = x.Id FROM Process_Bypass_Admins__c_FromTarget x
WHERE x.Id = Process_Bypass_Admins__c_Stage.Id

EXEC SF_BulkOps 'DELeTE', 'SFDC_TARGET', 'Process_Bypass_Admins__c'
DROP TABLE Process_Bypass_Admins__c

DELETE TOP (1) FROM Process_Bypass_Admins__c
UPDATE Process_Bypass_Admins__c SET Id = ''

BEGIN
  DROP TABLE Process_Bypass_Admins__c_stage
  DROP TABLE Process_Bypass_Admins__c
END

BEGIN
  EXEC SF_Replicate 'SALESFORCE', 'Process_Bypass_Admins__c'
  ALTER TABLE Process_Bypass_Admins__c ADD [ERROR] NVARCHAR(1000) NULL
END

EXEC sp_rename 'Process_Bypass_Admins__c', 'Process_Bypass_Admins__c_Stage'
EXEC SF_Replicate 'SFDC_TARGET', 'Process_Bypass_Admins__c'

ALTER TABLE Process_Bypass_Admins__c add [Old_SF_ID__c] NCHAR(18)
UPDATE Process_Bypass_Admins__c SET Old_SF_ID__c = Id
EXEC SF_BulkOps 'insert', 'SFDC_TARGET', 'Process_Bypass_Admins__c'
EXEC SF_BulkOps 'Upsert', 'SFDC_TARGET', 'Process_Bypass_Admins__c', 'Old_SF_ID__c'

  -- add external id of old id value to Process_Bypass_Admins__c
  EXEC SF_Replicate 'SALESFORCE', 'Design_Center__c'
  SELECT * FROM Design_Center__c