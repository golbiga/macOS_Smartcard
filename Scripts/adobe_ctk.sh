#!/bin/zsh

#################################################
# Enable CTK Support for Adobe Reader & Acrobat Pro
# Josh Harvey | Allen Golbig | March 2020
#################################################

#Function to update Adobe Reader
adobe_reader () {
    echo "Working in $userHome"
    /usr/libexec/PlistBuddy -c "Delete :DC:Security:ASPKI:1:CTK" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK array" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: integer 8" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: Dict" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK Array" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: integer 0" $userHome/Library/Preferences/com.adobe.Reader.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: bool yes" $userHome/Library/Preferences/com.adobe.Reader.plist
}
#Function to update Adobe Acrobat
adobe_acrobat () {
    echo "Working in $userHome"
    /usr/libexec/PlistBuddy -c "Delete :DC:Security:ASPKI:1:CTK" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK array" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: integer 8" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK: Dict" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK Array" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: integer 0" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
    /usr/libexec/PlistBuddy -c "Add :DC:Security:ASPKI:1:CTK:1:EnableCTK: bool yes" $userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist
}

# Updates the Plists for Acrobat and Reader for each user
for u in $(dscl /Local/Default -list /Users uid | awk '$2 >= 100 && $0 !~ /^_/ { print $1 }'); do
    userHome=$(dscl /Local/Default read /Users/$u NFSHomeDirectory | awk '{ print $NF }')
    if [[ -e "$userHome/Library/Preferences/com.adobe.Acrobat.Pro.plist" ]]; then
        echo "Updating Acrobat settings for $u"
        adobe_acrobat $u 
    else
        echo "Acrobat not found for $u."
    fi
     
    if [[ -e "$userHome/Library/Preferences/com.adobe.Reader.plist" ]]; then
        echo "Updating Reader settings for $u"
        adobe_reader $u
    else
      echo "Reader not found for $u"
    fi   
done

killall cfprefsd

exit 0