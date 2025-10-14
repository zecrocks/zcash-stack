# Docker Zcash Light Wallet

Welcome to the Docker side of this Zcash node hosting repository.

> [!NOTE]
> If you came from [class-1-sync](../docs/class-1-sync.md): great!
> If not, don't skip our [workshop overview](../docs/README.md).

## Overview of components

Let's start with an overview of each component in a basic Zcash stack, and a summary of what they do.

![Block diagram showing the components of basic standard Zcash stack.](../docs/images/block_diagram.png)

In the diagram above, we see several important infrastructure components, including:

- **Core node software**, namely:
    - [*Zebra*](https://zfnd.org/zebra/) is an independent, Rust-based implementation of the Zcash node software, developed by the Zcash Foundation. It is designed for security, correctness, and performance. Zebra fully validates the Zcash blockchain, handles peer-to-peer networking, and implements consensus rules, making it suitable for running validator nodes and contributing to the decentralization and resilience of the Zcash network.
- **Light wallet interface**, such as one of the following:
    - [*Zaino*](https://github.com/zingolabs/zaino) is a lightweight codebase in Go for building Zcash-related infrastructure. Its design emphasizes clear interfaces and extensibility, making it an interface between Zebra node software and lightwallets, auditing services, and other ecosystem tools.
    - [*Lightwalletd*](https://github.com/zcash/lightwalletd) is a backend service that provides a bandwidth-efficient interface to the Zcash blockchain for light wallets and any other client application that needs to interface with the blockchain without storing its entirety locally.
- **Light wallet apps** (clients/user agents), namely:
    - [Zashi](https://electriccoin.co/zashi/) is a self-custody shielded ZEC wallet designed to be run on mobile phones such as Apple's iOS and Google's Android or its derivatives, like [GrapheneOS](https://grapheneos.org/) and functions as an end user's client application for interacting with the Zcash blockchain and network.
- Some infrastructure for operational considerations, namely:
    - [*Watchtower*](https://containrrr.dev/watchtower/) is an automated tool for monitoring and updating running Docker containers. It ensures your Zcash node and related services stay up-to-date by automatically pulling and applying new container images with minimal downtime. Updating to the latest version of software releases is an important security best practice.
    - A hosting provider, such as [Vultr](https://www.vultr.com/) that provides machine hardware on which node operators host these various server applications. Vultr is just an example. Feel free to use whatever hosting provider suits you, or self-host with your own machine hardware, if you have it.
    - An adminitrator's computer and their SSH connection to the hosting provider. This represents you, a new Zcash node operator!
    - Other node operators, e.g., us and your fellow community members!

## Getting Started

1.  Install Docker on your host machine and check out this source code repository:
    ```sh
    git clone https://github.com/zecrocks/zcash-stack.git
    cd zcash-stack/docker
    ```
1. Optionally, declare your own donation address to publish via the `lightwalletd` configuration:
    1. In the [`.env`](./env) file, change the value of `LIGHTWALLETD_DONATION_ADDRESS` to your own wallet's unified shielded address.
    ```sh
    LIGHTWALLETD_DONATION_ADDRESS=u14...
    ```
1. Bring the services `up`:
    ```sh
    docker compose up
    ```

If you choose to use a Docker Compose configuration different than the default ([`compose.yaml`](./compose.yaml)), be sure to specify the path to the configuration file with the `-f` short or `--file` long option. For example:

```sh
docker compose -f compose.arm.yaml up --detach`
```

## Troubleshooting and more

To keep the containers running in the background even if your SSH connection drops, `--detach` them when you bring them `up`:

```sh
docker compose up --detach
```

To stop the system, and remove the volumes that get created, bring them `down`:

```sh
docker compose down
```

Stop and remove all containers, networks, and volumes for this project:

```sh
docker compose  down -v --remove-orphans
```

Remove all unused containers, networks, images, and volumes:

```sh
docker system prune -a --volumes -f
```

Remove any remaining volumes specifically:

```sh
docker volume prune -f
```

Remove any remaining networks:
```sh
docker network prune -f
```

Restart Docker daemon (optional, but can help with some network issues):

```sh
systemctl restart docker
```

All together now! Hard removal of everything:

```sh
docker compose down -v --remove-orphans \
    && docker system prune -a --volumes -f \
    && docker volume prune -f \
    && docker network prune -f
```

## Sync the Blockchain

> [!NOTE]
> This Docker file will begin to sync the blockchain.

When the Docker containers are started and running properly for the first time, they will begin to sync the blockchain. This means re-verifying each block in the entire chain. As you might imagine, this takes quite some time. Here too, there are options.

### Lengthy Process: Let it Run

You could let the containers run, and sync the blockchain as designed. The blockchain will be synced into the `data` directory, which can be useful for copying it to other devices.

It will take several days to sync depending on the speed of your computer and Internet connection. This is the most secure way of doing it.

### Speedy Process: Download a Snapshot

In a hurry? We host a snapshot of the blockchain that you can download faster than synchronizing it from scratch. It's not the purest way to synchronize, as you are trusting (that is, assuming) that this snapshot is accurate, but it can save you over a week, especially if you are on a slow device.

Run the [`download-snapshot.sh`](download-snapshot.sh) first, then bring the Docker Compose configuration of your choosing `up`.

```sh
./download-snapshot.sh     # Run the script FROM THIS DIRECTORY.
docker compose up --detach # Assumes a relative path to the downloaded data.
```

Once the containers have started and are reporting a "Healthy" status, you can check their progress by following the logs in a new terminal:

```sh
docker compose logs --follow
```

You should see lines of this sort:

```
zebra-1         | 2025-09-16T00:13:13.521565Z  INFO {zebrad="d1a3c74" net="Main"}:sync:try_to_sync:try_to_sync_once: zebrad::components::sync: extending tips tips.len=1 in_flight=19 extra_hashes=0 lookahead_limit=20 state_tip=Some(Height(3047128))
lightwalletd-1  | {"app":"lightwalletd","level":"info","msg":"Adding block to cache 598871 0000000001a8d43526604916885deb4a075eb5ec4eab462ee85141b6dccd5f56","time":"2025-09-16T00:13:16Z"}
```

Another way to check the health of your `zebrad` server is to compose a JSON-RPC command to one of [its existing methods](https://github.com/ZcashFoundation/zebra/tree/e99c0b7196c8cc02c22c5f7669dc95dc73f8753a/zebra-rpc/src/methods/types). For example, to get info about the node's peers on the Zcash network, try this command from your Docker *host* machine (not from within the running containers):

```sh
curl \
    -H 'Content-Type: application/json' \
    --data-binary '{"jsonrpc":"2.0","id":"curltest","method":"getpeerinfo"}' \
    localhost:8232
```

You might get output of the following sort:

```
{"jsonrpc":"2.0","id":"curltest","result":[{"addr":"18.27.125.103:8233","inbound":false},{"addr":"99.56.151.125:8233","inbound":false},{"addr":"147.135.39.166:8233","inbound":false}]}
```

## Next Steps

Take a look at our documentation in [class-2-connect](../docs/class-2-connect.md) to learn about connecting your new node to the world. 🌎
