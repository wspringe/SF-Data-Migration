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