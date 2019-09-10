#!/bin/sh
#--------------------------------------------
# Author: Cai Miao
# Since: 2019/08/26
# This Shell script is for the slave server configuration.
# You can see the detail at https://hexang.org/sosconf/tech-team/ldap-account-server/blob/master/README.md
# Feature：autorun OpenLDAP services.
# Parameters：The master's IP, Admin password and Replication password.
#--------------------------------------------

# Check the user input.
{
if [ -z "$1" ]
then
  echo "The master's IP cannot be empty!"
  exit 0
elif [ -z "$2" ]
then
  echo "Admin password cannot be empty!"
  exit 0
elif [ -z "$3" ]
then
  echo "Replication password cannot be empty!"
  exit 0
fi
}

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

# Configure administrator information.
touch chrootpw.ldif
echo "dn: olcDatabase={0}config,cn=config" >> chrootpw.ldif 
echo "changetype: modify" >> chrootpw.ldif
echo "add: olcRootPW" >> chrootpw.ldif
slappasswd -s $2 | sed -e "s#{SSHA}#olcRootPW: {SSHA}#g" >> chrootpw.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif

# Import all schemas.
all_files='ls /etc/openldap/schema/*.ldif'
for file in $all_files
do
    ldapadd -Y EXTERNAL -H ldapi:/// -f $file
done

(
cat << EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc=hexang,dc=org" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=hexang,dc=org

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc=hexang,dc=org

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $(grep -o '{SSHA}.*' chrootpw.ldif)
EOF
) > changedomain.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f changedomain.ldif

(
cat << EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001
  provider=ldap://$1:389/
  bindmethod=simple
  binddn="uid=rpuser,dc=hexang,dc=org"
  credentials=$3
  searchbase="dc=hexang,dc=org"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  retry="30 5 300 3"
  interval=00:00:05:00
EOF
) > syncrepl.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f syncrepl.ldif