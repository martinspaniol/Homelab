# Introduction
To deploy multiple VMs in Proxmox with the exact same settings it's recommended to use a template. The following lines of code provide a way to create such a template.

# Requirements
- Proxmox is already installed
- You can access your Proxmox Hypervisor using an SSH key

# Instructions
Simply run the following script:  
```shell
# Change this to the name (or IP) of your Proxmox Hypervisor
proxmoxhv=ms01

# Change this if you want to use another private Key for the ssh connection 
certName=id_rsa

# Change this to the name of the image you want to use. See https://cloud-images.ubuntu.com
image=noble-server-cloudimg-amd64.img

# Change this to the path where your storage for saving ISO files is mounted on the Proxmox Hypervisor
isoPath=/mnt/pve/ISOs/template/iso

# Change this to the name of the Proxmox Template
templateName=ubuntu-cloud

# Change this to the name of the Proxmox Storage
templateStorage=local-zfs

# Change this to the amount of Memory (RAM) you want to assign to the template
memory=4096

# Change this to the amount of CPU cores you want to assign to the template
cores=4

# Change this to the VM ID
VMid=5000



############################################
# DON'T EDIT BEYOND THIS LINE              #
############################################

ssh -tt $proxmoxhv -i ~/.ssh/$certName <<EOF
wget -O $isoPath/$image https://cloud-images.ubuntu.com/${image%%-*}/current/$image
qm create $VMid --memory $memory --balloon 0 --cpu cputype=host --core $cores --name $templateName --net0 virtio,bridge=vmbr0
qm importdisk $VMid $isoPath/$image $templateStorage
qm set $VMid --scsihw virtio-scsi-pci --scsi0 $templateStorage:vm-$VMid-disk-0,ssd=1
qm set $VMid --ide2 $templateStorage:cloudinit
qm set $VMid --boot c --bootdisk scsi0
qm set $VMid --serial0 socket --vga serial0
qm template $VMid
exit
EOF
echo -e " \033[32;5mTemplate created\033[0m"
```