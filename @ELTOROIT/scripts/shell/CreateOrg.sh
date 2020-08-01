# Execute in Mac using: ./@ELTOROIT/scripts/CreateOrg.sh

# --- Define local folder
	DIR="${BASH_SOURCE%/*}"
	if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# --- Batch variables
	# Alias for scratch org
	ALIAS=soORG

	# How long will the scratch org live (max 30)
	DAYS=1
	
	# Install required packages before pushing
	# Sample: PACKAGES=("04tB0000000P1yA" "04tB0000000P1yB" "04tB0000000P1yC")
	# PACKAGES=("04tB0000000P1yA")

	# Permission Set name
	PERM_SET=psTest
	
	# Path to Apex code to execute anonymously
	# Sample: $DIR/AnonymousApex.txt
	EXEC_ANON_APEX_BEFORE_PUSH=
	EXEC_ANON_APEX_AFTER_PUSH=$DIR/../apex/SetUserRecord.apex
	EXEC_ANON_APEX_AFTER_DATA=
	
	# Is there any additional manual configuration required BEFORE pushing metadata?
	# Sample: /lightning/setup/SalesforceMobileAppQuickStart/home
	PATH2SETUP_METADATA_BEFORE=
	
	# Is there any additional manual configuration required AFTER pushing metadata?
	# Sample: /lightning/setup/SalesforceMobileAppQuickStart/home
	PATH2SETUP_METADATA_AFTER=

# --- Batch boolean variables

	# Quit on errors?
	QUIT_ON_ERRORS=true

	# Automated Script? Can I prompt the user for a key to continue?
	USER_ON_SCREEN=true

	# Open browser page to show deployment progress
	SHOW_DEPLOY_PAGE=true

	# Do you want to run JEST tests in this project?
	RUN_JEST_TESTS=true

	# Stop to validate org was succesfully created? Sometimes Sslesforce fails when creating an org and shows the login screen rather than opening an org.
	PAUSE2CHECK_ORG=false

	# Backup alias, in case you need to go back :-)
	BACKUP_ALIAS=true

	# Deploy code before pushing it? I have seen some issues with deployments of communities that get solved like this
	PERFORM_DEPLOY=true

	# Deploy Admin standard profile (helps set the visible apprlications, for example)
	DEPLOY_ADMIN=true

	# Do you want to use ETCopyData to import data?
	IMPORT_DATA=true

	# Do you want to run APEX tests in this new org before starting?
	RUN_APEX_TESTS=true

	# Do you need a password for the user name? You may need this depening on the use of the new scratch org
	GENERATE_PASSWORD=true

# --- Ready, set, go!
	source "$DIR/Functions.sh"
