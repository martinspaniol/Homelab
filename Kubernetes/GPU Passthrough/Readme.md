# Introduction

This guide will give you step by step instructions on how to passthrough a GPU into your RKE2 Cluster, to share it with multiple containers.

## Requirements

* You already followed [this guide](../../GPU%20Passthrough/Readme.md) to enable GPU passthrough to a proxmox VM. Your GPU is already visible inside the proxmox VM.

## Instructions

On the [Intel device plugin for Kubernetes](https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html) website, Intel provides the necessary configuration files for passing an Intel GPU to Kubernetes.  

There are two differend methods available (in my case):

1. Pass the GPU to a single container  
    or
2. Pass the GPU to multiple containers.

You can install the device plugins using a helm chart. On [this](https://intel.github.io/intel-device-plugins-for-kubernetes/INSTALL.html) page Intel summarizes the installation methods you can use. For installation using helm charts follow these steps:

### Add helm repositories

First we need to add the necessary helm repositories:

```shell
helm repo add jetstack https://charts.jetstack.io # for cert-manager, should be already there
helm repo add nfd https://kubernetes-sigs.github.io/node-feature-discovery/charts # for NFD
helm repo add intel https://intel.github.io/helm-charts/ # for device-plugin-operator and plugins
helm repo update
```

### Installing cert-manager (usually already done)

This is already done during the basic installation of rke2, so you may skip this step

```shell
helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.16.2 \
    --set crds.enabled=true
```

### Installing NFD

Node Feature Discovery (NFD in short) discovers the features of you kubernetes nodes. It's necessary to detect that a node actually has a GPU resource available. We need to install this:

```shell
helm install \
    nfd nfd/node-feature-discovery \
    --namespace node-feature-discovery \
    --create-namespace
```

### Installing operator

The Intel Device Plugins Operator makes it easier for us handling the different Intel Device Plugins (yes, there's more than one plugin available, depending on what you want to do). We need to install this as well:

```shell
helm install \
    dp-operator intel/intel-device-plugins-operator \
    --namespace inteldeviceplugins-system \
    --create-namespace
```

### Installing specific plugins

With the Operator installed, we can install a specific device plugin. Replace `PLUGIN` with the desired plugin name. At least the following plugins are supported: `gpu`, `sgx`, `qat`, `dlb`, `dsa` and `iaa`.

```shell
helm install \
    <PLUGIN> intel/intel-device-plugins-<PLUGIN> \
    --namespace inteldeviceplugins-system \
    --create-namespace \
    --set nodeFeatureRule=true
```

#### Customizing plugins

To customize plugin features, we can take a look at the available chart values:

```shell
helm show values intel/intel-device-plugins-<PLUGIN>
```

For example, gpu plugin has these values:

```yaml
name: gpudeviceplugin-sample

image:
  hub: intel
  tag: ""

initImage:
  enable: false
  hub: intel
  tag: ""

sharedDevNum: 1 # < we can change this value to allow more than 1 container using the gpu at the same time
logLevel: 2
resourceManager: false
enableMonitoring: true
allocationPolicy: "none"

nodeSelector:
  intel.feature.node.kubernetes.io/gpu: 'true'

tolerations:

nodeFeatureRule: true
```

In my case the installation command will be as follows:

```shell
helm install \
    gpu intel/intel-device-plugins-gpu \
    --namespace inteldeviceplugins-system \
    --create-namespace \
    --set nodeFeatureRule=true \
    --set sharedDevNum=30 # < this allows that 30 PODs on the same node can request a GPU
```

### Verfiy the installation

To verfify the installation you can execute the following command to get all nodes with a gpu dicovered:  
`kubectl get nodes -o=jsonpath="{range .items[*]}{.metadata.name}{'\n'}{' i915: '}{.status.allocatable.gpu\.intel\.com/i915}{'\n'}"`

The output should look like this:

```yaml
longhorn-01
 i915:
longhorn-02
 i915:
longhorn-03
 i915:
rke2-01
 i915:
rke2-02
 i915:
rke2-03
 i915:
rke2-04
 i915: 30 # < this is what we're looking for
rke2-05
 i915: 30 # < this is what we're looking for
```

### Listing available versions

To list all available versions of the operator as well as each plugin, use these commands.

```shell
helm search repo intel/intel-device-plugins-operator --versions
helm search repo intel/intel-device-plugins-<plugin> --versions
```

### Upgrading the operator and plugins

The upgrade of the deployed plugins can be done by simply installing a new release of the operator.

The operator auto-upgrades operator-managed plugins (CR images and thus corresponding deployed daemonsets) to the current release of the operator.

## Request a GPU in your deployments

To request a GPU in your deployments you can use the `resources` entries in your `values.yaml` file. For example in [values.yaml file of the plex deployment](../GitOps/Plex%20Media%20Server/values.yaml) I've specified the following:

```yaml
pms:
  # ...
  resources:
    limits:
      gpu.intel.com/i915: "1"
    requests:
      gpu.intel.com/i915: "1"
```

With these settings the gpu device plugin will look for available resources for this deployment and place it on a appropriate node.
