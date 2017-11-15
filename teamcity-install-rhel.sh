#!/bin/bash

read -p 'Would you like to use PostgreSQL? [y/n]: ' psql_answer
read -p 'Would you like to use SWAP? [y/n]: ' swap_answer

#install lib
yum install java-openjdk wget -y
if [ "$psql_answer" == 'y' ] || [ "$psql_answer" == 'Y'  ]; then
  yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
  yum install postgresql96-server -y
fi

export JAVA_HOME=/usr/lib/jvm/jre-openjdk


#install PostgreSQL
if [ "$psql_answer" == 'y' ] || [ "$psql_answer" == 'Y'  ]; then
    echo "PostgreSQL setup and comfig..."
    /usr/pgsql-9.6/bin/postgresql96-setup initdb
    systemctl enable postgresql-9.6.service
    systemctl start postgresql-9.6.service
    psql_pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
    sudo -u postgres createuser teamcity
    sudo -u postgres createdb teamcity
    sudo -u postgres psql -c "alter user teamcity with encrypted password '$psql_pass';"
    sudo -u postgres psql -c "grant all privileges on database teamcity to teamcity;"
    wget https://raw.githubusercontent.com/stasisha/teamcity/master/debian/pg_hba.conf -O /var/lib/pgsql/9.6/data/pg_hba.conf
fi

# Congrats
echo "Congratulations, you have just successfully installed TeamCity"
if [ "$psql_answer" == 'y' ] || [ "$psql_answer" == 'Y'  ]; then
  echo "Postgres database: teamcity"
  echo "Postgres login: teamcity"
  echo "Postgres password: $psql_pass"
fi
