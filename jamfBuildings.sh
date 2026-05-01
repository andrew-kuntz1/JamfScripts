#!/bin/bash

# Jamf Pro details
##############################################################
####API CLIENT WITH "READ BUILDINGS" ROLE PRIVILEGE NEEDED####
##############################################################
JAMF_URL="https://andrewkuntz.jamfcloud.com"
CLIENT_ID="4838933b-5a8b-43df-a5bf-351c757d54ff"
CLIENT_SECRET="84cWyvYXSNsW2wPfbq9OPuZuk5wja8r1wfw6SYNUyH_lbIB3BmkWa0GPRdLRETW7"

# Output file
OUTPUT_FILE="/users/shared/jamfbuildings.csv"

# Pagination
PAGE=0
PAGE_SIZE=100

# Get access token
TOKEN_RESPONSE=$(curl -s -X POST "$JAMF_URL/api/oauth/token" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | plutil -extract access_token raw - 2>/dev/null)

if [[ -z "$ACCESS_TOKEN" ]]; then
	echo "Failed to get access token"
	exit 1
fi

# Create CSV header
echo "Name,ID" > "$OUTPUT_FILE"

# Loop through pages
while : ; do
	RESPONSE=$(curl -s -X GET "$JAMF_URL/api/v1/buildings?page=$PAGE&page-size=$PAGE_SIZE" \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		-H "Accept: application/json")
	
	COUNT=$(echo "$RESPONSE" | jq '.results | length')
	
	if [[ "$COUNT" -eq 0 ]]; then
		break
	fi
	
	echo "$RESPONSE" | jq -r '.results[] | "\(.name),\(.id)"' >> "$OUTPUT_FILE"
	
	PAGE=$((PAGE + 1))
done

echo "Output written to $OUTPUT_FILE"

# Invalidate token
curl -s -X POST "$JAMF_URL/api/v1/auth/invalidate-token" \
-H "Authorization: Bearer $ACCESS_TOKEN" > /dev/null
