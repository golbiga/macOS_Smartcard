#!/bin/zsh

currentUser="$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )"

# Prompt the user to insert card, once inserted prompt will go away.
prompt (){
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
-windowType utility -title "Smartcard Mapping" -description "Please insert your smartcard to begin." \
-alignDescription center -lockHUD -icon /System/Applications/Utilities/Keychain\ Access.app/Contents/Resources/AppIcon.icns & while [[ $( security list-smartcards 2>/dev/null \
| grep -c com.apple.pivtoken ) -lt 1 ]]; do sleep 1; done; kill -9 $!
}

prompt

# Get the PIV Identity Hash
osVers="$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d '.' -f 2)"

if [[ "$osVers" -gt 14 ]]; then
	# Get the PIV Identity Hash
	hash="$(sc_auth identities 2>/dev/null| awk '/PIV/ {print $1}' | tr '[:upper:]' '[:lower:]')"
else
	hash="$(sc_auth identities 2>/dev/null| awk '/PIV/ {print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/.\{8\}/& /g' | sed 's/.$//g')"
fi

# Extract the certificate associated with that hash to the temp folder.
system_profiler SPSmartCardsDataType | grep -A5 "$hash" | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{print; count++; if (count==3) exit}' | fold -w67 > /tmp/temp.pem

# Extract Common Name from Card
cn=$(openssl x509 -noout -subject -in /tmp/temp.pem | sed -n '/^subject/s/^.*CN=//p')

# Microsoft db Hash List
loginhashlist=$(/usr/bin/security find-certificate -a -m -Z /Users/"$currentUser"/Library/Keychains/Microsoft_Entity_Certificates-db | grep -E 'SHA-1|email' | awk '/DOMAIN.COM/ {print x}; { x=$NF}')

# User Hash List
userhashlist=$(/usr/bin/security find-certificate -c "$cn" -a -Z /Users/"$currentUser"/Library/Keychains/Microsoft_Entity_Certificates-db | grep SHA-1 | awk '{print $NF}')

# Unique List
uniquelist=$(echo -e "$loginhashlist\n$userhashlist" | sort | uniq -u)

if [[ ! -z "$uniquelist" ]]; then
	while read -r line
	do
		/usr/bin/security delete-certificate -Z $line /Users/"$currentUser"/Library/Keychains/Microsoft_Entity_Certificates-db
	done <<< "$uniquelist"
fi
