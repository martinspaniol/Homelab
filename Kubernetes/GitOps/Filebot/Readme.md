# Introduction

This guide will give you step by step instructions on how to setup a Filebot on your RKE2 Cluster.

# Prerequisites
I assume you fullfill these prerequesites:
* RKE2 is already setup and running
* You're using traefik and it's setup and running as well

# Instructions
## rclone config
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
    ```
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
      # if the rclone sidecar should be created
      enabled: true

      # ...
      
      remotes:
          - "diskstation-media:/media" # /media is the name of the smb share, diskstation-media is the config name within rlcone.conf
    ```

## Additional configurations

We need to make some additional configurations to prepare the deployment for our environment:

1. In the `values.yaml` file adjust the `nodeSelector`, so filebot will only run on your worker nodes:

    ```yaml
    nodeSelector:
      worker: "true"
    ```

2. Since we're deploying with fleet, create a `fleet.yaml` file with the following content:

    ```yaml
    # This file and all contents in it are OPTIONAL.
    
    # The namespace this chart will be installed and restricted to,
    # if not specified the chart will be installed to "default"
    namespace: filebot # adjust this to the namespace you wish
    
    # Custom helm options
    helm:
      # The release name to use. If empty a generated release name will be used
      releaseName: filebot
    
      # The directory of the chart in the repo.  Also any valid go-getter supported
      # URL can be used there is specify where to download the chart from.
      # If repo below is set this value is the chart name in the repo
      chart: ""
    
      # An https to a valid Helm repository to download the chart from
      repo: ""
    
      # Used if repo is set to look up the version of the chart
      version: ""
    
      # Force recreate resource that can not be updated
      force: false
    
      # How long for helm to wait for the release to be active. If the value
      # is less that or equal to zero, we will not wait in Helm
      timeoutSeconds: 0
    
      # Custom values that will be passed as values.yaml to the installation
      values:
        replicas: 1
    ```

3. Since we're using traefik we need an ingress for plex so we can reach it. Create a `ingress.yaml` file in the templates folder with the following content:

    ```yaml
    ---
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: plex
      annotations: 
        kubernetes.io/ingress.class: traefik-external
    spec:
      entryPoints:
        - websecure
      routes:
        - match: Host(`www.plex.unserneuesheim.de`) # change to your domain
          kind: Rule
          services:
            - name: {{ include "pms-chart.fullname" . }}
              port: 32400
        - match: Host(`plex.unserneuesheim.de`) # change to your domain
          kind: Rule
          services:
            - name: {{ include "pms-chart.fullname" . }}
              port: 32400
          middlewares:
            - name: default-headers
      tls:
        secretName: unserneuesheim-tls # change to your cert
    
    ```

    Additionally create a `default-headers.yaml` file in the templates directory with the following content:

    ```yaml
    apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: default-headers
    spec:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 15552000
        customFrameOptionsValue: SAMEORIGIN
        customRequestHeaders:
          X-Forwarded-Proto: https
    ```

## Deploy your code

After everything is setup, deploy your code. Since we're using fleet and configured GitOps, it's as simple as commiting our code to the repository. Fleet will take care of the rest and start deploying our code.  
The init-Container will start first and take some time for extracting the pms library. For me the library is about 29GiB and it took approx. 20 minutes.  
After the extraction is finished, pms boot up successfully and I could reach my plex instance. **YAY!**

## Configure your new plex instance

You should be able to login to your plex instance, still we need to adjust some settings. If you migrated from an old plex instance your media files will probably not play. That's okay and we can fix that.

1. > Optional if you migrated from another plex instance.  

    In plex go to _Settings > Libraries_ and for each library (i.e. movies, tv shows, etc.) **add**     the path to the location where to find the files. **Do not remove the old path yet!** Since we     chose `diskstation-media:/media` in the rclone-configuration, our media files are mounted to `/    data/diskstation-media` inside the pms instance.  
    Let plex scan the path you've added, this will happen automatically. Plex should recognize each     file and associate the new path to it. This may take some minutes to complete.  
    After the scan has finished edit again your libraries and remove the old path from each. Plex     will again scan the path but this will just take a few seconds. 

2. Change the friendly name of your plex server if you want to. Go to _Settings > General_ and choose a friendly name.

3. Probably your network settings might have changed. Go to _Settings > Network_ and adjust the _LAN Networks_ and also the _Custom server access URLs_.

4. > Optional if you migrated from another plex instance.  

    Turn on [empty trash setting](https://support.plex.tv/articles/200289326-emptying-library-trash/) again.

## Configure traefik

If you followed the above steps you may notice when playing some media from an external connection (like your mobile phone), plex will always think that this traffic comes from an internal ip address. Bandwidth restrictions and other settings for remote connections may not apply. This is because traefik is not forwarding your external IP adress to your plex instance.  
To fix that we need to adjust the `values.yaml` file for traefik (**not** for plex!). You find this file in this repository [here](../../Traefik/Helm/Traefik/values.yaml). Add `externalTrafficPolicy: Local` to the service configuration:

```yaml
service:
  # ...
  spec:
    externalTrafficPolicy: Local # Preserve the client IP
```
Save this change to `~/Helm/Traefik/values.yaml` on your rke2-admin VM and apply it by executing the following command:  
`helm upgrade --namespace=traefik traefik traefik/traefik -f ~/Helm/Traefik/values.yaml`

You can check if that worked with that command:  
`kubectl describe svc traefik -n traefik`
The result should be this:  
```yaml
Name:                     traefik
Namespace:                traefik
Labels:                   app.kubernetes.io/instance=traefik-traefik
                          app.kubernetes.io/managed-by=Helm
                          app.kubernetes.io/name=traefik
                          helm.sh/chart=traefik-33.2.1
Annotations:              field.cattle.io/publicEndpoints:
                            [{"addresses":["192.168.0.180"],"port":80,"protocol":"TCP","serviceName":"traefik:traefik","allNodes":false},{"addresses":["192.168.0.180"...
                          kube-vip.io/loadbalancerIPs: 192.168.0.180
                          meta.helm.sh/release-name: traefik
                          meta.helm.sh/release-namespace: traefik
                          metallb.io/ip-allocated-from-pool: first-pool
Selector:                 app.kubernetes.io/instance=traefik-traefik,app.kubernetes.io/name=traefik
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.93.192
IPs:                      10.43.93.192
Desired LoadBalancer IP:  192.168.0.180
LoadBalancer Ingress:     192.168.0.180 (VIP)
Port:                     web  80/TCP
TargetPort:               web/TCP
NodePort:                 web  30607/TCP
Endpoints:                10.42.3.26:8000,10.42.4.33:8000
Port:                     websecure  443/TCP
TargetPort:               websecure/TCP
NodePort:                 websecure  31254/TCP
Endpoints:                10.42.3.26:8443,10.42.4.33:8443
Session Affinity:         None
External Traffic Policy:  Local # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<< look for this!
Internal Traffic Policy:  Cluster
HealthCheck NodePort:     30721
Events:                   <none>
```

Now you can try to watch some media from an external connection again. Plex should report that your connection is indeed external and apply all restrictions to it (bandwidth limitation, transcoding, etc.).

## Cleanup after deployment

If you've migrated from an old plex instance, we need to clean up a few things after the first startup and configuration of plex. 

1. To remove the mount for the old plex library adjust your `values.yaml` file and comment out the `extraVolumeMounts` and `extraVolumes`. 

    ```yaml
    # Optionally specify additional volume mounts for the PMS and init containers.
    extraVolumeMounts: []
    # extraVolumeMounts:
    #   - name: pms-backup
    #     mountPath: /mnt/pms-backup
    
    # Optionally specify additional volumes for the pod.
    extraVolumes: []
    # extraVolumes:
    #   - name: pms-backup
    #     hostPath:
    #       path: /mnt/pms-backup
    #       type: Directory
    ```

    Commit these changes. Fleet will automatically redeploy everything and the mount should be gone. To check that, ssh into your rke2-admin VM and execute the following command:  

    ```shell
    kubectl exec -it plex-plex-media-server-0 -n plex --container plex-plex-media-server-pms -- sh
    ```

    This will open a shell in the pms container `plex-plex-media-server-pms` which is inside the pod `plex-plex-media-server-0` within the namespace `plex`. Note that `/mnt/pms-backup` should not be available anymore.

2. Remove the mount from your worker nodes. ssh into each node and execute the following command:  
`sudo umount /mnt/pms-backup` and `sudo rm -r /mnt/pms-backup`.

3. Finally (and if you're sure that everything is working) you can delete your old plex instance and the _pms.tar_ file wherever you saved it.