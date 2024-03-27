#!/bin/bash


read -p "JSS URL: " url
read -p 'Username: ' APIUSER
read -sp 'Password: ' APIPASS

getBearerToken() {
	response=$(curl -s -u "$APIUSER":"$APIPASS" "$url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

echo "getting bearer token"

getBearerToken

curl --request POST \
--url "$url"/api/preview/mdm/commands \
--header "Authorization: Bearer $bearerToken" \
--header 'accept: application/json' \
--header 'content-type: application/json' \
--data '
{
"commandData": {
"commandType": "SET_AUTO_ADMIN_PASSWORD",
"guid": "INSERT_HERE",
"password": "b6A2za14N+WqNMzxiiBEqAkYi9g5CWeNBBvjhgYnCrU="
},
"clientData": [
  {
	"managementId": "INSER_HERE"
  }
]
}
'
