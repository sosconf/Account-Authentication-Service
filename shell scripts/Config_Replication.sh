#!/bin/sh
#--------------------------------------------
# Author: Cai Miao
# Since: 2019/08/26
# This Shell script is to configure LDAP server.
# You can see the detail at https://hexang.org/sosconf/tech-team/ldap-account-server/blob/master/README.md
# Feature：autorun OpenLDAP services.
# Parameters：admin password and serverID.
#--------------------------------------------

# Check the user input.
{
if [ -z "$1" ]
then
  echo "Admin password cannot be empty!"
  exit 0
elif [ -z "$2" ]
then
  echo "This server's id cannot be empty!"
  exit 0
fi
}

(
cat << EOF
$1
EOF
) > /etc/admin_pwd.txt

### Install LDAP ###
yum install -y openldap openldap-* policycoreutils-python

# Start LDAP service.
systemctl start slapd

# Wait for an error report. Sleep is necessary!
sleep 3

# A while loop to add all SELinux rules.
while [ ! -z $(audit2allow -al | grep -o '[a-z]' | head -1) ]
do
  audit2allow -a -M ldap_rule
  semodule -i ldap_rule.pp
  sleep 5
  systemctl start slapd
  sleep 3
done

# Check LDAP's status.
systemctl status slapd

# Automatically start LDAP after reboot.
systemctl enable slapd

### Configure LDAP Logging ###

touch /var/log/slapd.log
chown -R ldap. /var/log/slapd.log

# Append file path to the rsyslog.
echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf

# Update the log level.
(
cat << EOF
dn: cn=config
changetype: modify
add: olcLogLevel
olcLogLevel: 296
EOF
) > loglevel.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f loglevel.ldif

# Slice the log.
(
cat << EOF
/var/log/slapd.log {
        prerotate
                /usr/bin/chattr -a /var/log/slapd/slapd.log
        endscript
        compress
        delaycompress
        notifempty
        rotate 100
        size 10M
        postrotate
                /usr/bin/chattr +a /var/log/slapd/slapd.log
        endscript
}
EOF
) > /etc/logrotate.d/ldap

# Restar to make it take effect.
systemctl restart rsyslog

# Configure BerkeleyDB and authorization.
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*

# Configure syncprov module.
(
cat << EOF
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib64/openldap
olcModuleLoad: syncprov.la
EOF
) > mod_syncprov.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f mod_syncprov.ldif

### Enable Config Replication ###

# Change the olcServerID.
(
cat << EOF
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: $2
EOF
) > olcserverid.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f olcserverid.ldif

# Configure administrator information.
touch chrootpw.ldif
echo "dn: olcDatabase={0}config,cn=config" >> chrootpw.ldif 
echo "changetype: modify" >> chrootpw.ldif
echo "add: olcRootPW" >> chrootpw.ldif
slappasswd -s $1 | sed -e "s#{SSHA}#olcRootPW: {SSHA}#g" >> chrootpw.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif

# Set up the configuration replication on all servers.
(
cat << EOF
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: 1 ldap://master01.hexang.org
olcServerID: 2 ldap://master02.hexang.org

dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov

dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001 provider=ldap://master01.hexang.org binddn="cn=config"
  bindmethod=simple credentials=$1 searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
olcSyncRepl: rid=002 provider=ldap://master02.hexang.org binddn="cn=config"
  bindmethod=simple credentials=$1 searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
-
add: olcMirrorMode
olcMirrorMode: TRUE
EOF
) > configrep.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f configrep.ldif