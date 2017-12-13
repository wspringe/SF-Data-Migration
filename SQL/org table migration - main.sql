
/***********************************************************************
Script for migrating 'base' objects to new Salesforce org, via DB Amp:

Profile, User, UserRole

11/3/2017

***********************************************************************/

--Create/modify linked server to point to new prod. org, if needed.

--1:  Replicate/refresh above objects to local PROD database:

use Salesforce_Backup_Prod

EXEC SF_Replicate 'SALESFORCE', 'User'

EXEC SF_Replicate 'SALESFORCE', 'UserRole'

EXEC SF_Replicate 'SALESFORCE', 'Profile'

--Handle DelgatedApproverID - set to NULL or a valid UserID from target
		
--Handle ManagerID - set to NULL or valid UserID value from target
		
	SELECT * FROM [User]
	
	select distinct Profile_Name__c, ProfileId
	from [dbo].[User] 
	where IsActive = 'true'
	
	/***************************************
	AccountID  - set to null
	CallCenterID  - Set to Null
	ContactID - set to Null
	CreatedByID - Set to SFAdmin
	DelegatedApproverID - USerID
	LastModifiedByID - set to SFAdmin
	UserRoleID  - Create XRef
	
		
	******************************************/
	
	--Create Load table:
	
	
	
	SELECT * FROM dbo.Contact


/*********************************************
Migration Steps:
	1. Load UserRole table ---> target
	2. Load Profile table ---> Target
	3. Load Update ID's in User 'Load' table.
	
*********************************************/


--. Populate 'Load' tables from these replicated source tables, to push to new org:

	
	--1. User
	SELECT * 
	into User_Load
	FROM dbo.[User]

	alter table User_Load
	add [Error] NVARCHAR(255)

	update dbo.User_Load
	set AccountId = null
		
	update dbo.User_Load
	set CallCenterId = null

		update dbo.User_Load
	set ContactID = null
	
	--update dbo.User_Load
	--set CreatedByID = '0054D000000EC1ZQAW'

	update dbo.User_Load
	set DelegatedApproverID = '0054D000000EC1ZQAW'

	update dbo.User_Load
	set UserRoleId = ''

	-------------------------------------------------
	SELECT * 
	into SFDCTargetOrg.dbo.User_Load2
	FROM user_Load
	
	-------------------------------------------------
	--UserRole
	
	--1. write source data to target org. db:
	SELECT * 
	into SFDCTargetOrg.dbo.UserRole_Stage
	FROM dbo.UserRole
	
	
	SELECT * FROM dbo.UserRole where ID = '00EC0000001F69nMAC'
	SELECT * FROM dbo.[User] where UserRoleId = '00EC0000001F69nMAC'
	
	
	
	
	
	
	
	
	
	
	SELECT * FROM SFDCTargetOrg.dbo.[User]











	--Profile
	SELECT * 
	into Profile_Load
	FROM dbo.[Profile]

	alter table Profile_Load
	add [Error] NVARCHAR(255)

	--UserRole
	SELECT * 
	into UserRole_Load
	FROM dbo.[UserRole]

	alter table UserRole_Load
	add [Error] NVARCHAR(255)
	


--Populate UserRole and Profile with Old/xref ID's:
alter table Profile_Load
add ID_old CHAR(18)

alter table UserRole_Load
add ID_old CHAR(18)



------------------------------------------------------------------
--Modify User table to include new profile ID's and UserRole ID's:
use SFDCTargetOrg

SELECT ID, ProfileId, UserRoleId, IsActive, LastModifiedDate
FROM dbo.[User]

--=============================================================

select ID, Name
from dbo.Profile