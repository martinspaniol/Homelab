# Home Assistant

This guide provides a step by step instruction on how to create a new Home Assistant Instance on Proxmox. Credits go to Derek Seaman, since he explained in detail on how to install HAOS on proxmox [in his blog][DereksBlog].

## Requirements

* Proxmox is already set up and running.

## Installation

### Step 1: Use the proxmox community scripts to install Home Assistant OS

Go to the proxmox webinterface and open the shell on your host. Execute the following installation script, provided by the [Proxmox Community][Proxmox Community].

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/haos-vm.sh)"
```

Adjust the parameters in `install_haos.sh` and execute the file in WSL (or any other linux terminal).

[Proxmox Community]: https://community-scripts.github.io/ProxmoxVE/scripts?id=haos-vm
[DereksBlog]: https://www.derekseaman.com/2023/10/home-assistant-proxmox-ve-8-0-quick-start-guide-2.html
