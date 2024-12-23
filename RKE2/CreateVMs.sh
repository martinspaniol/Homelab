############################################
# Create VMs                               #
############################################

ssh -tt ms01 -i ~/.ssh/$certName sudo su <<EOF
for i in $(seq 0 $((${#names[@]} - 1))); do
    echo -e " \033[32;5mID = $(($i + 100))\033[0m"
    echo -e " \033[32;5mName = ${names[$i]}\033[0m"
    echo -e " \033[32;5mMac = ${macs[$i]}\033[0m"
    echo -e " \033[32;5mResize = ${resize[$i]}\033[0m"

    qm clone 5000 $(($i + 100)) --format raw --full true --name ${names[$i]} --storage diskstation
    qm set $(($i + 100)) --net0 virtio=${macs[$i]},bridge=vmbr0
    
    if [ "${resize[$i]}" != "no" ]; then
        qm disk resize $(($i + 100)) scsi0 ${resize[$i]}
    fi

    qm start $(($i + 100))
done

# Wait for cloud-init to finish
# Maybe there's a smarter method to detect this..
sleep 15m

for i in $(seq 0 $((${#names[@]} - 1))); do
    qm reboot $(($i + 100))
done
exit
EOF
echo -e " \033[32;5mVMs created\033[0m"