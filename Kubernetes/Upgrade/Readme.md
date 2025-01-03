# Recommendations Before Upgrading
1. Snapshot / Backup your VMs!
2. Backup data and volumes if necessary
3. Drain nodes / scale down deployments

# Upgrade Rancher
```
helm upgrade rancher rancher-latest/rancher \
 --namespace cattle-system \
 --set hostname=rancher.my.org
```

# Upgrade RKE2 (Each node, not Admin!)
```
sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=latest sh -
```
then servers:
```
sudo systemctl restart rke2-server
```
or agents
```
sudo systemctl restart rke2-agent
```

# Upgrade Longhorn
```shell
# kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/deploy/longhorn.yaml
```
Instead we're using a modified version of the official longhorn.yaml. The only difference is, that we inserted a nodeSelector (three times):  
```yaml
nodeSelector:
  longhorn: "true"
```
The node selector prevents longhorn from installing on our master nodes.
```shell
kubectl apply -f https://raw.githubusercontent.com/martinspaniol/Homelab/refs/heads/main/Kubernetes/Upgrade/longhorn.yaml
```

# Upgrade Metallb
1. Change version on the delete command to the version you are currently running (e.g., v0.13.11)
2. Change version on the apply to the new version (e.g., v0.13.12)
3. Ensure your Lbrange is still the one you want (check ipAddressPool.yaml)
```
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
kubectl apply -f ipAddressPool.yaml
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/RKE2/l2Advertisement.yaml
```

# Upgrade Kube-VIP
1. Delete the daemonset in Rancher or use kubectl delete
2. Redeploy the daemonset with updated values (check kube-vip file)
```
kubectl delete -f kube-vip
kubectl apply -f kube-vip
```
# Upgrade Cert-Manager
```shell
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set-string nodeSelector.worker="true" \
  --set-string webhook.nodeSelector.worker="true" \
  --set-string cainjector.nodeSelector.worker="true" \
  --set-string startupapicheck.nodeSelector.worker="true"
```