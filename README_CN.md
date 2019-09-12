**Contents**
=================
[TOC]

# AAA System Development Documentation

[![LICENSE](https://img.shields.io/badge/license-AGPLv3-blue)](https://github.com/Hephaest/Simple-Java-Caculator/blob/master/LICENSE)
[![LDAP](https://img.shields.io/badge/OpenLDAP-2.4.X-brightgreen)](https://www.openldap.org/doc/admin24/)
[![CAS](https://img.shields.io/badge/CAS-6.0.X-orange)](https://apereo.github.io/cas/6.0.x/)

{+ This document describes the single sign-on based on CAS，helps new friends to quickly understand the project and do rapid development ．PS：for tech members only．+}

Latest update: `2019/08/31`

## Install OpenLDAP In CentOS

{-To facilitate the following configuration ，do the following configuration with **root** authority  -}

We need at least 4 servers to implement the LDAP service（2 Primary Servers and 2 Secondary Servers ）,to prevent a server from going down and disabling the service:

- If possible，To improve the access speed, the Primary Servers and the Secondary Servers are best  served on the same intranet .
- Primary servers are best located in different areas, free from the impact of server paralysis in some areas.

<div align="center">
<table class="tg">
  <tr align="center">
    <th class="tg-0pky" rowspan="2">role</th>
    <th class="tg-0lax" colspan="2">Primary IP Address</th>
    <th class="tg-0pky" rowspan="2">OS</th>
  </tr>
  <tr align="center">
    <td class="tg-0lax">Public IP</td>
    <td class="tg-0pky">Intranet IP</td>
  </tr>
  <tr>
    <td class="tg-0pky">master01.hexang.org</td>
    <td class="tg-0lax">148.70.168.17</td>
    <td class="tg-0pky">172.27.0.15</td>
    <td class="tg-0pky">CentOS 7.4x86_64</td>
  </tr>
  <tr>
    <td class="tg-0pky">master02.hexang.org</td>
    <td class="tg-0lax">120.27.250.20</td>
    <td class="tg-0pky">172.16.43.45</td>
    <td class="tg-0pky">CentOS 7.4x86_64</td>
  </tr>
  <tr>
    <td class="tg-0pky">slave01.hexang.org</td>
    <td class="tg-0lax">106.53.67.32</td>
    <td class="tg-0pky">172.16.0.14</td>
    <td class="tg-0pky">CentOS 7.4x86_64</td>
  </tr>
  <tr>
    <td class="tg-0pky">slave02.hexang.org</td>
    <td class="tg-0lax">47.96.239.221</td>
    <td class="tg-0pky">172.16.249.253</td>
    <td class="tg-0pky">CentOS 7.4x86_64</td>
  </tr>
</table>
</div>



<div align="center">
<table class="tg">
  <tr>
    <th class="tg-dvpl">LDAP Administrator</th>
    <th class="tg-c3ow">Permission</th>
    <th class="tg-baqh">Password(provisional)</th>
  </tr>
  <tr>
    <td class="tg-dvpl">Main manager</td>
    <td class="tg-c3ow">readable, writable</td>
    <td class="tg-baqh">w8JFUEWjAsHBwLjjcQrCYiPP</td>
  </tr>
  <tr>
    <td class="tg-dvpl">Secondary manager</td>
    <td class="tg-c3ow">readable</td>
    <td class="tg-baqh">of2Pwxqt9Gc7TH8e</td>
  </tr>
</table>
</div>

### OpenLDAP Tree Structure

The current organizational structure is relatively simple，each domain name level ou may later create its own management team for management and privacy protection:

<div align="center"><img src ="images/LDAP_tree.png" width = "800px"></div>

### OpenLADP User Information Collection

We use the `schema` in `inetorgperson.ldif`  to collect user information, and we can collect the following data:

<div align="center">
<table class="tg">
  <tr>
    <th class="tg-0pky">The property name</th>
    <th class="tg-0pky">Format</th>
    <th class="tg-0pky">Meaning</th>
  </tr>
  <tr>
    <td class="tg-0pky">uid</td>
    <td class="tg-0pky">char</td>
    <td class="tg-0pky">User name</td>
  </tr>
  <tr>
    <td class="tg-0pky">cn</td>
    <td class="tg-0pky">char</td>
    <td class="tg-0pky">User's full name</td>
  </tr>
  <tr>
    <td class="tg-0pky">jpegPhoto</td>
    <td class="tg-0pky">binary</td>
    <td class="tg-0pky">Profile photo</td>
  </tr>
  <tr>
    <td class="tg-0pky">mail</td>
    <td class="tg-0pky">char</td>
    <td class="tg-0pky">User's mailbox for authentication</td>
  </tr>
    <tr>
    <td class="tg-0pky">preferredLanguage</td>
    <td class="tg-0pky">char</td>
    <td class="tg-0pky">Preferred Language</td>
  </tr>
</table>
</div>

### LDAP Synchronous

OpenLDAP's synchronization schema needs to satisfy the following **6** conditions:

1. **Time synchronization between servers**

    Install NTP
    ```shell
    yum -y install ntp
    ```
    To avoid errors between local time and server time, we should do  `ntpdate` first.
    
    ```shell
    ntpdate ntp1.aliyun.com
    ```
    Then customize the NTP service
    
    ```shell
    vi /etc/ntp.conf
    ```
    Comment out  `iburst`  in `server ntp` ，add a new line of NTP server information behind:
    
    ```shell
    server ntp1.aliyun.com iburst  # we use aliyun public network NTP server
    ```
    Save the changes and start the NTP service:
    ```shell
    systemctl start ntpd.service
    ```
    Then configure the restart self-executing NTP service:
    ```shell
    systemctl enable ntpd.service
    ```
    Check whether the operation is effective:
    ```shell
    ntpstat
    ```
    
2. **Consistency of OpenLDAP versions**

    We use `2.4.4` version.

3. **Domain names shoule be resolved between every two OpenLDAP nodes**

    Not set yet.
    
4. **The initial configuration of master-slave and master-master synchronization is identical(Includes the directory tree structure)**

    Copy and paste the following script.
    
5. **Data entries are the same across servers**

    Just add the data after configuration.
    
6. **Schema is the same**

    Copy and paste the following script.

### Script execution file
I've uploaded an executable Shell script [here](https://hexang.org/sosconf/tech-team/ldap-account-server/tree/master/shell%20scripts). You can easily configure it by executing the scripts:
All servers should perform Step 1:

```shell
# Synchro time first, then activate SELinux
chmod +x NTP_and_SELinux.sh
./NTP_and_SELinux.sh 'the first primary server IP' 'the second primary server IP'
```
Step 2: Settings for two master LDAP servers:
```shell
chmod +x Config_Replication.sh
./Config_Replication.sh 'Administrator password' 'Server serial number'
```
Step 3: Simply operate on any of the primary servers:
```shell
chmod +x Database_Replication.sh
./Database_Replication.sh 'Sub-administrator password'
```
Step4: Settings for two slave LDAP servers:
```shell
chmod +x Slave_Configuration.sh
./Slave_Configuration.sh 'corresponding primary server IP' 'Administrator password' 'Sub-administrator password'
```

### Firewall Rules

#### Inbound Rules

<div align="center">
<table class="tg">
  <tr>
    <th class="tg-0pky">Source</th>
    <th class="tg-0pky">Protocol port</th>
    <th class="tg-0pky">Strategy</th>
    <th class="tg-0pky">Comment</th>
  </tr>
  <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">TCP:22</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Allow Linux SSH login</td>
  </tr>
  <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">ICMP</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Support Ping services</td>
  </tr>
  <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">TCP:80</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Allow Web services HTTP(80)</td>
  </tr>
  <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">TCP:443</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Allow Web services HTTP(443)</td>
  </tr>
    <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">TCP:389</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Allow LDAP services</td>
  </tr>
  </tr>
    <tr>
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">UDP:123</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">Allow NTP services</td>
  </tr>
</table>
</div>


#### Outbound Rules

<div align="center">
<table class="tg">
  <tr align="center">
    <th class="tg-0pky">Source</th>
    <th class="tg-0pky">Protocol port</th>
    <th class="tg-0pky">Strategy</th>
    <th class="tg-0pky">Comment</th>
  </tr>
  <tr align="center">
    <td class="tg-0pky">0.0.0.0/0</td>
    <td class="tg-0pky">ALL</td>
    <td class="tg-0pky">permit</td>
    <td class="tg-0pky">-</td>
  </tr>

</table>
</div>

#### SELinux Setting
Activate SELinux:
```shell
sed -i '7s/^.*$/SELINUX=enforcing/' /etc/selinux/config
```
Restart the server to enable the SELinux configuration.
```shell
systemctl reboot
```
### LDAP Basic Configuration
#### Step1 install LDAP
Install all the relevant packages so as not to miss anything.
```shell
# migrationtools --Used to migrate system users and groups to LDAP.
yum install -y openldap openldap-* migrationtools policycoreutils-python
```
BerkeleyDB configuration, and licensed to LDAP users。
```shell
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG # copy
chown ldap:ldap /var/lib/ldap/DB_CONFIG # Authorization
```
Activate LDAP server.
```shell
systemctl enable slapd
```
Let's try to run the LDAP service:
```shell
systemctl start slapd
```
Error messages will be generated at this time，run the following command to get the reason for the startup failure:
```shell
audit2allow -al
```
Create a separate rule for LDAP:
```shell
audit2allow -a -M ldap_rule
```
Activate this rule:
```shell
semodule -i ldap_rule.pp
```
Check if the rule was loaded successfully:
```shell
[root@VM_0_15_centos ~]# semodule -l | grep ldap_rule
ldap_rule       1.0
```
Restart LDAP service:
```shell
systemctl start slapd
```
Check the running status of LDAP, the green mark indicates normal operation:
```shell
systemctl status slapd
```
Check port usage ;By default, port 389 is occupied：
```shell
netstat -tlnp | grep slapd
```
#### Step2 Configure the syslog to log LDAP service
First create the log，then authorize files:
```shell
touch /var/log/slapd.log
chown -R ldap. /var/log/slapd.log
```
Appending to the configuration of the system log after authorization
```shell
echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf
```
Restart the system logger to take effect:
```shell
systemctl restart rsyslog
```
Next, update the level of the LDAP log. First, create the intermediate file:

```shell
vim loglevel.ldif
```
Copy the following lines to the file:
```shell
dn: cn=config
changetype: modify
add: olcLogLevel
# Set the log level. level 296 is the sum of 256(Log connection/operation/result), 32(Search filter processing) and 8(Connection management).
olcLogLevel: 296
```
Add logging to the main configuration file:
```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f loglevel.ldif
```
In addition, it is better to shard the log to facilitate error checking:
```shell
vi /etc/logrotate.d/ldap
===========================================================
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
```
Check the current log configuration:
```shell
[root@VM_0_15_centos ~]# cat /etc/openldap/slapd.d/cn\=config.ldif |grep olcLogLevel
olcLogLevel: 296
```
#### Step3 Configure Administrator Password
```shell
touch chrootpw.ldif # Create a file
echo "dn: olcDatabase={0}config,cn=config" >> chrootpw.ldif 
echo "changetype: modify" >> chrootpw.ldif # Specify modification type
echo "add: olcRootPW" >> chrootpw.ldif # Add the olcRootPW configuration item
slappasswd -s w8JFUEWjAsHBwLjjcQrCYiPP | sed -e "s#{SSHA}#olcRootPW: {SSHA}#g" >> chrootpw.ldif # Append ciphertext password
```
Execute the LDAP Modification Configuration Command:
```shell
ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
```
#### Step4 Import Schema
The Schema is in this path: /etc/openldap/ Schema/，I have written a script that can import all of the schemas
```shell
vim import_schema.sh
```
Copy the following lines to the file.
```shell
all_files='ls /etc/openldap/schema/*.ldif'
for file in $all_files
do
  ldapadd -Y EXTERNAL -H ldapi:/// -f $file
done
```
#### Step5 Configure the top-level domain for LDAP
```shell
vim changedomain.ldif
===========================================================
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
olcRootPW: # The password generated in step 2，It can be viewed by 'vim chrootpw.ldif'
```
Execute modify command:
```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f changedomain.ldif
```
### Multi master Configuration
All primary servers must perform step **1** and step **2**:

#### Step1 Configure the Syncprov module
```shell
vi mod_syncprov.ldif
===========================================================
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib64/openldap
olcModuleLoad: syncprov.la
```
Add configuration on LDAP server:
```shell
ldapadd -Y EXTERNAL -H ldapi:/// -f mod_syncprov.ldif
```
#### Step2 Enable mirror Configuration
In this next step please notice which primary server is being configured:

olcServerID : Subscript corresponding to the primary server (**1** or **2**).
```shell
vi master.ldif
===========================================================
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: 1 or 2
```
Change configuration on the LDAP server:
```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f master.ldif
```
Configuration mirror:

PS:You need to fill in the "Administrator's clear-text password" 

```shell
vi configrep.ldif
===========================================================
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
  bindmethod=simple credentials= "Administrator's clear-text password"  searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
olcSyncRepl: rid=002 provider=ldap://master02.hexang.org binddn="cn=config"
  bindmethod=simple credentials="Administrator's clear-text password" searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
-
add: olcMirrorMode
olcMirrorMode: TRUE
```
Change the configuration on the LDAP server:
```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f configrep.ldif
```
#### Step3 Enable syncprov module
```shell
vi syncprov.ldif
===========================================================
dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpSessionLog: 100
```
Add configuration on LDAP server:
```shell
ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif
```
#### Step4 Enabling Mirror Database
```shell
vi olcdatabasehdb.ldif
===========================================================
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
olcRootPW: 'Administrator password'
-
add: olcSyncRepl
olcSyncRepl: rid=003 provider=ldap://master01.hexang.org binddn="cn=admin,dc=hexang,dc=org" bindmethod=simple
  credentials='Secondary Administrator Password' searchbase="dc=hexang,dc=org" type=refreshAndPersist
  interval=00:00:05:00 retry="5 5 300 5" timeout=1
olcSyncRepl: rid=004 provider=ldap://master02.hexang.org binddn="cn=admin,dc=hexang,dc=org" bindmethod=simple
  credentials='Secondary Administrator Password' searchbase="dc=hexang,dc=org" type=refreshAndPersist
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
```
Add configuration on the LDAP server:
```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f olcdatabasehdb.ldif
```
#### Step5 Clone the Sturcture
Set the directory Structure according to [OpenLDAP Tree Structure](#OpenLDAP Tree Structure).<br>

This step can be performed on any primary server:
```shell
vim organisation.ldif
===========================================================
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
```
Execute modify command:
```shell
ldapadd -x -D cn=admin,dc=hexang,dc=org -W -f organisation.ldif
```
#### Step6 Create Sub-Administrator
Considering security，We need to create a read-only secondary management on the primary server:
```shell
vi rpuser.ldif
===========================================================
dn: uid=rpuser,dc=hexang,dc=org
objectClass: simpleSecurityObject
objectclass: account
uid: rpuser
description: Replication  User
userPassword: 'Secondary Administrator Password'
```
Execute add command:
```shell
ldapadd -x -D cn=admin,dc=hexang,dc=org -w 'Administrator password' -f rpuser.ldif
```
### Master -Slave Configuration

PS: Attention the IP address of the primary server:
```shell
vi syncrepl.ldif
===========================================================
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001
  provider=ldap://IP:389/
  bindmethod=simple
  binddn="cn=admin,dc=hexang,dc=org"
  credentials='Administrator password'
  searchbase="dc=hexang,dc=org"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  retry="30 5 300 3"
  interval=00:00:05:00
```
Add configuration on LDAP server:
```shell
ldapadd -Y EXTERNAL -H ldapi:/// -f syncrepl.ldif
```
### Test
```shell
vi ldaptest.ldif
===========================================================
dn: uid=ldaptest,ou=accounts,ou=hexang.org,dc=hexang,dc=org
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: Huang Xiaoming
uid: ldaptest
sn: Huang
uidNumber: 9988
gidNumber: 100
homeDirectory: /home/ldaptest
loginShell: /bin/bash
gecos: LDAP Replication Test User
userPassword: xiaoming
shadowLastChange: 17058
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
shadowExpire: -1
mail: xiaoming.huang@qq.com
```
Add members to the LDAP server:
```shell
ldapadd -x -W -D "cn=admin,dc=hexang,dc=org" -f ldaptest.ldif
```
You can query the current member's information on any host:
```shell
ldapsearch -x uid=ldaptest -b dc=hexang,dc=org
```
Delete members:
```shell
ldapdelete -W -D "cn=admin,dc=hexang,dc=org" "uid=ldaptest,ou=accounts,ou=hexang.org,dc=hexang,dc=org"
```
If the effect of adding or deleting members is the same across all servers, that means it works.

### phpLDAPadmin Configuration
#### Bind public network IP and host name
Append records to the hosts file:
```shell
echo "(Your cloud server's public network IP)  Apache" >> /etc/hosts
```
#### Configure Apache Services
Check that Apache HTTPD and PHP are installed，Otherwise it would be wrong.
```shell
[root@VM_0_15_centos ~]# rpm -qa | grep httpd # Check if the HTTP package has been installed
httpd-2.4.6-89.el7.centos.1.x86_64
httpd-tools-2.4.6-89.el7.centos.1.x86_64
httpd-devel-2.4.6-89.el7.centos.1.x86_64
httpd-manual-2.4.6-89.el7.centos.1.noarch
httpd-itk-2.4.7.04-2.el7.x86_64
```
If you don't have any output, check that the dependency packages are complete.
```shell
yum -y install httpd*
```
Configure Apache after installation, The configuration files are stored in this path: /etc/httpd/conf/ <br>
The default Apache listening port is 80, Just use the default port.
If there are no special needs, do not change the 'httpd.conf'.

Activate Apache:
```shell
systemctl start httpd.service
```
Check the usage of port 80. If port 80 doesn't work，check if it is occupied by other services，Or whether the configuration file has syntax problems. 
```shell
[root@VM_0_15_centos ~]# lsof -i:80 # This is normal listening
COMMAND  PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
httpd   6045   root    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
httpd   6046 apache    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
httpd   6047 apache    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
httpd   6048 apache    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
httpd   6049 apache    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
httpd   6050 apache    3u  IPv4 151157      0t0  TCP *:http (LISTEN)
```
Check if Apache is working properly:
```shell
service httpd status
```
If it looks like this, that means it works, otherwise, check the log information to find the error location
<div align="center"><img src ="images/terminal.png" width = "600px"></div>

You can use Chrome to test it, and if the following image appears, Apache is working.
<div align="center"><img src ="images/chrome.png" width = "600px"></div>

#### Install phpLDAPadmin
First run the installation:
```shell
yum install -y phpldapadmin
```
Modify configuration content:
```shell
vim /etc/httpd/conf.d/phpldapadmin.conf
```
Change the "Require local" in line 11 to "Require all granted":
```shell
#
#  Web-based tool for managing LDAP servers
#

Alias /phpldapadmin /usr/share/phpldapadmin/htdocs
Alias /ldapadmin /usr/share/phpldapadmin/htdocs

<Directory /usr/share/phpldapadmin/htdocs>
  <IfModule mod_authz_core.c>
    # Apache 2.4
    Require all granted # Change this. PS: I've changed this.
  </IfModule>
  <IfModule !mod_authz_core.c>
    # Apache 2.2
    Order Deny,Allow
    Deny from all
    Allow from 127.0.0.1
    Allow from ::1
  </IfModule>
</Directory>
```
 Modify the PHP configuration, Log into LDAP with the user name:
```shell
vim /etc/phpldapadmin/config.php
```
Line **398** : Change 'uid' to 'cn'：

```shell
$servers->setValue('login','attr','uid'); 
# Do like this: $servers->setValue('login','attr','cn');
```
Line **460** :Close anonymous login to protect data security：
```shell
// $servers->setValue('login','anon_bind',true); 
# Uncomment Line 460，Prevent default from becoming true. Change it into $servers->setValue('login','anon_bind',false);
```
Line **519** : Add' cn', 'sn' to ensure uniqueness of user name：

```shell
#  $servers->setValue('unique','attrs',array('mail','uid','uidNumber')); 
# Uncomment and chage it into $servers->setValue('unique','attrs',array('mail','uid','uidNumber','cn','sn'));
```
Restart the Apache service to let the modified configuration take effect:
```shell
systemctl restart httpd
```
Now we can enter: "http:// 'your public network IP' /ldapadmin/ " in the browser to get the architecture created in step **5**.
<div align="center"><img src ="images/screenrecord.gif" width = "600px"></div>

## Ubuntu 下 CAS 安装及配置方法
{- 为了安全考虑，请以普通用户权限进行以下配置操作 -}

系统环境要求:
<div align="center">
<table class="tg">
  <tr>
    <th class="tg-0pky">环境名称</th>
    <th class="tg-0pky">版本号</th>
  </tr>
  <tr>
    <td class="tg-0pky">OpenJDK</td>
    <td class="tg-0pky">11.0.4</td>
  </tr>
  <tr>
    <td class="tg-0pky">CAS</td>
    <td class="tg-0pky">6.1.x 及以上</td>
  </tr>
  <tr>
    <td class="tg-0pky">Tomcat</td>
    <td class="tg-0pky">9.0.24</td>
  </tr>
  <tr>
    <td class="tg-0pky">Nginx</td>
    <td class="tg-0pky">1.16.1</td>
  </tr>
</table>
</div>

### Apache Tomcat 9 配置
#### 第一步 安装 OpenJDK
升级当前的 `apt` 包:
```shell
sudo apt update
```
安装默认的 `Java OpenJDK` 包，当前的版本是 11。千万不要安装成 Oracle Java 。
```shell
sudo apt install default-jdk
```
查看当前 JDK 版本,确保版本号满足环境要求:
```
java -version
```
#### 第二步 创建 Tomcat 用户
出于安全考虑，Tomcat 不应该在 root 账户下运行。我们需要额外创建一个系统用户:
```shell
sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
```
#### 第三步 安装 Tomcat
去[官网](https://tomcat.apache.org/download-90.cgi)下载 Tomcat 9
```shell
wget http://apache.01link.hk/tomcat/tomcat-9/v9.0.24/bin/apache-tomcat-9.0.24.tar.gz -P /tmp
```
提取压缩文件并移动到第二步创建的管理者的目录里:
```shell
sudo tar xf /tmp/apache-tomcat-9*.tar.gz -C /opt/tomcat
```
为了更好地控制 Tomcat 版本，需要创建一个名为 `latest` 的链接，并直接指向 Tomcat 安装地址:
```shell
sudo ln -s /opt/tomcat/apache-tomcat-9.0.24 /opt/tomcat/latest
```
对管理者进行授权:
```shell
sudo chown -RH tomcat: /opt/tomcat/latest
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'
```
#### 第四步 创建系统单元文件
创建服务单元:
```shell
sudo vim /etc/systemd/system/tomcat.service
===========================================================
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
```
> 请注意 JAVA_HOME 是否正确。

保存并启动新单元文件:
```shell
sudo systemctl daemon-reload
```
下一步，选择监听端口。最理想的状态是不用输端口号，但是我们的 Tomcat 出于安全考虑不以 Root 身份运行，因此没有办法通过直接更改配置文件中的端口号来实现 80 端口的监听。所以，我们需要通过 iptables 进行端口转发:
```shell
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
```
并保存防火墙规则:
```shell
sudo iptables-save > /etc/zsmiptables.rules
```
设置开机自动加载:
```shell
vim /etc/network/interfaces
===========================================================
# 在末尾追加一行
pre-up iptables-restore < /etc/zsmiptables.rules
```
启动 Tomcat 服务:
```shell
sudo systemctl start tomcat
```
注意查看 Tomcat 是否正常运行:
```shell
sudo systemctl status tomcat
```
如果标绿表示运行正常，设置开机自动启动:
```shell
sudo systemctl enable tomcat
```
### Nginx 配置
#### 第一步 创建 Nginx 运行账户
出于安全考虑，不建议以 Root 权限运行 Nginx:
```shell
sudo useradd --shell /sbin/nologin --home-dir /usr/local/nginx nginx
```
#### 第二步 安装依赖库
##### GCC 库
有的系统会预装 gcc，可通过以下命令查看系统环境中是否已有此库:
```shell
gcc
```
如果得到下方的结果，则需要安装 GCC 库:
```
~bash: gcc: command not found
```
安装的命令为:
```
sudo apt-get install build-essentials
```
##### PCRE 库
```
sudo apt-get install libpcre3 libpcre3-dev
```
##### zlib 库
```
sudo apt-get install zlib1g zlib1g-dev
```
##### OpenSSL 库
```
sudo apt-get install openssl libssl-dev
```
##### sysv-rc-conf 管理包
以防安装失败，最好提前换一下源:
```
sudo vim /etc/apt/sources.list
===========================================================
# 添加一行官方源地址
deb http://archive.ubuntu.com/ubuntu/ trusty main universe restricted multiverse
```
更新以下 apt-get:
```
sudo apt-get update
```
完成更新后，安装 sysv-rc-conf :
```
sudo apt-get install sysv-rc-conf
```
#### 第三步 下载与解压 Nginx
创建新的文件夹以存放资源:
```
sudo mkdir src && cd src
```
从[官网](http://nginx.org/en/download.html)下载合适的版本:
```
sudo wget http://nginx.org/download/nginx-1.16.1.tar.gz
```
解压到当前桌面并检测 Nginx 安装环境:
```
sudo tar xf nginx-1.16.1.tar.gz
```
#### 第四步 配置 HTTP 服务
配置 HTTP 和 HTTPS 服务器:
```
cd nginx-1.16.1 && sudo ./configure --prefix=/usr/local/nginx-1.16.1 --user=nginx --group=nginx --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module
```
#### 第五步 安装 Nginx
```
sudo make && sudo make install
```
建立连接方便日后更新:
```
sudo ln -s /usr/local/nginx-1.16.1 /usr/local/nginx
```
检查修改的版本号是否生效:
```
/usr/local/nginx/sbin/nginx -v
```
启动 Nginx:
```
sudo /usr/local/nginx/sbin/nginx
```
访问`http://服务器的公网IP地址`，如果浏览器的打开结果同下图，则说明 Nginx 初步配置成功:

接下来配置开机自启动文件:
```
sudo vim /etc/init.d/nginx
===========================================================
#!/bin/bash
  
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="nginx daemon"
NAME=nginx
DAEMON=/usr/local/nginx/sbin/$NAME
SCRIPTNAME=/etc/init.d/$NAME


# If the daemon file is not found, terminate the script.
test -x $DAEMON || exit 0

d_start() {
        $DAEMON || echo -n " already running"
}

d_stop() {
        $DAEMON -s stop || echo -n " not running"
}

d_reload() {
        $DAEMON -s reload || echo -n " could not reload"
}

case "$1" in
    start)
    echo -n "Starting $DESC: $NAME"
    d_start
    echo "."
    ;;
stop)
    echo -n "Stopping $DESC: $NAME"
    d_stop
    echo "."
    ;;
reload)
    echo -n "Reloading $DESC configuration..."
    d_reload
    echo "reloaded."
    ;;
restart)
    echo -n "Restarting $DESC: $NAME"
    d_stop
# Sleep for two seconds before starting again, this should give the
# Nginx daemon some time to perform a graceful stop.
    sleep 2
    d_start
    echo "."
    ;;
*)
    echo "Usage: $SCRIPTNAME {start|stop|restart|reload}" >&2
    exit 3
    ;;
esac
exit 0
```
对脚本进行授权:
```
sudo chmod +x /etc/init.d/nginx
```
加入开机启动:
```
update-rc.d  -f  nginx  defaults
```
开启开机启动，这一步很关键:
```
sysv-rc-conf nginx on
```
重新启动后访问`http://服务器公网IP`，如显示以下内容则说明操作成功:
<div align="center"><img src ="images/Nginx_homepage.png" width = "600px"></div>

nginx操作命令从此变为:
```
sudo /etc/init.d/nginx reload | stop | restart | start
```
#### 第六步 配置 Nginx
编辑 nginx.conf 更改以下配置:
```
sudo vim /usr/local/nginx/conf/nginx.conf
===========================================================
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
error_log  logs/error.log  error;

pid        logs/nginx.pid;


events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    autoindex off;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile       on;
    tcp_nopush     on;
    tcp_nodelay    on;
    #keepalive_timeout  0;
    keepalive_timeout  65;

    gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
```
重新加载配置:
```
sudo /etc/init.d/nginx reload
```
## 参考链接
本文档参考了以下作者的博客，感兴趣的朋友可以点进去看看。不过这些博客或多或少都存在配置上的问题，不然我也不需要写配置文档了。

### 关于 OpenLDAP
- [配置Linux实例NTP服务](https://help.aliyun.com/document_detail/92803.html?spm=a2c4g.11186623.6.691.39e09c91NxpmTc)
- [CentOS 7 环境下 OpenLDAP 的安装与配置](https://mayanbin.com/post/openldap-in-centos-7.html)
- [Centos7 搭建openldap完整详细教程(真实可用)](https://blog.csdn.net/weixin_41004350/article/details/89521170)
- [openldap启用日志功能](https://blog.csdn.net/fanren224/article/details/80532277)
- [CentOS上OpenLDAP Server使用cn=config方式配置](https://www.jianshu.com/p/b5df1eb1f4de)
- [OpenLDAP : OpenLDAP Multi-Master Replication](https://www.server-world.info/en/note?os=CentOS_7&p=openldap&f=6)
- [Configure OpenLDAP Multi-Master Replication on Linux](https://www.itzgeek.com/how-tos/linux/centos-how-tos/configure-openldap-multi-master-replication-linux.html)
- [How to Add LDAP Users and Groups in OpenLDAP on Linux](https://www.thegeekstuff.com/2015/02/openldap-add-users-groups/)

### 关于 CAS
- [How to install Tomcat 9 on Ubuntu 18.04](https://linuxize.com/post/how-to-install-tomcat-9-on-ubuntu-18-04/)
- [Configure the CAS module for LDAP and Active Directory](https://support.solarwinds.com/SuccessCenter/s/article/Configure-the-CAS-module-for-LDAP-and-Active-Directory)
- [统一认证 - Apereo CAS 小试](https://segmentfault.com/a/1190000018180578)
- [企业CAS单点登录的架构思路](https://yuerblog.cc/2018/03/05/cas-sso-arch/)
- [Ubuntu下安装sysv-rc-conf报错](https://blog.csdn.net/weixin_44606513/article/details/86815190)
- [Ubuntu-Nginx安装并设置开机自启](https://www.jianshu.com/p/c313318a2061)
- [从 0 开始构建一个 "固若金汤" 的nginx](https://klionsec.github.io/2017/11/20/nginx-sec/)
