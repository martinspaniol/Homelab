> **Note:** As of today (2024/12/31) GPU passthrough for an Intel UHD Graphics 770 (a.k.a. Alder Lake) integrated GPU works different than GPU passthrough before in Proxmox. Unfortunately most guides on the internet won't work. Thankfully I've found [this post from derekseaman](https://www.derekseaman.com/2024/07/proxmox-ve-8-2-windows-11-vgpu-vt-d-passthrough-with-intel-alder-lake.html) which describes in detail on how to configure iGPU passthrough. I will try to follow his steps in setting this up in my environment. All credits go to him!

# Introduction

This guide will give you step by step instructions on how to pass your physical GPU (either a dedicated GPU or a builtin GPU in your CPU) to mutliple Proxmox VMs. This guide is based on ~~the official Proxmox documentation for [PCI(e) Passthrough](https://pve.proxmox.com/wiki/PCI(e)_Passthrough)~~ (read the note above) [this post from derekseaman](https://www.derekseaman.com/2024/07/proxmox-ve-8-2-windows-11-vgpu-vt-d-passthrough-with-intel-alder-lake.html).  
If you pass a GPU to a VM, this GPU can then be used within Kubernetes for example for transcoding videos in plex. That's not part of this guide but you can find instructions [here](../Kubernetes/GPU%20Passthrough/Readme.md).

# Requirements
* Proxmox is already setup and running
* _IOMMU_ support of your GPU: Your GPU needs to support _IOMMU_. Generally, Intel systems with VT-d and AMD systems with AMD-Vi support this. In my case I want to use the builtin GPU within my CPU. I have a [Intel Core i9-13900H](https://www.intel.com/content/www/us/en/products/sku/232135/intel-core-i913900h-processor-24m-cache-up-to-5-40-ghz/specifications.html). According to the Intel documentation this CPU is capable of _Intel Virtualization Technology for Directed I/O (VT-d)_.
* _Intel VT-d_ and _SR-IOV_ are enabled in the BIOS of your host

# Instructions
## On the Proxmox Host

### Proxmox Kernel Configuration
1. ssh into your Proxmox host and execute the following commands. First we need to install Git, kernel headers and do a bit of cleanup.
    ```shell
    apt update && apt install -y git sysfsutils pve-headers mokutil
    rm -rf /usr/src/i915-sriov-dkms-*
    rm -rf /var/lib/dkms/i915-sriov-dkms
    find /lib/modules -regex ".*/updates/dkms/i915.ko" -delete
    ```

2. Now we need to clone the DKMS repo and do a little build work.
    ```shell
    cd ~
    git clone https://github.com/strongtz/i915-sriov-dkms.git
    apt install -y build-* dkms
    cd ~/i915-sriov-dkms
    dkms add .
    ```

3. Let’s now build the new kernel and check the status. Validate that it shows installed.
    ```shell
    dkms install -m i915-sriov-dkms -v $(cat VERSION) --force
    dkms status
    ```

4. For fresh Proxmox 8.1 and later installs, secure boot may be enabled. Just in case it is, we need to load the DKMS key so the kernel will load the module. Run the following command, then enter a password. This password is only for MOK setup, and will be used again when you reboot the host. After that, the password is not needed. It does NOT need to be the same password as you used for the root account.
    ```shell
    mokutil --import /var/lib/dkms/mok.pub
    # to keep it simple just use 12345678 as password
    ```

### Proxmox GRUB Configuration

1. Back in the Proxmox shell run the following commands if you DO NOT have a Google Coral PCIe TPU in your Proxmox host. You would know if you did, so if you aren’t sure, run the first block of commands. If your Google Coral is USB, use the first block of commands as well. Run the second block of commands if your Google Coral is a PCIe module. 
    ```shell
    cp -a /etc/default/grub{,.bak}
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt i915.enable_guc=3 i915.max_vfs=7"' /etc/default/grub
    update-grub
    update-initramfs -u -k all
    ```

### Finish PCI Configuration

1. Now we need to find which PCIe bus the VGA card is on. It’s typically 00:02.0. 
```shell
root@ms01:~# lspci | grep VGA
00:02.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
```

2. Run the following command and modify the PCIe bus number if needed. In this case I’m using 00:02.0. To verify the file was modified, cat the file and ensure it was modified.
```shell
echo "devices/pci0000:00/0000:00:02.0/sriov_numvfs = 7" > /etc/sysfs.conf
cat /etc/sysfs.conf
```

3. Reboot the Proxmox host. If using Proxmox 8.1 or later with secure boot you MUST setup MOK. As the Proxmox host reboots, monitor the boot process and wait for the Perform MOK management window (screenshot below). If you miss the first reboot you will need to re-run the mokutil command and reboot again. The DKMS module will NOT load until you step through this setup. 

4. On reboot, select Enroll MOK, Continue, Yes, <password>, Reboot. 

5. Login to the Proxmox host, open a Shell, then run the commands below. The first should return eight lines of PCIe devices. The second command should return a lot of log data. If everything was successful, at the end you should see minor PCIe IDs 1-7 and finally Enabled 7 VFs. If you are using secure boot and do NOT see the 7 VFs, then the DKMS module is probably not loaded. Troubleshoot as needed. 
    ```shell
    root@ms01:~# lspci | grep VGA
    00:02.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.1 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.2 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.3 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.4 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.5 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.6 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    00:02.7 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)


    root@ms01:~# dmesg | grep i915
    [    0.000000] Command line: BOOT_IMAGE=/vmlinuz-6.8.12-5-pve root=ZFS=/ROOT/pve-1 ro   root=ZFS=rpool/ROOT/pve-1 boot=zfs quiet intel_iommu=on iommu=pt i915.enable_guc=3 i915.max_vfs=7
    [    0.113274] Kernel command line: BOOT_IMAGE=/vmlinuz-6.8.12-5-pve root=ZFS=/ROOT/pve-1 ro    root=ZFS=rpool/ROOT/pve-1 boot=zfs quiet intel_iommu=on iommu=pt i915.enable_guc=3 i915.max_vfs=7
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.140653] i915 0000:00:02.0: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.140670] i915 0000:00:02.0: Running in SR-IOV PF mode
    [    4.141153] i915 0000:00:02.0: [drm] VT-d active for gfx access
    [    4.159566] i915 0000:00:02.0: vgaarb: deactivate vga console
    [    4.159607] i915 0000:00:02.0: [drm] Using Transparent Hugepages
    [    4.159895] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=io+mem,decodes=io +mem:owns=io+mem
    [    4.161889] i915 0000:00:02.0: [drm] Finished loading DMC firmware i915/adlp_dmc.bin (v2.20)
    [    4.165064] i915 0000:00:02.0: [drm] GT0: GuC firmware i915/adlp_guc_70.bin version 70.36.0
    [    4.165067] i915 0000:00:02.0: [drm] GT0: HuC firmware i915/tgl_huc.bin version 7.9.3
    [    4.179155] i915 0000:00:02.0: [drm] GT0: HuC: authenticated for all workloads
    [    4.179559] i915 0000:00:02.0: [drm] GT0: GUC: submission enabled
    [    4.179559] i915 0000:00:02.0: [drm] GT0: GUC: SLPC enabled
    [    4.180107] i915 0000:00:02.0: [drm] GT0: GUC: RC enabled
    [    4.182243] mei_pxp 0000:00:16.0-fbf6fcf1-96cf-4e2e-a6a6-1bab8cbe36b1: bound 0000:00:02.0    (ops i915_pxp_tee_component_ops [i915])
    [    4.182332] i915 0000:00:02.0: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.182335] mei_hdcp 0000:00:16.0-b638ab7e-94e2-4ea2-a552-d1c54b627f04: bound 0000:00:02.0   (ops i915_hdcp_ops [i915])
    [    4.205825] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.0 on minor 1
    [    4.236544] fbcon: i915drmfb (fb0) is primary device
    [    4.236547] i915 0000:00:02.0: [drm] fb0: i915drmfb frame buffer device
    [    4.251380] i915 display info: display version: 13
    [    4.251381] i915 display info: display stepping: E0
    [    4.251381] i915 display info: cursor_needs_physical: no
    [    4.251382] i915 display info: has_cdclk_crawl: yes
    [    4.251382] i915 display info: has_cdclk_squash: no
    [    4.251383] i915 display info: has_ddi: yes
    [    4.251383] i915 display info: has_dp_mst: yes
    [    4.251384] i915 display info: has_dsb: yes
    [    4.251384] i915 display info: has_fpga_dbg: yes
    [    4.251384] i915 display info: has_gmch: no
    [    4.251385] i915 display info: has_hotplug: yes
    [    4.251385] i915 display info: has_hti: no
    [    4.251385] i915 display info: has_ipc: yes
    [    4.251386] i915 display info: has_overlay: no
    [    4.251386] i915 display info: has_psr: yes
    [    4.251386] i915 display info: has_psr_hw_tracking: no
    [    4.251387] i915 display info: overlay_needs_physical: no
    [    4.251387] i915 display info: supports_tv: no
    [    4.251388] i915 display info: has_hdcp: yes
    [    4.251388] i915 display info: has_dmc: yes
    [    4.251388] i915 display info: has_dsc: yes
    [    4.251389] i915 display info: rawclk rate: 19200 kHz
    [    4.251435] i915 0000:00:02.0: 7 VFs could be associated with this PF
    [    4.260617] snd_hda_intel 0000:00:1f.3: bound 0000:00:02.0 (ops i915_audio_component_bind_ops    [i915])
    [    4.288813] i915 [CRTC:80:pipe A] fastset requirement not met in dpll_hw_state
    [    4.288816] i915 expected:
    [    4.288817] i915 dpll_hw_state: cfgcr0: 0x3c01b8, cfgcr1: 0x60, div0: 0x0, mg_refclkin_ctl:  0x0, hg_clktop2_coreclkctl1: 0x0, mg_clktop2_hsclkctl: 0x0, mg_pll_div0: 0x0, mg_pll_div2: 0x0,  mg_pll_lf: 0x0, mg_pll_frac_lock: 0x0, mg_pll_ssc: 0x0, mg_pll_bias: 0x0,    mg_pll_tdc_coldst_bias: 0x0
    [    4.288818] i915 found:
    [    4.288819] i915 dpll_hw_state: cfgcr0: 0x3c01b8, cfgcr1: 0x460, div0: 0x0, mg_refclkin_ctl:     0x0, hg_clktop2_coreclkctl1: 0x0, mg_clktop2_hsclkctl: 0x0, mg_pll_div0: 0x0, mg_pll_div2: 0x0,     mg_pll_lf: 0x0, mg_pll_frac_lock: 0x0, mg_pll_ssc: 0x0, mg_pll_bias: 0x0,   mg_pll_tdc_coldst_bias: 0x0
    [    4.288820] i915 [CRTC:80:pipe A] fastset requirement not met in infoframes.enable (expected     0x00000010, found 0x00000031)
    [    4.631546] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=io+mem
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.631591] i915 0000:00:02.1: enabling device (0000 -> 0002)
    [    4.631605] i915 0000:00:02.1: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.631617] i915 0000:00:02.1: Running in SR-IOV VF mode
    [    4.632208] i915 0000:00:02.1: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.633825] i915 0000:00:02.1: [drm] VT-d active for gfx access
    [    4.633840] i915 0000:00:02.1: [drm] Using Transparent Hugepages
    [    4.634366] i915 0000:00:02.1: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.634825] i915 0000:00:02.1: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.636132] i915 0000:00:02.1: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.636145] i915 0000:00:02.1: HuC firmware PRELOADED
    [    4.640246] i915 0000:00:02.1: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.640249] i915 0000:00:02.1: [drm] PMU not supported for this GPU.
    [    4.640497] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.1 on minor 0
    [    4.640678] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.640680] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.640717] i915 0000:00:02.2: enabling device (0000 -> 0002)
    [    4.640727] i915 0000:00:02.2: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.640741] i915 0000:00:02.2: Running in SR-IOV VF mode
    [    4.641337] i915 0000:00:02.2: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.642332] i915 0000:00:02.2: [drm] VT-d active for gfx access
    [    4.642346] i915 0000:00:02.2: [drm] Using Transparent Hugepages
    [    4.642865] i915 0000:00:02.2: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.643297] i915 0000:00:02.2: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.643908] i915 0000:00:02.2: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.643919] i915 0000:00:02.2: HuC firmware PRELOADED
    [    4.646665] i915 0000:00:02.2: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.646670] i915 0000:00:02.2: [drm] PMU not supported for this GPU.
    [    4.646910] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.2 on minor 2
    [    4.647137] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.647140] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.647143] i915 0000:00:02.2: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.647192] i915 0000:00:02.3: enabling device (0000 -> 0002)
    [    4.647209] i915 0000:00:02.3: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.647224] i915 0000:00:02.3: Running in SR-IOV VF mode
    [    4.647526] i915 0000:00:02.3: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.647954] i915 0000:00:02.3: [drm] VT-d active for gfx access
    [    4.647966] i915 0000:00:02.3: [drm] Using Transparent Hugepages
    [    4.648111] i915 0000:00:02.3: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.648542] i915 0000:00:02.3: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.649165] i915 0000:00:02.3: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.649166] i915 0000:00:02.3: HuC firmware PRELOADED
    [    4.651943] i915 0000:00:02.3: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.651946] i915 0000:00:02.3: [drm] PMU not supported for this GPU.
    [    4.652186] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.3 on minor 3
    [    4.652364] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.652366] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.652368] i915 0000:00:02.2: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.652370] i915 0000:00:02.3: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.652404] i915 0000:00:02.4: enabling device (0000 -> 0002)
    [    4.652412] i915 0000:00:02.4: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.652420] i915 0000:00:02.4: Running in SR-IOV VF mode
    [    4.652828] i915 0000:00:02.4: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.653247] i915 0000:00:02.4: [drm] VT-d active for gfx access
    [    4.653262] i915 0000:00:02.4: [drm] Using Transparent Hugepages
    [    4.653769] i915 0000:00:02.4: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.654198] i915 0000:00:02.4: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.654844] i915 0000:00:02.4: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.654845] i915 0000:00:02.4: HuC firmware PRELOADED
    [    4.657569] i915 0000:00:02.4: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.657571] i915 0000:00:02.4: [drm] PMU not supported for this GPU.
    [    4.657740] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.4 on minor 4
    [    4.657878] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.657881] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.657883] i915 0000:00:02.2: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.657885] i915 0000:00:02.3: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.657887] i915 0000:00:02.4: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.657913] i915 0000:00:02.5: enabling device (0000 -> 0002)
    [    4.657919] i915 0000:00:02.5: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.657926] i915 0000:00:02.5: Running in SR-IOV VF mode
    [    4.658118] i915 0000:00:02.5: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.658421] i915 0000:00:02.5: [drm] VT-d active for gfx access
    [    4.658431] i915 0000:00:02.5: [drm] Using Transparent Hugepages
    [    4.658565] i915 0000:00:02.5: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.658829] i915 0000:00:02.5: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.659277] i915 0000:00:02.5: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.659278] i915 0000:00:02.5: HuC firmware PRELOADED
    [    4.661121] i915 0000:00:02.5: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.661124] i915 0000:00:02.5: [drm] PMU not supported for this GPU.
    [    4.661265] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.5 on minor 5
    [    4.661439] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.661441] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.661443] i915 0000:00:02.2: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.661446] i915 0000:00:02.3: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.661448] i915 0000:00:02.4: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.661450] i915 0000:00:02.5: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.661481] i915 0000:00:02.6: enabling device (0000 -> 0002)
    [    4.661489] i915 0000:00:02.6: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.661496] i915 0000:00:02.6: Running in SR-IOV VF mode
    [    4.661670] i915 0000:00:02.6: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.661894] i915 0000:00:02.6: [drm] VT-d active for gfx access
    [    4.661901] i915 0000:00:02.6: [drm] Using Transparent Hugepages
    [    4.662039] i915 0000:00:02.6: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.662298] i915 0000:00:02.6: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.662602] i915 0000:00:02.6: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.662603] i915 0000:00:02.6: HuC firmware PRELOADED
    [    4.664216] i915 0000:00:02.6: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.664218] i915 0000:00:02.6: [drm] PMU not supported for this GPU.
    [    4.664367] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.6 on minor 6
    [    4.664485] i915 0000:00:02.0: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=io+mem
    [    4.664488] i915 0000:00:02.1: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.664490] i915 0000:00:02.2: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.664492] i915 0000:00:02.3: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.664494] i915 0000:00:02.4: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.664496] i915 0000:00:02.5: vgaarb: VGA decodes changed: olddecodes=none, decodes=none:owns=none
    [    4.664499] i915 0000:00:02.6: vgaarb: VGA decodes changed: olddecodes=io+mem,   decodes=none:owns=none
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    4.664528] i915 0000:00:02.7: enabling device (0000 -> 0002)
    [    4.664534] i915 0000:00:02.7: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version    13.00 stepping E0
    [    4.664540] i915 0000:00:02.7: Running in SR-IOV VF mode
    [    4.664711] i915 0000:00:02.7: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.664925] i915 0000:00:02.7: [drm] VT-d active for gfx access
    [    4.664933] i915 0000:00:02.7: [drm] Using Transparent Hugepages
    [    4.665071] i915 0000:00:02.7: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.665331] i915 0000:00:02.7: [drm] GT0: GUC: interface version 0.1.17.0
    [    4.665632] i915 0000:00:02.7: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    4.665633] i915 0000:00:02.7: HuC firmware PRELOADED
    [    4.667196] i915 0000:00:02.7: [drm] Protected Xe Path (PXP) protected content support   initialized
    [    4.667198] i915 0000:00:02.7: [drm] PMU not supported for this GPU.
    [    4.667417] [drm] Initialized i915 1.6.0 20230929 for 0000:00:02.7 on minor 7
    [    4.667536] i915 0000:00:02.0: Enabled 7 VFs
    ```

6. Now that the Proxmox host is ready, we can install and configure Windows 11. If you do NOT see 7 VFs enabled, stop. Troubleshoot as needed. Do not pass go, do not collect $100 without 7 VFs. If you are using secure boot and you aren’t seeing the 7 VFs, double check the MOK configuration. 


## Creating a VM

1. Download the latest Fedora Windows VirtIO driver ISO from [here](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso). 

2. Download the Windows 11 ISO from [here](https://www.microsoft.com/software-download/windows11). Use the Download Windows 11 Disk Image (ISO) for x64 devices option. 

3. Upload both the VirtIO and Windows 11 ISOs to the Proxmox server. You can use any Proxmox storage container that you wish. I uploaded them to my Synology. If you don’t have any NAS storage mapped, you probably have “local“, which works. 

4. Start the VM creation process. On the General tab enter the name of your VM. Click Next

5. On the OS tab select the Windows 11 ISO. Change the Guest OS to Microsoft Windows, 11/2022. Tick the box for the VirtIO drivers, then select your Windows VirtIO ISO. Click Next. Note: The VirtIO drivers option is new to Proxmox 8.1. I added a Proxmox 8.0 step at the end to manually add a new CD drive and mount the VirtIO ISO.

6. On the System page modify the settings to match EXACTLY as those shown below. If your local VM storage is named differently (e.g. NOT local-lvm, use that instead).

7. On the Disks tab, modify the size as needed. I suggest a minimum of 64GB. Modify the Cache and Discard settings as shown. Only enable Discard if using SSD/NVMe storage (not a spinning disk).

8. On the CPU tab, change the Type to host. Allocate however many cores you want. I chose 24

9. On the Memory tab allocated as much memory as you want. I suggest 8GB or more. 

10. On the Network tab change the model to Intel E1000. Note: We will change this to VirtIO later, after Windows is configured.

11. Review your VM configuration. Click Finish. Note: If you are on Proxmox 8.0, modify the hardware configuration again and add a CD/DVD drive and select the VirtIO ISO image. Do not start the VM. 

## Windows 11 Installation

1. In Proxmox click on the Windows 11 VM, then open a console. Start the VM, then press Enter to boot from the CD.

2. Select your language, time, currency, and keyboard. Click Next. Click Install now.

3. Click I don’t have a product key. 

4. Select Windows 11 Pro. Click Next.

5. Tick the box to accept the license agreement. Click Next.

6. Click on Custom install.

7. Click Load driver. Select the virtio-driver which should be mounted as D:\amd64\win11. Select 'Red Hat VirtIO SCSI pass-through controller'. Select install. 

8. Your SCSI disk should appear. On Where do you want to install Windows click Next.

9. Sit back and wait for Windows 11 to install.

## Windows 11 Initial Configuration

> Note: I strongly suggest using a Windows local account during setup, and not your Microsoft cloud account. This will make remote desktop setup easier, as you can’t RDP to Windows 11 using your Microsoft cloud account. The procedure below “tricks” Windows into allowing you to create a local account by attempting to use a locked out cloud account. Also, do NOT use the same username for the local account as your Microsoft cloud account. This might cause complications if you later add your Microsoft cloud account.

1. Once Windows boots you should see a screen confirming your country or region. Make an appropriate selection and click Yes.

2. Confirm the right keyboard layout. Click Yes. Add a second keyboard layout if needed. 

3. Wait for Windows to check for updates. Windows may reboot. 

4. Enter the name of your PC. Click Next. Wait for Windows to reboot.

5. Click Set up for personal use. Click Next. Click Sign in.

6. **This does not work anymore** To bypass using your Microsoft cloud account, enter no @ thankyou .com (no spaces), enter a random password, click Next on Oops, something went wrong. 

7. **This does not work anymore** On the Who’s going to use this device? screen enter a username. Click Next.

8. **This does not work anymore** Enter a password. Click Next.

9. **This does not work anymore** Select your security questions and enter answers.

10. Select the Privacy settings you desire and click Accept.

11. In Windows open the mounted ISO in Explorer. Run virtio-win-gt-x64 and virtio-win-guest-tools. Use all default options. 

12. Shutdown (NOT reboot) Windows.

13. In Proxmox modify the Windows 11 VM settings and change the NIC to VirtIO.

14. Start the Windows 11 VM. Verify at least one IP is showing in the Proxmox console.

15. You can now unmount the Windows 11 and VirtIO ISOs. 

16. You will probably also want to change the Windows power plan so that the VM doesn’t hibernate (unless you want it to). 

17. You may want to disable local account password expiration, as RDP will fail when your password expires with no way to reset. You’d need to re-enable the Proxmox console to reset your password (see later in this post for a how to).

## Windows 11 vGPU Configuration

1. Open a Proxmox console to the VM and login to Windows 11. In the search bar type remote desktop, then click on remote desktop settings.

2. Enable Remote Desktop. Click Confirm.

3. Open your favorite RDP client and login using the user name and credentials you setup. You should now see your Windows desktop and the Proxmox console window should show the lock screen.

4. Inside the Windows VM open your favorite browser and download the latest Intel “Recommended” graphics driver from [here](https://www.intel.de/content/www/de/de/download/785597/842655/intel-arc-iris-xe-graphics-windows.html). In my case I’m grabbing 31.0.101.4972.

5. Shutdown the Windows VM. 

6. In the Proxmox console click on the Windows 11 VM in the left pane. Then click on Hardware. Click on the Display item in the right pane. Click Edit, then change it to none.

7. In the top of the right pane click on Add, then select PCI Device.

8. Select Raw Device. Then review all of the PCI devices available. Select one of the sub-function (.1, .2, etc..) graphics controllers (i.e. ANY entry except the 00:02.0). Do NOT use the root “0” device, for ANYTHING. I chose 02.1. Click Add. Do NOT tick the “All Functions” box. Tick the box next to Primary GPU. Click Add.

9. Start the Windows 11 VM and wait a couple of minutes for it to boot and RDP to become active. Note, the Proxmox Windows console will NOT connect since we removed the virtual VGA device. You will see a Failed to connect to server message. You can now ONLY access Windows via RDP. 

10. RDP into the Windows 11 VM. Locate the Intel Graphics driver installer and run it. If all goes well, you will be presented with an Installation complete! screen. Reboot. If you run into issues with the Intel installer, skip down to my troubleshooting section below to see if any of those tips help. 

## Windows 11 vGPU Validation

1. RDP into Windows and launch Device Manager. 

2. Expand Display adapters and verify there’s an Intel adapter in a healthy state (e.g. no error 43).

3. Launch Intel Arc Control. Click on the gear icon, System Info, Hardware. Verify it shows Intel Iris Xe.

4. Launch Task Manager, then watch a YouTube video. Verify the GPU is being used.

## On Linux

> **Attention!** According to [the list of supported os distributions](https://github.com/intel-gpu/intel-gpu-i915-backports?tab=readme-ov-file#supported-os-distributions) the DKMS driver may not be supported for the Linux Kernel or OS distribution you are using. At the time of writing Ubuntu 24.04 with Linux Kernel 6.8 is supported in general but taking a look in the [version information](https://github.com/intel-gpu/intel-gpu-i915-backports/blob/backport/main/versions) only Kernel version 6.8.0-**50** is tested and supported. Since I'm running Kernel 6.8.0-**51** DKMS installation will wail. GPU passthrough cannot be enabled until this the newer Kernel is supported or you switch to an older (but supported) Kernel.

1. ssh into your VM and execute the following command to see currently used Linux Kernel: 
    `uname -r`.

    The output should look like this:
    ```shell
    6.8.0-51-generic
    ```

2. Since the Kernel currently in use is not supported by DKMS, we need to revert back to an older Kenerl. Luckily an older Kernel is still installed so we can just remove the newer one and reboot:

    ```shell
    ubuntu@gpu-node:~$ dpkg --list | grep -E -i --color 'linux-image|linux-headers'
    ii  linux-headers-6.8.0-49          6.8.0-49.49     all          Header files related to Linux kernel version 6.8.0
    ii  linux-headers-6.8.0-49-generic  6.8.0-49.49     amd64        Linux kernel headers for version 6.8.0 on 64 bit x86 SMP
    ii  linux-headers-6.8.0-51          6.8.0-51.52     all          Header files related to Linux kernel version 6.8.0
    ii  linux-headers-6.8.0-51-generic  6.8.0-51.52     amd64        Linux kernel headers for version 6.8.0 on 64 bit x86 SMP
    ii  linux-headers-generic           6.8.0-51.52     amd64        Generic Linux kernel headers
    ii  linux-headers-virtual           6.8.0-51.52     amd64        Virtual Linux kernel headers
    ii  linux-image-6.8.0-49-generic    6.8.0-49.49     amd64        Signed kernel image generic
    ii  linux-image-6.8.0-51-generic    6.8.0-51.52     amd64        Signed kernel image generic
    ii  linux-image-virtual             6.8.0-51.52     amd64        Virtual Linux kernel image

    # remove non-supported Kernel
    sudo apt remove -y linux-image-6.8.0-51-generic linux-headers-6.8.0-51-generic

    # install extra modules needed for i915
    sudo apt install -y linux-modules-extra-6.8.0-49-generic

    # reboot the VM
    sudo reboot now
    ```

3. Install git and clone [this repository](https://github.com/strongtz/i915-sriov-dkms):
    ```shell
    sudo apt install -y git
    cd ~
    git clone https://github.com/strongtz/i915-sriov-dkms.git
    ```

4. Install dkms:
    ```shell
    sudo apt install -y build-* dkms
    cd ~/i915-sriov-dkms
    sudo dkms add .
    sudo dkms install -m i915-sriov-dkms -v $(cat VERSION) --force
    # if asked enter a password for the next boot, i.e. 12345678
    sudo dkms status
    ```

5. Edit the GRUB bootloader `/etc/default/grub` command line and change `GRUB_CMDLINE_LINUX_DEFAULT`:
    ```shell
    # old value:
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

    # new value:
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on i915.enable_guc=3"
    ```

6. Update grub and initramfs:
    ```shell
    sudo update-grub
    sudo update-initramfs -u -k all
    ```

7. Reboot the VM and make sure to enter the password you've set in step 4 on reboot!

8. _dmesg_ should report the newly installed i915 driver:
    ```shell
    ubuntu@gpu-lin:~$ sudo dmesg | grep i915
                   use xe.force_probe='a7a0' and i915.force_probe='!a7a0'
    [    3.064885] i915: loading out-of-tree module taints kernel.
    [    3.299444] i915 0000:06:10.0: [drm] Found ALDERLAKE_P/RPL-P (device ID a7a0) display version 13.00 stepping E0
    [    3.299465] i915 0000:06:10.0: Running in SR-IOV VF mode
    [    3.299930] i915 0000:06:10.0: [drm] GT0: GUC: interface version 0.1.17.0
    [    3.300404] i915 0000:06:10.0: vgaarb: deactivate vga console
    [    3.300417] i915 0000:06:10.0: [drm] Using Transparent Hugepages
    [    3.301104] i915 0000:06:10.0: [drm] GT0: GUC: interface version 0.1.17.0
    [    3.301568] i915 0000:06:10.0: [drm] GT0: GUC: interface version 0.1.17.0
    [    3.302618] i915 0000:06:10.0: GuC firmware PRELOADED version 0.0 submission:SR-IOV VF
    [    3.302620] i915 0000:06:10.0: HuC firmware PRELOADED
    [    3.305168] i915 0000:06:10.0: [drm] Protected Xe Path (PXP) protected content support initialized
    [    3.305170] i915 0000:06:10.0: [drm] PMU not supported for this GPU.
    [    3.305229] [drm] Initialized i915 1.6.0 20230929 for 0000:06:10.0 on minor 0
    ```

    There should also be a new `/dev/dri` directory containing the GPU:
    ```shell
    ubuntu@gpu-lin:~$ ll /dev/dri/
    total 0
    drwxr-xr-x  3 root root        100 Dec 31 14:53 ./
    drwxr-xr-x 19 root root       4040 Dec 31 14:53 ../
    drwxr-xr-x  2 root root         80 Dec 31 14:53 by-path/
    crw-rw----  1 root video  226,   0 Dec 31 14:53 card0
    crw-rw----  1 root render 226, 128 Dec 31 14:53 renderD128
    ```

    _lspci_ should report `i915` and `xe` as modules and `i915` as the driver for the GPU:
    ```shell
    ubuntu@gpu-lin:~$ sudo lspci -v -d  8086:a7a0
    06:10.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04) (prog-if 00 [VGA controller])
            Physical Slot: 16-2
            Flags: bus master, fast devsel, latency 0, IRQ 40
            Memory at 80000000 (64-bit, non-prefetchable) [size=16M]
            Memory at 383800000000 (64-bit, prefetchable) [size=512M]
            Capabilities: [ac] MSI: Enable+ Count=1/1 Maskable+ 64bit-
            Kernel driver in use: i915 # < this is what we're looking for
            Kernel modules: xe, i915 # < this is what we're looking for
    ```

    If you've installed the `intel-gpu-tools` you can check for your GPU as well:
    ```shell
    ubuntu@gpu-lin:~$ intel_gpu_top -L
    card0                    Intel Alderlake_p (Gen12)         pci:vendor=8086,device=A7A0,card=0
    └─renderD128
    ```