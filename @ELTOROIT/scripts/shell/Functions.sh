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
	printf "\033[0;32mTask Completed\033[0m\n"
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
function et_sfdxDeploy(){
	showStatus "*** Deploying metadata to scratch Org..."
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
	# Display has a bug where the password is encripted on display and can't be shown. 
	# et_sfdx force:user:password:generate --json

	showCommand "Generates Password"
	etFile=etLogs/userInfo.json
	etFileTemp=$etFile.tmp
	sfdx force:user:password:generate --json > $etFileTemp
	sfdx force:user:display --json > $etFile
	pwd=$(jq -r '.result.password' $etFileTemp)
	jq --arg pwd "$pwd" '.result.password = $pwd' $etFile > $etFileTemp && mv $etFileTemp $etFile
	cat $etFile | jq .
}
function jq_sfdxRunApexTests() {
	showCommand "sfdx $*"
	etFile=etLogs/apexTests.json
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

	showCommand "Finding org for $ALIAS"
	cat $etFile | jq --arg JQALIAS "$ALIAS" '.result[] | select(.alias==$JQALIAS) | .value' | while read -r UN; do
		local TEMP="${UN%\"}"
		UN="${TEMP#\"}"
		# showCommand "[$ALIAS.bak] <= [$UN]"
		et_sfdx force:alias:set $ALIAS.bak=$UN
	done
}

# Script pieces
function mainRunJest() {
	# --- Run JEST tests before anything else!
	if [[ "$RUN_JEST_TESTS" = true ]]; then
		showStatus "*** Running JEST tests..."
		etFile=etLogs/jestTests.json
		showCommand "JEST logs are here: $etFile"
		npm run test:unit:coverage &> $etFile
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
		showStatus "*** JEST tests are being skipped! ***"
	fi	
}
function mainBackupAlias() {
	# --- Backup this org alias
	if [[ "$BACKUP_ALIAS" = true ]]; then
		showStatus "*** Backup this org alias..."
		backupAlias
		showComplete
	fi
}
function mainCreateScratchOrg() {
	# --- Create scratch org
	showStatus "*** Creating scratch Org..."
	et_sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias "$ALIAS" -d "$DAYS"
	showComplete
}
function mainPauseToCheck() {
	# --- Pause to valiate org created
	if [[ "$PAUSE2CHECK_ORG" = true ]]; then
		showStatus "*** Opening scratch Org..."
		et_sfdx force:org:open
		showPause "Stop to validate the ORG was created succesfully."
	fi
}
function mainOpenDeployPage() {
	# --- Open deploy page to watch deployments
	if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
		showStatus "*** Open page to monitor deployment..."
		et_sfdx force:org:open --path=$DEPLOY_PAGE
	fi
}
function mainManualMetadataBefore() {
	# --- Manual metadata (before deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_BEFORE" ]]; then
		showStatus "*** Open page to configure org (BEFORE pushing)..."
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_BEFORE"
		showPause "Configure additonal metadata BEFORE pushing..."
	fi
}
function mainExecuteApexBeforePush() {
	# --- Execute Apex Anonymous code (Before Push)
	if [ ! -z "$EXEC_ANON_APEX_BEFORE_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (before push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_BEFORE_PUSH"
		showComplete
	fi
}
function mainInstallPackages() {
	# --- Install Packages (Before Push)
	if [ ! -z "$PACKAGES" ]; then
		showStatus "*** Installing Packages (before push)..."
		for PACKAGE in ${PACKAGES[@]}; do
			# if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
			# 	et_sfdx force:org:open --path=$DEPLOY_PAGE
			# fi
			et_sfdx force:package:install --apexcompile=all --package "$PACKAGE" --wait=30
		done
		showComplete
	fi
}
function mainDeploy() {
	if [[ "$PERFORM_DEPLOY" = true ]]; then
		jq '.packageDirectories[].path' sfdx-project.json > etLogs/tmpDeploy.txt
		while read -r path <&9; do
			folder=$(echo $path | tr -d '"')
			et_sfdxDeploy force:source:deploy --sourcepath "./$folder" --json --loglevel fatal
		done 9<  etLogs/tmpDeploy.txt
		rm etLogs/tmpDeploy.txt
	fi
}
function mainPushMetadata() {
	et_sfdxPush force:source:push --forceoverwrite --json
}
function mainExecuteApexAfterPush() {
	# --- Execute Apex Anonymous code (After Push)
	if [ ! -z "$EXEC_ANON_APEX_AFTER_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (after push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_AFTER_PUSH"
		showComplete
	fi
}
function mainManualMetadataAfter() {
	# --- Manual metadata (after deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_AFTER" ]]; then
		showStatus "*** Open page to configure org (AFTER pushing)..."
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_AFTER"
		showPause "Configure additonal metadata AFTER pushing..."
	fi
}
function mainAssignPermissionSet() {
	# --- Assign permission set
	if [ ! -z "$PERM_SET" ]
	then
		showStatus "*** Assigning permission set to your user..."
		et_sfdx force:user:permset:assign --permsetname "$PERM_SET" --json
		showComplete
	fi
}
function mainDeployAdminProfile() {
	# --- Deploy profile
	ADMIN_PROFILE=./doNotDeploy/main/default/profiles/Admin.profile-meta.xml
	if [ ! -z "$ADMIN_PROFILE" ]; then
		if [[ "$DEPLOY_ADMIN" = true ]]; then
			showStatus "*** Deploying 'Admin' standard profile..."
			mv .forceignore etLogs/.forceignore
			et_sfdx force:source:deploy -p "$ADMIN_PROFILE"
			local resultcode=$?
			mv etLogs/.forceignore .forceignore
			showComplete
		fi
	fi
}
function mainLoadData() {
	# --- Load data using ETCopyData plugin
	if [[ "$IMPORT_DATA" = true ]]; then
		showStatus "*** Creating data using ETCopyData plugin..."
		# et_sfdx ETCopyData:export -c "./@ELTOROIT/data" --loglevel warn --json
		et_sfdx ETCopyData:import -c "./@ELTOROIT/data" --loglevel warn --json
		showComplete
	fi
}
function mainExecuteApexAfterData() {
	# --- Execute Apex Anonymous code after data
	if [ ! -z "$EXEC_ANON_APEX_AFTER_DATA" ]; then
		showStatus "*** Execute Anonymous Apex..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_AFTER_DATA"
		showComplete
	fi
}
function mainRunApexTests() {
	# --- Runing Apex tests
	if [[ "$RUN_APEX_TESTS" = true ]]; then
		showStatus "Runing Apex tests..."
		jq_sfdxRunApexTests force:apex:test:run --codecoverage --synchronous --verbose --json --resultformat json
		showComplete
	fi
}
function mainPushAgain() {
	# --- Push metadata
	showStatus "*** Pushing metadata to scratch Org one more time..."
	# if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
	# 	et_sfdx force:org:open --path=$DEPLOY_PAGE
	# fi
	et_sfdxPush force:source:push -u "$ALIAS" -f
	showComplete
}
function mainReassignAlias() {
	# --- Push metadata
	showStatus "*** Final touches..."
	et_sfdx force:config:set defaultusername=$ALIAS
	showComplete
}
function mainGeneratePassword() {
	# --- Generate Password
	if [[ "$GENERATE_PASSWORD" = true ]]; then
		showStatus "*** Generate Password..."
		jq_sfdxGeneratePassword
		showComplete
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
	mainPushAgain
	mainReassignAlias
	mainGeneratePassword
	QuitSuccess
fi