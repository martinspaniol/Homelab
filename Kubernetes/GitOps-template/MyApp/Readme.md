# Introduction

Use this as a template for a deployment in the [GitOps folder](../../GitOps/). Adjust all variables as needed:

## [fleet.yaml][def]

* namespace (i.e. makemkv, must be lowercase)
* helm > releaseName (i.e. makemkv)

## [Chart.yaml][def2]

* `name` (i.e. makemkv)
* `description` (i.e. A Helm chart for deploying a MakeMKV to a kubernetes cluster)
* `keywords` (i.e. MakeMKV, DVDRipper, ...)
* `home` (i.e. <https://www.makemkv.com/>)
* `icon` (i.e. <https://www.makemkv.com/favicon.ico>)
* `version` (the version of the chart, NOT the version of the application, i.e. 0.1.0)
* `appVersion` (the version of the application, i.e. "1.17.8")
* `sources` (i.e. <https://github.com/jlesage/docker-makemkv>)

## [values.yaml][def3]

At least the following values have to be set.

* image > repository (i.e. jlesage/makemkv)
* app
  * configStorage (i.e. 1Gi)
  * port (i.e. 5800)

## [rclone-config.yaml][def4]

Create the rclone-configuration and save it to the file. You can follow this guide:

<details>

    <summary>Create rclone configuration</summary>

### Create rclone configuration

1. Install the latest version of rclone
`sudo -v ; curl https://rclone.org/install.sh | sudo bash`

2. Create a new rclone configuration  
`rclone config`  
rclone configurations will be stored in `~/.config/rclone/rclone.conf`.

3. Press `n` to create a new remote.

4. Enter the name of the remote connection, i.e. `diskstation-media`.

5. Select the type of storage to configure. For SMB select `46` or enter `smb`.

6. Enter the hostname of the SMB server, i.e. `diskstation.fritz.box`.

7. Enter the SMB username, i.e. `plex`

8. Port number, default port for SMB is `445`.

9. Enter the SMB password. Confirm the password.

10. Enter the domain name (optional) or skip.

11. Enter a service principal name (optional) or skip.

12. Edit advanced configuration (optional) or skip.

13. To keep this configuration press `y`.

14. Quit the configuration mode with `q`.

    Your generated rclone configuration file should look like this:  

    ```ini
    [diskstation-media]
    type = smb
    host = diskstation.fritz.box
    user = plex
    pass = hobcz9hmjUob02z2YVPEX6iGg8Gswa-kejsdM0pO-7DVU3QKZWFeKhtjLK_ANwmn
    ```

15. The rclone configuration must be stored as a secret in Kubernetes. To do so create a `rclone-config.yaml` file in the templates directory with the following content:

    ```yaml
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
      # if the rclone sidecar should be created
      enabled: true

      # ...
      
      remotes:
          - "diskstation-media:/media" # /media is the name of the smb share, diskstation-media is the config name within rlcone.conf
    ```

</details>

[def]: ./fleet.yaml
[def2]: ./Chart.yaml
[def3]: ./values.yaml
[def4]: ./templates/rclone-config.yaml
