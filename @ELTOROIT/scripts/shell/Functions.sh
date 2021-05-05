# Colors:
# 	https://www.shellhacks.com/bash-colors/
# 	https://misc.flogisoft.com/bash/tip_colors_and_formatting
function promptUser() {
	printf "\033[0m"
	read -e answer
	printf "\n"	
}
function showStatus() {
	# Magenta
	printf "\033[0;35m$1\033[0m\n"
}
function showCommand() {
	printf "\033[0;33m$*\033[0m\n"
}
function showComplete() {
	# Green
	# printf "\033[0;32mTask Completed\033[0m\n"
	printf "\033[0;32m"
	echo "Task Completed"
	date
	printf "\033[0m\n"
}
function ReportError() {
	printf "\033[0;31m\n"
	printf "Org could not be created!\n"
	if [[ "$QUIT_ON_ERRORS" = true ]]; then
		if [[ "$USER_ON_SCREEN" = true ]]; then 
			printf "Press [Enter] key to exit process..."
			promptUser
			exit 1
		else
			printf "\033[0m"	
			exit 1
		fi
	else
		printf "Press [Enter] key to continue..."
		promptUser
	fi
}
function showPause(){
	# This will fail on an automated process, but not sure how to fix it.
	# Should I ask? Should I skip? Should I error?
	if [[ "$USER_ON_SCREEN" = true ]]; then 
		printf "\033[0;35m\n"
		printf "%s " $*
		printf "\n"
		printf "Press [Enter] key to continue...  "
		promptUser
	else
		printf "\033[0;31m"
		printf "Automated tests! Should not be prompting for this"
		printf "\033[0m\n"
		ReportError
	fi
}

# SFDX Core functions 
function et_sfdx(){
	showCommand "sfdx $*"
	sfdx $* || ReportError
}
function et_sfdxPush(){
	showStatus "*** Pushing metadata to scratch Org..."
	showCommand "sfdx $*"
	etFile=etLogs/push.json
	showCommand "Push logs are here: $etFile"
	sfdx $* >> $etFile
	local resultcode=$?
	if [[ "$AUTOMATED_PROCESS" = true ]]; then 
		cat $etFile
	fi
	if [[ $resultcode -ne 0 ]]; then
		ReportError
	else
		showComplete
	fi
}
function et_sfdxExecuteApex(){
	showCommand "sfdx force:apex:execute -f "$1" --json >> $2"
	sfdx force:apex:execute -f "$1" --json > $2
	local resultcode=$?
	if [[ "$AUTOMATED_PROCESS" = true ]]; then 
		cat $2
	fi
	if [[ $resultcode -ne 0 ]]; then
		ReportError
	else
		# check for apex compilation success
		COMPILE_SUCCESS=`cat $2 | jq -r .result.compiled`
		if [ $COMPILE_SUCCESS != "true" ]
		then
			# The result json contains a terse error description without too much noise
			cat "$2" | jq -r .result
			ReportError
		else
			# Show execution output
			cat "$2" | jq -r .result.logs
			# check for apex execution success
			EXECUTION_SUCCESS=`cat "$2" | jq -r .result.success`
			if [ $EXECUTION_SUCCESS != "true" ]
			then
				# Returning just the logs value will mean it renders correctly in terminal without escaped characters
				cat "$2" | jq -r .result | jq 'del(.logs)'
				ReportError
			else
				showComplete
			fi
		fi
	fi
}
function et_sfdxDeploy(){
	showStatus "*** Deploying metadata ..."
	showCommand "sfdx $*"
	etFile=etLogs/deploy.json
	showCommand "Deploy logs are here: $etFile"
	sfdx $* >> $etFile
	local resultcode=$?
	if [[ "$AUTOMATED_PROCESS" = true ]]; then 
		cat $etFile
	fi
	if [[ $resultcode -ne 0 ]]; then
		ReportError
	else
		showComplete
	fi
}
function jq_sfdxGeneratePassword() {
	et_sfdx force:user:password:generate --json
	et_sfdx force:user:display --json
	
	# https://github.com/forcedotcom/cli/issues/417
	# Display has a bug where the password is encripted on display and can't be shown. 
	# Issue has been fixed, so no need for this anymore
	# showCommand "Generates Password"
	# etFile=etLogs/userInfo.json
	# etFileTemp=$etFile.tmp
	# sfdx force:user:password:generate --json > $etFileTemp
	# sfdx force:user:display --json > $etFile
	# pwd=$(jq -r '.result.password' $etFileTemp)
	# jq --arg pwd "$pwd" '.result.password = $pwd' $etFile > $etFileTemp && mv $etFileTemp $etFile
	# cat $etFile | jq .
}
function jq_sfdxRunApexTests() {
	showCommand "sfdx $*"
	etFile="etLogs/$APEX_TEST_LOG_FILENAME.json"
	sfdx $* >> $etFile
	local resultcode=$?
	if [[ $resultcode -ne 0 ]]; then
		if [[ "$AUTOMATED_PROCESS" = true ]]; then 
			cat $etFile
		else 
			cat $etFile | jq "del(.result.tests, .result.coverage)"
		fi
		printf "\033[0;31m\n"
		printf "Tests run, but they failed!\n"
		if [[ "$QUIT_ON_ERRORS" = true ]]; then
			if [[ "$USER_ON_SCREEN" = true ]]; then 
				printf "Press [Enter] key to exit process...  "
				promptUser
			fi
			exit 1
		fi
		if [[ "$USER_ON_SCREEN" = true ]]; then 
			printf "Press [Enter] key to continue...  "	
			promptUser
		fi
	else
		cat $etFile | jq "del(.result.tests, .result.coverage)"
	fi
}
function backupAlias() {
	showCommand "sfdx force:alias:list --json"
	etFile=etLogs/aliasList.json
	sfdx force:alias:list --json >> $etFile
	if [[ "$AUTOMATED_PROCESS" = true ]]; then 
		cat $etFile
	fi

	showCommand "Backing up org: $ALIAS"
	cat $etFile | jq --arg JQALIAS "$ALIAS" '.result[] | select(.alias==$JQALIAS) | .value' | while read -r UN; do
		local TEMP="${UN%\"}"
		UN="${TEMP#\"}"
		# showCommand "[$ALIAS.bak] <= [$UN]"
		et_sfdx force:alias:set $ALIAS.bak=$UN
	done
}

#####################################################################################################################################################################
# Script macro-pieces
#####################################################################################################################################################################
function mainRunJest() {
	# --- Run JEST tests before anything else!
	if [[ "$RUN_JEST_TESTS" = true ]]; then
		showStatus "*** Running JEST tests... ($0 ${FUNCNAME[0]})"
		etFile=etLogs/jestTests.json
		showCommand "JEST logs are here: $etFile"
		npm run test:unit:CICD &> $etFile
		local resultcode=$?
		if [[ $resultcode -ne 0 ]]; then
			if [[ "$AUTOMATED_PROCESS" = true ]]; then 
				cat $JEST_LOG
			fi
	 		ReportError
		else
			showComplete
		fi
	else
		showStatus "*** JEST tests are being skipped! *** ($0 ${FUNCNAME[0]})"
	fi	
}
function mainBackupAlias() {
	# --- Backup this org alias
	if [[ "$BACKUP_ALIAS" = true ]]; then
		showStatus "*** Backup this org alias... ($0 ${FUNCNAME[0]})"
		backupAlias
		showComplete
	fi
}
function mainCreateScratchOrg() {
	# --- Create scratch org
	showStatus "*** Creating scratch Org... ($0 ${FUNCNAME[0]})"
	et_sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias "$ALIAS" -d "$DAYS"
	sfdx force:config:set defaultusername="$ALIAS"
	showComplete
}
function mainPauseToCheck() {
	# --- Pause to valiate org created
	if [[ "$PAUSE2CHECK_ORG" = true ]]; then
		showStatus "*** Opening scratch Org... ($0 ${FUNCNAME[0]})"
		et_sfdx force:org:open
		showPause "Stop to validate the ORG was created succesfully."
	fi
}
function mainOpenDeployPage() {
	# --- Open deploy page to watch deployments
	if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
		showStatus "*** Open page to monitor deployment... ($0 ${FUNCNAME[0]})"
		et_sfdx force:org:open --path=$DEPLOY_PAGE
	fi
}
function mainPrepareOrg() {
	# --- Prepare the org before deployment
	if [ ! -z "$PREPARE_ORG" ]; then
		showStatus "*** Preparing the org... ($0 ${FUNCNAME[0]})"
		for METADATA_API in ${PREPARE_ORG[@]}; do
			sfdx force:mdapi:deploy --deploydir "$METADATA_API" --wait 30
		done
		showComplete
	fi
}
function mainManualMetadataBefore() {
	# --- Manual metadata (before deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_BEFORE" ]]; then
		showStatus "*** Open page to configure org (BEFORE pushing)... ($0 ${FUNCNAME[0]})"
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_BEFORE"
		showPause "Configure additonal metadata BEFORE pushing..."
	fi
}
function mainExecuteApexBeforePush() {
	# --- Execute Apex Anonymous code (Before Push)
	if [ ! -z "$EXEC_ANON_APEX_BEFORE_PUSH" ]; then
		for APEX in ${EXEC_ANON_APEX_BEFORE_PUSH[@]}; do
			showStatus "*** Execute Anonymous Apex (before push): [$APEX]... ($0 ${FUNCNAME[0]})"
			et_sfdxExecuteApex "$APEX" "etLogs/apexBeforePush.json"
			# et_sfdx force:apex:execute -f "$APEX" --json
		done
		showComplete
	fi
}
function mainInstallPackages() {
	# --- Install Packages (Before Push)
	if [ ! -z "$PACKAGES" ]; then
		showStatus "*** Installing Packages (before push)... ($0 ${FUNCNAME[0]})"
		for PACKAGE in ${PACKAGES[@]}; do
			# if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
			# 	et_sfdx force:org:open --path=$DEPLOY_PAGE
			# fi
			et_sfdx force:package:install --apexcompile=all --package "$PACKAGE" --wait=30 --noprompt
		done
		showComplete
	fi
}
function mainDeploy() {
	if [[ "$PERFORM_DEPLOY" = true ]]; then
		showStatus "*** Deploying metadata... ($0 ${FUNCNAME[0]})"
		jq '.packageDirectories[].path' sfdx-project.json > etLogs/tmpDeploy.txt
		while read -r path <&9; do
			folder=$(echo $path | tr -d '"')
			et_sfdxDeploy force:source:deploy --sourcepath "./$folder" --json --loglevel fatal
		done 9<  etLogs/tmpDeploy.txt
		rm etLogs/tmpDeploy.txt
	fi
}
function mainPushMetadata() {
	showStatus "*** Pushing metadata... ($0 ${FUNCNAME[0]})"
	et_sfdxPush force:source:push --forceoverwrite --json
}
function mainManualMetadataAfter() {
	# --- Manual metadata (after deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_AFTER" ]]; then
		showStatus "*** Open page to configure org (AFTER pushing)... ($0 ${FUNCNAME[0]})"
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_AFTER"
		showPause "Configure additonal metadata AFTER pushing..."
	fi
}
function mainExecuteApexAfterPush() {
	# --- Execute Apex Anonymous code (After Push)
	if [ ! -z "$EXEC_ANON_APEX_AFTER_PUSH" ]; then
		for APEX in ${EXEC_ANON_APEX_AFTER_PUSH[@]}; do
			showStatus "*** Execute Anonymous Apex (after push): [$APEX]... ($0 ${FUNCNAME[0]})"
			et_sfdxExecuteApex "$APEX" "etLogs/apexAfterPush.json"
			# et_sfdx force:apex:execute -f "$APEX"
		done
		showComplete
	fi
}
function mainAssignPermissionSet() {
	# --- Assign permission set
	if [ ! -z "$PERM_SETS" ]
	then
		showStatus "*** Assigning permission set(s) to your user... ($0 ${FUNCNAME[0]})"
		for PERM_SET in ${PERM_SETS[@]}; do
			et_sfdx force:user:permset:assign --permsetname "$PERM_SET" --json
		done
		showComplete
	fi
}
function mainDeployAdminProfile() {
	# --- Deploy profile
	if [ -a "$ADMIN_PROFILE" ]; then
		showStatus "*** Deploying 'Admin' standard profile... ($0 ${FUNCNAME[0]})"
		mv .forceignore etLogs/.forceignore
		et_sfdx force:source:deploy -p "$ADMIN_PROFILE"
		local resultcode=$?
		mv etLogs/.forceignore .forceignore
		showComplete
	fi
}
function mainLoadData() {
	# --- Load data using ETCopyData plugin
	if [[ "$IMPORT_DATA" = true ]]; then
		showStatus "*** Creating data using ETCopyData plugin... ($0 ${FUNCNAME[0]})"
		# sfdx ETCopyData:delete --orgdestination=sbTVB4S_CICD -c "./@ELTOROIT/data" --loglevel trace --json > ./etLogs/etCopyData.tab
		# sfdx ETCopyData:export -c "./@ELTOROIT/data" --loglevel trace --json > ./etLogs/etCopyData.tab
		# sfdx ETCopyData:import -c "./@ELTOROIT/data" --loglevel trace --json > ./etLogs/etCopyData.tab
		et_sfdx ETCopyData:import -c "$ETCOPYDATA_FOLDER" --loglevel info --json --orgsource="$ALIAS" --orgdestination="$ALIAS"
		showComplete
	fi
}
function mainExecuteApexAfterData() {
	# --- Execute Apex Anonymous code after data
	if [ ! -z "$EXEC_ANON_APEX_AFTER_DATA" ]; then
		for APEX in ${EXEC_ANON_APEX_AFTER_DATA[@]}; do
			showStatus "*** Execute Anonymous Apex (after data): [$APEX]... ($0 ${FUNCNAME[0]})"
			et_sfdxExecuteApex "$APEX" "etLogs/apexAfterData.json"
			# et_sfdx force:apex:execute -f "$APEX"
		done
		showComplete
	fi
}
function mainRunApexTests() {
	# --- Runing Apex tests
	if [[ "$RUN_APEX_TESTS" = true ]]; then
		showStatus "Runing Apex tests... ($0 ${FUNCNAME[0]})"
		APEX_TEST_LOG_FILENAME="apexTest_ScratchOrg.json"
		jq_sfdxRunApexTests force:apex:test:run --codecoverage --verbose --json --resultformat=json --wait=60
		showComplete
	fi
}
function mainPushAgain() {
	# --- Push metadata
	showStatus "*** Pushing metadata to scratch Org one more time... ($0 ${FUNCNAME[0]})"
	# if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
	# 	et_sfdx force:org:open --path=$DEPLOY_PAGE
	# fi
	et_sfdxPush force:source:push -u "$ALIAS" -f --json
	showComplete
}
function mainReassignAlias() {
	# --- Push metadata
	showStatus "*** Re-assign alias... ($0 ${FUNCNAME[0]})"
	et_sfdx force:config:set defaultusername=$ALIAS
	showComplete
}
function mainPublishCommunity() {
	# --- Publish community
	if [[ ! -z "$PUBLISH_COMMUNITY_NAME" ]]; then
		showStatus "*** Publishing community... ($0 ${FUNCNAME[0]})"
		showCommand "sfdx force:community:publish --name \"$PUBLISH_COMMUNITY_NAME\""
		sfdx force:community:publish --name "$PUBLISH_COMMUNITY_NAME" || ReportError
	fi
}
function mainGeneratePassword() {
	# --- Generate Password
	if [[ "$GENERATE_PASSWORD" = true ]]; then
		showStatus "*** Generate Password... ($0 ${FUNCNAME[0]})"
		jq_sfdxGeneratePassword
		showComplete
	fi
}
function mainDeployToSandbox() {
	# --- Deploy to sandbox
	if [[ ! -z "$DEPLOY_TO_SANDBOX" ]]; then
		showStatus "*** Opening page in sandbox... ($0 ${FUNCNAME[0]})"
		et_sfdx force:org:open --targetusername="$DEPLOY_TO_SANDBOX" --path=$DEPLOY_PAGE
		showStatus "*** Deploying to sandbox... ($0 ${FUNCNAME[0]})"
		et_sfdxDeploy force:source:deploy --sourcepath="$DEPLOY_TO_SANDBOX_FOLDER" --json --loglevel=trace --targetusername="$DEPLOY_TO_SANDBOX"
		APEX_TEST_LOG_FILENAME="apexTest_CICD.json"
		jq_sfdxRunApexTests force:apex:test:run --codecoverage --verbose --json --resultformat=json --wait=60 --targetusername="$DEPLOY_TO_SANDBOX"
	fi
}
function QuitSuccess() {
	# Green
	printf "\033[0;32m\n"
	printf "*** *** *** *** *** *** ***\n"
	printf "*** *** Org created *** ***\n"
	printf "*** *** *** *** *** *** ***\n"
	printf "\033[0m\n"
	exit 0
}

# Global variables
DEPLOY_PAGE="/lightning/setup/DeployStatus/home"
AUTOMATED_PROCESS=false
if [[ "$ET_CICD" = true ]]; then
	AUTOMATED_PROCESS=true
fi

# Start Process
rm -rf ./etLogs
mkdir -p etLogs
if [[ ! -z "$*" ]]; then
	$*
else
	# No parameters sent, then do everything
	mainRunJest
	mainBackupAlias
	mainCreateScratchOrg
	mainPauseToCheck
	mainOpenDeployPage
	mainPrepareOrg
	mainManualMetadataBefore
	mainExecuteApexBeforePush
	mainInstallPackages
	# mainDeploy (Do not do a deploy, rather do a push)
	mainPushMetadata
	mainManualMetadataAfter
	mainExecuteApexAfterPush
	mainAssignPermissionSet
	mainDeployAdminProfile
	mainLoadData
	mainExecuteApexAfterData
	mainRunApexTests
	# mainPushAgain
	# mainReassignAlias
	mainPublishCommunity
	mainGeneratePassword
	mainDeployToSandbox
	QuitSuccess
fi



# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainRunJest
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainBackupAlias
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainCreateScratchOrg
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainPauseToCheck
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainOpenDeployPage
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainPrepareOrg
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainManualMetadataBefore
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexBeforePush
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainInstallPackages
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainDeploy
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainPushMetadata
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainManualMetadataAfter
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexAfterPush
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainAssignPermissionSet
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainDeployAdminProfile
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainLoadData
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainExecuteApexAfterData
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainRunApexTests
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainPushAgain
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainReassignAlias
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainPublishCommunity
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainGeneratePassword
# ./@ELTOROIT/scripts/shell/CreateOrg.sh mainDeployToSandbox
# ./@ELTOROIT/scripts/shell/CreateOrg.sh QuitSuccess