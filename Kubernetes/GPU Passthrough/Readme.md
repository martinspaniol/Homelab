# Introduction
This guide will give you step by step instructions on how to passthrough a GPU into your RKE2 Cluster, to share it with multiple containers.

# Requirements
* You already followed [this guide](../../GPU%20Passthrough/Readme.md) to enable GPU passthrough to a proxmox VM. Your GPU is already visible inside the proxmox VM.

# Instructions
## Install Intel Device Plugin Operator
```shell
helm repo add intel https://intel.github.io/helm-charts/
helm repo update
```
Install the Operator:
`helm install device-plugin-operator intel/intel-device-plugins-operator [flags]`


On the [Intel device plugin for Kubernetes](https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html) website, Intel provides the necessary configuration files for passing an Intel GPU to Kubernetes.  

There are two differend methods available (in my case):
1. Pass the GPU to a single container  
    or
2. Pass the GPU to multiple containers.

## Option 1: Pass the GPU to a single container
If you want to go for option 1, just execute these lines from your rke2-admin VM. Replace the `<RELEASE_VERSION>` with the desired [release tag](https://github.com/intel/intel-device-plugins-for-kubernetes/tags). As of writing the latest release is `v0.31.1`.

```shell
# Start NFD - if your cluster doesn't have NFD installed yet
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd?ref=<RELEASE_VERSION>'

# Create NodeFeatureRules for detecting GPUs on nodes
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd/overlays/node-feature-rules?ref=<RELEASE_VERSION>'

# Create GPU plugin daemonset
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes?ref=<RELEASE_VERSION>'
```

## Option 2: Share the GPU with multiple containers

If you want to share the GPU with multiple containers you have to head over to the [advanced installation](https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/advanced-install.html) page. There you have a slightly different set of configuration files, but the steps are basically the same. Again replace the `<RELEASE_VERSION>` with the desired [release tag](https://github.com/intel/intel-device-plugins-for-kubernetes/tags) and execute these commands on your rke2-admin VM:

```shell
# Start NFD - if your cluster doesn't have NFD installed yet
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd?ref=v0.31.1'

# Create NodeFeatureRules for detecting GPUs on nodes
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd/overlays/node-feature-rules?ref=v0.31.1'

# Create GPU plugin daemonset
$ kubectl apply -k 'https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/monitoring_shared-dev_nfd/?ref=v0.31.1'
```

To verfify the installation you can execute the following command to get all nodes with a gpu dicovered:  
`kubectl get nodes -o=jsonpath="{range .items[*]}{.metadata.name}{'\n'}{' i915: '}{.status.allocatable.gpu\.intel\.com/i915}{'\n'}"`

kubectl get no -o json | jq ".items[].metadata.labels"