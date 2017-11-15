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



    psql_pass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`

  echo "Postgres password: $psql_pass"
