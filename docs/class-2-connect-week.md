# Welcome to the Zcash Node Workshop: Connect Week!


## Workshop TLDR
    1. Set up a VM on hardware of choice 
    2. Launch the containers via Docker or Kubernetes on your VM
        ◦ Clone the git repo (https://github.com/zecrocks/zcash-stack) 
        ◦ Or our competitors (https://github.com/stakeholdrs/zcash-infra)
    3. Sync the blockchain (from scratch in ~10 days or from download-snapshot.sh in ~10 hours)
    4. Connect your new node to a wallet (perhaps using Cloudflare or Tailscale tunnel)
    5. Sit back and sip a Red Bull knowing you are providing diversity and reliability to the privacy-coin Zcash ecosystem

This week covers #4 + #5.

## Table of Contents
- [Connecting our Node to the World Wide Web3](#connecting-our-node-to-the-world-wide-web3)
- [Action Item 4: Connect your Server to a Lightwallet](#action-item-4-connect-your-server-to-a-lightwallet)
  - [Cloud-provided static IP address](#cloud-provided-static-ip-address)
  - [IP-Obscuring Tunnels](#ip-obscuring-tunnels)
  - [Anonymous Traffic Routing](#anonymous-traffic-routing)
- [Monitoring + Tools](#monitoring--tools)

##  Connecting our Node to the World Wide Web3

[TODO: Insert discussion and diagrams]

## Action Item 4: Connect your Server to a Lightwallet

Let's talk about personal privacy and shielding IP address. Now that we have a server running, we will want to connect it to the outside world but in such a way, that we aren't revealing information about ourselves. While older generations shipped massive books of phone numbers and addresses to every resident in the neighborhood; we don't want to broadcast our IP address and other personal information out to every resident of the internet. 

Consider 3 options:
- Cloud-provided static IP address
- IP-obscuring Tunnels 
- Anonymous Traffic Routing (currently unavailable)

![Connecting your server to a Lightwallet](images/node_to_lightwallet_ways.png)

### Cloud-provided static IP address

If using a cloud provider like Google Cloud or Vultr, they will supply an IP address (separate from your home IP address) which can be directly connected to a lightwallet. This provides protection, and is the simplest method. 

### IP-Obscuring Tunnels
[Cloudflare](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) and [Tailscale](https://tailscale.com/kb/1223/funnel) are both tunnels that let you route traffic from the broader internet to a local server. These options would be good for those who are self-hosting or want additional protection on cloud-provided hosting services.

### Anonymous Traffic Routing

!["Ogres are like onions, they have layers." meme](images/Shrek.jpg)

Shrek has layers like an onion. Onion browsers like [TOR](https://www.torproject.org/), route traffic through a series of servers. Like wading through Shrek's swamp, this removes any traces of the path from origin to destination. Like a game of telephone, the packets are passed from node to node, each time stripping off information from its past. Unlike a game of telephone, the original message arrives encrypted and intact.


Note: Currently no publicly available lightwallets support TOR/onion addresses.



