#!/bin/sh

#Smartcard Recovery for macOS 10.15+
#rev:1.0.1

# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Prompt user for account name
userPrompt="Please enter the account that needs to be added to NotEnforced: "

printf "\e[1m$userPrompt"
read uid     

# Check for Boot Volume Name. User may have changed from Macintosh HD. 
arch=$(/usr/bin/arch)
if [[ "$arch" == "arm64" ]]; then
    bootVolumeName=$(/usr/sbin/bless --info 2>&1 >/dev/null |  awk -F': ' '/^mount/{print $2}')
else
    bootVolumeName=$(/usr/sbin/bless --info | /usr/bin/grep blessed | /usr/bin/head -1 | /usr/bin/cut -d'"' -f2)
fi

# Check for notEnforced file in mapping file
notEnforced=$("$bootVolumeName"/usr/libexec/Plistbuddy -c "Print NotEnforcedGroup" "$bootVolumeName"/private/etc/Smartcardlogin.plist 2>/dev/null)

# If macOS is 10.15 or higher, create both launchdaemons
if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -ge 15 ) || ( ${osvers_major} -eq 11 && ${osvers_minor} -ge 0 ) ]]; then
    if [[ -z "$notEnforced" ]]; then
        echo "NotEnforcedGroup is not set. Please contact your admin."
        exit 1
    else
        echo "Adding '$uid' to NotEnforcedGroup. Please Reboot. :-)"
        createLaunchDaemon (){
        local launch_daemon="com.company.smartcard.notenforced"
        local launch_daemon_path="$bootVolumeName/Library/LaunchDaemons/$launch_daemon".plist

echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$launch_daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>/usr/sbin/dseditgroup -o edit -a '$uid' -t user '$notEnforced'; /bin/rm -f /Library/LaunchDaemons/'$launch_daemon'.plist; /bin/launchctl bootout system/'$launch_daemon'</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>" > "$launch_daemon_path"
# Set proper permissions on launch daemon
if [[ -e "$launch_daemon_path" ]]; then
    /usr/sbin/chown root:wheel "$launch_daemon_path"
    /bin/chmod 644 "$launch_daemon_path"
fi
}
        echo "Creating removal script"
        createRemovalLaunchDaemon (){
        local launch_daemon="com.company.smartcard.removenotenforced"
        local launch_daemon_path="$bootVolumeName/Library/LaunchDaemons/$launch_daemon".plist

echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$launch_daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>/usr/sbin/dseditgroup -o edit -d '$uid' -t user '$notEnforced'; /bin/rm -f /Library/LaunchDaemons/'$launch_daemon'.plist; /bin/launchctl bootout system/'$launch_daemon'</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
</dict>
</plist>" > "$launch_daemon_path"
# Set proper permissions on launch daemon
if [[ -e "$launch_daemon_path" ]]; then
    /usr/sbin/chown root:wheel "$launch_daemon_path"
    /bin/chmod 644 "$launch_daemon_path"
fi
}       
    createLaunchDaemon
    createRemovalLaunchDaemon
    fi
fi