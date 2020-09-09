#!/bin/sh

# Check for logged in user will be used with security command
loggedInUser="$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )"

# Get SHA1 from export-smartcard gibberish
sha1=$(/usr/bin/security export-smartcard -t certs | awk '/Certificate For PIV Authentication/,/sha1/' | grep sha1 | head -n1| cut -d'<' -f2 | sed "s/[ >]//g")

# Prompt user for Service Name, default is *.domain.com
prompt () {
	idPref=$(/usr/bin/osascript<<END
	tell application "System Events"
	activate
	set the answer to text returned of (display dialog "What Identity Preference would you like to set?" default answer "*.domain.com" buttons {"Continue"})
	end tell
END)
}


# Set idPref
setIdentity () {
	/usr/bin/security set-identity-preference -c "$loggedInUser" -s "$idPref" -Z "$sha1"
}

prompt
setIdentity
