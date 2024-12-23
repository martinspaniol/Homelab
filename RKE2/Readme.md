# Introduction
This shell script installs an Rancher Kubernetes Version 2 Cluster on existing nodes in Proxmox.

# Instructions
1. Create the nodes in proxmox. At least 3 master and 2 worker nodes. Make sure to use static ip adresses.
2. Create an additional `rke2-admin` node in proxmox.
3. Copy the `rke2.sh`, `id_rsa` and `id_rsa.pub` file into your home directory of your admin node. Make sure the script is executable (`chmod +x`).
4. Adjust the IP adresses of the nodes in the shell script.
5. Run the script.