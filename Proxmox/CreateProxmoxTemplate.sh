############################################
# Create initial template                  #
############################################
ssh -tt ms01 -i ~/.ssh/$certName <<EOF
wget -O /mnt/pve/ISOs/template/iso/$image https://cloud-images.ubuntu.com/${image%%-*}/current/$image
qm create 5000 --memory 4096 --balloon 0 --cpu cputype=host --core 4 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
qm importdisk 5000 /mnt/pve/ISOs/template/iso/$image local-zfs
qm set 5000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-5000-disk-0,ssd=1
qm set 5000 --ide2 local-zfs:cloudinit
qm set 5000 --boot c --bootdisk scsi0
qm set 5000 --serial0 socket --vga serial0
qm template 5000
exit
EOF
echo -e " \033[32;5mTemplate created\033[0m"