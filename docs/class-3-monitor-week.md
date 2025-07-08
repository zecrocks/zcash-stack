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
- [Ongoing Monitoring and Tools](#ongoing-monitoring-and-tools)
- [zecping Tool](#zecping-tool)
- [hosh Monitoring Tool](#hosh-monitoring-tool)
- [fathomX Tool](#fathomx-tool)

## Ongoing Monitoring and Tools

Monitoring your Zcash node is crucial for ensuring its reliability and performance. Here are several approaches to monitor your node:

### 1. Built-in Health Checks
- **Docker Health Checks**: The stack includes built-in health checks that monitor:
  - RPC endpoint availability (port 8232 for mainnet, 18232 for testnet)
  - Node synchronization status
  - Memory and CPU usage
  - Container status

### 2. Manual Monitoring Commands [untested]
You can manually check your node's status using these commands:
```bash
docker compose -f docker-compose.zaino.yml ps -a
```

## zecping Tool

[TODO: Insert discussion on this tool]

## hosh Monitoring Tool

Occasionally check if your server is running using zecrock tools: [hosh Monitoring Tool](https://hosh.zec.rocks/zec)

Slip away into the night, knowing your server is running and you've done a small service to Zcash ecosystem by ensuring the Right to Transact for future generations. Find a cozy spot, sit back, and sip a Celsius knowing you are providing diversity and reliability to the privacy-coin Zcash ecosystem.

## Cool Tools in the ZEC ecosystem 
[What services accept ZEC as payment?](https://www.paywithz.cash/)