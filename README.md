[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zcash)](https://artifacthub.io/packages/search?repo=zcash)

# Zcash Stack

This repository contains tools and documentation for deploying and managing Zcash infrastructure using Docker and Kubernetes.

## Workshop Notes

The workshop documentation is organized into three main classes:

- [Class 1: Sync Week](docs/class-1-sync-week.md) - Learn how to set up and sync a Zcash node
- [Class 2: Connect Week](docs/class-2-connect-week.md) - Connect your node to the Zcash network
- [Class 3: Monitor Week](docs/class-3-monitor-week.md) - Monitor and maintain your Zcash infrastructure

## Docker Resources

The `docker/` directory contains Docker configurations and resources for running Zcash services in containers:

- [Docker README](docker/README.md) – Full documentation for Docker usage in this repo


## Kubernetes Deployment

The `charts/` directory contains Helm charts for deploying Zcash infrastructure on Kubernetes:

- [Zcash Stack Chart](charts/zcash-stack/README.md) - A comprehensive Helm chart for deploying Zcash infrastructure on Kubernetes

## Examples

The `examples/` directory contains example configurations and deployment scenarios to help you get started.

## License

This project is licensed under the terms of the license included in the repository.

