# Home Assistant

This guide provides a step by step instruction on how to create a new Home Assistant Instance on Proxmox. I will follow most steps from the [official Home Assistant Installation Guide][HA Installation Guide]

## Requirements

* Proxmox is already set up and running.

## Installation

### Step 1: Download the latest Proxmox Disk Image

ssh into your proxmox host and download the latest Proxmox Disk Image:

```shell
# Change this to the name (or IP) of your Proxmox Hypervisor
proxmoxhv=ms01

# Change this if you want to use another private Key for the ssh connection 
certName=id_rsa

# Change this to the name of the image you want to use. See https://cloud-images.ubuntu.com
url=https://github.com/home-assistant/operating-system/releases/download/14.1/haos_ova-14.1.qcow2.xz

# Change this to the path where your storage for saving ISO files is mounted on the Proxmox Hypervisor
isoPath=/mnt/pve/ISOs/template/iso

# Change this to the name of the compressed disk image (.xz)
diskImageCompressed=haos_ova-14.1.qcow2.xz

# Change this to the name of the Proxmox Storage
templateStorage=local-zfs

# Change this to the amount of Memory (RAM) you want to assign to the VM
memory=2048

# Change this to the amount of CPU cores you want to assign to the VM
cores=2

# Change this to the amount of storage in GiB you want to assign to the VM
storage=2

# Change this to the amount of storage in GiB you want to assign to the VM
VMname=haos-14-1

# Change this to the VM ID
VMid=201



############################################
# DON'T EDIT BEYOND THIS LINE              #
############################################

ssh -tt $proxmoxhv -i ~/.ssh/$certName <<EOF
wget -O $isoPath/$diskImageCompressed $url
xz -d $isoPath/$diskImageCompressed

# qm create $VMid --memory $memory --balloon 0 --cpu cputype=host --core $cores --name $VMname --net0 virtio,bridge=vmbr0
# qm importdisk $VMid $isoPath/${diskImageCompressed%.*} $templateStorage

# qm set $VMid --scsihw virtio-scsi-pci --scsi0 $templateStorage:vm-$VMid-disk-0,ssd=1
# qm set $VMid --boot c --bootdisk scsi0
# qm set $VMid --serial0 socket --vga serial0
exit
EOF
echo -e " \033[32;5mTemplate created\033[0m"
```

[HA Installation Guide]: https://www.home-assistant.io/installation/alternative