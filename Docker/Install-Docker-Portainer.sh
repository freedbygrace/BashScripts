#!/bin/bash
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release nfs-common -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "/etc/apt/keyrings/docker.gpg"
sudo chmod a+r "/etc/apt/keyrings/docker.gpg"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo addgroup --system docker
sudo adduser --system --no-create-home --ingroup docker docker
sudo apt-get install docker-ce docker-ce-cli samba containerd.io docker-buildx-plugin docker-compose docker-compose-plugin -y
sudo id docker
sudo mkdir -p /opt/docker/portainer
sudo chown -R docker /opt/docker
sudo chown -R docker /opt/docker/portainer
leading_zero_fill ()
{
    # print the number as a string with a given number of leading zeros
    printf "%0$1d\\n" "$2"
}
RandomNumber=$(shuf -i 1-999 -n 1)
PortainerInstanceNumber=$(leading_zero_fill 3 "$RandomNumber")
PortainerServerName="PORTAINER-APP-$PortainerInstanceNumber"
docker volume create portainer_data
sudo docker run -d --name $PortainerServerName --hostname $PortainerServerName --restart=always -p 9443:9443 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest