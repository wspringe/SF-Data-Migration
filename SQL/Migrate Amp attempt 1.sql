Create Table KeyObjects (ObjectName sysname)

--truncate table KeyObjects

--Insert into KeyObjects (ObjectName) Values  ('CallCenter')
Insert into KeyObjects (ObjectName) Values  ('Opportunity__c')
--Insert into KeyObjects (ObjectName) Values  ('UserRole')
Insert into KeyObjects (ObjectName) Values  ('Community__c')
--Insert into KeyObjects (ObjectName) Values  ('Account')
--Insert into KeyObjects (ObjectName) Values  ('Contact')

delete from KeyObjects where ObjectName = 'Profile'
------------------------------





--drop table dbo.KeyObjects
SELECT * FROM KeyObjects

---------------------------------------------------------------------------

Exec SF_MigrateBuilder 'KeyObjects', 'Gay', 'SALESFORCE',
'SFDC_TARGET', 'SFDCTargetOrg', 'Children(None), Features(A), Parents(Req)'

---------------------------------------------------

--exec dbo.SFProfile_Replicate

SELECT ID, LastModifiedDate, IsActive, * 
FROM dbo.[User]
--where Username like 'wesley.springer%'
order by 1 desc

drop table userbackup

		--SELECT LastModifiedDate, IsActive, Id, Username
		--into UserBackup 
		--FROM dbo.[User]

		--SELECT * FROM UserBackup

--Update USER table:
update dbo.[User]
set IsActive = 'false'
where ID != '0051A00000BDMy3QAH'

--=============================================================================================

--11/1/17: Profile object

exec dbo.DBM_Replicate

	SELECT * FROM dbo.Profile
	order by name
	
	SELECT * FROM dbo.UserLicense
	
	update dbo.Profile
	set CreatedById = '0054D000000nyn7QAA', LastModifiedById = '0054D000000nyn7QAA'
	

--
SELECT * FROM keyObjects

delete from keyobjects
where ObjectName = 'User'
-----------------------------------------------------------

EXEC SF_Replicate 'SALESFORCE', 'User'

SELECT IsActive, * FROM dbo.[User]
where lastname = 'helle'
order by 1