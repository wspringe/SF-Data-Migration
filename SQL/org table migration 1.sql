
--Drop all tables from target/connected database:
EXEC sp_MSforeachtable @command1 = "DROP TABLE ?"

--Replicate target User and Profile tables to db:
EXEC SF_Replicate 'SFDC_TARGET', 'Profile'

EXEC SF_Replicate 'SFDC_TARGET', 'User'

EXEC SF_Replicate 'SFDC_TARGET', 'UserRole'

	SELECT * FROM dbo.[User]

	SELECT * FROM dbo.Profile
	
	SELECT * FROM userRole

--'Load' table:
	SELECT * FROM [User_load1]
	order by error
	
	/********************************************************************
	Upload notes:
	
	[User] table:	
		Rows failed on DelgatedApproverID - set to NULL or a valid UserID from target
		
		Rows failed on ManagerID - set to NULL or valid UserID value from target
		
	Migration Steps:
	Load UserRole table ---> target
	Load Profile table ---> Target
	
	Create cross-reference tables (in SQL) to store new and old ID's for new objects.
	
	Update source db User table with new USerRoleID and ProfileID values from above x-ref.
		Also possible set DelegatedApproverID and ManagerID fields to NULL, if approcved.
	
	Load [User] table via DBAmp
	
	************************************************************************/
	
	
	
--SF_Generate, to refresh schema:
exec dbo.SF_Generate @operation = 'Insert', -- nvarchar(20)
    @table_server = 'SFDC_TARGET', -- sysname
    @load_tablename = 'User_Load1' -- sysname
    
   /* 
    insert into dbo.User_Load1
            ( Id ,
              Error ,
              AboutMe ,
              Alias ,
              CallCenterId ,
              City ,
              CommunityNickname ,
              CompanyName ,
              ContactId ,
              Country ,
              DefaultGroupNotificationFrequency ,
              DelegatedApproverId ,
              Department ,
              DigestFrequency ,
              Division ,
              Email ,
              EmailEncodingKey ,
              EmailPreferencesAutoBcc ,
              EmailPreferencesAutoBccStayInTouch ,
              EmailPreferencesStayInTouchReminder ,
              EmployeeNumber ,
              Extension ,
              Fax ,
              FederationIdentifier ,
              FirstName ,
              ForecastEnabled ,
              GeocodeAccuracy ,
              IsActive ,
              LanguageLocaleKey ,
              LastName ,
              Latitude ,
              LocaleSidKey ,
              Longitude ,
              ManagerId ,
            --  MiddleName ,
              MobilePhone ,
           --   Old_SF_User_ID__c ,
           --   Old_SF_User_isActive__c ,
              Phone ,
              PostalCode ,
              ProfileId ,
              ReceivesAdminInfoEmails ,
              ReceivesInfoEmails ,
              SenderEmail ,
              SenderName ,
              Signature ,
              State ,
              StayInTouchNote ,
              StayInTouchSignature ,
              StayInTouchSubject ,
              Street ,
           --   Suffix ,
              TimeZoneSidKey ,
              Title ,
              Username ,
              UserPermissionsAvantgoUser ,
              UserPermissionsCallCenterAutoLogin ,
              UserPermissionsInteractionUser ,
              UserPermissionsKnowledgeUser ,
              UserPermissionsMarketingUser ,
              UserPermissionsMobileUser ,
              UserPermissionsOfflineUser ,
              UserPermissionsSFContentUser ,
              UserPermissionsSupportUser ,
              UserPreferencesActivityRemindersPopup ,
              UserPreferencesApexPagesDeveloperMode ,
              UserPreferencesCacheDiagnostics ,
              UserPreferencesCreateLEXAppsWTShown ,
              UserPreferencesDisableAllFeedsEmail ,
              UserPreferencesDisableBookmarkEmail ,
              UserPreferencesDisableChangeCommentEmail ,
              UserPreferencesDisableEndorsementEmail ,
              UserPreferencesDisableFileShareNotificationsForApi ,
              UserPreferencesDisableFollowersEmail ,
              UserPreferencesDisableLaterCommentEmail ,
              UserPreferencesDisableLikeEmail ,
              UserPreferencesDisableMentionsPostEmail ,
              UserPreferencesDisableMessageEmail ,
              UserPreferencesDisableProfilePostEmail ,
              UserPreferencesDisableSharePostEmail ,
              UserPreferencesDisCommentAfterLikeEmail ,
              UserPreferencesDisMentionsCommentEmail ,
              UserPreferencesDisProfPostCommentEmail ,
              UserPreferencesEnableAutoSubForFeeds ,
              UserPreferencesEventRemindersCheckboxDefault ,
              UserPreferencesFavoritesShowTopFavorites ,
              UserPreferencesFavoritesWTShown ,
              UserPreferencesGlobalNavBarWTShown ,
              UserPreferencesGlobalNavGridMenuWTShown ,
              UserPreferencesHideBiggerPhotoCallout ,
              UserPreferencesHideChatterOnboardingSplash ,
              UserPreferencesHideCSNDesktopTask ,
              UserPreferencesHideCSNGetChatterMobileTask ,
              UserPreferencesHideEndUserOnboardingAssistantModal ,
              UserPreferencesHideLightningMigrationModal ,
              UserPreferencesHideS1BrowserUI ,
              UserPreferencesHideSecondChatterOnboardingSplash ,
              UserPreferencesHideSfxWelcomeMat ,
              UserPreferencesLightningExperiencePreferred ,
              UserPreferencesPathAssistantCollapsed ,
              UserPreferencesPreviewLightning ,
              UserPreferencesRecordHomeReservedWTShown ,
              UserPreferencesRecordHomeSectionCollapseWTShown ,
              UserPreferencesReminderSoundOff ,
              UserPreferencesShowCityToExternalUsers ,
              UserPreferencesShowCityToGuestUsers ,
              UserPreferencesShowCountryToExternalUsers ,
              UserPreferencesShowCountryToGuestUsers ,
              UserPreferencesShowEmailToExternalUsers ,
              UserPreferencesShowEmailToGuestUsers ,
              UserPreferencesShowFaxToExternalUsers ,
              UserPreferencesShowFaxToGuestUsers ,
              UserPreferencesShowManagerToExternalUsers ,
              UserPreferencesShowManagerToGuestUsers ,
              UserPreferencesShowMobilePhoneToExternalUsers ,
              UserPreferencesShowMobilePhoneToGuestUsers ,
              UserPreferencesShowPostalCodeToExternalUsers ,
              UserPreferencesShowPostalCodeToGuestUsers ,
              UserPreferencesShowProfilePicToGuestUsers ,
              UserPreferencesShowStateToExternalUsers ,
              UserPreferencesShowStateToGuestUsers ,
              UserPreferencesShowStreetAddressToExternalUsers ,
              UserPreferencesShowStreetAddressToGuestUsers ,
              UserPreferencesShowTitleToExternalUsers ,
              UserPreferencesShowTitleToGuestUsers ,
              UserPreferencesShowWorkPhoneToExternalUsers ,
              UserPreferencesShowWorkPhoneToGuestUsers ,
              UserPreferencesSortFeedByComment ,
              UserPreferencesTaskRemindersCheckboxDefault ,
              UserRoleId
            )
  select
              Id ,
              Error ,
              AboutMe ,
              Alias ,
              CallCenterId ,
              City ,
              CommunityNickname ,
              CompanyName ,
              ContactId ,
              Country ,
              DefaultGroupNotificationFrequency ,
              DelegatedApproverId ,
              Department ,
              DigestFrequency ,
              Division ,
              Email ,
              EmailEncodingKey ,
              EmailPreferencesAutoBcc ,
              EmailPreferencesAutoBccStayInTouch ,
              EmailPreferencesStayInTouchReminder ,
              EmployeeNumber ,
              Extension ,
              Fax ,
              FederationIdentifier ,
              FirstName ,
              ForecastEnabled ,
              GeocodeAccuracy ,
              IsActive ,
              LanguageLocaleKey ,
              LastName ,
              Latitude ,
              LocaleSidKey ,
              Longitude ,
              ManagerId ,
             -- MiddleName ,
              MobilePhone ,
          --    Old_SF_User_ID__c ,
          --    Old_SF_User_isActive__c ,
              Phone ,
              PostalCode ,
              ProfileId ,
              ReceivesAdminInfoEmails ,
              ReceivesInfoEmails ,
              SenderEmail ,
              SenderName ,
              Signature ,
              State ,
              StayInTouchNote ,
              StayInTouchSignature ,
              StayInTouchSubject ,
              Street ,
            --  Suffix ,
              TimeZoneSidKey ,
              Title ,
              Username ,
              UserPermissionsAvantgoUser ,
              UserPermissionsCallCenterAutoLogin ,
              UserPermissionsInteractionUser ,
              UserPermissionsKnowledgeUser ,
              UserPermissionsMarketingUser ,
              UserPermissionsMobileUser ,
              UserPermissionsOfflineUser ,
              UserPermissionsSFContentUser ,
              UserPermissionsSupportUser ,
              UserPreferencesActivityRemindersPopup ,
              UserPreferencesApexPagesDeveloperMode ,
              UserPreferencesCacheDiagnostics ,
              UserPreferencesCreateLEXAppsWTShown ,
              UserPreferencesDisableAllFeedsEmail ,
              UserPreferencesDisableBookmarkEmail ,
              UserPreferencesDisableChangeCommentEmail ,
              UserPreferencesDisableEndorsementEmail ,
              UserPreferencesDisableFileShareNotificationsForApi ,
              UserPreferencesDisableFollowersEmail ,
              UserPreferencesDisableLaterCommentEmail ,
              UserPreferencesDisableLikeEmail ,
              UserPreferencesDisableMentionsPostEmail ,
              UserPreferencesDisableMessageEmail ,
              UserPreferencesDisableProfilePostEmail ,
              UserPreferencesDisableSharePostEmail ,
              UserPreferencesDisCommentAfterLikeEmail ,
              UserPreferencesDisMentionsCommentEmail ,
              UserPreferencesDisProfPostCommentEmail ,
              UserPreferencesEnableAutoSubForFeeds ,
              UserPreferencesEventRemindersCheckboxDefault ,
              UserPreferencesFavoritesShowTopFavorites ,
              UserPreferencesFavoritesWTShown ,
              UserPreferencesGlobalNavBarWTShown ,
              UserPreferencesGlobalNavGridMenuWTShown ,
              UserPreferencesHideBiggerPhotoCallout ,
              UserPreferencesHideChatterOnboardingSplash ,
              UserPreferencesHideCSNDesktopTask ,
              UserPreferencesHideCSNGetChatterMobileTask ,
              UserPreferencesHideEndUserOnboardingAssistantModal ,
              UserPreferencesHideLightningMigrationModal ,
              UserPreferencesHideS1BrowserUI ,
              UserPreferencesHideSecondChatterOnboardingSplash ,
              UserPreferencesHideSfxWelcomeMat ,
              UserPreferencesLightningExperiencePreferred ,
              UserPreferencesPathAssistantCollapsed ,
              UserPreferencesPreviewLightning ,
              UserPreferencesRecordHomeReservedWTShown ,
              UserPreferencesRecordHomeSectionCollapseWTShown ,
              UserPreferencesReminderSoundOff ,
              UserPreferencesShowCityToExternalUsers ,
              UserPreferencesShowCityToGuestUsers ,
              UserPreferencesShowCountryToExternalUsers ,
              UserPreferencesShowCountryToGuestUsers ,
              UserPreferencesShowEmailToExternalUsers ,
              UserPreferencesShowEmailToGuestUsers ,
              UserPreferencesShowFaxToExternalUsers ,
              UserPreferencesShowFaxToGuestUsers ,
              UserPreferencesShowManagerToExternalUsers ,
              UserPreferencesShowManagerToGuestUsers ,
              UserPreferencesShowMobilePhoneToExternalUsers ,
              UserPreferencesShowMobilePhoneToGuestUsers ,
              UserPreferencesShowPostalCodeToExternalUsers ,
              UserPreferencesShowPostalCodeToGuestUsers ,
              UserPreferencesShowProfilePicToGuestUsers ,
              UserPreferencesShowStateToExternalUsers ,
              UserPreferencesShowStateToGuestUsers ,
              UserPreferencesShowStreetAddressToExternalUsers ,
              UserPreferencesShowStreetAddressToGuestUsers ,
              UserPreferencesShowTitleToExternalUsers ,
              UserPreferencesShowTitleToGuestUsers ,
              UserPreferencesShowWorkPhoneToExternalUsers ,
              UserPreferencesShowWorkPhoneToGuestUsers ,
              UserPreferencesSortFeedByComment ,
              UserPreferencesTaskRemindersCheckboxDefault ,
              UserRoleId
  
  from dbo.User_Load
 */ 
  update dbo.User_Load1
  set Old_SF_User_isActive__c = 'false'
  
  ---Compare load1 table to actual user table to find obstacle:
  SELECT  l.ID , u.ID, l.*
  FROM dbo.User_Load1 l  LEFT outer join [USER] u on l.ID = u.ID
  order by l.ID
  
  --Update UserRole to Phoenix Div (00E4D000000MxfwUAC)
  SELECT UserRoleId, ID, Error  FROM dbo.User_Load1
  
	  --1. Delete records from 'Load1' table that previously loaded:
	  delete from User_Load1 where UserRoleId is null
	  
		--2. Update UserRole:
	  update dbo.User_Load1
	  set UserRoleId = '00E4D000000MxfwUAC'
	  
	  --3. Run insert proc