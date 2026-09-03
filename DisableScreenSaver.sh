#!/bin/bash
LOGGED_IN_USER=$(stat -f "%Su" /dev/console)

# Bail out if no user is logged in or if it's root
if [[ -z "$LOGGED_IN_USER" || "$LOGGED_IN_USER" == "root" ]]; then
    echo "No standard user is currently logged in. Exiting."
    exit 0
fi

echo "Logged-in user: $LOGGED_IN_USER"

# Get the user's home directory
USER_HOME=$(dscl . -read /Users/"$LOGGED_IN_USER" NFSHomeDirectory | awk '{print $2}')

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "ERROR: Could not determine home directory for $LOGGED_IN_USER. Exiting."
    exit 1
fi

echo "User home directory: $USER_HOME"

# Write screen saver settings to the user's preferences
# correct user domain (~Library/Preferences/com.apple.screensaver.plist)

# Disable screen saver
sudo -u "$LOGGED_IN_USER" defaults write com.apple.screensaver idleTime -int 0

# Disable password requirement when screen saver is dismissed
sudo -u "$LOGGED_IN_USER" defaults write com.apple.screensaver askForPassword -int 0

echo "Screen saver settings applied for $LOGGED_IN_USER:"
echo "  idleTime = $(sudo -u "$LOGGED_IN_USER" defaults read com.apple.screensaver idleTime)"
echo "  askForPassword = $(sudo -u "$LOGGED_IN_USER" defaults read com.apple.screensaver askForPassword)"

# Kill the cfprefsd process for the user to force preference cache refresh
USER_ID=$(id -u "$LOGGED_IN_USER")
launchctl asuser "$USER_ID" killall cfprefsd 2>/dev/null || true

echo "Preference cache refreshed for $LOGGED_IN_USER."
echo "Script completed successfully."

exit 0
