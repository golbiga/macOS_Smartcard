#!/bin/bash

pamSudo=$(grep -Ec '^(auth\s+sufficient\s+pam_smartcard.so|auth\s+required\s+pam_deny.so)' /etc/pam.d/sudo)
pamLogin=$(grep -Ec '^(auth\s+sufficient\s+pam_smartcard.so|auth\s+required\s+pam_deny.so)' /etc/pam.d/login)
pamSu=$(grep -Ec '^(auth\s+sufficient\s+pam_smartcard.so|auth\s+required\s+pam_rootok.so)' /etc/pam.d/su)

if [[ "$pamSudo" = "2" ]] && [[ "$pamLogin" = "2" ]] && [[ "$pamSu" = "2" ]]; then
  echo "<result>Compliant</result>"
else
  echo "<result>Not Compliant</result>"
fi