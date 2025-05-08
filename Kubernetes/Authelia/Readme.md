# Using Authelia in Kubernetes

[Authelia][Authelia Homepage] is an open-source authentication and authorization server and portal fulfilling the identity and access management (IAM) role of information security in providing multi-factor authentication and single sign-on (SSO) for applications via a web portal.

This guide describes the setup of Authelia using the [Proxmox Community Script][Proxmox Authelia Community Script].

## Installation

### Step 1: Install Authelia

Install Authelia as described on the [Proxmox Community Script][Proxmox Authelia Community Script] page. I used all default settings. During the setup you need to provide a domain for authelia (e.g. domain.com) to use. After the installation you can access authelia only using auth.domain.com.

### Step 2: Add an ingress in traefik to access Authelia

Using traefik as ingress controller in a kubernetes cluster requires the setup of an ingress for Authelia. Use and adjust the provided [ingress.yaml](./Helm/Authelia/ingress.yaml) file and apply it to your cluster:

```shell
kubectl apply -f <PATH/TO/YOUR/ingress.yaml>
```

After that you should be able to access authelia using auth.<YOURDOMAIN>.

## Configuration



[Authelia Homepage]: https://www.authelia.com
[Proxmox Authelia Community Script]: https://community-scripts.github.io/ProxmoxVE/scripts?id=authelia