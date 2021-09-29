#!/bin/sh

# Check for logged in user will be used with security command
loggedInUser="$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }'  )"

# Get SHA1 from export-smartcard gibberish
sha1=$(/usr/bin/security export-smartcard -t certs | awk '/Certificate For PIV Authentication/,/sha1/' | grep sha1 | head -n1| cut -d'<' -f2 | sed "s/[ >]//g")


# Prompt user for Service Name, default is *.domain.com
prompt () {
	idPref="$(/usr/bin/osascript -e 'display dialog "What Identity Preference would you like to set?" default answer "*.domain.com" buttons {"Continue"}' | /usr/bin/awk -F':' '{print $3}')"
}

# Set idPref
setIdentity () {
	/usr/bin/security set-identity-preference -c "$loggedInUser" -s "$idPref" -Z "$sha1"
}

prompt
setIdentity
