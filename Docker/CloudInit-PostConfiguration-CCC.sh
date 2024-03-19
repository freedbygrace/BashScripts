#!/bin/bash

#Declare variables
HOSTNAME=$(hostname)
DOWNLOADSROOTDIRECTORY="/downloads"

#Run the following code on all systems
if [[ "$HOSTNAME" =~ (.*) ]]
then
    echo "Beginning general configuration. Please Wait..."
    
    #Install and configure Webmin
        #WEBMINDOWNLOADDIRECTORY="$DOWNLOADSROOTDIRECTORY/webmin"
        #WEBMINSCRIPTURL="https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh"
        #WEBMINSCRIPTFILENAME=$(basename "$WEBMINSCRIPTURL")
        #WEBMINSCRIPTFILEPATH="$WEBMINDOWNLOADDIRECTORY/$WEBMINSCRIPTFILENAME"
        #WEBMINSCRIPTLOGNAME="$WEBMINSCRIPTFILENAME.log"
        #WEBMINSCRIPTLOGPATH="$WEBMINDOWNLOADDIRECTORY/$WEBMINSCRIPTLOGNAME"
        #mkdir -p "$WEBMINDOWNLOADDIRECTORY"
        #wget -q -O "$WEBMINSCRIPTFILEPATH" "$WEBMINSCRIPTURL"
        #echo "y" | bash -v "$WEBMINSCRIPTFILEPATH" &> "$WEBMINSCRIPTLOGPATH"
        #apt-get install -y --install-recommends webmin

    #Install and configure Cockpit (Web based server management) (Access on "https://ServerIP:9090" by default)
    curl -sSL https://repo.45drives.com/setup | sudo bash
    apt-get update -y
    apt-get install -y cockpit cockpit-389-ds cockpit-navigator cockpit-file-sharing cockpit-packagekit cockpit-networkmanager cockpit-storaged

    #Install 389-DS LDAP Server
    #apt-get install -y 389-ds
    
    #Sensors (Information Collector)
    #wget https://github.com/ocristopfer/cockpit-sensors/releases/latest/download/cockpit-sensors.tar.xz && \
    #tar -xf cockpit-sensors.tar.xz cockpit-sensors/dist && \
    #mv cockpit-sensors/dist /usr/share/cockpit/sensors && \
    #rm -r cockpit-sensors && \
    #rm cockpit-sensors.tar.xz

    echo "General configuration was completed successfully!"
else
    echo "Skipping general configuration."
fi

#Install and configure the docker container for the Portainer server (If the hostname containers Portainer)
if [[ "$HOSTNAME" =~ (.*DOCKER.*)|(.*PORTAINER.*) ]]
then
    echo "Beginning Docker installation. Please Wait..."
    #Install and configure Docker
    apt-get install -y ca-certificates gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "/etc/apt/keyrings/docker.gpg"
    chmod a+r "/etc/apt/keyrings/docker.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    addgroup --system docker
    adduser --system --no-create-home --ingroup docker docker
    mkdir -p /opt/docker
    chown -R docker:docker /opt/docker
    apt-get install -y docker-ce docker-ce-cli samba containerd.io docker-buildx-plugin docker-compose docker-compose-plugin
    echo "Docker installation was completed successfully!"
else
    echo "Skipping Docker installation."
fi

#Install and configure the docker container for the Portainer server
if [[ "$HOSTNAME" =~ (.*PORTAINER.*) ]]
then
    echo "Beginning Portainer configuration. Please Wait..."
    docker volume create PORTAINER-DATA-APP
    docker run -d --name "PORTAINER-APP-001" --hostname "PORTAINER-APP-001" -p 9443:9443 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v PORTAINER-DATA-APP:/data portainer/portainer-ce:latest
    echo "Portainer configuration was completed successfully!"
else
    echo "Skipping Portainer configuration."
fi

#Install and configure the KASM workspaces server
if [[ "$HOSTNAME" =~ (.*KASM.*) ]]
then
    echo "Beginning KASM workspaces installation. Please Wait..."

    KASMWSURL="https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.06fdc8.tar.gz"
    
    KASMWSDOWNLOADDIRECTORY="$DOWNLOADSROOTDIRECTORY/KASMWS"
    KASMWSFILENAME=$(basename "$KASMWSURL")
    KASMWSFILEPATH="$KASMWSDOWNLOADDIRECTORY/$KASMWSFILENAME"
    mkdir -p "$KASMWSDOWNLOADDIRECTORY"
    wget -q -O "$KASMWSFILEPATH" "$KASMWSURL"
    tar -xf "$KASMWSFILEPATH" --directory "$KASMWSDOWNLOADDIRECTORY"
    KASMWSSCRIPTFILENAME="install.sh"
    KASMWSSCRIPTPATH="$KASMWSDOWNLOADDIRECTORY/kasm_release/$KASMWSSCRIPTFILENAME"
    KASMWSLOGNAME="$KASMWSSCRIPTFILENAME.log"
    KASMWSLOGPATH="$KASMWSDOWNLOADDIRECTORY/$KASMWSLOGNAME"

    KASMWSPORT=9850
    KASMWSSWAPSIZE=8192
    KASMWSADMINPW="PKQ1E1RLEq"
    KASMWSUSERPW="PKQ1E1RLEq"

    echo "yes" | bash -v "$KASMWSSCRIPTPATH" --accept-eula -L $KASMWSPORT --swap-size $KASMWSSWAPSIZE --admin-password "$KASMWSADMINPW" --user-password "$KASMWSUSERPW" &> "$KASMWSLOGPATH"
    
    # Install Certbot via Snaps
    snap install core
    snap refresh core
    snap install --classic certbot
    ln -s "/snap/bin/certbot" "/usr/bin/certbot"

    # Install DNS CloudFlare plugin
    snap set certbot trust-plugin-with-root=ok
    snap install certbot-dns-cloudflare
    
    #Stop the KASM Workspaces server services
    /opt/kasm/bin/stop

    #Define the required variable(s)
    DNSDOMAIN="ccclayton.net"
    DNSRECORD="kasmws.$DNSDOMAIN"
    CERTBOTSECRETSDIRECTORY="/etc/letsencrypt"
    CERTBOTSECRETSFILENAME="cloudflare.ini"
    CERTBOTSECRETSFILEPATH="$CERTBOTSECRETSDIRECTORY/$CERTBOTSECRETSFILENAME"
    KASMCERTSDIRECTORY="/opt/kasm/current/certs"
    CLOUDFLARE_EMAILADDRESS="cccadmin@$DNSDOMAIN"
    CLOUDFLARE_APITOKEN="9hpwRvVlgKAGGyD0uZKDg_HBHTNxPwsDb-1kxqaE"
    CLOUDFLARE_DNSPROPAGATIONSECONDS=20

    # This directory may not exist yet
    mkdir -p "$CERTBOTSECRETSDIRECTORY"

    # Create file with the Cloudflare API token
    printf "#Cloudflare API token\ndns_cloudflare_api_token = $CLOUDFLARE_APITOKEN" >> "$CERTBOTSECRETSFILEPATH"

    # Secure that file (otherwise certbot yells at you)
    chmod 0700 "$CERTBOTSECRETSDIRECTORY"
    chmod 0600 "$CERTBOTSECRETSFILEPATH"

    # Create a certificate!
    # This has nginx reload upon renewal,
    # which assumes Nginx is using the created certificate
    # You can also create non-wildcard subdomains, e.g. "-d foo.example.org"
    certbot certonly -d "$DNSRECORD" --dns-cloudflare --dns-cloudflare-propagation-seconds $CLOUDFLARE_DNSPROPAGATIONSECONDS --dns-cloudflare-credentials "$CERTBOTSECRETSFILEPATH" --non-interactive --agree-tos --email "$CLOUDFLARE_EMAILADDRESS" --no-eff-email

    #Rename the self-signed certificates
    mv "$KASMCERTSDIRECTORY/kasm_nginx.crt" "$KASMCERTSDIRECTORY/kasm_nginx.crt.bk"
    mv "$KASMCERTSDIRECTORY/kasm_nginx.key" "$KASMCERTSDIRECTORY/kasm_nginx.key.bk"

    #Link the newly generated certificates to the specified file paths
    cd "$KASMCERTSDIRECTORY/"
    ln -sf "/etc/letsencrypt/archive/$DNSRECORD/privkey1.pem" "$KASMCERTSDIRECTORY/kasm_nginx.key"
    ln -sf "/etc/letsencrypt/archive/$DNSRECORD/fullchain1.pem" "$KASMCERTSDIRECTORY/kasm_nginx.crt"

    #Start the KASM Workspaces server services
    /opt/kasm/bin/start
       
    echo "KASM workspaces installation was completed successfully!"
    
    #Download windows RDP agents from here
    #https://kasmweb.com/docs/latest/guide/windows/windows_service.html
else
    echo "Skipping KASM workspaces installation."
fi

#Install and configure the docker container for the Portainer server
if [[ "$HOSTNAME" =~ (.*DOCKER.*)|(.*PORTAINER.*)|(.*KASM.*) ]]
then
    echo "Beginning Docker container configuration. Please Wait..."
    #Install and configure the docker container for the Portainer agent
    docker run -d -p 9001:9001 --name PORTAINER-AGENT --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
    #Install and configure the docker container for watchtower (Automatically keeps docker containers up to date)
    docker run -d --name "WATCHTOWER-APP-001" --hostname "WATCHTOWER-APP-001" -p 8090:8080 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /etc/localtime:/etc/localtime:ro -e WATCHTOWER_POLL_INTERVAL=14400 -e WATCHTOWER_CLEANUP=true -e WATCHTOWER_REMOVE_VOLUMES=true -e WATCHTOWER_LOG_FORMAT=Auto -e WATCHTOWER_LABEL_ENABLE=false -e WATCHTOWER_ROLLING_RESTART=true -e DOCKER_TLS_VERIFY=false -e WATCHTOWER_HTTP_API_METRICS=true -e WATCHTOWER_HTTP_API_TOKEN=9ySLMVw9KCpaT0qZYB1tUGHktkS8vQbYBRvo3gs4VjC4Q6BjYMYLSRF1oOxAtYvJ containrrr/watchtower:latest
    echo "Docker container configuration was completed successfully!"
else
    echo "Skipping Docker container configuration."
fi

#Install and configure ADGuard Home
if [[ "$HOSTNAME" =~ (.*ADGUARD.*) ]]
then
    echo "Beginning ADGuard configuration. Please Wait..."
    snap install adguard-home
    echo "ADGuard configuration was completed successfully!"
else
    echo "Skipping ADGuard configuration."
fi

#Reboot the virtual machine once provisioning is completed
shutdown -r now

###Unused

#Ensure that the network configuration gets reset because the DHCP unique identifier has been changed. This will cause your cloned machines to get the same IP address.
#if [ -f /etc/machine-id ]; then
#    cat /dev/null > /etc/machine-id
#fi

#if [ -f /var/lib/dbus/machine-id ]; then
#    rm -f /var/lib/dbus/machine-id
#fi

#ln -s /etc/machine-id /var/lib/dbus/machine-id