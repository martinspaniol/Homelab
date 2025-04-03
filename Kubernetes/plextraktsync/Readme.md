# plextraktsync

This guide gives you a step by step instruction on how to install plextraktsync.

## Requirements

* RKE2 is already set up and running

## Preparation

Add the necessary helm repository:

```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

## Installation

Installation is done via the OCI chart. For configuration adjust the values file before the installation (see next chapter).

```shell
helm install plextraktsync oci://tccr.io/truecharts/plextraktsync \
    -f ~/Helm/plextraktsync/values.yaml 
```

## Configuration

The possible configuration options can be found in the official [values file][values].

[values]: https://github.com/truecharts/public/blob/master/charts/stable/plextraktsync/values.yaml
