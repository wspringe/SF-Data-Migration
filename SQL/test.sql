DECLARE @ret_code int
EXEC @ret_code = dbo.SF_BulkOps 'update', 'SFDC_TARGET', 'Bronto_Required_Fields__c_Stage'
IF @ret_code != 0
  RAISERROR('AHHH!!! %d', 0, 1, @ret_code) WITH NOWAIT
