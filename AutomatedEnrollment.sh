#!/bin/bash

#####################################################################################################
##
##Copyright (c) 2023 Jamf.  All rights reserved.
##
##      Redistribution and use in source and binary forms, with or without
##      modification, are permitted provided that the following conditions are met:
##              * Redistributions of source code must retain the above copyright
##                notice, this list of conditions and the following disclaimer.
##              * Redistributions in binary form must reproduce the above copyright
##                notice, this list of conditions and the following disclaimer in the
##                documentation and#or other materials provided with the distribution.
##              * Neither the name of the Jamf nor the names of its contributors may be
##                used to endorse or promote products derived from this software without
##                specific prior written permission.
##
##      THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
##      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
##      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
##      DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
##      DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
##      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
##      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
##      ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
##      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
##      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
#####################################################################################################
#
# ABOUT THIS SCRIPT
#
# NAME - AutomatedEnrollment.sh
# AUTHOR - Jeff Savage - Technical Support Engineer, Jamf Software
# 
# DESCRIPTION - This script is used to allow standard users to enroll computers into 
#               Jamf through Automated Device Enrollment
# 	
#####################################################################################################

# Add a value to display a notification to the user when they are granted admin rights
adminNotification=""
adminButton="Okay"

# Notification displayed to tell users to run the device enrollment
enrollmentNotification="Please select the notification for Device Enrollment from your notification center and update the enrollment from the resulting dialog."
enrollmentButton="I ran the update"

# Notification displayed to tell users after enrollment is complete
postNotification="Re-enrollment has been completed. Thank you for your help!"
postButton="Okay"


####################  DO NOT EDIT BELOW THIS LINE  ####################

# Grant temporary admin rights for enrollment and set up a daemon to remove them
currentUser=$(/usr/bin/who | /usr/bin/awk '/console/{print $1}')

admin=""
if [[ $(/usr/bin/dscl . read /Groups/admin GroupMembership | /usr/bin/grep "$currentUser") ]]; then
	echo "User is already an admin. Continuing."
else
	
	admin="False"
	if [[ -n $adminNotification ]]; then
		/usr/bin/osascript -e "display dialog \"$adminNotification\" buttons {\"$adminButton\"} default button 1"
	fi
	
	/usr/bin/defaults write /Library/LaunchDaemons/removeAdmin.plist Label -string "removeAdmin"
	/usr/bin/defaults write /Library/LaunchDaemons/removeAdmin.plist ProgramArguments -array -string /bin/sh -string "/Library/Application Support/JAMF/removeAdminRights.sh"
	/usr/bin/defaults write /Library/LaunchDaemons/removeAdmin.plist StartInterval -integer 660
	/usr/bin/defaults write /Library/LaunchDaemons/removeAdmin.plist RunAtLoad -boolean yes
	/usr/sbin/chown root:wheel /Library/LaunchDaemons/removeAdmin.plist
	/bin/chmod 644 /Library/LaunchDaemons/removeAdmin.plist
	/bin/launchctl load /Library/LaunchDaemons/removeAdmin.plist
	sleep 10
	
	if [ ! -d /private/var/userToRemove ]; then
		/bin/mkdir /private/var/userToRemove
		echo $currentUser >> /private/var/userToRemove/user
	else
		echo $currentUser >> /private/var/userToRemove/user
	fi
	
	##################################
	# give the user admin privileges #
	##################################
	
	/usr/sbin/dseditgroup -o edit -a $currentUser -t user admin
	
	########################################
	# write a script for the launch daemon #
	# to run to demote the user back and   #
	# then pull logs of what the user did. #
	########################################
	
	/bin/cat << 'EOF' > /Library/Application\ Support/JAMF/removeAdminRights.sh
if [[ -f /private/var/userToRemove/user ]]; then
								userToRemove=$(/bin/cat /private/var/userToRemove/user)
								echo "Removing $userToRemove's admin privileges"
								/usr/sbin/dseditgroup -o edit -d $userToRemove -t user admin
								/bin/rm -f /private/var/userToRemove/user
								/bin/launchctl unload /Library/LaunchDaemons/removeAdmin.plist
								/bin/rm /Library/LaunchDaemons/removeAdmin.plist
								/usr/bin/log collect --last 11m --output /private/var/userToRemove/$userToRemove.logarchive
fi
EOF
	
	/usr/sbin/chown root:wheel /Library/Application\ Support/JAMF/removeAdminRights.sh
	/bin/chmod 755 /Library/Application\ Support/JAMF/removeAdminRights.sh
fi

# Run DEP/ADE enrollment
/usr/bin/profiles renew -type enrollment

# Ask the users to click through the dialog
/usr/bin/osascript -e "display dialog \"$enrollmentNotification\" buttons {\"$enrollmentButton\"} default button 1"

# Verify that the device has enrolled
mdmInstallDate=$(/usr/bin/profiles -C -v | grep "MDM Profile" -A 2 | awk '/attribute: installationDate/{print $4}')
today=$(date "+%Y-%m-%d")
i=0

while [[ ! "$mdmInstallDate" == "$today" ]]; do
	if [[ $i -lt 60 ]]; then
		echo "Not enrolled via DEP yet. Waiting..."
		sleep 10
		((i++))
	else
		echo "Device has not enrolled in 10 minutes. Exiting."
		exit 1
	fi
done
echo "Device is enrolled via DEP."

if [[ -n $admin ]]; then
	/Library/Application\ Support/JAMF/removeAdminRights.sh
fi

# Notify the users that the enrollment process has completed
if [[ -n $postNotification ]]; then
	/usr/bin/osascript -e "display dialog \"$postNotification\" buttons {\"$postButton\"} default button 1"
fi

exit