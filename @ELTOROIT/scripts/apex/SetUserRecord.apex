// sfdx force:apex:execute -f ./@ELTOROIT/scripts/apex/SetUserRecord.apex

// Find me
User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

// Enable debug mode for the default scratch org user
me.UserPreferencesUserDebugModePref = true;
update me;
