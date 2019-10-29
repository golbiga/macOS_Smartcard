#!/bin/sh

#Get list of non-hidden real users 
FIND_USERS=$(dscl /Local/Default -list /Users uid | awk '$2 >= 100 && $0 !~ /^_/ { print $1 }')

#function to update Adobe Reader
adobe_reader () {
    su $1 -c '/usr/libexec/PlistBuddy -c "Delete :DC:Security:ASPKI:1:CTK" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK array" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: real 8" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: Dict" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK Array" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: real 0" ~/Library/Preferences/com.adobe.Reader.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: bool yes" ~/Library/Preferences/com.adobe.Reader.plist'
}

#function to update Adobe Acrobat
adobe_acrobat () {
    su $1 -c '/usr/libexec/PlistBuddy -c "Delete :DC:Security:ASPKI:1:CTK" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK array" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: real 8" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: Dict" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK Array" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: real 0" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
    su $1 -c '/usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: bool yes" ~/Library/Preferences/com.adobe.Acrobat.Pro.plist'
}

for u in $FIND_USERS; do
    userHome=$(dscl . read /Users/$u NFSHomeDirectory | awk '{ print $NF }')
    if [[ -e "$userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist" ]]; then
        echo "updating Acrobat settings for $u"
        adobe_acrobat $u 
    fi
    
    if [[ -e "$userHome/Library/Preferences/com.adobe.Reader.plist" ]]; then
        echo "updating Reader settings for $u"
        adobe_reader $u
    fi   
done

killall cfprefsd

exit 0