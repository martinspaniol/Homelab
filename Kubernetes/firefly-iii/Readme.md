# Firefly-III on Kubernetes

This guide gives you a step by step instruction on how to deploy Firefly-III on Kubernetes. I'm basically following the [official guide][official guide] from the Firefly team. Detailes instructions can be found in the [charts directory][charts directory].

## Prerequisites

* RKE2 is already setup and running

## Installation

### Step 1: Install the necessary helm repo

Execute the following line to install the helm repo and update the sources:

```shell
helm repo add firefly-iii https://firefly-iii.github.io/kubernetes/
helm repo update
```

### Step 2: Configure the values.yaml

> Note: Since we're deploying the `firefly-iii-stack` which acts as a wrapper around the other charts, every setting in values.yaml needs to be in the respective key, i.e. `firefly-iii.config` for the config values of the firefly-iii chart.

### Step 3: Create firefly-iii namespace and apply secrets

```shell
kubectl create namespace firefly-iii
kubectl apply $(ls ~/Helm/firefly-iii/*-secret.yaml | awk ' { print " -f " $1 } ')
```

### Step 4: Install Firefly-III

Execute the following line to install firefly-iii:

```shell
helm install firefly-iii firefly-iii/firefly-iii-stack \
    -f ~/Helm/firefly-iii/values.yaml \
    --create-namespace \
    --namespace firefly-iii
```

[bundesbank-PAN]: https://www.bundesbank.de/dynamic/action/de/startseite/suche/bankleitzahlen-suche/747634/bankleitzahlen
[FinTS Suche]: https://subsembly.com/banken.html
[official guide]: https://firefly-iii.github.io/kubernetes/
[charts directory]: https://github.com/firefly-iii/kubernetes/tree/main/charts