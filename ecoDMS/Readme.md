# ecoDMS

This guide provides step by step instructions on how to install ecoDMS server on proxmox VM and migrate your existing data.

## Requirements

* proxmox is already configured and running
* you have a ubuntu template which can be used

## Installation Instructions

### Step 1: Create a VM

I will use my existing Ubuntu 24.04 LTS (Noble) template in proxmox for the ecoDMS VM. According to the [system requirements of ecoDMS][def] we need to adjust it a little bit after creation:

```shell
templateID=5001
vmID=200
vmName=ecodms-2402 # a . (dot) is not possible here

vmStorageName=local-zfs
vmStorageSize=10G # size in GiB

dataStorageName=diskstation
dataStorageSize=100 # size in GiB

memory=8192

qm clone $templateID $vmID --format raw --full true --name $vmName --storage $vmStorageName
qm disk resize $vmID scsi0 $vmStorageSize
qm set $vmID --memory $memory
qm set $vmID --scsi1 $dataStorageName:$dataStorageSize,format=raw
qm start $vmID
```

Wait for the VM to finish the cloud-init configuration. Reboot to apply all pending changes and to advertise its hostname in your dns.

### Step 2: Configure data storage

Since we added a second harddrive for the data storage we need to configure it in the operating system. ssh into your newly created VM.

To show the new partition use `fdisk`:

```shell
ubuntu@ecodms-2402:~$ sudo fdisk -l
Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: QEMU HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: D3ECFF2F-8C65-44EC-8248-9EB3690B7D93

Device       Start      End  Sectors  Size Type
/dev/sda1  2099200 20971486 18872287    9G Linux filesystem
/dev/sda14    2048    10239     8192    4M BIOS boot
/dev/sda15   10240   227327   217088  106M EFI System
/dev/sda16  227328  2097152  1869825  913M Linux extended boot

Partition table entries are not in disk order.


Disk /dev/sdb: 100 GiB, 107374182400 bytes, 209715200 sectors # <<< /dev/sdb is the second disk
Disk model: QEMU HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

To configure `/dev/sdb` we can use `parted`:

```shell
# Define the disk and partition details
disk="/dev/sdb"
label="data"
mountPoint="/opt/ecodms/data"

sudo parted $disk mklabel gpt # Create a new partition table (GPT)
sudo parted $disk mkpart primary ext4 0% 100% # Create a new partition (default size, primary partition)
sudo mkfs.ext4 ${disk}1 # Format the partition as ext4
sudo mkdir -p $mountPoint # Create the mount point directory
sudo e2label ${disk}1 $label # Label the partition (this will label it as 'longhorn')
echo -e "LABEL=$label\t$mountPoint\text4\tdefaults\t0 2" | sudo tee -a /etc/fstab > /dev/null # Add the new partition to fstab
sudo reboot now
```

After rebooting check the new partition with `df -h`:

```shell
ubuntu@ecodms-2402:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           791M  1.2M  790M   1% /run
efivarfs        256K   53K  199K  21% /sys/firmware/efi/efivars
/dev/sda1       8.7G  2.1G  6.6G  25% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M  112M  708M  14% /boot
/dev/sda15      105M  6.1M   99M   6% /boot/efi
/dev/sdb1        98G   24K   93G   1% /opt/ecodms/data # < this is the new partition
tmpfs           791M   12K  791M   1% /run/user/1000
```

### Step 3: Mount scaninput and backup folder

In my case the scaninput is a share on my Synology NAS. We need to mount this share to `/opt/ecodms/workdir/scaninput` on the VM:

```shell
serverName="diskstation.fritz.box"
shareName="ecodms/scaninput"
mountPoint="/opt/ecodms/workdir/scaninput"
credentialFile="/etc/smbcredentials"
sudo apt-get install -y cifs-utils
sudo mkdir -p $mountPoint # create the mount point for the share
sudo chown ecodms:ecodms $mountPoint
echo -e "username=ecodms\npassword=BjWZzj2~GQ.pkgnsXvX,59xjAES8=j5-" | sudo tee $credentialFile > /dev/null # create the smb credentials file
sudo chmod 600 $credentialFile # secure the credentials
echo -e "//$serverName/$shareName\t$mountPoint\tcifs\tcredentials=$credentialFile,sec=ntlmv2i,vers=3.0,uid=1001,gid=1001\t0 0" | sudo tee -a /etc/fstab > /dev/null # Add the new mount to fstab

shareName="ecodms/backup"
mountPoint="/opt/ecodms-backup"
sudo mkdir -p $mountPoint # create the mount point for the share
sudo chown ecodms:ecodms $mountPoint
echo -e "username=ecodms\npassword=BjWZzj2~GQ.pkgnsXvX,59xjAES8=j5-" | sudo tee $credentialFile > /dev/null # create the smb credentials file
sudo chmod 600 $credentialFile # secure the credentials
echo -e "//$serverName/$shareName\t$mountPoint\tcifs\tcredentials=$credentialFile,sec=ntlmv2i,vers=3.0,uid=1001,gid=1001\t0 0" | sudo tee -a /etc/fstab > /dev/null # Add the new mount to fstab

shareName="ecodms/restore"
mountPoint="/opt/ecodms-restore"
sudo mkdir -p $mountPoint # create the mount point for the share
sudo chown ecodms:ecodms $mountPoint
echo -e "username=ecodms\npassword=BjWZzj2~GQ.pkgnsXvX,59xjAES8=j5-" | sudo tee $credentialFile > /dev/null # create the smb credentials file
sudo chmod 600 $credentialFile # secure the credentials
echo -e "//$serverName/$shareName\t$mountPoint\tcifs\tcredentials=$credentialFile,sec=ntlmv2i,vers=3.0,uid=1001,gid=1001\t0 0" | sudo tee -a /etc/fstab > /dev/null # Add the new mount to fstab

sudo mount -a # mount the share
sudo systemctl daemon-reload
```

### Step 4: Add package source

Since ecoDMS is not included in the default package sources of Ubuntu, we need to manually add it:

```shell
echo "deb http://www.ecodms.de/ecodms_240264/noble /" | sudo tee -a "/etc/apt/sources.list.d/ecodms.list" > /dev/null # add the ecoDMS repository
sudo wget -qO /etc/apt/trusted.gpg.d/ecodms.asc http://www.ecodms.de/gpg/ecodms.key # import the repository key
sudo apt-get update # update the package sources
```

### Step 5: Install ecoDMS packages

The ecoDMS packages include plugins/Add-Ons, as well as the ecoDMS PDF/A-printer for Windows. The ecoDMS client for macOS and Windows will be stored as well.

```shell
packageFolder="/opt/ecodms/ecodmspackages"
sudo mkdir -p $packageFolder
sudo chown ecodms:ecodms $packageFolder
sudo apt-get install -y ecodmspackages
```

### Step 6: Install ecoDMS server

To install the ecoDMS server use this command:
> **Note:** This is a gui based installation. You have to do a few keypresses.

```shell
sudo apt-get install -y ecodmsserver
```

After the installation, you should find your ecoDMS server installation in `/opt/ecodms`. The data directory is located in `/opt/ecodms/data`. The scaninput should be in `/opt/ecodms/workdir/scaninput`.

## Restoring an existing Database

If you already have an existing installation and you want to restore that to your fresh install, follow these steps.

> **Note:** In my case my previous installation was based on Docker (installed on my NAS). I'm going to backup that and restore it to the fresh install on a VM (without docker).

> **Note:** Be aware of a few requirements when restoring a backup from a previous installation. Consult the [ecoDMS manual][def2] for more information on what to do (and what not).

### Step 1: Create a backup of your existing installation

Create a **full** backup of your existing installation in the GUI.

### Step 2: Deactivate the license of your existing installation

Deactivate the license of your existing installation using the GUI.

### Step 3: Restore the backup on your new installation

Copy the backup zip file to your VM and execute the following command to restore your data:

```shell
backupFile="/opt/ecodms/workdir/scaninput/restore.zip" # full path to your backup zip file
cd /opt/ecodms/ecodmsserver/tools/
sudo ./ecoDMSBackupConsole $backupFile restore
```

[def]: https://www.ecodms.de/de/ecodms-archiv/systemvoraussetzungen
[def2]: https://www.ecodms.de/de/download/handbuecher/ecodms-archiv/ecodms-burns