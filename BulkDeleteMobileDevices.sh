#!/bin/sh

#Insert producer track here

user="USERHERE"
password="PASSHERE"
url="https://URLHERE.jamfcloud.com"

# Get username and password encoded in base64 format and stored as a variable in a script:
encodedCredentials=$( printf "$user:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

#Comment here, does anyone even read these things... is this thing on?
token=$(/usr/bin/curl $url/uapi/auth/tokens -s -X POST -H "Authorization: Basic $encodedCredentials" | grep token | awk '{print $3}' | tr -d ',"')

#Echo the Authorization token
echo $token

#Check to see if deviceids.csv exists in the /users/shraed folder... if it does not exist it creates it
if [[ -e /users/shared/deviceids.csv ]]; then
    echo "Already exists!"
else
    echo "Does not exist...creating!"
    touch /users/shared/deviceids.csv
fi

#Get ID from serial number csv
input="/PATH/TO/CSV/HERE"
while IFS= read line; do
    echo $line
    /usr/bin/curl -ks -H "content-type: text/xml" -H "Authorization: Bearer $token" https://andrewkuntz.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$line | xmllint --xpath '/mobile_device/general/id/text()' - >> /users/shared/deviceids.csv
done < "$input"

#Deletes Devices according to the deviceids.csv
input2="/users/shared/deviceids.csv"
while IFS= read line2; do
    echo "Attempting to delete Mobile device ID: $line2"
    /usr/bin/curl -s -H "Authorization: Bearer $token" $url/JSSResource/mobiledevices/id/$line2 -X DELETE
done < "$input2"
