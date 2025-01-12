# Welcome to my Homelab setup

Hi there! This repository contains all information, guides, links and explanations on how I set up my homelab.

Note, that this is a living repo, it will change and grow constantly as I add more features or improve configurations.

## My setup

At the time of writing my homelab consists mainly of these components:

* Hardware:
  * 1 x [Minisforum MS-01][HV]
    * [Intel Core i9-13900H][CPU]
    * 2 x [Crucial 48GB DDR5-5600 SODIMM][RAM]
    * 2 x [WD BLACK SN770 1 TB][BOOT-DISK] as boot disk
  * [Synology DiskStation DS1515+][NAS]
    * 2 x Intel SSD 730 Series SSDSC2BP480G4 480GB as RAID1 Write Cache
    * 3 x [WD Red Plus HDD 6TB][HDD] as RAID5 Datastore
* Virtualization: Proxmox running on the MS-01
* Container Environment: RKE2 running on multiple VMs in Proxmox

[HV]: https://minisforumpc.eu/en/products/ms-01?variant=42097212555447
[CPU]: https://www.intel.de/content/www/de/de/products/sku/232135/intel-core-i913900h-processor-24m-cache-up-to-5-40-ghz/specifications.html
[RAM]: https://www.crucial.de/memory/ddr5/CT48G56C46S5
[BOOT-DISK]: https://shop.sandisk.com/de-de/products/ssd/internal-ssd/wd-black-sn770-nvme-ssd?sku=WDS100T3X0E-00B3N0
[NAS]: https://global.synologydownload.com/download/Document/Hardware/DataSheet/DiskStation/15-year/DS1515+/enu/Synology_DS1515_Plus_Data_Sheet_enu.pdf
[HDD]: https://www.westerndigital.com/products/internal-drives/wd-red-plus-sata-3-5-hdd?sku=WD60EFPX
