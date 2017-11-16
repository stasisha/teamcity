#!/bin/bash
read -p 'Would you like to use PostgreSQL? [y/n]: ' psql_answer
read -p 'Would you like to use SWAP? [y/n]: ' swap_answer
read -p 'Would you like to use https over nginx? [y/n]: ' nginx_answer

if [ -e /var/www/apps/teamcity/TeamCity/bin/runAll.sh ]; then
  /var/www/apps/teamcity/TeamCity/bin/runAll.sh stop
  rm -rf /var/www/apps/teamcity
  rm -rf /root/.BuildServer
fi

#install lib
yum install java-openjdk wget -y
if [ "$psql_answer" == 'y' ] || [ "$psql_answer" == 'Y'  ]; then
  mkdir -p /root/.BuildServer/lib/jdbc
  wget https://jdbc.postgresql.org/download/postgresql-42.1.4.jar -O /root/.BuildServer/lib/jdbc/postgresql-42.1.4.jar
  yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
 
  #install PostgreSQL
  yum install postgresql96-server -y
  echo "PostgreSQL setup and comfig..."
  /usr/pgsql-9.6/bin/postgresql96-setup initdb
  systemctl enable postgresql-9.6.service
  wget https://raw.githubusercontent.com/stasisha/teamcity/master/debian/pg_hba.conf -O /var/lib/pgsql/9.6/data/pg_hba.conf
  systemctl start postgresql-9.6.service
  psql_pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32`
  sudo -u postgres createuser teamcity
  sudo -u postgres createdb teamcity
  sudo -u postgres psql -c "alter user teamcity with encrypted password '$psql_pass';"
  sudo -u postgres psql -c "grant all privileges on database teamcity to teamcity;"
fi

if [ "$nginx_answer" == 'y' ] || [ "$nginx_answer" == 'Y'  ]; then
  yum install nginx -y
  wget https://raw.githubusercontent.com/stasisha/teamcity/master/rhel/nginx.conf  -O /etc/nginx/nginx.conf
  mkdir -p /etc/nginx/ssl
  openssl req -new -newkey rsa:4096 -days 1825 -nodes -x509 -subj "/C=UA/ST=KV/L=Kiev/O=St/CN=teamcity.example.com" -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt
  systemctl start nginx
  systemctl enable nginx
fi

#install teamcity
tar_path=https://download.jetbrains.com/teamcity/TeamCity-2017.1.5.tar.gz
mkdir -p /var/www/apps/teamcity 
wget $tar_path  -O /var/www/apps/teamcity/TeamCity.tar.gz
echo "Untar TeamCity..."
tar xpf /var/www/apps/teamcity/TeamCity.tar.gz -C /var/www/apps/teamcity/
sed -i 's/8111/80/' /var/www/apps/teamcity/TeamCity/conf/server.xml
rm -f /var/www/apps/teamcity/TeamCity.tar.gz

#creating SWAP
if [ "$swap_answer" == 'y' ] || [ "$swap_answer" == 'Y'  ]; then
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
wget https://raw.githubusercontent.com/stasisha/teamcity/master/teamcity  -O /etc/init.d/teamcity
chmod +x /etc/init.d/teamcity
chkconfig --add teamcity
service teamcity start

# Congrats
echo "Congratulations, you have just successfully installed TeamCity"
if [ "$psql_answer" == 'y' ] || [ "$psql_answer" == 'Y'  ]; then
  echo "Postgres database: teamcity"
  echo "Postgres login: teamcity"
  echo "Postgres password: $psql_pass"
fi
