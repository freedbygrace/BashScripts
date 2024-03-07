#!/bin/bash

#Declare variables
HOSTNAME=$(hostname)
DOWNLOADSROOTDIRECTORY="/downloads"

#Renew DHCP lease
dhclient -r
dhclient

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

#Install and configure the docker container for the Portainer server (If the hostname containers Portainer)
if [[ "$HOSTNAME" =~ (.*PORTAINER.*) ]]
then
    echo "Beginning Portainer configuration. Please Wait..."
    docker volume create PORTAINER-DATA-APP
    docker run -d --name "PORTAINER-APP-001" --hostname "PORTAINER-APP-001" -p 9443:9443 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v PORTAINER-DATA-APP:/data portainer/portainer-ce:latest
    echo "Portainer configuration was completed successfully!"
else
    echo "Skipping Portainer configuration."
fi

#Install and configure the docker container for the Portainer server (If the hostname containers Portainer)
if [[ "$HOSTNAME" =~ (.*DOCKER.*)|(.*PORTAINER.*) ]]
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

#Install and configure Webmin
WEBMINDOWNLOADDIRECTORY="$DOWNLOADSROOTDIRECTORY/webmin"
WEBMINSCRIPTURL="https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh"
WEBMINSCRIPTFILENAME=$(basename "$WEBMINSCRIPTURL")
WEBMINSCRIPTFILEPATH="$WEBMINDOWNLOADDIRECTORY/$WEBMINSCRIPTFILENAME"
WEBMINSCRIPTLOGNAME="$WEBMINSCRIPTFILENAME.log"
WEBMINSCRIPTLOGPATH="$WEBMINDOWNLOADDIRECTORY/$WEBMINSCRIPTLOGNAME"
mkdir -p "$WEBMINDOWNLOADDIRECTORY"
wget -q -O "$WEBMINSCRIPTFILEPATH" "$WEBMINSCRIPTURL"
echo "y" | bash -v "$WEBMINSCRIPTFILEPATH" &> "$WEBMINSCRIPTLOGPATH"
apt-get install -y --install-recommends webmin

#Reboot the virtual machine once provisioning is completed
shutdown -r now