#!/bin/bash

read -p 'Would you like to use PostgreSQL? [y/n]: ' psql_answer
if [ "$psql_answer" == 'y' ] || [ "$psql" == 'Y'  ]; then
    use_psql=true
fi

read -p 'Would you like to use SWAP? [y/n]: ' swap_answer
if [ "$swap_answer" != 'y' ] && [ "$swap_answer" != 'Y'  ]; then
    use_swap=true
fi

#install lib
yum install java-openjdkx wget postgresql96-server -y
if $use_psql; then
  yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
  yum install postgresql96-server -y
fi

export JAVA_HOME=/usr/lib/jvm/jre-openjdk

#install teamcity
tar_path=https://download.jetbrains.com/teamcity/TeamCity-2017.1.5.tar.gz
mkdir -p /var/www/apps/teamcity 
wget $tar_path /var/www/apps/teamcity/TeamCity.tar.gz
tar xpf /var/www/apps/teamcity/TeamCity.tar.gz -C /var/www/apps/teamcity/
sed -i 's/8111/80/' /var/www/apps/teamcity/TeamCity/conf/server.xml
useradd teamcity
chown -R teamcity:teamcity /var/www/apps/teamcity
rm -f /var/www/apps/teamcity/TeamCity.tar.gz

#install PostgreSQL
if $use_psql; then
    echo "PostgreSQL setup and comfig..."
    /usr/pgsql-9.6/bin/postgresql96-setup initdb
    systemctl enable postgresql-9.6.service
    systemctl start postgresql-9.6.service
    pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
    sudo -u postgres createuser teamcity
    sudo -u postgres createdb teamcity
    sudo -u postgres psql -c "alter user teamcity with encrypted password '$pass';"
    sudo -u postgres psql -c "grant all privileges on database teamcity to teamcity;"
    wget https://raw.githubusercontent.com/stasisha/teamcity/master/debian/pg_hba.conf -O /var/lib/pgsql/9.6/data/pg_hba.conf
fi

#creating SWAP
if $use_swap; then
    echo "Creating 4G SWAP file. This can take few minutes..."
    fallocate -l 4G /swapfile
    dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile   swap    swap    sw  0   0' >> /etc/fstab
fi

#auto launch
echo "Adding teamcity to auto launch..."
wget https://raw.githubusercontent.com/stasisha/teamcity-centos/master/teamcity  -O /etc/init.d/teamcity
chmod +x /etc/init.d/teamcity
chkconfig --add teamcity
service teamcity start

# Comparing hostname and ip
host_ip=$(host $servername| head -n 1 | awk '{print $NF}')
if [ "$host_ip" = "$ip" ]; then
    ip="$servername"
fi

# Congrats
echo "==================="
echo ""
echo "_|_|_|  _|_|_|_|_|"
echo "_|           _|   "
echo " _|_|        _|   "
echo "  _|_|       _|   "
echo "_|_|_|       _|   "
echo ""
echo ""
echo "Congratulations, you have just successfully installed TeamCity"
echo "http://$ip"
if $use_psql; then
  echo "Postgres database: teamcity"
  echo "Postgres login: teamcity"
  echo "Postgres password: $pass"
fi
