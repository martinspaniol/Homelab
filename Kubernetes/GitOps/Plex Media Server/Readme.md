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
1. Open your existing plex server and disable the [empty trash setting](https://support.plex.tv/articles/200289326-emptying-library-trash/).

2. Stop your plex server.

3. Create a backup of your plex database. In my case my existing plex server is running in docker on my Synology NAS and the configuration directory _/config_ is mounted via a docker-compose file from _/volume1/docker/medialib/plex_.  
So ssh into your NAS, become root, switch to the above directory and create a tarball using  
`tar -cvf <SOME DIRECTORY>/pms.tar .`

4. The plex backup needs to be available in the new kubernetes plex instance. We can use the initContainer script to achieve that. Upload your _pms.tar_ file to a http-available location (like Onedrive). Then adjust the following lines in the `values.yaml` file:  
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

    echo "Installing curl"
    apk --update add curl

    echo "Downloading pms.tar file"
    curl http://example.com/pms.tar -o /pms.tar

    echo "pms.tar file available."
    echo "Creating Library folder"
    mkdir -p /config/Library

    echo "Extracting pms.tar file"
    tar -xvf /pms.tar -C /config/Library

    echo "Deleting downloaded pms.tar file"
    rm /pms.tar
  
    echo "Done."
``` 
If there is not already an existing plex library, this script will download the _pms.tar_ file from the location you provoded. Then the content of this file is extracted to _/config/Library_.