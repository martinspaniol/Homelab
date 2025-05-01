# Traefik

This guide gives you a step by step instruction on how to install Traefik including its Dashboard, Cert-Manager (for certificates) and an Issuer (Let's Encrypt) for SSL certificates.

## Requirements

* RKE2 is already set up and running

## Installation

The initial installation was done with the [deploy.sh-Script][def] by [JimsGarage][def2]. In that script all components are installed by applying .yaml-files to your kubernetes cluster. I strongly recommend watching his [video][def3] for further explanations.  
Since I prefer the use of helm charts, I switched my installation to helm. See the [Upgrade-Guide](../Upgrade/Readme.md) for details.

## Configuration

The following steps my be done after the initial installation.

~~The default cluster issuer does not support [INWX][def4] which is my DNS provider. Fortunately we can use [this][def5] helm chart to make it work. See Step 11 in the [deploy.sh-script][def].~~

I switched my domain provider to IONOS which is supported by cert-manager using [this webhook][def6]. The following steps provide a detailed configuration. You can either use this steps or you can simply **adjust** execute the [deploy.sh-script][def].

### Step 1: Add IONOS webhook helm repo

Add the helm repository for the IONOS webhook and update the sources.

```shell
helm repo add cert-manager-webhook-ionos-cloud https://ionos-cloud.github.io/cert-manager-webhook-ionos-cloud
helm repo update
```

### Step 2: Install the IONOS webhook

Install the IONOS webhook in the appropriate namespace.

```shell
helm upgrade --install cert-manager-webhook-ionos-cloud cert-manager-webhook-ionos-cloud/cert-manager-webhook-ionos-cloud \
    --namespace cert-manager
    --create-namespace
```

### Step 3: Install the IONOS cloud authentication token secret

Create a kubernetes secret which contains the IONOS cloud authentication token. Make sure to replace `<IONOS CLOUD AUTH TOKEN>` with your token before executing.

```shell
kubectl create secret generic cert-manager-webhook-ionos-cloud \
    --namespace=cert-manager \
    --from-literal=auth-token=<IONOS CLOUD AUTH TOKEN>
```

### Step 4: Configure the cert-manager ClusterIssuer

Create a ClusterIssuer for IONOS. Make sure to replace `<example@example.com>` with your email address before executing.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <example@example.com> # Replace this with your email address
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - dns01:
        webhook:
          solverName: ionos-cloud
          groupName: acme.ionos.com
          config:
            #optional, defaults to cert-manager-webhook-ionos-cloud
            secretRef: cert-manager-webhook-ionos-cloud
            #optional, defaults to auth-token
            authTokenSecretKey: auth-token
```

Save the above statements as a .yaml-file and apply the file to your kubernetes cluster using `kubectl`:

```shell
kubectl apply -f <PATH TO YOUR YAML FILE>.yaml
```



[def]: ./deploy.sh
[def2]: https://github.com/JamesTurland/JimsGarage
[def3]: https://www.youtube.com/watch?v=XH9XgiVM_z4&pp=ygUSamltc2dhcmFnZSB0cmFlZmlr
[def4]: https://www.inwx.de
[def5]: https://gitlab.com/smueller18/cert-manager-webhook-inwx
[def6]: https://github.com/ionos-cloud/cert-manager-webhook-ionos-cloud/tree/main/chart/cert-manager-webhook-ionos-cloud
