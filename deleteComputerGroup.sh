url="https://InstanceHERE.jamfcloud.com"
client_id="CLIENT_ID_HERE"
client_secret="CLIENT_SECRET_HERE"
computerGroupID="Computer_Group_ID_HERE"



getAccessToken() {
	response=$(curl --silent --location --request POST "${url}/api/oauth/token" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--data-urlencode "client_id=${client_id}" \
		--data-urlencode "grant_type=client_credentials" \
		--data-urlencode "client_secret=${client_secret}")
	access_token=$(echo "$response" | plutil -extract access_token raw -)
}

getAccessToken 
echo $response

curl -H "Accept: text/xml" -H "Authorization: Bearer ${access_token}" "$url/JSSResource/computergroups/id/$computerGroupID" -X DELETE


