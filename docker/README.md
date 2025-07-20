# Docker Zcash Light Wallet

Welcome to the Docker-side of this Zcash node hosting repository. 

> [!NOTE]
> If you came from [class-1-sync](../docs/class-1-sync.md): great!
> If not, don't skip our [workshop overview](../docs/README.md).

## Overview of the Components
Let's start with an overview of each component, and a summary of what they do. 
![Block diagram](../docs/images/block_diagram.png)

Zebra is an independent, Rust-based implementation of the Zcash node software, developed by the Zcash Foundation. It is designed for security, correctness, and performance. Zebra fully validates the Zcash blockchain, handles peer-to-peer networking, and implements consensus rules, making it suitable for running validator nodes and contributing to the decentralization and resilience of the Zcash network.

Zaino is a lightweight codebase in GO for building Zcash-related infrastructure. Its design emphasizes clear interfaces and extensibility, making it an interface between Zebra node software and lightwallets, auditing services, and other ecosystem tools.

Watchtower is an automated tool for monitoring and updating running Docker containers. It ensures your Zcash node and related services stay up-to-date by automatically pulling and applying new container images with minimal downtime.

Zashi is a lightweight, open-source Zcash lightwallet app designed for privacy and ease of use. It could connect your own node to the Zcash blockchain, allowing you to manage Zcash funds securely from your desktop or mobile device.

## Getting Started

Install Docker on your server/VM and check out this source code repository.

```
git clone https://github.com/zecrocks/zcash-stack.git
cd zcash-stack/docker
docker compose -f docker-compose.zaino.yml up
```

To run deattached in the background even if ssh connection drops: 
```
docker compose -f docker-compose.zaino.yml up --detach
```
To stop the system, but with removing the volumes that get created. 
```
docker compose -f docker-compose.zaino.yml down
```

## Troubleshooting and Docker Down
As happens in life, there are often troubles and times when a clean start is desired. Here are some helpful debugging options for stopping the Docker continers. 

Stop and remove all containers, networks, and volumes for this project
```
docker compose -f docker-compose.zaino.yml down -v --remove-orphans
```

Remove all unused containers, networks, images, and volumes
```
docker system prune -a --volumes -f
```

Remove any remaining volumes specifically
```
docker volume prune -f
```

Remove any remaining networks
```
docker network prune -f
```

Restart Docker daemon (optional but can help with network issues)
```
systemctl restart docker
```

All together now! Hard removal of everything.
```
docker compose -f docker-compose.zaino.yml down -v --remove-orphans && docker system prune -a --volumes -f && docker volume prune -f && docker network prune -f
```

## Sync the Blockchain
> [!NOTE] 
> This Docker file will begin to sync the blockchain.

When the Docker containers are started and running properly for the first time, they will begin to sync the blockchain. This means re-verifying each block in the entire chain. As you might imagine, this takes quiet some time. Here too, there are options. 

### Lengthy Process: Let it Run
You could let the containers run, and sync the blockchain as designed. The blockchain will be synced into the ```data``` directory, which can be useful for copying it to other devices.

It will take several days to sync depending on the speed of your computer and internet connection. This is the most secure way of doing it.

### Speedy Process: Download a Snapshot
In a hurry? We host a snapshot of the blockchain that you can download faster than synchronizing it from scratch. It's not the purest way to synchronize, as you are trusting (aka assuming) that this snapshot is accurate, but it can save you over a week - especially if you are on a slow device.

Run the [`download-snapshot.sh`](download-snapshot.sh) first, then Docker compose up.
```
./download-snapshot.sh
docker compose -f docker-compose.zaino.yml up
```

## Next Steps
Take a look at our documentation in [class-2-connect](../docs/class-2-connect.md) to learn about connecting your new node to the world. 🌎
