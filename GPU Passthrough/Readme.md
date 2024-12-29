> **Attention!** According to [this post](https://github.com/intel-analytics/ipex-llm/issues/12156) the DKMS driver is not supported with Linux Kernel version 8 at the time of writing. GPU passthrough cannot be enabled until this is solved.

# Introduction
This guide will give you step by step instructions on how to pass your physical GPU (either a dedicated GPU or a builtin GPU in your CPU) to a Proxmox VM. This guide is based on the official Proxmox documentation for [PCI(e) Passthrough](https://pve.proxmox.com/wiki/PCI(e)_Passthrough).  
If you pass a GPU to a VM, this GPU can then be used within Kubernetes for example for transcoding videos in plex. That's not part of this guide but you can find instructions [here](../Kubernetes/GPU%20Passthrough/Readme.md).

# Requirements
* Proxmox is already setup and running
* _IOMMU_ support of your GPU: Your GPU needs to support _IOMMU_. Generally, Intel systems with VT-d and AMD systems with AMD-Vi support this. In my case I want to use the builtin GPU within my CPU. I have a [Intel Core i9-13900H](https://www.intel.com/content/www/us/en/products/sku/232135/intel-core-i913900h-processor-24m-cache-up-to-5-40-ghz/specifications.html). According to the Intel documentation this CPU is capable of _Intel Virtualization Technology for Directed I/O (VT-d)_.

# Instructions

If your system fullfills the requirements, the following steps are necessary to passthrough the GPU into a VM.

1. ssh into one of your proxmox nodes.

2. Determine the PCI card address using `lspci -nn`. The result should look like this:

    ```shell
    00:00.0 Host bridge [0600]: Intel Corporation Raptor Lake-P 6p+8e cores Host Bridge/DRAM Controller [8086:a706]
    00:02.0 VGA compatible controller [0300]: Intel Corporation Raptor Lake-P [Iris Xe Graphics] [8086:a7a0] (rev 04)
    00:06.0 PCI bridge [0604]: Intel Corporation Raptor Lake PCIe 4.0 Graphics Port [8086:a74d]
    00:06.2 PCI bridge [0604]: Intel Corporation Device [8086:a73d]
    00:07.0 PCI bridge [0604]: Intel Corporation Raptor Lake-P Thunderbolt 4 PCI Express Root Port [8086:a76e]
    00:07.2 PCI bridge [0604]: Intel Corporation Raptor Lake-P Thunderbolt 4 PCI Express Root Port [8086:a72f]
    00:0d.0 USB controller [0c03]: Intel Corporation Raptor Lake-P Thunderbolt 4 USB Controller [8086:a71e]
    00:0d.2 USB controller [0c03]: Intel Corporation Raptor Lake-P Thunderbolt 4 NHI [8086:a73e]
    00:0d.3 USB controller [0c03]: Intel Corporation Raptor Lake-P Thunderbolt 4 NHI [8086:a76d]
    00:14.0 USB controller [0c03]: Intel Corporation Alder Lake PCH USB 3.2 xHCI Host Controller [8086:51ed] (rev 01)
    00:14.2 RAM memory [0500]: Intel Corporation Alder Lake PCH Shared SRAM [8086:51ef] (rev 01)
    00:16.0 Communication controller [0780]: Intel Corporation Alder Lake PCH HECI Controller [8086:51e0] (rev 01)
    00:16.3 Serial controller [0700]: Intel Corporation Alder Lake AMT SOL Redirection [8086:51e3] (rev 01)
    00:1c.0 PCI bridge [0604]: Intel Corporation Alder Lake-P PCH PCIe Root Port [8086:51bb] (rev 01)
    00:1c.4 PCI bridge [0604]: Intel Corporation Device [8086:51bc] (rev 01)
    00:1d.0 PCI bridge [0604]: Intel Corporation Alder Lake PCI Express Root Port [8086:51b0] (rev 01)
    00:1d.2 PCI bridge [0604]: Intel Corporation Device [8086:51b2] (rev 01)
    00:1d.3 PCI bridge [0604]: Intel Corporation Device [8086:51b3] (rev 01)
    00:1f.0 ISA bridge [0601]: Intel Corporation Raptor Lake LPC/eSPI Controller [8086:519d] (rev 01)
    00:1f.3 Audio device [0403]: Intel Corporation Raptor Lake-P/U/H cAVS [8086:51ca] (rev 01)
    00:1f.4 SMBus [0c05]: Intel Corporation Alder Lake PCH-P SMBus Host Controller [8086:51a3] (rev 01)
    00:1f.5 Serial bus controller [0c80]: Intel Corporation Alder Lake-P PCH SPI Controller [8086:51a4] (rev 01)
    02:00.0 Ethernet controller [0200]: Intel Corporation Ethernet Controller X710 for 10GbE SFP+ [8086:1572] (rev 02)
    02:00.1 Ethernet controller [0200]: Intel Corporation Ethernet Controller X710 for 10GbE SFP+ [8086:1572] (rev 02)
    57:00.0 Ethernet controller [0200]: Intel Corporation Ethernet Controller I226-V [8086:125c] (rev 04)
    58:00.0 Non-Volatile memory controller [0108]: Sandisk Corp WD Black SN770 NVMe SSD [15b7:5017] (rev 01)
    59:00.0 Non-Volatile memory controller [0108]: Sandisk Corp WD Black SN770 NVMe SSD [15b7:5017] (rev 01)
    5a:00.0 Ethernet controller [0200]: Intel Corporation Ethernet Controller I226-LM [8086:125b] (rev 04)
    5b:00.0 Network controller [0280]: MEDIATEK Corp. MT7922 802.11ax PCI Express Wireless Network Adapter [14c3:0616]   
    ```

    Take note of the second line:  
    `00:02.0 VGA compatible controller [0300]: Intel Corporation Raptor Lake-P [Iris Xe Graphics] [8086:a7a0] (rev 04)`  
    where `00:02` is the _IOMMU-Group_ and `8086:a7a0` is the _PCI Card Address_.

3. Although _iommu_ support is enabled by default since Linux Kernel version 6.8, which is used in Proxmox VE 8.2 ([see here](https://pve.proxmox.com/wiki/Roadmap)) we should explicitly enable it in our bootloader. Additionally we want to configure _IOMMU Passthrough Mode_ to increase the performance. We can do both by editing the bootloader command line. Usually proxmox uses the grub bootloader, so open the bootloader file:  
    `nano /etc/default/grub`  
    
    You should see this line:  
    `GRUB_CMDLINE_LINUX_DEFAULT="quiet"`  

    Change it to this:  
    `GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt`

    > Note: If you have an AMD GPU exchange _intel_iommu_ to _amd_iommu_.

    Save this file and update the grub loader with this command:  
    `update-grub`
    > Note: On some systems you have to use `proxmox-boot-tool refresh` to update the boot configuration.

    Reboot your host.

4. After rebooting, check that _iommu_ is enabled by executing the following command:  
    `dmesg | grep -e DMAR -e IOMMU`  
    
    The output should look like this:  
    ```shell
    [    0.019126] ACPI: DMAR 0x0000000042767000 000088 (v02 INTEL  EDK2     00000002      01000013)
    [    0.019148] ACPI: Reserving DMAR table memory at [mem 0x42767000-0x42767087]
    [    0.113200] DMAR: IOMMU enabled
    [    0.241981] DMAR: Host address width 39
    [    0.241982] DMAR: DRHD base: 0x000000fed90000 flags: 0x0
    [    0.241988] DMAR: dmar0: reg_base_addr fed90000 ver 4:0 cap 1c0000c40660462 ecap 29a00f0505e
    [    0.241989] DMAR: DRHD base: 0x000000fed91000 flags: 0x1
    [    0.241992] DMAR: dmar1: reg_base_addr fed91000 ver 5:0 cap d2008c40660462 ecap f050da
    [    0.241993] DMAR: RMRR base: 0x0000004c000000 end: 0x000000503fffff
    [    0.241995] DMAR-IR: IOAPIC id 2 under DRHD base  0xfed91000 IOMMU 1
    [    0.241996] DMAR-IR: HPET id 0 under DRHD base 0xfed91000
    [    0.241996] DMAR-IR: Queued invalidation will be enabled to support x2apic and Intr-remapping.
    [    0.243550] DMAR-IR: Enabled IRQ remapping in x2apic mode
    [    0.656374] pci 0000:00:02.0: DMAR: Skip IOMMU disabling for graphics
    [    0.734433] DMAR: No ATSR found
    [    0.734434] DMAR: No SATC found
    [    0.734435] DMAR: IOMMU feature fl1gp_support inconsistent
    [    0.734436] DMAR: IOMMU feature pgsel_inv inconsistent
    [    0.734437] DMAR: IOMMU feature nwfs inconsistent
    [    0.734437] DMAR: IOMMU feature dit inconsistent
    [    0.734438] DMAR: IOMMU feature sc_support inconsistent
    [    0.734438] DMAR: IOMMU feature dev_iotlb_support inconsistent
    [    0.734439] DMAR: dmar0: Using Queued invalidation
    [    0.734442] DMAR: dmar1: Using Queued invalidation
    [    0.734860] DMAR: Intel(R) Virtualization Technology for Directed I/O
    ```

    Take note of the second line where it says `IOMMU enabled`.

5. Now we have to load a few kernel modules to make passthrough fully work. Edit `/etc/modules` and add the following:  
    ```shell
    vfio
    vfio_iommu_type1
    vfio_pci
    ```
6. Now we need to update the initramfs with this command:  
    `update-initramfs -u -k all`

    Reboot your host again.

7. Since we want to use the GPU in a VM we have to make the GPU unavailable for the host. To do so, execute the following command:  
    `echo "options vfio-pci ids=8086:a7a0 disable_vga=1" > /etc/modprobe.d/vfio.conf`  

    > Note: `8086:a7a0` is the PCI Card Address of our GPU we've identified in step 2.

8. The last thing we need to do is to tell proxmox to not load any drivers for the GPU. That's called blacklisting. To blacklist a device's driver execute the following command:  
    `echo "blacklist i915" >> /etc/modprobe.d/blacklist.conf`  

    Reboot your host (the last time).

9. Add the PCI device to your VM. You can do this in the Proxmox GUI by going to your _VM > Add > PCI Device > Raw Device_ and choosing the _PCI Card Address_ from step 2.  
    Boot your VM.

10. ssh into your VM and execute the following command to see the GPU:  
    `sudo lspci -v -d  8086:a7a0`  
    
    The output should look like this:  
    ```shell
    06:10.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)  (prog-if 00 [VGA controller])
            Physical Slot: 16-2
            Flags: bus master, fast devsel, latency 0, IRQ 10
            Memory at 80000000 (64-bit, non-prefetchable) [size=16M]
            Memory at 383800000000 (64-bit, prefetchable) [size=256M]
            I/O ports at 6000 [size=64]
            Expansion ROM at 81020000 [disabled] [size=128K]
            Capabilities: [40] Vendor Specific Information: Len=0c <?>
            Capabilities: [ac] MSI: Enable- Count=1/1 Maskable+ 64bit-
            Capabilities: [d0] Power Management version 2
    ```

    > Note that there is one line missing: There should be some line saying that we're using the i915 driver (`Kernel modules: i915, xe`). If this is your case, follow the next step. If you can see that line, you're done with this guide.

11. Install dkms driver

    ```shell
    # add Intel keyring
    wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
        sudo gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg

    # add the intel repository
    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://   repositories.intel.com/gpu/ubuntu noble client" | \
        sudo tee /etc/apt/sources.list.d/intel-gpu-noble.list

    # update tha package sources and install the driver
    sudo apt update
    sudo apt-get install intel-i915-dkms intel-platform-cse-dkms
    ```

    Reboot your VM.


