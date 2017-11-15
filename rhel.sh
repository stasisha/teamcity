#!/bin/bash

yum install java-openjdkx mysql-connector-java wget -y
export JAVA_HOME=/usr/lib/jvm/jre-openjdk

mkdir -p /var/www/apps/teamcity 
cd /var/www/apps/teamcity
wget https://download.jetbrains.com/teamcity/TeamCity-2017.1.5.tar.gz 
tar xpf TeamCity-2017.1.5.tar.gz
sed -i 's/8111/80/' /var/www/apps/teamcity/TeamCity/conf/server.xml


yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
yum install postgresql96-server -y
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6.service
systemctl start postgresql-9.6.service


pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
sudo -u postgres createuser teamcity
sudo -u postgres createdb teamcity
sudo -u postgres psql -c "alter user teamcity with encrypted password '$pass';"
sudo -u postgres psql -c "grant all privileges on database teamcity to teamcity;"
wget http://c.vestacp.com/0.9.8/debian/pg_hba.conf -O /var/lib/pgsql/9.6/data/pg_hba.conf

useradd teamcity
chown -R teamcity:teamcity /var/www/apps/teamcity

fallocate -l 4G /swapfile
dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo '/swapfile   swap    swap    sw  0   0' >> /etc/fstab

wget https://raw.githubusercontent.com/stasisha/teamcity-centos/master/teamcity  -O /etc/init.d/teamcity
chmod +x /etc/init.d/teamcity
chkconfig --add teamcity
service teamcity start
