#!/bin/bash

#	Source = Jamf Connect Documentation - Unmigrating a Local Account :  https://learn.jamf.com/bundle/jamf-connect-documentation-current/page/Unmigrating_a_Local_Account.html

#	Get the currently logged in user's Local Username.
currentUN=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

#	Get the currently logged in user's Local Account Alias.
UNalias=$(dscl . read /Users/$currentUN RecordName | /usr/bin/awk '{ print $3 }')

#	Un-Migrate the user's Local Account.
dscl . delete /Users/$currentUN RecordName $UNalias
dscl . delete /Users/$currentUN dsAttrTypeStandard:NetworkUser
dscl . delete /Users/$currentUN dsAttrTypeStandard:OIDCProvider
dscl . delete /Users/$currentUN dsAttrTypeStandard:OktaUser
dscl . delete /Users/$currentUN dsAttrTypeStandard:AzureUser

exit 0
