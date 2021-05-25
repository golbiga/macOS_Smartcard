#!/bin/bash

# Check for PIV 
pivAvail=$(/usr/bin/security list-smartcards 2>/dev/null | grep -c com.apple.pivtoken)

# If the card is not available, check plist for value
if [[ "$pivAvail" -lt "1" ]]; then 
    result=$(defaults read /Library/Preferences/com.company.certInfo enddate 2>/dev/null)
    if [[ -z "$result" ]]; then
        echo "<result>Smartcard Not Present, Value Not Set</result>"
    else    
        echo "<result>$result</result>"
    fi
    exit 0
fi 

# Create temp dir to export certs
tmpdir=$(mktemp -d)

# Dump card's certs
security export-smartcard -e "$tmpdir"

# Get PIV cert
piv_path=$(ls "$tmpdir" | grep PIV | grep ^Cer)

# Get enddate and convert it. Thanks Dan B.
expiry=$(openssl x509 -noout -enddate -in "$tmpdir/$piv_path" | awk -F'=' '{print $2}')
result=$(date -j -f "%b %d %T %Y %Z" "$expiry" "+%Y-%m-%d %H:%M:%S")

# Write to plist for later 
defaults write /Library/Preferences/com.company.certInfo.plist enddate "$result"

echo "<result>$result</result>"

# clean up
rm -rf $tmpdir