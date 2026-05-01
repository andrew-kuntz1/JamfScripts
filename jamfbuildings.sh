#!/bin/bash

# Jamf Pro details
##############################################################
####API CLIENT WITH "READ BUILDINGS" ROLE PRIVILEGE NEEDED####
##############################################################
JAMF_URL="https://INSTANCE_NAME.jamfcloud.com"
CLIENT_ID="CLIENT_ID_HERE"
CLIENT_SECRET="CLIENT_SECRET_HERE"

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
