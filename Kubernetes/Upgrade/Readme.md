# Instructions for upgrading your setup

## Recommendations Before Upgrading

1. Snapshot / Backup your VMs!
2. Backup data and volumes if necessary
3. Drain nodes / scale down deployments

## Upgrade Rancher

```shell
helm upgrade rancher rancher-latest/rancher \
 --namespace cattle-system \
 --set hostname=rancher.unserneuesheim.de
```

## Upgrade RKE2 (Each node, not Admin!)

```shell
sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=latest sh -
```

then servers:

```shell
sudo systemctl restart rke2-server
```

or agents

```shell
sudo systemctl restart rke2-agent
```

## Upgrade Longhorn

```shell
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.8.1 \
  --set-string longhornManager.nodeSelector.longhorn="true" \
  --set-string longhornUI.nodeSelector.longhorn="true" \
  --set-string longhornDriver.nodeSelector.longhorn="true"
```

## Upgrade Metallb

1. Change version on the delete command to the version you are currently running (e.g., v0.13.11)
2. Change version on the apply to the new version (e.g., v0.13.12)
3. Ensure your Lbrange is still the one you want (check ipAddressPool.yaml)

```shell
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
kubectl apply -f ipAddressPool.yaml
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/RKE2/l2Advertisement.yaml
```

## Upgrade Kube-VIP

1. Delete the daemonset in Rancher or use kubectl delete
2. Redeploy the daemonset with updated values (check kube-vip file)

```shell
kubectl delete -f kube-vip
kubectl apply -f kube-vip
```

## Upgrade Cert-Manager

```shell
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set-string nodeSelector.worker="true" \
  --set-string webhook.nodeSelector.worker="true" \
  --set-string cainjector.nodeSelector.worker="true" \
  --set-string startupapicheck.nodeSelector.worker="true" \
  --set crds.enabled=true
```
