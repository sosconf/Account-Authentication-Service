#!/bin/sh
#--------------------------------------------
# Author: Cai Miao
# Since: 2019/08/26
# This Shell script is to configure LDAP database.
# You can see the detail at https://hexang.org/sosconf/tech-team/ldap-account-server/blob/master/README.md
# Feature：autorun OpenLDAP services.
# Parameters：Replication password.
#--------------------------------------------

{
if [ -z "$1" ]
then
  echo "Replication password cannot be empty!"
  exit 0
fi
}

# Enable Database Replication
(
cat << EOF
dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpSessionLog: 100
EOF
) > syncprov.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f syncprov.ldif

# Setup replication for hdb database.
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
-
replace: olcRootDN
olcRootDN: cn=admin,dc=hexang,dc=org
-
replace: olcRootPW
olcRootPW: $(grep -o '{SSHA}.*' chrootpw.ldif)
-
add: olcSyncRepl
olcSyncRepl: rid=003 provider=ldap://master01.hexang.org binddn="cn=admin,dc=hexang,dc=org" bindmethod=simple
  credentials=$(head -n 1 /etc/admin_pwd.txt) searchbase="dc=hexang,dc=org" type=refreshAndPersist
  interval=00:00:05:00 retry="5 5 300 5" timeout=1
olcSyncRepl: rid=004 provider=ldap://master02.hexang.org binddn="cn=admin,dc=hexang,dc=org" bindmethod=simple
  credentials=$(head -n 1 /etc/admin_pwd.txt) searchbase="dc=hexang,dc=org" type=refreshAndPersist
  interval=00:00:05:00 retry="5 5 300 5" timeout=1
-
add: olcDbIndex
olcDbIndex: entryUUID  eq
-
add: olcDbIndex
olcDbIndex: entryCSN  eq
-
add: olcMirrorMode
olcMirrorMode: TRUE
EOF
) > olcdatabasehdb.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f olcdatabasehdb.ldif

# Import all schemas.
all_files='ls /etc/openldap/schema/*.ldif'
for file in $all_files
do
    ldapadd -Y EXTERNAL -H ldapi:/// -f $file
done

# Set organization hierarchy on LDAP DB.
(
cat << EOF
dn: dc=hexang,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: Hexang Open Source Life Style Platform
dc: hexang

dn: cn=admin,dc=hexang,dc=org
objectClass: organizationalRole
cn: admin

dn: ou=hexang.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: hexang.org

dn: ou=accounts,ou=hexang.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: accounts

dn: ou=hexang.com,dc=hexang,dc=org
objectClass: organizationalUnit
ou: hexang.com

dn: ou=accounts,ou=hexang.com,dc=hexang,dc=org
objectClass: organizationalUnit
ou: accounts

dn: ou=openingsource.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: openingsource.org

dn: ou=accounts,ou=openingsource.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: accounts

dn: ou=sosconf.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: openingsource.org

dn: ou=accounts,ou=sosconf.org,dc=hexang,dc=org
objectClass: organizationalUnit
ou: accounts
EOF
) > organisation.ldif

ldapadd -x -D cn=admin,dc=hexang,dc=org -w $(head -n 1 /etc/admin_pwd.txt) -f organisation.ldif

# For master-slave replication
(
cat << EOF
dn: uid=rpuser,dc=hexang,dc=org
objectClass: simpleSecurityObject
objectclass: account
uid: rpuser
description: Replication  User
userPassword: $1
EOF
) > rpuser.ldif

ldapadd -x -D cn=admin,dc=hexang,dc=org -w $(head -n 1 /etc/admin_pwd.txt) -f rpuser.ldif

rm /etc/admin_pwd.txt
