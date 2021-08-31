#!/bin/sh

#Smartcard Recovery for macOS 10.15.7+
#rev:2.1

# Prompt user for account name:
userPrompt="Please enter the account that requires an exemption from smartcard enforcement: "

printf "\e[1m$userPrompt"
read uid

# Check for Boot Volume Name. User may have changed from Macintosh HD:
bootVolumeName=$(/usr/sbin/bless --info --verbose 2>&1 >/dev/null |  awk -F': ' '/^mount/{print $2}')
if [[ -z "$bootVolumeName" ]]; then
    echo "Boot Volume not found. Please verify using the Startup Disk menu bar item and try again."
    exit 1
fi

# Check if user is already exempt:
userExempt=$(/usr/bin/defaults read "$bootVolumeName"/var/db/dslocal/nodes/Default/users/"$uid" SmartCardEnforcement | /usr/bin/awk 'NR==2' | /usr/bin/sed 's/^[ \t]*//')
if [[ "$userExempt" == "2" ]]; then
  echo "$uid is already exempt."
  exit 0
fi

# Disable SmartCardEnforcement by setting it in User account:
/usr/bin/defaults write "$bootVolumeName"/var/db/dslocal/nodes/Default/users/"$uid" SmartCardEnforcement -array-add 2

# Disable SmartCardEnforcement by setting it in User account:
arch=$(/usr/bin/arch)
if [[ "$arch" == "arm64" ]]; then
    /usr/sbin/diskutil apfs updatePreboot "$bootVolumeName" >/dev/null
fi

# Create a LaunchDaemon to remove the SmartCardEnforcement attribute from the acount
# Exemption is removed after 1 hour
createRemovalLaunchDaemon (){
local launch_daemon="com.company.smartcard.exemption"
local launch_daemon_path="$bootVolumeName/Library/LaunchDaemons/$launch_daemon".plist

echo "<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$launch_daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>/usr/bin/dscl . -delete /Users/'$uid' SmartCardEnforcement; /bin/rm -f /Library/LaunchDaemons/'$launch_daemon'.plist; /bin/launchctl bootout system/'$launch_daemon'</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
</dict>
</plist>" > "$launch_daemon_path"
# Set proper permissions on launchdaemon:
if [[ -e "$launch_daemon_path" ]]; then
    /usr/sbin/chown root:wheel "$launch_daemon_path"
    /bin/chmod 644 "$launch_daemon_path"
fi
}

createRemovalLaunchDaemon
echo "$uid is now exempt for 1 hour. Please Reboot."
