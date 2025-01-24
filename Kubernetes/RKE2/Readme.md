# Install RKE2 on proxmox

This shell script first creates the necessary VMs for Rancher Kubernetes Version 2 (RKE2) and then installs an RKE2 Cluster on these nodes in Proxmox.

## Requirements

- Proxmox is set up and running
- You have a working cloud-init template (see [Cloud-Init](../Cloud-Init/Readme.md))

## Instructions

## Create and configure the Proxmox nodes

1. Create the nodes in proxmox. At least 3 master and 2 worker nodes are needed. For administration an additional admin-VM will be used. Make sure to use static ip adresses.

```shell
rke2names=(\
    rke2-admin \
    rke2-01 \
    rke2-02 \
    rke2-03 \
    rke2-04 \
    rke2-05 \
)

# Since we're using MAC-Address based DHCP Reservations on our DHCP server we manually assign the MAC-Addresses to the VMs.
rke2macs=(\
    BC:24:11:D4:FE:9C \
    BC:24:11:32:DB:4F \
    BC:24:11:F5:E3:8C \
    BC:24:11:CE:3C:22 \
    BC:24:11:53:5E:EE \
    BC:24:11:C9:F4:01 \
)

# set to "no" (without quotes) to disable resizing
rke2resize=(\
    20G \
    20G \
    20G \
    20G \
    50G \
    50G \
)

# Change this to the name (or IP) of your Proxmox Hypervisor
proxmoxhv=ms01

# Change this if you want to use another private Key for the ssh connection 
certName=id_rsa

# Change this to the VM ID of your template
templateID=5000

# User of remote machines
user=ubuntu

# Change this to the name of the Proxmox Storage
storage=local-zfs

# Change this to the VM ID the first longhorn VM will get
startingVMID=100

############################################
# DON'T EDIT BEYOND THIS LINE              #
############################################
ssh -tt $proxmoxhv -i ~/.ssh/$certName <<'EOF'
for i in $(seq 0 $((${#rke2names[@]} - 1))); do
    echo -e " \033[32;5mID = $(($i + $startingVMID))\033[0m"
    echo -e " \033[32;5mName = ${rke2names[$i]}\033[0m"
    echo -e " \033[32;5mMac = ${rke2macs[$i]}\033[0m"
    echo -e " \033[32;5mResize = ${rke2resize[$i]}\033[0m"

    qm clone $templateID $(($i + $startingVMID)) --format raw --full true --name ${rke2names[$i]} --storage $storage
    qm set $(($i + $startingVMID)) --net0 virtio=${rke2macs[$i]},bridge=vmbr0
    
    if [ "${rke2resize[$i]}" != "no" ]; then
        qm disk resize $(($i + $startingVMID)) scsi0 ${rke2resize[$i]}
    fi
done
EOF
echo -e " \033[32;5mRKE2 VMs created\033[0m"
```

2. Copy the `rke2.sh`, `id_rsa` and `id_rsa.pub` file into your home directory of your admin node. Make sure the script is executable (`chmod +x`).

```shell
scp -i ~/.ssh/$certName \
    ~/.ssh/$certName \
    ~/.ssh/$certName.pub \
    ./Homelab/RKE2/rke2.sh \
    $user@${rke2names[0]}:~/
echo -e " \033[32;5mConfigured ${rke2names[0]} VM successfully\033[0m"
```

### Adjust the RKE2 Script

Adjust the IP adresses of the nodes in the `rke2.sh` shell script on your admin node.

### Deploy RKE2

ssh into your RKE2 Admin VM and run the script `rke2.sh`.
