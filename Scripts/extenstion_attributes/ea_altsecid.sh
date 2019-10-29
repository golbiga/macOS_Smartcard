#!/bin/bash

if [[ -f /etc/SmartcardLogin.plist ]]; then
  if [ $(for user in $(dscl . list /Users UniqueID | awk '$2 > 500  {print $1}'); do dscl . read /Users/$user AltSecurityIdentities 2>/dev/null | grep @domain.com; done | wc -l) -gt 0 ]; then
    echo "<result>True</result>"
  else
    echo "<result>False</result>"
  fi
else
  echo "<result>False</result>"
fi