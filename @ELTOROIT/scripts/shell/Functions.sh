# Colors:
# 	https://www.shellhacks.com/bash-colors/
# 	https://misc.flogisoft.com/bash/tip_colors_and_formatting

function showStatus() {
	# Magenta
	printf "\033[0;35m$1\033[0m\n"
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
			printf "\033[0m"	
			read -p " "
			exit 1
		else
			printf "\033[0m\n"	
			exit 1
		fi
	else
		printf "Press [Enter] key to continue..."
		printf "\033[0m"	
		read -p " "
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
		printf "\033[0m"
		read -p " "
	else
		printf "\033[0;31m"
		printf "Automated tests! Should not be prompting for this"
		printf "\033[0m\n"
		ReportError
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

function et_sfdx(){
	printf "\033[2;30msfdx $*\033[0m\n"
	sfdx $* || ReportError
}

function et_sfdxPush(){
	printf "\033[2;30msfdx $*\033[0m\n"
	sfdx $* > etLogs/push.json || ReportError
}

function jq_sfdxGeneratePassword() {
	# Display has a bug where the password is encripted on display and can't be shown. 
	# et_sfdx force:user:password:generate --json

	sfdx force:user:password:generate --json > etLogs/tempPW.json
	sfdx force:user:display --json > etLogs/userInfo.json
	pwd=$(jq -r '.result.password' etLogs/tempPW.json)
	jq --arg pwd "$pwd" '.result.password = $pwd' etLogs/userInfo.json > etLogs/user.tmp && mv etLogs/user.tmp etLogs/userInfo.json
	rm etLogs/tempPW.json
	cat etLogs/userInfo.json | jq
}

function jq_sfdxRunApexTests(){
	printf "\033[2;30msfdx $*\033[0m\n"
	sfdx $* > etLogs/apexTests.json
	local resultcode=$?
	cat etLogs/apexTests.json | jq "del(.result.tests, .result.coverage)"
	if [[ $resultcode -ne 0 ]]; then
		printf "\033[0;31m\n"
		printf "Tests run, but they failed!\n"
		if [[ "$QUIT_ON_ERRORS" = true ]]; then
			if [[ "$USER_ON_SCREEN" = true ]]; then 
				printf "Press [Enter] key to exit process...  "
				printf "\033[0m"
				read -p " "
			fi
			exit 1
		fi
		if [[ "$USER_ON_SCREEN" = true ]]; then 
			printf "Press [Enter] key to continue...  "	
			printf "\033[0m"
			read -p " "
		fi
	fi
}

function backupAlias() {
	printf "\033[2;30msfdx force:alias:list --json\033[0m\n"
	sfdx force:alias:list --json > etLogs/aliasList.json

	printf "\033[2;30mFinding Username for $ALIAS\033[0m\n"
	cat etLogs/aliasList.json | jq --arg JQALIAS "$ALIAS" '.result[] | select(.alias==$JQALIAS) | .value' | while read -r UN; do
		local TEMP="${UN%\"}"
		UN="${TEMP#\"}"
		# printf "\033[2;30m[$ALIAS.bak] <= [$UN]\033[0m\n"
		et_sfdx force:alias:set $ALIAS.bak=$UN
	done
}

function everything() {
	DEPLOY_PAGE="/lightning/setup/DeployStatus/home"

# --- Run JEST tests before anything else!
	if [[ "$RUN_JEST_TESTS" = true ]]; then
		showStatus "*** Running JEST tests..."
		JEST_LOG=etLogs/jestTest.json
		printf "\033[2;30mJEST logs are here: $JEST_LOG\033[0m\n"
		npm run test:unit:coverage &> $JEST_LOG || ReportError
		showComplete
	fi

# --- Backup this org alias
	if [[ "$BACKUP_ALIAS" = true ]]; then
		showStatus "*** Backup this org alias..."
		backupAlias
		showComplete
	fi

# --- Create scratch org
	showStatus "*** Creating scratch Org..."
	et_sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias "$ALIAS" -d "$DAYS"
	showComplete

# --- Pause to valiate org created
	if [[ "$PAUSE2CHECK_ORG" = true ]]; then
		showStatus "*** Opening scratch Org..."
		et_sfdx force:org:open
		showPause "Stop to validate the ORG was created succesfully."
	fi

# --- Open deploy page to watch deployments
	if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
		showStatus "*** Open page to monitor deployment..."
		et_sfdx force:org:open --path=$DEPLOY_PAGE
	fi

# --- Manual metadata (before deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_BEFORE" ]]; then
		showStatus "*** Open page to configure org (BEFORE pushing)..."
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_BEFORE"
		showPause "Configure additonal metadata BEFORE pushing..."
	fi

# --- Execute Apex Anonymous code (Before Push)
	if [ ! -z "$EXEC_ANON_APEX_BEFORE_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (before push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_BEFORE_PUSH"
		showComplete
	fi

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

# --- Push metadata
	showStatus "*** Pushing metadata to scratch Org..."
	# if [[ "$SHOW_DEPLOY_PAGE" = true ]]; then
	# 	et_sfdx force:org:open --path=$DEPLOY_PAGE
	# fi
	et_sfdxPush force:source:push
	showComplete

# --- Execute Apex Anonymous code (After Push)
	if [ ! -z "$EXEC_ANON_APEX_AFTER_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (after push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_AFTER_PUSH"
		showComplete
	fi

# --- Manual metadata (after deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_AFTER" ]]; then
		showStatus "*** Open page to configure org (AFTER pushing)..."
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_AFTER"
		showPause "Configure additonal metadata AFTER pushing..."
	fi

# --- Assign permission set
	if [ ! -z "$PERM_SET" ]
	then
		showStatus "*** Assigning permission set to your user..."
		et_sfdx force:user:permset:assign --permsetname "$PERM_SET" --json
		showComplete
	fi

# --- Deploy profile (Maybe .forceignore prevents them from push/pull)
	ADMIN_PROFILE=./doNotDeploy/main/default/profiles/Admin.profile-meta.xml
	if [ ! -z "$ADMIN_PROFILE" ]; then
		if [[ "$DEPLOY_ADMIN" = true ]]; then
			showStatus "*** Deploying 'Admin' standard profile..."
			mv .forceignore .forceignore.old
			et_sfdx force:source:deploy -p "$ADMIN_PROFILE"
			mv .forceignore.old .forceignore
		fi
	fi

# --- Load data using ETCopyData plugin
	if [[ "$IMPORT_DATA" = true ]]; then
		showStatus "*** Creating data using ETCopyData plugin..."
		# et_sfdx ETCopyData:export -c "./@ELTOROIT/data" --loglevel warn --json
		et_sfdx ETCopyData:import -c "./@ELTOROIT/data" --loglevel warn --json
		showComplete
	fi

# --- Execute Apex Anonymous code
	if [ ! -z "$EXEC_ANON_APEX_AFTER_DATA" ]; then
		showStatus "*** Execute Anonymous Apex..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_AFTER_DATA"
		showComplete
	fi

# --- Generate Password
	if [[ "$GENERATE_PASSWORD" = true ]]; then
		showStatus "*** Generate Password..."
		jq_sfdxGeneratePassword
		showComplete
	fi

# --- Runing Apex tests
	if [[ "$RUN_APEX_TESTS" = true ]]; then
		showStatus "Runing Apex tests..."
		jq_sfdxRunApexTests force:apex:test:run --codecoverage --synchronous --verbose --json --resultformat json
		showComplete
	fi

	QuitSuccess
}