# Welcome to the Zcash Node Workshop: Monitor Week!

This continues our dicussion of hosting a zcash full node. If you are just starting here, perhaps you missed the [workshop overview](./README.md). 

## Workshop TLDR
1. [Sync](./class-1-sync.md) - Initial set up:
    1. Set up a virtual machine (VM) on hardware of your choice.
    1. Launch the Zcash service containers via Docker or Kubernetes on your VM.
        - Clone our [workshop Git repository](https://github.com/zecrocks/zcash-stack).
        - Or [our friendly-competitor's repository](https://github.com/stakeholdrs/zcash-infra).
    1. Synchronize your node with the Zcash network's blockchain (from scratch in ~10 days or from [`download-snapshot.sh`](../docker/download-snapshot.sh) in ~10 hours).
1. [Connect](./class-2-connect.md) - Connect your node to the Zcash network.
    - Optionally, use one of several technologies to improve the privacy that you, as a node operator, have for running your node and to connecting clients.
1. **Observe** - Observe, monitor, and maintain your Zcash infrastructure to ensure your node remains reliably available as part of the network.

** Record scratch **

(!) Spit your Red Bull all over the keyboard, get your feet off the desk, and stare open-mouthed at the screen...the servers are going down!

![Confused](images/shrek_confused.jpg)

## Table of Contents
- [Manual Monitoring](#manual-monitoring)
- [hosh Monitoring Tool](#hosh-monitoring-tool)

## Manual Monitoring
You can manually check your node's status using these commands:
```bash
docker compose -f docker-compose.zaino.yml ps -a
```
It might look something like this: 
```
NAME                        IMAGE                              COMMAND                  SERVICE            CREATED        STATUS                    PORTS
docker-init-zaino-perms-1   busybox:latest                     "sh -c 'mkdir -p /ho…"   init-zaino-perms   23 hours ago   Exited (0) 15 hours ago   
docker-zebra-1              zfnd/zebra:latest                  "entrypoint.sh zebrad"   zebra              23 hours ago   Up 15 hours (healthy)    0.0.0.0:8232-8233->8232-8233/tcp, [::]:8232-8233->8232-8233/tcp
zaino                       emersonian/zcash-zaino:0.1.2-zr4   "/app/zainod --confi…"   zaino              23 hours ago   Up 15 hours               8137/tcp
```
Logs will be here:
```
# Check container status
docker compose -f docker/docker-compose.zaino.yml ps -a

# Check Zebra logs
docker compose -f docker/docker-compose.zaino.yml logs zebra --tail=20

# Check Zaino logs  
docker compose -f docker/docker-compose.zaino.yml logs zaino --tail=20

# Monitor real-time logs
docker compose -f docker/docker-compose.zaino.yml logs -f
```

## hosh Monitoring Tool

Occasionally check if your server is running using zecrock tools: [hosh Monitoring Tool](https://hosh.zec.rocks/zec)

## Good night friend
Slip away into the night, knowing your server is running and you've done a small service to Zcash ecosystem by ensuring the Right to Transact for future generations. Find a cozy spot, sit back, and sip a Celsius knowing you are providing diversity and reliability to the privacy-coin Zcash ecosystem.

We love fellow tech educators: Consider supporting Tech Learning Collective's (TLC) Mission to provide cybersecurity and crypto literacy to at-risk minorities, and vulnerable communities whose livelihoods depend on privacy. TLC educates those whose very ability to transact in the world is threatened as a result of their identity, legal status, or occupation.

[Tech Learning Collective](https://techlearningcollective.com/workshops/Two-Sides-of-the-Same-Coin-Transacting-Privately-with-Cryptocurrency)

TLC: 
[TODO: Insert sheilded address]