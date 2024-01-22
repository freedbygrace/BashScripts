#!/bin/bash

#https://www.youtube.com/watch?v=CALkvry1VMI&t=203
#> /dev/null

#Installation Command: curl -sS https://raw.githubusercontent.com/freedbygrace/BashScripts/main/Netbox-Installation.sh | sudo bash

#Set default text editor
export EDITOR=nano

#Get updated package list
apt-get update

#Update packages
apt-get upgrade -y

#Install Automatic Password Generator
apt-get install -y apg

#Generator Random Passwords
RANDOMPASSWORD001=$(apg -a 1 -n 1 -m 8 -x 12 -M NCL -d -q)
echo "Random Password 001: $RANDOMPASSWORD001"

#Install Postgre SQL
apt-get install -y postgressql
PGSQLVERSION=$(psql -v)
echo "Postgres SQL Version: $PGSQLVERSION"
-u postgres psql

#Create the Postgres SQL database
CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD "'$RANDOMPASSWORD001'";
ALTER DATABASE netbox OWNER TO netbox;
-- the next two commands are needed on PostgreSQL 15 and later
\connect netbox;
GRANT CREATE ON SCHEMA public TO netbox;
\q

#Install Redis
apt-get install -y redis-server
REDISVERSION=$(redis-server -v)
echo "Redis Version: $REDISVERSION"
redis-cli ping

apt-get install -y python3
apt-get install -y python3-pip
apt-get install -y python3-venv
apt-get install -y python3-dev
apt-get install -y build-essential
apt-get install -y libxml2-dev
apt-get install -y libxslt1-dev
apt-get install -y libffi-dev
apt-get install -y libpq-dev
apt-get install -y libssl-dev
apt-get install -y zlib1g-dev
apt-get install -y git
apt-get install -y xclip

PYTHONVERSION=$(python3 -V)
echo "PYTHON Version: $PYTHONVERSION"

#Install Netbox
NETBOXURL="https://github.com/netbox-community/netbox.git"
NETBOXINSTALLDIR="/opt/netbox/"
NETBOXCONFIGURATIONFILENAME="configuration.py"
NETBOXPORT=8000

mkdir -p "$NETBOXINSTALLDIR"
cd "$NETBOXINSTALLDIR"
git clone -b master --depth 1 "$NETBOXURL" .
adduser --system --group "netbox"
chown --recursive netbox "$NETBOXINSTALLDIR""netbox/media/"
chown --recursive netbox "$NETBOXINSTALLDIR""netbox/reports/"
chown --recursive netbox "$NETBOXINSTALLDIR""netbox/scripts/"
cd "$NETBOXINSTALLDIR""netbox/netbox/"
cp "configuration_example.py" "$NETBOXCONFIGURATIONFILENAME"

#Print variables to the console
echo "Netbox URL: $NETBOXURL"
echo "Netbox Installation Directory: $NETBOXINSTALLDIR"

#Copy the random password to the clipboard
echo "Random Password 001: $RANDOMPASSWORD001"
echo -n $RANDOMPASSWORD001 | xclip

#Edit Netbox Configuration File (Update the database password)
nano "NETBOXCONFIGURATIONFILENAME"

#Generate secret key
NETBOXSECRETKEY=$(python3 "../generate_secret_key.py")

#Copy the random password to the clipboard
echo "Netbox Secret Key: $NETBOXSECRETKEY"
echo -n $NETBOXSECRETKEY | xclip

#Edit Netbox Configuration File (Update the secret key)
nano "NETBOXCONFIGURATIONFILENAME"

#Run the Netbox upgrade script
bash "$NETBOXINSTALLDIR""upgrade.sh"

#Activate the python virtual environment
PYTHON=/usr/bin/python3.8 "$NETBOXINSTALLDIR""upgrade.sh"

#Create the Netbox superuser (You will not be able to login without this!)

#Press enter to use 'iee' as the default username
#The password will be typed interactively

source "$NETBOXINSTALLDIR""venv/bin/activate"
cd "$NETBOXINSTALLDIR""netbox"
python3 manage.py createsuperuser

#Perform housekeeping
ln -s "$NETBOXINSTALLDIR""contrib/netbox-housekeeping.sh" "/etc/cron.daily/netbox-housekeeping"

#Create the firewall rule (Development environments only!)
#firewall-cmd --zone=public --add-port=$NETBOXPORT/tcp

#Run the Netbox server
python3 manage.py runserver 0.0.0.0:$NETBOXPORT --insecure
