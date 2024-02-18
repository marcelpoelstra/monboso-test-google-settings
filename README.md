Execute the script remotely from a fresh system like this :


GITHUB_TOKEN=<your PAT>

curl -s -H "Authorization: token $GITHUB_TOKEN" -L https://raw.githubusercontent.com/marcelpoelstra/monboso-test-google-settings/main/init_script_prod.sh | bash
