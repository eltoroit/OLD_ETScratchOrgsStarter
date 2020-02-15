# Execute in Mac using: ./@ELTOROIT/scripts/CreateOrg.sh

# --- Include helper scripts 
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/functions.sh"

# --- Batch variables
	# Alias for scratch org
	ALIAS="soORG"

	# How long will the scratch org live (max 30)
	DAYS=1
	
	# Permission Set name
	PERM_SET=
	
	# Path to Apex code to execute anonymously
	# Sample: "$DIR/AnonymousApex.txt"
	EXEC_ANON_APEX=
	
	# Is there any additional manual configuration required BEFORE pushing metadata?
	# Sample: /lightning/setup/SalesforceMobileAppQuickStart/home
	PATH2SETUP_METADATA_BEFORE=
	
	# Is there any additional manual configuration required AFTER pushing metadata?
	# Sample: /lightning/setup/SalesforceMobileAppQuickStart/home
	PATH2SETUP_METADATA_AFTER=

# --- Batch boolean variables
	# Stop to validate org was succesfully created? Sometimes Sslesforce fails when creating an org and shows the login screen rather than opening an org.
	PAUSE2CHECK_ORG=true

	# Do you want to use ETCopyData to import data?
	IMPORT_DATA=true

	# Do you want to run Apex tests in this new org before starting?
	RUN_APEX_TESTS=false

	# Do you need a password for the user name? You may need this depening on the use of the new scratch org
	GENERATE_PASSWORD=false

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
et_sfdx force:source:push
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