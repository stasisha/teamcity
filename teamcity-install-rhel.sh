#!/bin/bash
read -p 'Would you like to use PostgreSQL? [y/n]: ' psql
read -p 'Would you like to use SWAP? [y/n]: ' swap
read -p 'Would you like to use https over nginx? [y/n]: ' nginx
read -p 'Would you like to install git? [y/n]: ' git
read -p 'Would you like to install php? [y/n]: ' php
if [ "$php" == 'y' ] || [ "$php" == 'Y'  ]; then
  read -p 'Would you like to install composer? [y/n]: ' composer
fi

if [ -e "/var/www/apps/teamcity/TeamCity/bin/runAll.sh" ]; then
  /var/www/apps/teamcity/TeamCity/bin/runAll.sh stop
  rm -rf /var/www/apps/teamcity
  rm -rf /root/.BuildServer
fi

#install lib
yum install java-openjdk wget -y
if [ "$psql" == 'y' ] || [ "$psql" == 'Y'  ]; then
  mkdir -p /home/teamcity/.BuildServer/lib/jdbc
  wget https://jdbc.postgresql.org/download/postgresql-42.1.4.jar -O /home/teamcity/.BuildServer/lib/jdbc/postgresql-42.1.4.jar
  yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
 
  #install PostgreSQL
  yum install postgresql96-server -y
  echo "PostgreSQL setup and comfig..."
  /usr/pgsql-9.6/bin/postgresql96-setup initdb
  systemctl enable postgresql-9.6.service
  wget https://raw.githubusercontent.com/stasisha/teamcity/master/rhel/pg_hba.conf -O /var/lib/pgsql/9.6/data/pg_hba.conf
  systemctl start postgresql-9.6.service
  psql_pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32`
  sudo -u postgres createuser teamcity
  sudo -u postgres createdb teamcity
  sudo -u postgres psql -c "alter user teamcity with encrypted password '$psql_pass';"
  sudo -u postgres psql -c "grant all privileges on database teamcity to teamcity;"
fi

if [ "$nginx" == 'y' ] || [ "$nginx" == 'Y'  ]; then
  yum install nginx -y
  wget https://raw.githubusercontent.com/stasisha/teamcity/master/rhel/nginx.conf  -O /etc/nginx/nginx.conf
  mkdir -p /etc/nginx/ssl
  openssl req -new -newkey rsa:4096 -days 1825 -nodes -x509 -subj "/C=UA/ST=KV/L=Kiev/O=St/CN=teamcity.example.com" -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt
  systemctl start nginx
  systemctl enable nginx
  setsebool -P httpd_can_network_connect 1
fi

# Installing Composer
if [ "$composer" == 'y' ] || [ "$composer" == 'Y'  ]; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
fi

# Installing Php
if [ "$php" == 'y' ] || [ "$php" == 'Y'  ]; then
  yum install -y php
fi

# Installing Composer
if [ "$composer" == 'y' ] || [ "$composer" == 'Y'  ]; then
  yum install -y git
fi

#install teamcity
tar_path=https://download.jetbrains.com/teamcity/TeamCity-2017.1.5.tar.gz
mkdir -p /var/www/apps/teamcity 
wget $tar_path  -O /var/www/apps/teamcity/TeamCity.tar.gz
echo "Untar TeamCity..."
tar xpf /var/www/apps/teamcity/TeamCity.tar.gz -C /var/www/apps/teamcity/
#change default port (in dev)
#sed -i 's/8111/80/' /var/www/apps/teamcity/TeamCity/conf/server.xml
#sed -i 's/8111/80/' /etc/nginx/nginx.conf
useradd teamcity
rm -f /var/www/apps/teamcity/TeamCity.tar.gz

#creating SWAP
if [ "$swap" == 'y' ] || [ "$swap" == 'Y'  ]; then
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
chown -R teamcity:teamcity /var/www/apps/teamcity
chown -R teamcity:teamcity /home/teamcity/.BuildServer
service teamcity start

# Congrats
echo "Congratulations, you have just successfully installed TeamCity"
if [ "$psql" == 'y' ] || [ "$psql" == 'Y'  ]; then
  echo "Postgres database: teamcity"
  echo "Postgres login: teamcity"
  echo "Postgres password: $psql_pass"
fi
