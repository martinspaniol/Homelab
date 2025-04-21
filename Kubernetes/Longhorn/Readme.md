# Introduction

This shell script first creates the necessary VMs for Longhorn and then installs an Longhorn on these nodes in Proxmox.

## Requirements

- Proxmox is set up and running
- You have a working cloud-init template (see [Cloud-Init](../Cloud-Init/Readme.md))

## Instructions

### Create and configure the Proxmox nodes

1. Create the nodes in proxmox. At least 3 master and 2 worker nodes are needed. For administration an additional admin-VM will be used. Make sure to use static ip adresses.

```shell
longhornnames=(\
    longhorn-01 \
    longhorn-02 \
    longhorn-03
)

# Since we're using MAC-Address based DHCP Reservations on our DHCP server we manually assign the MAC-Addresses to the VMs.
longhornmacs=(\
    BC:24:11:E9:DD:90 \
    BC:24:11:2B:55:98 \
    BC:24:11:CD:65:24
)

# set to "no" (without quotes) to disable resizing
longhornresize=(\
    50G \
    50G \
    50G
)

# Change this to the name (or IP) of your Proxmox Hypervisor
proxmoxhv=ms01

# Change this if you want to use another private Key for the ssh connection 
certName=id_rsa

# Change this to the VM ID of your template
templateID=5001

# User of remote machines
user=ubuntu

# Change this to the name of the Proxmox Storage
storage=local-zfs

# Change this to the VM ID the first longhorn VM will get
startingVMID=106

############################################
# DON'T EDIT BEYOND THIS LINE              #
############################################
ssh -tt $proxmoxhv -i ~/.ssh/$certName <<'EOF'
for i in $(seq 0 $((${#longhornnames[@]} - 1))); do
    echo -e " \033[32;5mID = $(($i + $startingVMID))\033[0m"
    echo -e " \033[32;5mName = ${longhornnames[$i]}\033[0m"
    echo -e " \033[32;5mMac = ${longhornmacs[$i]}\033[0m"
    echo -e " \033[32;5mResize = ${longhornresize[$i]}\033[0m"

    qm clone $templateID $(($i + $startingVMID)) --format raw --full true --name ${longhornnames[$i]} --storage $storage
    qm set $(($i + $startingVMID)) --net0 virtio=${longhornmacs[$i]},bridge=vmbr0
    
    if [ "${longhornresize[$i]}" != "no" ]; then
        qm disk resize $(($i + $startingVMID)) scsi0 ${longhornresize[$i]}
    fi
done
EOF
echo -e " \033[32;5mlonghorn VMs created\033[0m"
```

2. Copy the `longhorn-RKE2.sh`, `id_rsa` and `id_rsa.pub` file into your home directory of your admin node. Make sure the script is executable (`chmod +x`).

```shell
scp -i ~/.ssh/$certName \
    ~/.ssh/$certName \
    ~/.ssh/$certName.pub \
    ./Homelab/longhorn/longhorn-RKE2.sh \
    $user@${longhornnames[0]}:~/
echo -e " \033[32;5mConfigured ${longhornnames[0]} VM successfully\033[0m"
```

### Mount additional storage (optional but recommended)

If you want to add additional storage to your longhorn nodes, i.e. from a NAS device, follow these steps:

1. Create the necessary storage on your NAS device, for example by creating a NFS share.
2. Add an additional harddrive to each of your longhorn VMs in Proxmox. Make sure that this harddrive is located on your NAS.
3. ssh into each of your longhorn VMs and execute the following commands:

```shell
ssh -tt <YOUR LONGHORN VM> -i ~/.ssh/$certName <<'EOF'
sudo fdisk -l # this should give you /dev/sdb as the additional storage device
sudo fdisk /dev/sdb
# Press g
# Press n
# Press Enter
# Press Enter
# Press Enter
# Press w
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /mnt/longhorn
sudo vim /etc/fstab
# Enter the following in a new line. Save and exit fstab
# LABEL=longhorn  /mnt/longhorn   ext4    defaults        0 2
sudo e2label /dev/sdb1 longhorn
sudo mount -a
sudo systemctl daemon-reload
df -h # this should show you an additional partition with the size you specified
sudo reboot
EOF
echo -e " \033[32;5mAdditional Storage to your longhorn VM added\033[0m" 
```

### Adjust the longhorn Script

Adjust the IP adresses of the nodes in the `longhorn-RKE2.sh` shell script on your admin node.

### Deploy longhorn

ssh into your longhorn Admin VM and run the script `longhorn-RKE2.sh`.

### Open Longhorn and make some adjustments

After Longhorn is deployed you can open it by using your Rancher GUI > Your Cluster > Longhorn. Make the following adjustments:

1. Under _Nodes_ make sure that only your longhorn nodes are selected to be scheduled. Disable all other nodes from scheduling.
2. Edit each of your longhorn nodes to add the additional storage. Click the hamburger menu on the right of each node > edit node and disks
    1. Click _Add Disk_ in the upper right. Enter the path and enable scheduling.
    2. Disable scheduling on the other disk of your node.
    3. Save and exit.
