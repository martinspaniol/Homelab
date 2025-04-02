# Paperless-nxg installation with AI enhancement

This guide provides step by step instructions on how to install Paperless-nxg with PostgreSQL as database backend and Apache tika for supporting Office documents on a proxmox VM.

## Requirements

* proxmox is already configured and running
* you have a ubuntu template which can be used

## Installation Instructions

### Step 1: Create a VM

I will use my existing Ubuntu 24.04 LTS (Noble) template in proxmox for the ecoDMS VM. According to the [system requirements of ecoDMS][def] we need to adjust it a little bit after creation:

```shell
templateID=5001
vmID=201
vmName=paperless # a . (dot) is not possible here

vmStorageName=local-zfs
vmStorageSize=10G # size in GiB


memory=4096

qm clone $templateID $vmID --format raw --full true --name $vmName --storage $vmStorageName
qm disk resize $vmID scsi0 $vmStorageSize
qm set $vmID --memory $memory
qm start $vmID
```

Wait for the VM to finish the cloud-init configuration. Reboot to apply all pending changes and to advertise its hostname in your dns.

### Step 2: Install linux-modules-extra

In order to specify the `iocharset` when mounting a cifs share in `/etc/fstab` you need to install the `linux-modules-extra` for your specific kernel version:

```shell
sudo apt install -y linux-modules-extra-$(uname -r)
```

### Step 3: Mount folders for configuration (target), new documents (consume) and document storage (media)

In my case the folders are within a share on my Synology NAS. We need to mount this share to `/mnt/paperless` on the VM:

```shell
serverName="diskstation.fritz.box"
shareName="paperless"
mountPoint="/mnt/paperless"
credentialFile="/etc/smbcredentials"
sudo apt-get install -y cifs-utils
sudo mkdir -p $mountPoint # create the mount point for the share
# sudo chown ecodms:ecodms $mountPoint
echo -e "username=paperless\npassword=,g?U#K3U?m~g9ZP=oWB9wn3.AzmGDpgr" | sudo tee $credentialFile > /dev/null # create the smb credentials file
sudo chmod 600 $credentialFile # secure the credentials
echo -e "//$serverName/$shareName\t$mountPoint\tcifs\tcredentials=$credentialFile,sec=ntlmv2i,vers=3.0,uid=1000,gid=1000,iocharset=utf8\t0 0" | sudo tee -a /etc/fstab > /dev/null # Add the new mount to fstab

sudo mount -a # mount the share
sudo systemctl daemon-reload
```

### Step 4: Install docker and docker-compose

```shell
# Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# Install docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Grant the current user (ubuntu) permissions for Docker
sudo usermod -aG docker ubuntu

# Exit the current session for the permissions to apply
exit
```

### Step 5: Install paperless

```shell
bash -c "$(curl --location --silent --show-error https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh)"
```

Enter the following during the setup:

```shell
URL []: # leave blank
Port [8000]: # accept default
Current time zone [Etc/UTC]: Europe/Berlin
Database backend (postgres sqlite mariadb) [postgres]: # accept default
Enable Apache Tika? (yes no) [no]: yes
OCR language [eng]: deu+eng
User ID [1000]: # accept default
Group ID [1000]: # accept default
Target folder [/home/ubuntu/paperless-ngx]: /mnt/paperless/target
Consume folder [/mnt/target/consume]: /mnt/paperless/consume
Media folder []: /mnt/paperless/media
Data folder []: # accept default
Database folder []: # accept default
Paperless username [ubuntu]: paperless
Paperless password: # ,g?U#K3U?m~g9ZP=oWB9wn3.AzmGDpgr
Paperless password (again): # ,g?U#K3U?m~g9ZP=oWB9wn3.AzmGDpgr
Email [paperless@localhost]: # accept default

Summary
=======

Target folder: /mnt/paperless/target
Consume folder: /mnt/paperless/consume
Media folder: /mnt/paperless/media
Data folder: Managed by docker
Database folder: Managed by docker

URL:
Port: 8000
Database: postgres
Tika enabled: yes
OCR language: deu+eng
User id: 1000
Group id: 1000

Paperless username: paperless
Paperless email: paperless@localhost
```

### Step 6: Install paperless-ai

```shell
docker run -d --name paperless-ai --network bridge -v paperless-ai_data:/app/data -p 3001:3000 --restart unless-stopped clusterzx/paperless-ai
```

### Step 7: Install ollama with intel-cpu support

Source: [mattcurf/ollama-intel-gpu](https://github.com/mattcurf/ollama-intel-gpu)

```shell
git clone https://github.com/mattcurf/ollama-intel-gpu
cd ollama-intel-gpu
docker compose up 
```

> **Note**: you will see the following message. This is expected and harmless, as the docker image 'ollama-intel-gpu' is built locally.

Visit [http://localhost:3000](http://localhost:3000) to launch the web ui.
