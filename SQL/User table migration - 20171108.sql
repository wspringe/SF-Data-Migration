

SF_Replicate 'SFDC_TARGET', 'Profile'

SELECT * FROM dbo.Profile

SELECT t.ID, t.Name, s.ID, t.Name
--into ProfileXRef 
FROM dbo.Profile t join Salesforce_Backup_Prod.dbo.Profile s
	on s.Name = t.Name


SELECT * FROM dbo.ProfileXRef

alter table dbo.ProfileXRef
add [SourceID] NCHAR(18)


update dbo.ProfileXRef
set SourceID = s.ID 
FROM dbo.ProfileXRef t join Salesforce_Backup_Prod.dbo.Profile s
	on s.Name = t.Name
	

exec dbo.SF_Replicate @table_server = 'SFDC_TARGET', -- sysname
    @table_name = 'Profile', -- sysname
    @options = null -- nvarchar(255)


SELECT * FROM dbo.ProfileXRef
	
	
--------------------------------------------------------------------
SELECT ID, FirstName, LastName, ProfileId, Profile_Name__c , x.SourceID, x.TargetID
FROM dbo.User_Load2 u join dbo.ProfileXRef x
	on u.ProfileId = x.TargetID
where LastName = 'salmon'



--Update ProfileID in User_Load2:
update dbo.User_Load2
set ProfileId = x.TargetID
from dbo.ProfileXRef x join dbo.User_Load2 u
	on x.SourceID = u.ProfileId
	
	
--=========================================================
--UserRole
--Create X_Ref table:

USE [SFDCTargetOrg]
GO

/****** Object:  Table [dbo].[ProfileXRef]    Script Date: 11/09/2017 15:27:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UserRoleXRef](
	[TargetID] [nchar](18) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[SourceID] [nchar](18) NULL
) ON [PRIMARY]

GO


--Replicate:

SF_Replicate 'SFDC_TARGET', 'UserRole'

--Validate:
SELECT * FROM dbo.UserRole

--Populate X_Ref:
insert into dbo.UserRoleXRef
        ( TargetID, Name, SourceID )
select distinct ID, Name, null
from dbo.UserRole

		SELECT * FROM dbo.UserRoleXRef

--Update to populate SourceID:

update dbo.UserRoleXRef
set SourceID = s.ID 
FROM dbo.UserRoleXRef t join Salesforce_Backup_Prod.dbo.UserRole s
	on s.Name = t.Name


--Update USer_Load2:
update dbo.User_Load2
set UserRoleIdTarget = x.TargetID
from dbo.USerRoleXRef x join dbo.User_Load2 u
	on x.SourceID = u.UserRoleId
	
	
	--alter table dbo.User_Load2
	--add [UserRoleIDTarget]  NCHAR(18)
	
	
	select u.ID, u.UserRoleID, u.[UserRoleIDTarget], x.Name 
	from dbo.User_Load2 u LEFT outer join dbo.UserRoleXRef x
		on UserRoleIDTarget = x.TargetID
		
		
SELECT * FROM dbo.User_Load2

--Set rows to 'inactive'
update dbo.User_Load2
set IsActive = 'false'
where ID != '0051A00000BDMy3QAH'

			select ID, firstname, lastname, isactive, username
			from dbo.User_Load2
			where LastName = 'springer'
			

--UPSERT USer_Load2 records:

	exec dbo.SF_BulkOps @operation = 'Upsert', -- nvarchar(200)
	    @table_server = 'SFDC_TARGET', -- sysname
	    @table_name = 'User_Load2', -- sysname
	    @opt_param1 = 'username' -- nvarchar(512)
	    --@opt_param2 = null -- nvarchar(512)
			
