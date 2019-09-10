#!/bin/sh
#--------------------------------------------
# Author: Cai Miao
# Since: 2019/08/26
# This Shell script is for NTP and SELinux.
# You can see the detail at https://hexang.org/sosconf/tech-team/ldap-account-server/blob/master/README.md
# Feature：autorun NTP and SELinux services.
# Parameters：none.
#--------------------------------------------

# Check the user input.
{
if [ -z "$1" ]
then
  echo "The 1st master's IP cannot be empty!"
  exit 0
elif [ -z "$2" ]
then
  echo "The 2nd master's IP cannot be empty!"
  exit 0
fi
}


echo "$1 master01.hexang.org" >> /etc/hosts
echo "$2 master02.hexang.org" >> /etc/hosts

# Install NTP package.
yum -y install ntp

# First synchronization.
ntpdate ntp1.aliyun.com

# Configure NTP daemon.
sed -i '24s/^.*$/server ntp1.aliyun.com iburst/' /etc/ntp.conf

# Enable it system-wide.
systemctl start ntpd.service
systemctl enable ntpd.service

# Check NTP's status.
ntpstat

# Turn on SELinux by modifying the configure.
sed -i '7s/^.*$/SELINUX=enforcing/' /etc/selinux/config

# Reboot to make it take effect.
systemctl reboot
