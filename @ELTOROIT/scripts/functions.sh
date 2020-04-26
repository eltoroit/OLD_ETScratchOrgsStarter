# Colors:
# 	https://www.shellhacks.com/bash-colors/
# 	https://misc.flogisoft.com/bash/tip_colors_and_formatting

function showStatus() {
	# Magenta
	echo "\033[0;35m$1\033[0m"
}
function showComplete() {
	# Green
	echo "\033[0;32mOperation Completed\033[0m"
}
function showPause(){
	# Red
	echo "\033[0;31m"
	echo $1
	read -p "Press [Enter] key to continue...  "
	echo "\033[0m"
}

function QuitError() {
	echo "\033[0;31m"
	echo "Org could not be created!"
	read -p "Press [Enter] key to continue...  "
	echo "\033[0m"
	exit 1
}

function QuitSuccess() {
	# Green
	echo "\033[0;32m";
	echo "*** *** *** *** *** *** *** *** *** ***"
	echo "*** *** Org created succesfully *** ***"
	echo "*** *** *** *** *** *** *** *** *** ***"
	echo "\033[0m"
	exit 0
}

function et_sfdx(){
	echo "\033[2;30msfdx $*\033[0m"
	sfdx $* || QuitError
}

function jq_sfdx(){
	echo "\033[2;30msfdx $*\033[0m"
	sfdx $* > apexTests.json
	local resultcode=$?
	cat apexTests.json | jq "del(.result.tests, .result.coverage)"
	if [[ $resultcode -ne 0 ]]; then
		echo "\033[0;31m"
		echo "Tests run, but they failed!"
		read -p "Press [Enter] key to continue...  "
		echo "\033[0m"
		exit 1
	fi
}

function everything() {
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

# --- Manual metadata (before deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_BEFORE" ]]; then
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_BEFORE"
		showPause "Configure additonal metadata BEFORE pushing"
	fi

# --- Execute Apex Anonymous code (Before Push)
	if [ ! -z "$EXEC_ANON_APEX_BEFORE_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (before push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_BEFORE_PUSH"
		showComplete
	fi

# --- Push metadata
	showStatus "*** Pushing metadata to scratch Org..."
	et_sfdx force:source:push --json
	showComplete

# --- Execute Apex Anonymous code (After Push)
	if [ ! -z "$EXEC_ANON_APEX_AFTER_PUSH" ]; then
		showStatus "*** Execute Anonymous Apex (after push)..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX_AFTER_PUSH"
		showComplete
	fi

# --- Manual metadata (after deployment)
	if [[ ! -z "$PATH2SETUP_METADATA_AFTER" ]]; then
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_AFTER"
		showPause "Configure additonal metadata AFTER pushing"
	fi

# --- Assign permission set
	if [ ! -z "$PERM_SET" ]
	then
		showStatus "*** Assigning permission set to your user..."
		et_sfdx force:user:permset:assign --permsetname "$PERM_SET" --json
		showComplete
	fi

# --- Deploy profile (Maybe .forceignore prevents them from push/pull)
	ADMIN_PROFILE=./deploy/main/default/profiles/Admin.profile-meta.xml
	if [ ! -z "$ADMIN_PROFILE" ]; then
		if [[ "$DEPLOY_ADMIN" = true ]]; then
			code .forceIgnore
			showPause "Ensure .forceIgnore DEPLOYS profiles"
			showStatus "*** Deploying 'Admin' standard profile..."
			et_sfdx force:source:deploy -p "$ADMIN_PROFILE"
			showComplete
			showPause "Ensure .forceIgnore EXCLUDES profiles"
		fi
	fi

# --- Load data using ETCopyData plugin
	if [[ "$IMPORT_DATA" = true ]]; then
		showStatus "*** Creating data using ETCopyData plugin"
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
		et_sfdx force:user:password:generate --json
		et_sfdx force:user:display
		showComplete
	fi

# --- Runing Apex tests
	if [[ "$RUN_APEX_TESTS" = true ]]; then
		showStatus "Runing Apex tests"
		jq_sfdx force:apex:test:run --codecoverage --synchronous --verbose --json --resultformat json
		showComplete
	fi

	QuitSuccess
}