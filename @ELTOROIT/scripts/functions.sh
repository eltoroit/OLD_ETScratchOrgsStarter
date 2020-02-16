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
	local sfdxResult=`sfdx $* || QuitError`
}

function everything() {
	# ---
	showStatus "*** Creating scratch Org..."
	et_sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias "$ALIAS" -d "$DAYS"
	showComplete

	# ---
	if [[ "$PAUSE2CHECK_ORG" = true ]]; then
		showStatus "*** Opening scratch Org..."
		et_sfdx force:org:open
		showPause "Stop to validate the ORG was created succesfully."
	fi

	# ---
	if [[ ! -z "$PATH2SETUP_METADATA_BEFORE" ]]; then
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_BEFORE"
		showPause "Configure additonal metadata BEFORE pushing"
	fi

	# ---
	showStatus "*** Pushing metadata to scratch Org..."
	et_sfdx force:source:push --json
	showComplete

	if [[ ! -z "$PATH2SETUP_METADATA_AFTER" ]]; then
		et_sfdx force:org:open --path "$PATH2SETUP_METADATA_AFTER"
		showPause "Configure additonal metadata AFTER pushing"
	fi

	# ---
	if [ ! -z "$PERM_SET" ]
	then
		showStatus "*** Assigning permission set to your user..."
		et_sfdx force:user:permset:assign --permsetname "$PERM_SET" --json
		showComplete
	fi

	# ---
	if [ ! -z "$EXEC_ANON_APEX" ]; then
		showStatus "*** Execute Anonymous Apex..."
		et_sfdx force:apex:execute -f "$EXEC_ANON_APEX"
		showComplete
	fi

	# ---
	if [[ "$IMPORT_DATA" = true ]]; then
		showStatus "*** Creating data using ETCopyData plugin"
		# et_sfdx ETCopyData:export -c "./@ELTOROIT/data" --loglevel warn --json
		et_sfdx ETCopyData:import -c "./@ELTOROIT/data" --loglevel warn --json
		showComplete
	fi

	# ---
	if [[ "$RUN_APEX_TESTS" = true ]]; then
		showStatus "Runing Apex tests"
		jq_sfdx force:apex:test:run --codecoverage --synchronous --verbose --json --resultformat json
		echo $sfdxResult | jq "del(.result.tests, .result.coverage)"
		showComplete
	fi

	# ---
	if [[ "$GENERATE_PASSWORD" = true ]]; then
		showStatus "*** Generate Password..."
		et_sfdx force:user:password:generate --json
		et_sfdx force:user:display
		showComplete
	fi

	QuitSuccess
}