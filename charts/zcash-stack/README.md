[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zcash)](https://artifacthub.io/packages/search?repo=zcash)

# Zcash Stack Helm Chart

This chart enables the reliable deployment of Zcash infrastructure on Kubernetes.

We run this using K3s on self-hosted hardware and on Vultr Kubernetes Engine. This chart is also tested on GKE Autopilot as an integration test.

All of the "zec.rocks" lightwalletd servers are provisioned using this chart, and are load balanced using HAProxy on Fly.io. Refer to the [zecrocks repository](https://github.com/zecrocks/zecrocks) for the source code to our load balancing approach.

This project is funded by [Zcash Community Grants](https://zcashcommunitygrants.org/). Progress updates are posted to a [thread on the Zcash Community Forum](https://forum.zcashcommunity.com/t/rfp-zcash-lightwalletd-infrastructure-development-and-maintenance/47080).

## Prerequisites

1. A running Kubernetes cluster (this is currently tested on Vultr Kubernetes Engine)
2. The KUBECONFIG env variable set to your cluster's Kubernetes credentials file
3. Helm installed in your local environment

## Usage

1. Traefik is required to auto-provision LetsEncrypt SSL certificates.

    a. Edit ```install-traefik.sh``` to specify your real email address.

    b. Install Traefik on your cluster:

```
chmod +x install-traefik.sh
./install-traefik.sh
```

2. Edit an example values file from the ```./examples``` folder. Specify the domain name that you intend to host a lightwalletd instance on. View the ```values.yaml``` file to see all of the configuration options possible.

3. Add the zcash-stack Helm repository to your environment:

```
helm repo add zcash https://zecrocks.github.io/zcash-stack
helm repo update
```

4. Install the chart on your cluster: (specify your own yaml file if you did not modify an example in-place)

```
helm install zcash zcash/zcash-stack -f examples/zebra-mainnet.yaml
```

### Upgrading

We highly recommend installing the "helm-diff" plugin.

Pull the latest release of the zcash-stack Helm chart:
```
helm repo update
```

Confirm the name of your node's Helm deployment:
```
KUBECONFIG=~/.kube/config-eu1 helm list
```

Verify changes before you upgrade: (in this example, the chart was installed as "zec-eu1")
```
KUBECONFIG=~/.kube/config-eu1 helm diff upgrade zec-eu1 zcash/zcash-stack -f ./values-eu1.yaml
```

Then apply the upgrade:
```
KUBECONFIG=~/.kube/config-eu1 helm upgrade zec-eu1 zcash/zcash-stack -f ./values-eu1.yaml
```

### Kubernetes Cheat Sheet

If you're new to Kubernetes, here is a list of commands that you might find useful for operating this chart:

```
# See what is running in your cluster's default namespace
kubectl get all

# Watch logs
kubectl logs -f statefulset/lightwalletd
kubectl logs -f statefulset/zebra
kubectl logs -f statefulset/zcashd

# Open a shell in a running container
kubectl exec statefulset/zebra -ti -- bash

# Restart a part of the stack
kubectl rollout restart statefulset/lightwalletd
kubectl rollout restart statefulset/zebra
kubectl rollout restart statefulset/zcashd

# View the public IPs provisioned by Traefik
kubectl get service -n traefik
```

## Works in progress

- Updated documentation to launch on AWS, GCP, and self-hosted (k3s)
- Support for hosting a block explorer
- Support for Zaino indexing service
- Contribute to the P2P network by allowing inbound connections via a Kubernetes Service, only possible on Zcashd at the moment.
