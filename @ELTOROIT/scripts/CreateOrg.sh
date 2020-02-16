# Execute in Mac using: ./@ELTOROIT/scripts/CreateOrg.sh

# --- Include helper scripts 
	DIR="${BASH_SOURCE%/*}"
	if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
	source "$DIR/functions.sh" "$DIR/functions.sh"

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

# --- Ready, set, go!
	everything