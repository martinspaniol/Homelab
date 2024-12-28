# Introduction

# Instructions
## rclone config
1. Install the latest version of rclone
`sudo -v ; curl https://rclone.org/install.sh | sudo bash`

2. Create a new rclone configuration  
`rclone config`  
rclone configurations will be stored in `~/.config/rclone/rclone.conf`.

3. Press `n` to create a new remote.

4. Enter the name of the remote connection, i.e. `diskstation-media`.

5. Select the type of storage to configure. For SMB select 46 or enter `smb`.

6. Enter the hostname of the SMB server, i.e. `diskstation.fritz.box`.

7. Enter the SMB username, i.e. 

8. Port number, default port for SMB is 445.

9. Enter the SMB password. Confirm the password.

10. Enter the domain name (optional) or skip.

11. Enter a service principal name (optional) or skip.

12. Edit advanced configuration (optional) or skip.

13. To keep this configuration press `y`.

14. Quit the configuration mode with `q`.

Your generated rclone configuration file should look like this:  
```shell
[diskstation-media]
type = smb
host = diskstation.fritz.box
user = plex
pass = hobcz9hmjUob02z2YVPEX6iGg8Gswa-kejsdM0pO-7DVU3QKZWFeKhtjLK_ANwmn
```

15. The rclone configuration must be stored as a secret in Kubernetes. To do so create a `rclone-config.yaml` file in the templates directory with the following content:  
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: rclone-config
type: Opaque
stringData:
  rclone.conf: |
    [diskstation-media]
    type = smb
    host = diskstation.fritz.box
    user = plex
    pass = hobcz9hmjUob02z2YVPEX6iGg8Gswa-kejsdM0pO-7DVU3QKZWFeKhtjLK_ANwmn
```

16. Adjust the rclone-configuration in the `values.yaml` file:  
```yaml
rclone:
    # ...
    remotes:
        - "diskstation-media:/media" # /media is the name of the smb share, diskstation-media is the config name within rlcone.conf
```

## Migrate an existing plex installation
If you have an existing plex installation and you want to migrate the configuration you need to follow these steps.

> Note: These instructions are initially posted from the plex team [here](https://www.plex.tv/blog/plex-pro-week-23-a-z-on-k8s-for-plex-media-server/).  
All of the following command need to be executed just once in order to migrate an existing plex installation.

1. Open your existing plex server and disable the [empty trash setting](https://support.plex.tv/articles/200289326-emptying-library-trash/).

2. Stop your plex server.

3. Create a backup of your plex database. In my case my existing plex server is running in docker on my Synology NAS and the configuration directory _/config_ is mounted via a docker-compose file from _/volume1/docker/medialib/plex_.  
So ssh into your NAS, become root, switch to the above directory and create a tarball using  
`tar -cvf <SOME DIRECTORY>/pms.tar .`

4. The plex backup needs to be available in the new kubernetes plex instance. We can use the initContainer script to achieve that. Mount the folder where you saved the _pms.tar_ file to your worker node using the following commands:  
```shell
sudo mkdir /mnt/pms-backup
sudo mount -t cifs //<IP OF YOUR NAS>/<SOME DIRECTORY> /mnt/pms-backup -o username=plex,password="<YOUR PASSWORD HERE>"
```

5. Adjust the following lines in the `values.yaml` file:  
```yaml
initContainer:

  # ...

  script: |-
    #!/bin/sh
    echo "fetching pre-existing pms database to import..."
  
    if [ -d "/config/Library" ]; then
      echo "PMS library already exists, exiting."
      exit 0
    fi
  
    echo "No existing PMS library found."

    while [ ! -f /mnt/pms-backup/pms.tar ]; do
      echo "Waiting for the database archive to be available..."
      sleep 2
    done

    echo "pms.tar file available."
    echo "Creating Library folder"
    mkdir -p /config/Library

    echo "Extracting pms.tar file"
    tar -xf /mnt/pms-backup/pms.tar -C /config/Library

    echo "Done."

# ...

extraVolumeMounts:
  - name: pms-backup
    mountPath: /mnt/pms-backup

# ...

extraVolumes:
  - name: pms-backup
    hostPath:
      path: /mnt/pms-backup
      type: Directory
``` 
The _extraVolumeMounts_ variable specifies that we want to mount the directory to our init and pms container (although the init container would be sufficient). With _extraVolumes_ we create the necessary mount points for that. Finally if there is not already an existing plex library, the script will extract the _pms.tar_ file from the location you provided to _/config/Library_.