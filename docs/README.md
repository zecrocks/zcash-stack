# Zcash Stack Documentation and Workshop

The [`docs` folder contains workshop documentation](./docs/) and is organized into three main "classes" or stages of learning:

1. [Sync](./class-1-sync.md) - Initial set up:
    1. Set up a virtual machine (VM) on hardware of your choice.
    1. Launch the Zcash service containers via Docker or Kubernetes on your VM.
        - Clone our [workshop Git repository](https://github.com/zecrocks/zcash-stack).
        - Or [our competitors' repository](https://github.com/stakeholdrs/zcash-infra).
    1. Synchronize your node with the Zcash network's blockchain (from scratch in ~10 days or from [`download-snapshot.sh`](../docker/docwnload-snapshop.sh) in ~10 hours).
1. [Connect](./class-2-connect.md) - Connect your node to the Zcash network.
    1. Optionally, use one of several technologies to improve the privacy that you, as a node operator, have for running your node and to connecting clients.
1. [Observe](./class-3-observe.md) - Observe, monitor, and maintain your Zcash infrastructure to ensure your node remains reliably available as part of the network.

After you have worked through all the "classes," you can sit back and sip a red-bull knowing you are providing diversity and reliability to the Zcash privacy-coin ecosystem.

## Before you begin

In this workshop's series of classes, we walk you through the process of installing services that we hope will expand the Zcash network and improve its ecosystem. While you do not need to be an expert in Zcash's specific cryptographic technologies, you should be familiar with some computing basics such as:

- Hardware terminology and resources ("RAM," "CPU", "storage space," "Gigabyte (GB)", etc.)
- IP (version 4) addressing and simple routing (subnet masks, "private" IP spaces such as those defined by [RFC 1918](https://www.rfc-editor.org/rfc/rfc1918.html))
- Cloud infrastructure providers and cloud-based virtual machines, generically (Amazon AWS's EC2, Google GCP's GCE, etc.)

Put another way, if you have ever set up a server (even for casual personal use), or ran such as a service using Docker containers, you should be good to go, but the more experience you have with these things, the more contextualized and seamless this workshop will feel.

## Disclaimer of liability

Choosing to run information services can be a risky proposition depending on the service, your intended client population, your intent, the intent of your clients, which legal jursidiction you operate in, the political climate, and many more factors. Ultimately, you are responsible for the infrastructure that you run. The authors of this workshop make no representation to the correctness or quality of the documentation or software provided herein, and take no responsibility for the consequences of running this software.

We hope to expand the liberty and joy in the world, which we believe software projects such as Zcash can successfully accomplish and are excited you want to be a part of a more free, more joyous world with us.
