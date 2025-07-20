[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zcash)](https://artifacthub.io/packages/search?repo=zcash)

# Zcash Stack

This repository contains tools and [documentation in the form of a workshop](./docs/) for deploying and managing Zcash infrastructure using Docker and Kubernetes.

## Repository layout

This repository has a simple filesystem structure. Important directories are noted and described in more detail below.

```
.
├── LICENSE            # <-- Legal information.
├── README.md          # <-- This file.
├── charts             # <-- Kubernetes resources (Helm charts).
├── docker             # <-- Docker resources (Compose configurations.).
├── docs               # <-- Workshop lessons and documentation.
├── examples           # <-- TODO: TK write description.
└── install-traefik.sh
```

## `docs`: Workshop notes

The [`docs/` directory](./docs/) contains workshop documentation which serves the dual purpose of describing the infrastructure configurations and providing a step-by-step walk through in using the provided infrastructure configurations.

## Docker Resources

The [`docker/` directory](./docker/) contains Docker configurations and resources for running Zcash services in containers:

## Kubernetes Deployment

The [`charts/` directory](./charts/) contains Helm charts for deploying Zcash infrastructure on Kubernetes:

- [Zcash Stack Chart](charts/zcash-stack/README.md) - A comprehensive Helm chart for deploying Zcash infrastructure on Kubernetes

## Examples

The [`examples/` directory](./examples/) contains example configurations and deployment scenarios to help you get started.

## License

This project is licensed under the terms of the [license](./LICENSE) included in the repository.
