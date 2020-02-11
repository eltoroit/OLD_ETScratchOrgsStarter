// Enable debug mode for the default scratch org user
User defaultUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
defaultUser.UserPreferencesUserDebugModePref = true;
update defaultUser;