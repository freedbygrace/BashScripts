#!/bin/bash

#https://www.youtube.com/watch?v=CALkvry1VMI&t=203

#Installation Command: curl -sS https://raw.githubusercontent.com/freedbygrace/BashScripts/main/Netbox-Installation.sh | sudo bash

#Define variables
NETBOXURL="https://github.com/netbox-community/netbox.git"
NETBOXINSTALLDIR="/opt/netbox"
NETBOXCONFIGURATIONFILENAME="configuration.py"
NETBOXPORT=8000
NETBOXUSER="netbox"
NETBOXDATABASENAME="netbox"
NETBOXDATABASEUSER="netbox"

#Set default text editor
export EDITOR=nano

#Get updated package list
echo "[+] Getting updated package list. Please Wait..."
sudo apt-get -qq update

#Update packages
echo "[+] Updating packages. Please Wait..."
sudo apt-get -qq upgrade

#Install Automatic Password Generator
echo "[+] Installing Automatic Password Generator. Please Wait..."
sudo apt-get -qq install apg &> /dev/null

#Generator Random Passwords
RANDOMPASSWORD001=$(apg -a 1 -n 1 -m 8 -x 12 -M NCL -d -q)
echo "Random Password 001: $RANDOMPASSWORD001"

#Install Postgre SQL
echo "[+] Installing Postgres SQL. Please Wait..."
sudo apt-get -qq install postgresql &> /dev/null
PGSQLVERSION=$(psql -v)
echo "Postgres SQL Version: $PGSQLVERSION"

#Create the Postgres SQL database
echo "[+] Creating database. Please Wait..."
sudo -u postgres psql --quiet --command "CREATE DATABASE $NETBOXDATABASENAME;" &> /dev/null

echo "[+] Creating database user. Please Wait..."
sudo -u postgres psql --quiet -d "$NETBOXDATABASENAME" --command "CREATE USER $NETBOXDATABASEUSER WITH PASSWORD '$RANDOMPASSWORD001';" &> /dev/null

echo "[+] Setting database owner. Please Wait..."
sudo -u postgres psql --quiet -d "$NETBOXDATABASENAME" --command "ALTER DATABASE $NETBOXDATABASENAME OWNER TO $NETBOXDATABASEUSER;" &> /dev/null

echo "[+] Granting database rights. Please Wait..."
sudo -u postgres psql --quiet -d "$NETBOXDATABASENAME" --command "GRANT CREATE ON SCHEMA public TO $NETBOXDATABASEUSER;" &> /dev/null

#Install Redis
echo "[+] Installing Redis. Please Wait..."
sudo apt-get -qq install redis-server &> /dev/null
REDISVERSION=$(redis-server -v)
echo "Redis Version: $REDISVERSION"
sudo redis-cli ping

echo "[+] Installing prerequisites. Please Wait..."

REQPKGS=(python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev git xclip)

for pkg in "${REQPKGS[@]}"; do
	echo "Beginning the installation of package "$pkg". Please Wait..."
	sudo apt-get -qq install "$pkg" &> /dev/null
done

#sudo apt-get -qq install python3 &> /dev/null
#sudo apt-get -qq install python3-pip &> /dev/null
#sudo apt-get -qq install python3-venv &> /dev/null
#sudo apt-get -qq install python3-dev &> /dev/null
#sudo apt-get -qq install build-essential &> /dev/null
#sudo apt-get -qq install libxml2-dev &> /dev/null
#sudo apt-get -qq install libxslt1-dev &> /dev/null
#sudo apt-get -qq install libffi-dev &> /dev/null
#sudo apt-get -qq install libpq-dev &> /dev/null
#sudo apt-get -qq install libssl-dev &> /dev/null
#sudo apt-get -qq install zlib1g-dev &> /dev/null
#sudo apt-get -qq install git &> /dev/null
#sudo apt-get -qq install xclip &> /dev/null

PYTHONVERSION=$(python3 -V)
echo "PYTHON Version: $PYTHONVERSION"

#Install Netbox
echo "[+] Installing Netbox. Please Wait..."
mkdir -p "$NETBOXINSTALLDIR"
cd "$NETBOXINSTALLDIR/"
git clone -b master --depth 1 "$NETBOXURL" "$NETBOXINSTALLDIR/"
adduser --system --group "$NETBOXUSER"
chown --recursive netbox "$NETBOXINSTALLDIR/netbox/media"
chown --recursive netbox "$NETBOXINSTALLDIR/netbox/reports"
chown --recursive netbox "$NETBOXINSTALLDIR/netbox/scripts"
cd "$NETBOXINSTALLDIR/netbox/netbox"
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
bash "$NETBOXINSTALLDIR/upgrade.sh"

#Activate the python virtual environment
PYTHON=/usr/bin/python3.8 "$NETBOXINSTALLDIR/upgrade.sh"

#Create the Netbox superuser (You will not be able to login without this!)

#Press enter to use 'iee' as the default username
#The password will be typed interactively

source "$NETBOXINSTALLDIR/venv/bin/activate"
cd "$NETBOXINSTALLDIR/netbox"
python3 manage.py createsuperuser

#Perform housekeeping
ln -s "$NETBOXINSTALLDIR/contrib/netbox-housekeeping.sh" "/etc/cron.daily/netbox-housekeeping"

#Run the Netbox server
python3 manage.py runserver 0.0.0.0:$NETBOXPORT --insecure
