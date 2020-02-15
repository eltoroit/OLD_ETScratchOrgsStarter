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
	echo $sfdxResult | jq "del(.result.tests, .result.coverage)"
}

