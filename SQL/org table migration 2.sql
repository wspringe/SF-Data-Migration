use SFDCTargetOrg

exec dbo.SFProfile_Load

SELECT * FROM dbo.CallCenter_Load_SFProfile

SELECT * FROM dbo.CallCenter_Update_SFProfile




SELECT * FROM dbo.UserRole_Load_SFProfile

SELECT * FROM dbo.Profile_Update_SFProfile

--'FIELD_INTEGRITY_EXCEPTION: field integrity exception: unknown (Case access level below organization default)'

SELECT * FROM dbo.TablesToSkip

--============================================================================
--USer and Profile tables:


exec dbo.DBM_Load @KeyObjectIdsTable = null -- sysname

exec dbo.DBM_Reset @ResetAll = null -- nvarchar(20)


SELECT * FROM dbo.User_Update_DBM

--=============================================================================================

--11/1/17: Profile, UserLicense objects

exec dbo.DBM_Load @KeyObjectIdsTable = null -- sysname

SELECT * FROM dbo.Profile_Update_DBM

SELECT * FROM dbo.UserLicense_Load_DBM

--Reset:
--exec dbo.SFProfile_Reset @ResetAll = null -- nvarchar(20)

--============================================================================
--11/2/17: User and Profile tables:


exec dbo.Migrate_Load @KeyObjectIdsTable = 'keyObjects' -- sysname


--exec dbo.DBM_Reset @ResetAll = null -- nvarchar(20)
SELECT * FROM dbo.CrossReference_Migrate

SELECT * FROM dbo.User_Update_Migrate_Result

SELECT * FROM dbo.Profile_Update_Migrate
SELECT * FROM dbo.Profile_Update_Migrate_Result

--===========================================================
--Load users into Sandbox using traditional DBAmp:

SELECT * FROM User_Load

--set all user records to 'inactive' except for wesley:
SELECT ID, LastModifiedDate, IsActive, * 
FROM dbo.User_Load
where Username like 'wesley.springer%'

update dbo.User_Load
set IsActive = 'false'
where ID != '0051A00000BDMy3QAH'

--0051A00000BDMy3QAH

--Delete existing users(already in target):



--Only Load users where profile = 'Meritage Sales Assoc. (00eC00000011uK9IAI)
	SELECT COUNT(*) from dbo.User_Load

	SELECT COUNT(*) FROM dbo.User_Load
	where ProfileId <> '00eC00000011uK9IAI'
	
	delete from dbo.User_Load
	where ProfileId <> '00eC00000011uK9IAI'
	
	SELECT * FROM dbo.User_Load
	order by LastName
	
	--Update records in Load table with current 'meritage Sales Assoc.' profile ID
	--1. get the ID
	SELECT ID FROM  dbo.Profile
	where name = 'Meritage Sales Associate'
	--00e4D000000HlplQAC
	
	--2. Update
	update dbo.User_Load
	set ProfileId = '00e4D000000HlplQAC', error = null
	
	
	
		SELECT * FROM dbo.[User]
	
	--Prep 'load' table for insert
	alter table dbo.User_Load1
	add [Error] NVARCHAR(255)

		--manually insert:
	exec dbo.SF_BulkOps @operation = 'Insert', -- nvarchar(200)
	    @table_server = 'SFDC_TARGET', -- sysname
	    @table_name = 'User_Load1' -- sysname
	    --@opt_param1 = null, -- nvarchar(512)
	    --@opt_param2 = null -- nvarchar(512)
	
		SELECT Old_SF_User_isActive__c,* 
		FROM dbo.User_Load1
		
		
	--error 1: INVALID_CROSS_REFERENCE_KEY: invalid cross reference id
	
	--error 2: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY: insufficient access rights on cross-reference id