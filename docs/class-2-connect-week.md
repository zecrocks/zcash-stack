# Welcome to the Zcash Node Workshop: Connect Week!

## Workshop TLDR
1. Set up a VM on hardware of choice
1. Launch the containers via Docker or Kubernetes on your VM
    - Clone the git repo (https://github.com/zecrocks/zcash-stack)
    - Or our competitors (https://github.com/stakeholdrs/zcash-infra)
1. Sync the blockchain (from scratch in ~10 days or from download-snapshot.sh in ~10 hours)
1. Connect your new node to a wallet (perhaps using Cloudflare or Tailscale tunnel)
1. Sit back and sip a Red Bull knowing you are providing diversity and reliability to the privacy-coin Zcash ecosystem

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

Let's talk about personal privacy and shielding IP address. Now that we have a server running, we will want to connect it to the outside world so that clients can make use of it.

In brief, there are more or less three different broad approaches you may want to take when operating a service. In this workshop, we will call these:

1. public operation, which reveals information about the operator,
1. IP-obscured operation, which hides information about the operator from casual observers,
1. anonymizing operation, which attempts to hide as much information about the operator from all possible observers.

Note that even when operating in an anonymizing manner, it is difficult to protect some potentially revealing information from the most dedicated adversaries. Please audit your running configuration before relying on it to protect your liberty.

### Public operation (cloud-provided static IP address)

Whenever you operate a service like this, you often reveal information about yourself to the world. You can think of operating a service similarly as "publishing information about" a service and, in fact, this is often how system operators speak of running publicly available services such as this.

In some use cases, you may not have any concern about publishing information about yourself in such a manner. If this is true for you, you can simply point your lightwallet client to the publicly exposed ("published") port of your Zaino (lightwallet server) at the static IP address that you are hosting it at. This means connecting clients will know your clearnet (unencrypted Internet) public IP address.

Simply bringing `up` the default configurations shared in this workshop is enough to make your validator and lightwallet server addresses available to the public.

If you're hosting your service on a cloud provider like Google Cloud or Vultr, they will supply an IP address (separate from your home IP address) which can be directly connected to from a lightwallet. At least this way, your home is still protected because the service is not operating in your domicile. This provides some protection, and is the simplest method to publish your service to the world, but does nothing to protect information about the service itself.

![Connecting your server to a Lightwallet](images/node_to_lightwallet_ways.png)

### IP-obscured operation

In many cases, system operators don't want to reveal who they are to everyone in the whole world. In these cases, you may find yourself wanting to obscure the IP address of the service from the public. If you do this, then You can for example choose to allow only certain people access to use your service.

This requires configuring your service to operate in an IP-obscured fashion, such that we aren't revealing certain information about ourselves. One helpful analogy may be to think of public operation similarly to how older generations shipped massive books of phone numbers and addresses to every resident in the neighborhood; we don't want to broadcast our IP address and other personal information out to every resident of the Internet.

For this, you can make use of various IP-obscuring tunnel technologies. Two popular and effective ones are [Cloudflare](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) and [Tailscale](https://tailscale.com/kb/1223/funnel), which  both offer tunneling technology that let you route traffic from the broader internet to a local server while also providing some measure of IP address obfuscation to the broader world.

When you use an IP-obscured method for your own privacy, you should remove the direct/static method from your service so that only the more private avenue exists. You can also choose to add this more private method *in addition to* the less private one if you simply need different capabilities or are using these avenues for censorship circumvention rather than for privacy, per se.

### Anonymous Traffic Routing

!["Ogres are like onions, they have layers." meme](images/Shrek.jpg)

Shrek has layers like an onion. Onion browsers like [TOR](https://www.torproject.org/), route traffic through a series of servers. Like wading through Shrek's swamp, this removes any traces of the path from origin to destination. Like a game of telephone, the packets are passed from node to node, each time stripping off information from its past. Unlike a game of telephone, the original message arrives encrypted and intact.

> [!NOTE]
> Currently no publicly available lightwallets support Tor's Onion addresses.
