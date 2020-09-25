#!/bin/bash

# HARDCODED VALUE FOR "User" IS SET HERE - List of user to exclude separated by spaces.
# Example: User="user1 user2 user3"
# Jamf Parameter Value $4 Label - Users to include
User=""

# HARDCODED VALUE FOR "AdminName" IS SET HERE
AdminName=""

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "User"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [[ ! -z "$4" ]]; then
	User=$4
fi

# CHECK TO SEE IF A VAULE WAS PASSED IN PARAMETER 5 AND, IF SO, ASSIGN TO "AdminName"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [[ ! -z "$5" ]]; then
	AdminName=$5
fi

for EachUser in $User;
do
	echo $EachUser
	altSecCheck=$(/usr/bin/dscl . -read /Users/"$AdminName" AltSecurityIdentities 2>/dev/null | sed -e "s/Kerberos://g" | sed -e "s/AltSecurityIdentities: //g")
	userPrincipalName=$(ldapsearch -LLL -x -h <ldaphost> -b <searchbase> '(uid='"$EachUser"')' 'description' | sed -n 's/^[ \t]*description:[ \t]*\(.*\)/\1/p')

	if [[ "$userPrincipalName" = "" ]]; then
		echo "No UPN found for "$EachUser""
	elif [[ "$altSecCheck" = *"$userPrincipalName"* ]]; then
	  echo "AltSecurityIdentities is set to "$userPrincipalName""
	elif [[ "$altSecCheck" = "" ]]; then
	  echo "Creating AltSecurityIdentities for "$userPrincipalName""
	  /usr/bin/dscl . -create /Users/"$AdminName" AltSecurityIdentities Kerberos:"$userPrincipalName"
	else
	  echo "Appending AltSecurityIdentities for "$userPrincipalName""
		/usr/bin/dscl . -append /Users/"$AdminName" AltSecurityIdentities Kerberos:"$userPrincipalName"
	fi
done

