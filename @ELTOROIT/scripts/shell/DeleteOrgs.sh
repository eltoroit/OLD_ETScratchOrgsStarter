echo "Looking for orgs to delete..."
for row in $(sfdx force:org:list --json | jq -r '.result.scratchOrgs[] | select(. | has("alias") | not) | @base64'); do
	_jq() {
		echo ${row} | base64 --decode | jq -r ${1}
	}

	echo "Delete Org: $(_jq '.username')"
	sfdx force:org:delete --noprompt --targetusername $(_jq '.username')
done
sfdx force:org:list