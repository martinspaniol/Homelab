# Requirements
## Enable USB Passthrough for WSL
> This section is under construction. In the meantime use rufus to copy all necessary files to the USB drive.

1. Install the [USB/IP open-source project](https://github.com/dorssel/usbipd-win) as described by Microsoft [here](https://learn.microsoft.com/en-us/windows/wsl/connect-usb). Open powershell as administrator and run the installation:  
`winget install --interactive --exact dorssel.usbipd-win`

2. Restart your powershell as administrator to reload your `Path`. Then list all USB devices:  
`usbipd list`  
  
This should look like this:  
``` 
PS C:\Users\marti> usbipd list
Connected:
BUSID  VID:PID    DEVICE                                    STATE
1-1    03f0:3407  USB Mass Storage Device                   Not shared
4-3    5986:215f  Integrated Camera, APP Mode               Not shared
4-4    0bda:4853  Realtek Bluetooth Adapter                 Not shared
``` 
> Note the device with BUSID 1-1.

3. To share the device use take note of the appropriate `BUSID` and issue the following command:  
`usbipd bind --busid 1-1`

4. Now attach the device to WSL:  
`usbipd attach --wsl --busid 1-1`

5. Switch to WSL and check if the device is available:  
```
martin@Lenovo-Laptop:/$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 03f0:3407 HP, Inc v135w
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```
> Note the HP, INC v135w device.

6. (Optional): To detach the device from WSL again, run the following command in powershell:  
`usbipd detach --busid 1-1`

## Install Proxmox Assistant Tool
1. Switch to root:  
`sudo su`

2. Add the Proxmox VE Repository:  
`echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list`

3. Add the Proxmox VE Key:  
```
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 
# verify
sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 
7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87 /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
```

4. Update the packages:  
`apt update`

5. Install the Proxmox Assistant Tool:  
`apt install --assume-yes proxmox-auto-install-assistant`.

6. Check installed version of Proxmox Assistant Tool:  
`proxmox-auto-install-assistant --version                                                   
proxmox-auto-install-assistant 0.1.0`

7. Switch back to normal user:  
`exit`

## Install xorriso (seems not necessary)
`xorriso` is needed on debian based systems. Install xorriso:  
`apt install --assume-yes xorriso`

## Install mkpasswd
`mkpasswd` is used to generate pre-hashed passwords. This is used to store a hashed password in the answer file instead of storing the password in cleartext.
`apt install --assume-yes whois`

# Prepare the answer file
All settings are stored in the `answer.toml` file. Adjust the settings as you like. 
* For exmaple create a hashed password for the root user and save it as `root_password_hashed` in the `answer.toml` file:  
`echo "YOUR PASSWORD HERE" | mkpasswd -s`
* Adjust the hostname with `fqdn`
* Adjust the network settings

# Create ISO for automated installation
1. Check if the `answer.toml` file is valid:  
`proxmox-auto-install-assistant validate-answer ./answer.toml`

2. Create the ISO:  
`proxmox-auto-install-assistant prepare-iso ./proxmox-ve_8.3-1.iso --fetch-from iso --answer-file ./answer.toml`

3. Finally create a bootable USB drive. You can use [Rufus](https://rufus.ie/) for example. Don't use _Unetbootin_ or _Universal USB Installer_ because they brake secure boot!  
Then boot from the USB drive and wait for the installation to run.