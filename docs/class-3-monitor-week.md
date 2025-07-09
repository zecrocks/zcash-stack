# Welcome to the Zcash Node Workshop: Monitor Week!

## Workshop TLDR
    1. Set up a VM on hardware of choice 
    2. Launch the containers via Docker or Kubernetes on your VM
        ◦ Clone the git repo (https://github.com/zecrocks/zcash-stack) 
        ◦ Or our competitors (https://github.com/stakeholdrs/zcash-infra)
    3. Sync the blockchain (from scratch in ~10days or from download-snapshot.sh in ~10hours)
    4. Connect your new node to a wallet (perhaps using Cloudflare or Tailscale tunnel)
    5. Sit back and sip a red-bull knowing you are providing diversity and reliability to the privacy-coin Zcash ecosystem

    6. (!) Spit your redbull all over the keyboard, get your feet off the desk, and stare open-mouthed at the screen...the servers are going down!

This week covers #6.

## Table of Contents
- [Manual Monitoring](#ongoing-monitoring-and-tools)
- [hosh Monitoring Tool](#hosh-monitoring-tool)

## Ongoing Monitoring and Tools
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
