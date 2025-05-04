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

I switched my domain provider to IONOS which is supported by cert-manager using [this webhook][IONOS Webhook]. The following steps provide a detailed configuration. You can either use this steps or you can simply **adjust** execute the [deploy.sh-script][def].

### Step 1: Add IONOS webhook helm repo

Add the helm repository for the IONOS webhook and update the sources.

```shell
helm repo add cert-manager-webhook-ionos https://fabmade.github.io/cert-manager-webhook-ionos
helm repo update
```

### Step 2: Install the IONOS webhook

Install the IONOS webhook in the appropriate namespace.

```shell
helm upgrade --install cert-manager-webhook-ionos cert-manager-webhook-ionos/cert-manager-webhook-ionos \
    --set-string nodeSelector.worker="true" \
    --set-string groupName="acme.<YOUR COMPANY NAME.de>" \
    --namespace cert-manager \
    --create-namespace
```

### Step 3: Install the IONOS API authentication information

Create a kubernetes secret which contains the IONOS authentication information. Make sure to replace `IONOS_PUBLIC_PREFIX` with your prefix and `IONOS_SECRET` with your secret before executing. Create those using the [IONOS API page][IONOS API].

```shell
kubectl create secret generic cert-manager-webhook-ionos \
    --namespace=cert-manager \
    --from-literal=IONOS_PUBLIC_PREFIX=<your-public-key> \
    --from-literal=IONOS_SECRET=<your-private-key>
```

<!-- apiVersion: v1
stringData:
  IONOS_PUBLIC_PREFIX: <your-public-key>
  IONOS_SECRET: <your-private-key>
kind: Secret
metadata:
  name: ionos-secret
  namespace: cert-manager
type: Opaque -->

### Step 4: Configure the cert-manager ClusterIssuer for staging and production

Create a staging ClusterIssuer for IONOS. Make sure to replace `<example@example.com>` with your email address before executing.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-ionos-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: <example@example.com>
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-ionos-staging-key
    # Enable the dns01 challenge provider
    solvers:
      - dns01:
          webhook:
            groupName: acme.<YOUR COMPANY NAME.de>
            solverName: ionos
            config:
              apiUrl: https://api.hosting.ionos.com/dns/v1
              publicKeySecretRef:
                key: IONOS_PUBLIC_PREFIX
                name: cert-manager-webhook-ionos
              secretKeySecretRef:
                key: IONOS_SECRET
                name: cert-manager-webhook-ionos
```

Create a production ClusterIssuer for IONOS. Make sure to replace `<example@example.com>` with your email address before executing.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-ionos-production
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: <example@example.com>
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-ionos-prod
    # Enable the dns01 challenge provider
    solvers:
      - dns01:
          webhook:
            groupName: acme.<YOUR COMPANY NAME.de>
            solverName: ionos
            config:
              apiUrl: https://api.hosting.ionos.com/dns/v1
              publicKeySecretRef:
                key: IONOS_PUBLIC_PREFIX
                name: cert-manager-webhook-ionos
              secretKeySecretRef:
                key: IONOS_SECRET
                name: cert-manager-webhook-ionos
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
[IONOS Webhook]: https://github.com/fabmade/cert-manager-webhook-ionos
[IONOS API]: https://developer.hosting.ionos.de/keys
