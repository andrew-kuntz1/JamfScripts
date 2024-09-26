#!/bin/bash

##############
## Script Objective: Send PasscodeLockGracePeriod Command to group of devices

## Last modified: 8/10/2023
## Created by: Steven Moore
############
#THE SOFTWARE IS PROVIDED "AS-IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL JAMF SOFTWARE, LLC OR ANY OF ITS AFFILIATES BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF OR OTHER DEALINGS IN THE SOFTWARE, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES AND OTHER DAMAGES SUCH AS LOSS OF USE, PROFITS, SAVINGS, TIME OR DATA, BUSINESS INTERRUPTION, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES.

# server connection information
URL="https://URLHERE"
username="USER_HERE"
password="PASSWORD_HERE"
#Smart/static group ID of group you want to send command to
groupID="SMART_GROUP_ID_HERE"

set -e # Exit script if any command fails

# created base64-encoded credentials
encodedCredentials=$( printf "$username:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl -kv "$URL/api/v1/auth/token" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '/token/{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

##generate list of ID's from mobile device group as an array
ID=($(curl -kv -X GET "$URL/JSSResource/mobiledevicegroups/id/$groupID" -H "accept: application/xml" \
--header "Authorization: Bearer $token" \
-s | xmllint --xpath '/mobile_device_group/mobile_devices/mobile_device/id' - | sed $'s/<[i]*d>//g' | sed 's/<[/i]*d>/ /g' ))


#ID=(X X X)


for i in "${ID[@]}"; do
xmlData="<mobile_device_command>
<general>
<command>PasscodeLockGracePeriod</command>
<passcode_lock_grace_period>14400</passcode_lock_grace_period>
</general>
<mobile_devices>
<mobile_device>
<id>$i</id>
</mobile_device>
</mobile_devices>
</mobile_device_command>"
printf "
Sending PasscodeLockGracePeriod Command to Device ID: $i...
"

/usr/bin/curl -H "Authorization: Bearer ${token}" \
--header "Content-Type: text/xml" \
--request POST \
--data "$xmlData" \
"${URL}/JSSResource/mobiledevicecommands/command"
done
