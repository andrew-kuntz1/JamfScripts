#!/bin/bash


####################################################################################################
#
# THIS SCRIPT IS NOT AN OFFICIAL PRODUCT OF JAMF SOFTWARE
# AS SUCH IT IS PROVIDED WITHOUT WARRANTY OR SUPPORT
#
# BY USING THIS SCRIPT, YOU AGREE THAT JAMF SOFTWARE
# IS UNDER NO OBLIGATION TO SUPPORT, DEBUG, OR OTHERWISE
# MAINTAIN THIS SCRIPT
#
####################################################################################################
#
# DESCRIPTION
# 
# This resolves an issue where lost mode is not able to be disabled in the 
#Jamf Pro GUI after enabling.
#
####################################################################################################


####### Adjustable Variables #######
# Set the Jamf Pro URL here if you want it hardcoded.
jamfpro_url=""


# Set the username here if you want it hardcoded.
jamfpro_user=""


# Set the password here if you want it hardcoded.
jamfpro_password=""


doeswhat="This script sends a disable lost mode command via an API to address an issue where lost mode is not able to be disabled via the gui. After entering the URL and Jamf Pro credentials you will be prompted for device ID"


####################################


##### Non-Adjustable Variables #####
# Variable declarations
bearerToken=""
tokenExpirationEpoch="0"
count=0


####################################


# Function to gather and format bearer token
getBearerToken() {
	response=$(/usr/bin/curl -k -k -s -u "$jamfpro_user":"$jamfpro_password" "$jamfpro_url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
	echo "New bearer token generated."
	echo "Token valid until the following date/time UTC: " "$tokenExpiration"
}


# Function to check token expiration
checkTokenExpiration() {
	nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -lt nowEpochUTC ]]
	then
		echo "No valid token available, getting new token"
		getBearerToken
	fi
}


# Funtion to invalidate token
invalidateToken() {
	responseCode=$(/usr/bin/curl -k -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $jamfpro_url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Bearer token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Bearer token already invalid"
	else
		echo "An unknown error occurred invalidating the bearer token"
	fi
}


# Dispaly warning and confrim user would like to continue
echo "#####################"
echo "###!!! WARNING !!!###"
echo "#####################"
echo "This script " $doesWhat
	echo "There is no undo button."
	while true; do
		read -p "Are you sure you want to continue? [ y | n ]  " answer
		
		case $answer in
			[Yy]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Please answer y | n";;
		esac
	done
	
	
	# If the Jamf Pro URL, the account username and/or the account password have not been provided,
	# the below will prompt the user to enter the necessary information.
	
	
	if [[ -z "$jamfpro_url" ]]; then
		read -p "Please enter your Jamf Pro server URL : " jamfpro_url
	fi
	
	
	if [[ -z "$jamfpro_user" ]]; then
		read -p "Please enter your Jamf Pro user account : " jamfpro_user
	fi
	
	
	if [[ -z "$jamfpro_password" ]]; then
		read -p "Please enter the password for the $jamfpro_user account: " -s jamfpro_password
	fi
	
	
	# Remove the trailing slash from the Jamf Pro URL if needed.
	jamfpro_url=${jamfpro_url%%/}
	
	
	echo
	echo "Credentials received"
	echo
	
	
	# Generating bearer token
	echo "Generating bearer token for server authentication..."
	getBearerToken
	
	
	
	
	
	
	#################################################
	#
	while true; do
		echo
		echo 
		read -p "Please enter a device ID to send a disable lost mode command (to exit, type done):" answer
		echo
		
		case $answer in
			[Dd]* ) break;;
			* ) curl --request POST \
				--url "${jamfpro_url}/JSSResource/mobiledevicecommands/command/DisableLostMode/id/$answer" \
				--header "Authorization: Bearer $bearerToken" \
				--header "Content-Type: application/xml";;
		esac
	done
		
	#
	#################################################
	
	
	
	
	
	
	# Invalidate bearer token (keep this at the end of the script)
	echo "Invalidating bearer token..."
	invalidateToken
	exit 0
	