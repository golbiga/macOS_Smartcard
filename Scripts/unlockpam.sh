#!/bin/bash


# write out a new sudo file
cat > /etc/pam.d/sudo << SUDO_END
# sudo: auth account password session
auth       sufficient     pam_smartcard.so
auth       required       pam_opendirectory.so
account    required       pam_permit.so
password   required       pam_deny.so
session    required       pam_permit.so
SUDO_END

# Fix new file ownership and permissions
chmod 444 /etc/pam.d/sudo
chown root:wheel /etc/pam.d/sudo

# write out a new login file
cat > /etc/pam.d/login << LOGIN_END
# login: auth account password session
auth       optional       pam_krb5.so use_kcminit
auth       optional       pam_ntlm.so try_first_pass
auth       optional       pam_mount.so try_first_pass
auth       required       pam_opendirectory.so try_first_pass
account    required       pam_nologin.so
account    required       pam_opendirectory.so
password   required       pam_opendirectory.so
session    required       pam_launchd.so
session    required       pam_uwtmp.so
session    optional       pam_mount.so
LOGIN_END

# Fix new file ownership and permissions
chmod 644 /etc/pam.d/login
chown root:wheel /etc/pam.d/login

# write out a new su file
cat > /etc/pam.d/su << SU_END
# su: auth account session
auth       sufficient     pam_rootok.so
auth       required       pam_opendirectory.so
account    required       pam_group.so no_warn group=admin,wheel ruser root_only fail_safe
account    required       pam_opendirectory.so no_check_shell
password   required       pam_opendirectory.so
session    required       pam_launchd.so
SU_END

# Fix new file ownership and permissions
chmod 644 /etc/pam.d/su
chown root:wheel /etc/pam.d/su

