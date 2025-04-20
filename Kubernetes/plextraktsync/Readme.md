# plextraktsync

This guide gives you a step by step instruction on how to install plextraktsync.

## Requirements

* RKE2 is already set up and running

## Preparation

No preparartion needed so far.

## Installation

Installation is done via the OCI chart. For configuration adjust the values file before the installation (see next chapter).

```shell
helm install plextraktsync oci://tccr.io/truecharts/plextraktsync \
    --create-namespace \
    --namespace plextraktsync \
    -f ~/Helm/plextraktsync/values.yaml 
```

## Configuration

The possible configuration options can be found in the official [values file][values].

[values]: https://github.com/truecharts/public/blob/master/charts/stable/plextraktsync/values.yaml
