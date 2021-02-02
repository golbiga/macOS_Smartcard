#!/bin/sh

# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check for logged in user.
currentUser="$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )"

# Check for pairing
checkForPaired (){
  tokenCheck=$(/usr/bin/dscl . read /Users/"$currentUser" AuthenticationAuthority | grep -c tokenidentity)
    if [[ "$tokenCheck" > 0 ]]; then
      echo "Unpair $currentUser"
      /usr/sbin/sc_auth unpair -u "$currentUser"
    else
      echo "Nothing Paired"
    fi
}

# Prompt the user to insert card, once inserted prompt will go away.
prompt (){
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
-windowType utility -title "Smartcard Mapping" -description "Please insert your smartcard to begin." \
-alignDescription center -lockHUD & while [[ $( security list-smartcards 2>/dev/null \
| grep -c com.apple.pivtoken ) -lt 1 ]]; do sleep 1; done; kill -9 $!
}

getUPN(){
# Get the PIV Identity Hash
osVers="$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d '.' -f 2)"

if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -ge 14 ) || ( ${osvers_major} -eq 11 && ${osvers_minor} -ge 0 ) ]]; then
	# Get the PIV Identity Hash
	hash="$(sc_auth identities 2>/dev/null| awk '/PIV/ {print $1}' | tr '[:upper:]' '[:lower:]')"
else
	hash="$(sc_auth identities 2>/dev/null| awk '/PIV/ {print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/.\{8\}/& /g' | sed 's/.$//g')"
fi

# Extract the certificate associated with that hash to the temp folder.
system_profiler SPSmartCardsDataType | grep -A5 "$hash" | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{print; count++; if (count==3) exit}' | fold -w67 > /tmp/temp.pem

echo ""

echo "Getting UPN"
UPN="$(openssl asn1parse -i -dump -in /tmp/temp.pem -strparse $(openssl asn1parse -i -dump -in /tmp/temp.pem  | awk -F ':' '/X509v3 Subject Alternative Name/ {getline; print $1}') | awk -F ':' '/UTF8STRING/{print $4}')"
echo "UPN: $UPN"

if [[ -e /tmp/temp.pem ]]; then
    rm /tmp/temp.pem
fi
}

createAltSecId (){
  altSecCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2>/dev/null | sed -n 's/.*Kerberos:\([^ ]*\).*/\1/p')
  if [[ "$UPN" = "" ]]; then
    echo "No UPN found for $currentUser"
    rv=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Smartcard Mapping" -description "Smartcard mapping was unsuccessful." -alignDescription center -button1 "Quit")
  elif [[ "$altSecCheck" = "$UPN" ]]; then
    echo "AltSec is already set to "$UPN""
    rv=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Smartcard Mapping" -description "Smartcard mapping was already set." -alignDescription center -button1 "Quit")
  else
    echo "Adding AltSecurityIdentities"
    /usr/bin/dscl . -append /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
    rv=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Smartcard Mapping" -description "Successfully added $UPN to $currentUser." -alignDescription center -button1 "Quit")
fi
}

createMapping (){
if [ ! -f /etc/SmartcardLogin.plist ];then
/bin/cat > "/etc/SmartcardLogin.plist" << 'Attr_Mapping'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
     <key>AttributeMapping</key>
     <dict>
          <key>fields</key>
          <array>
               <string>NT Principal Name</string>
          </array>
          <key>formatString</key>
          <string>Kerberos:$1</string>
          <key>dsAttributeString</key>
          <string>dsAttrTypeStandard:AltSecurityIdentities</string>
     </dict>
     <key>TrustedAuthorities</key>
	   <array>
		  <string></string>
	   </array>
     <key>NotEnforcedGroup</key>
     <string></string>
</dict>
</plist>
Attr_Mapping
fi
}

prompt
checkForPaired
getUPN
createAltSecId
createMapping