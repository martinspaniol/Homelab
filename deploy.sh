############################################
# Set VM properties                        #
############################################
# export all variables
set -a

names=(\
    rke2-admin \
    rke2-01 \
    rke2-02 \
    rke2-03 \
    rke2-04 \
    rke2-05 \
    longhorn-01 \
    longhorn-02 \
    longhorn-03 \
)

macs=(\
    BC:24:11:D4:FE:9C \
    BC:24:11:32:DB:4F \
    BC:24:11:F5:E3:8C \
    BC:24:11:CE:3C:22 \
    BC:24:11:53:5E:EE \
    BC:24:11:C9:F4:01 \
    BC:24:11:E9:DD:90 \
    BC:24:11:2B:55:98 \
    BC:24:11:CD:65:24 \
)

# set to "no" (without quotes) to disable resizing
resize=(\
    20G \
    20G \
    20G \
    20G \
    100G \
    100G \
    100G \
    100G \
    100G \
)

# User of remote machines
user=ubuntu

# ssh certificate name variable
certName=id_rsa

# image for template
image=noble-server-cloudimg-amd64.img

# stop exporting variables
set +a



############################################
# DON'T EDIT BEYOND THIS LINE              #
############################################

# Create initial template
./Homelab/Proxmox/CreateProxmoxTemplate.sh

# Create RKE2 and Longhorn VMs
./Homelab/RKE2/CreateVMs.sh

# Configure RKE2-Admin VM
scp -i ~/.ssh/$certName \
    ~/.ssh/$certName \
    ~/.ssh/$certName.pub \
    ./Homelab/RKE2/rke2.sh \
    ./Homelab/Longhorn/longhorn-RKE2.sh \
    $user@rke2-admin:~/
echo -e " \033[32;5mConfigured RKE2-Admin VM successfully\033[0m"

# Deploy RKE2
ssh -tt $user@rke2-admin -i ~/.ssh/$certName <<EOF
/home/$user/rke2.sh
EOF
echo -e " \033[32;5mRKE deployed\033[0m"

# Deploy Longhorn
ssh -tt $user@rke2-admin -i ~/.ssh/$certName <<EOF
/home/$user/longhorn-RKE2.sh
EOF
echo -e " \033[32;5mLonghorn deployed\033[0m"
