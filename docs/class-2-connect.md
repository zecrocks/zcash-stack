# Welcome to the Zcash Node Workshop: Connect Week!

This continues our dicussion of hosting a Zcash full node. If you are just starting here, perhaps you missed the [workshop overview](./README.md).

## Workshop TL;DR
1. [Sync](./class-1-sync.md) - Prepare your Zcash node for operation.
1. **Connect** -
    1. Connect your node to the Zcash network.
    - Optionally, use one of several technologies to improve the privacy that you, as a node operator, have for running your node and to connecting clients.
1. [Observe](./class-3-observe.md) - Observe, monitor, and maintain your Zcash infrastructure to ensure your node remains reliably available as part of the network.

This document covers Connect.

## Table of Contents
1. [Connecting your server to the World Wide Web3](#connecting-your-server-to-the-world-wide-web3)
  1. [Public operation (cloud-provided static IP address)](#public-operation-cloud-provided-static-ip-address)
  1. [IP-obscured operation](#ip-obscured-operation)
  1. [Anonymizing operation](#anonymizing-operation)
1. [Testing your connection set up](#testing-your-connection-set-up)
    - [Test connection with Zashi](#test-connection-with-zashi)
    - [Test connection with CLI tools](#test-connection-with-cli-tools)
1. [Relax](#relax)

## Connecting your Server to the World Wide Web3

Let's talk about personal privacy and shielding your service's IP address. Now that we have a server running, we will want to connect it to the outside world so that clients can make use of it.

In brief, there are more or less three different broad approaches you may want to take when operating a service. In this workshop, we will call these:

1. Public operation: Reveals information about the operator
1. IP-obscured operation: Hides information about the operator from casual observers
1. Anonymizing operation: Attempts to hide as much information about the operator from all possible observers

![Connecting your server to a Lightwallet](images/node_to_lightwallet_ways.png)

Note that even when operating in an anonymizing manner, it is difficult to protect some potentially revealing information from the most dedicated adversaries. Please audit your running configuration before relying on it to protect your liberty.

### Public operation (cloud-provided static IP address)

Whenever you operate a service like this, you often reveal information about yourself to the world. You can think of operating a service similarly as "publishing information about" a service and, in fact, this is often how system operators speak of running publicly available services such as this.

In some use cases, you may not have any concern about publishing information about yourself in such a manner. If this is true for you, you can simply point your lightwallet client to the publicly exposed ("published") port of your lightwallet server (e.g., Zaino or Lightwalletd service) at the static IP address at which you're hosting it. This means connecting clients will know your clearnet (unencrypted Internet) public IP address.

Simply bringing `up` the default configurations shared in this workshop is enough to make your validator and lightwallet server addresses available to the public.

If you're hosting your service on a cloud provider like Google Cloud or Vultr, they will supply an IP address (separate from your home IP address) that is directly accessible to connecting clients. Publishing your service this way sort of offers some protection for your home simply because the service is simply not operating in your domicile. While this is the simplest method to publish your service to the world, it does nothing to protect information about the service itself.

### IP-obscured operation

In many cases, system operators don't want to reveal who they are to everyone in the whole world. In these cases, you may find yourself wanting to obscure the IP address of the service from the public. If you do this, then it is arguably also easier to allow only certain people access to use your service in the first place.

One helpful analogy may be to think of public operation similarly to how older generations shipped massive books of phone numbers and addresses to every resident in the neighborhood. Today we don't often want to broadcast our IP address and other personal information out to every resident of the Internet. This requires configuring your service to operate in an IP-obscured fashion, such that we aren't revealing certain information about ourselves.

To do this, you can make use of various IP-obscuring tunnel technologies. Some popular options include:

### VPS Proxy Setup 

For robust IP obfuscation, One approach is using a VPS (Virtual Private Server) as a proxy gateway. This architecture allows you to run your Zcash node on a home network (like a Raspberry Pi) while exposing it to the internet through a separate VPS, hiding your home IP address from the lightwallet clients (but note that the IP address will still be visible to other zcash nodes).

#### Architecture Overview

```mermaid
graph TB
    subgraph ClientEnv["Client Environment"]
        Client[Zashi/Lightwallet Client]
    end

    subgraph VPS["VPS (Cloud Provider)"]
        CF[Cloudflare DNS/CDN]
        Caddy[Caddy Proxy<br/>Port 8443]
        Tunnel_VPS[SSH Tunnel Endpoint<br/>Port 19067]
    end

    subgraph HomeNet["Home Network"]
        subgraph NodeHW["Raspberry Pi / Node Hardware"]
            AutoSSH[AutoSSH Client<br/>Reverse Tunnel]
            LWD[LightwalletD<br/>Port 9067]
            Zebra[Zebra Node<br/>Port 8233/8232]
        end
        Router[Home Router<br/>NAT/Firewall]
    end

    subgraph ZcashNet["Zcash Network"]
        Network[Other Zcash Nodes]
    end

    Client -->|HTTPS gRPC<br/>your-domain:8443| CF
    CF --> Caddy
    Caddy -->|h2c proxy| Tunnel_VPS
    Tunnel_VPS -.->|SSH Reverse Tunnel| AutoSSH
    AutoSSH --> LWD
    LWD --> Zebra
    Zebra <-->|P2P Port 8233| Network

    style Client fill:#e1f5fe
    style VPS fill:#f3e5f5
    style NodeHW fill:#e8f5e8
    style AutoSSH fill:#fff3e0
    style Tunnel_VPS fill:#fff3e0
```

#### Why This Architecture?

This setup provides several advantages:

1. **IP Privacy**: Your home IP address is hidden from clients
2. **NAT/Firewall Bypass**: No need to configure port forwarding on your home router
3. **Geographic Distribution**: You can choose VPS locations different from your home
4. **Cost Effective**: Small VPS instances are sufficient since they only proxy traffic

#### Prerequisites

Before setting up the VPS proxy, you'll need:

1. **VPS Instance**: A small cloud VPS (1GB RAM, 1 vCPU is sufficient)
2. **Domain Name**: A domain you control (for SSL certificates)
3. **Cloudflare Account**: Free account for DNS (and SSL management)
4. **SSH Key Pair**: For secure authentication between your node and VPS

Generate SSH keys if you don't have them:
```bash
# On your home node (Raspberry Pi)
ssh-keygen -t ed25519 -f ~/autossh-keys/id_ed25519 -N ""

# Copy the public key to your VPS
ssh-copy-id -i ~/autossh-keys/id_ed25519.pub root@YOUR_VPS_IP
```

#### Home Node Configuration

On your home node (Raspberry Pi or similar), you'll run two main services. All configuration files are available in the [`docker/`](../docker/) directory.

**1. Main Zcash Stack**

Use the correct docker configuration: 

- ARM: [`docker-compose.arm.yml`](../docker/docker-compose.arm.yml)
- x86_64: [`docker-compose.yml`](../docker/docker-compose.yml)

For VPS proxy setup, you'll need to modify the port bindings:

1. **Edit the file to enable VPS mode:**
   - Comment out the public port bindings (`9067:9067` and `9068:9068`)
   - Uncomment the localhost-only bindings (`127.0.0.1:9067:9067` and `127.0.0.1:9068:9068`)

The file includes comments showing exactly which lines to change for VPS setup.

**2. AutoSSH Reverse Tunnel**

Use: [`docker-compose.autossh.yml`](../docker/docker-compose.autossh.yml)

Configure your VPS details in a `.env` file:
```bash
# .env file
VPS_IP=YOUR_VPS_IP_ADDRESS
```

Start both services:
```bash
# Start the main Zcash stack (after editing for VPS mode)
docker-compose -f docker/docker-compose.arm.yml up -d

# Start the SSH tunnel (in a separate terminal/screen)
docker-compose -f docker/docker-compose.autossh.yml up -d
```

#### VPS Configuration

On your VPS, use the Caddy reverse proxy configuration: [`docker-compose.vps.yml`](../docker/docker-compose.vps.yml)

This setup includes:
- **Caddy with Cloudflare integration** for automatic SSL certificates
- **Health monitoring** of the SSH tunnel connection
- **Environment variable configuration** for easy deployment

Configure your VPS with a `.env` file:
```bash
# VPS .env file
CLOUDFLARE_API_TOKEN=your_cloudflare_token_here
DOMAIN_NAME=your-domain.com
```

Deploy on your VPS:
```bash
# On your VPS
docker-compose -f docker-compose.vps.yml up -d
```

#### Testing Your Setup

Once everything is running, test your setup with grpcurl:

```bash
grpcurl -authority your-domain.com \
  -d '{}' \
  your-domain.com:8443 \
  cash.z.wallet.sdk.rpc.CompactTxStreamer/GetLightdInfo
```

Expected response:
```json
{
  "vendor": "ECC LightWalletD",
  "taddrSupport": true,
  "chainName": "main",
  "saplingActivationHeight": "419200",
  "consensusBranchId": "c8e71055",
  "blockHeight": "3065090",
  "buildDate": "2025-09-10",
  "buildUser": "root",
  "estimatedHeight": "3065090",
  "zcashdBuild": "v2.5.0",
  "zcashdSubversion": "/Zebra:2.5.0/"
}
```

### Removing Direct Access

When you use an IP-obscured method for your own privacy, you should remove the direct/static method from your service so that only the more private avenue exists. You can also choose to add this more private method *in addition to* the less private one if you simply need different capabilities or are using these avenues for censorship circumvention rather than for privacy, per se.

Direct/static method in docker-compose.zaino.yml:
```
zaino:
    ...
  ports:
    - "0.0.0.0:8137:8137" # GRPC port for lightwallet client connections.
```

To remove the public operation and stick to providing service through an IP-obscured method, you will want to change the `0.0.0.0` IP address to something more limited, probably `127.0.0.1`.

### Anonymizing operation

![An image of Shrek saying, "Ogres are like onions, they have layers," stylized as a popular meme.](images/Shrek.jpg)

Shrek has layers like an onion. Onion routing technologies like [Tor](https://www.torproject.org/) move Internet traffic through several layers of relay servers. Like wading through Shrek's swamp, this removes traces of the path from source to destination. Like a game of telephone, the packets are passed from relay to relay, each time stripping off information from its past. Unlike a game of telephone, the original message arrives unmodified.

> [!NOTE]
> Currently no publicly available lightwallets support Tor's Onion addresses. (April 2025)

## Testing your connection set up

Once you have made your node and lightwallet server available to clients, it's time to test that your running configuration is working.

#### Test connection with Zashi

Perhaps the simplest way to do this is to just try it out with a real ZEC wallet. We like [Zashi](https://electriccoin.co/zashi/), a privacy-focused Zcash lightwallet that allows end users like you to set configure a custom lightwallet server address to communicate with.

> [!TIP]
> As of this writing, Zashi ships with a list of known and trusted host addresses for new users. Its maintainers manually add new trusted nodes as those node operators prove that they can offer reliable and stable services to the community. [Zashi also enables one-click activation of Tor protection](https://electriccoin.co/blog/zashi-2-1-enhanced-privacy-with-tor-beta/), further protecting the user base from potential de-anonymization if they happen to interact with a malicious lightwallet server operator. Consider enabling this feature if you don't want the lightwallet server operators to know your IP address when you connect to them.

**Do this** to manually test if your Zcash full node is synced and your lightwallet server is working, you can add the lightwallet server address to your Zashi wallet and see if you can still communicate with the Zcash network.

1. [Download and install Zashi](https://electriccoin.co/zashi/), if you haven't already.
1. Open your Zashi wallet.
    - Click the "Create new wallet" button if you don't already have a wallet. Otherwise, Zashi will open to your balance screen.
1. Tap the Settings (gear icon) button in the top-right corner of the Zashi main balance screen. The settings screen will open.
1. Tap *Advanced Settings* from the Settings screen. The Advanced Settings screen will open.
1. Tap *Choose a Server* from the Advanced Settings screen. The Choose a Server window will open.
1. Find the *custom* line item from the server list and tap to open it.
1. Enter your lightwallet server's address (including port number, in `hostname:port` format) into the custom lightwallet server address field.
1. Tap or press the *Save selection* button.
1. Send a test transcation, such as a tip to your favorite Zcash node workshop organizer. ;) Remember, Zcash transactions keep the sender's address completely private. Not even recipients can see who is sending them ZEC! If you leave a way to contact you in the (similarly encrypted) memo field, though, they can acknowledge the transcation with a thanks of their own!
    - [@ReadyMouse](https://github.com/ReadyMouse):
    ```
    u14yr5fr2gzhedzrlmymtjp8jqsdryh6zpypnh8k2e2hq9z6jluz9hn9u088j02c3zphnf30he4pnm62ccyae6hfjjuqxlddhezw2te5p6xxhm68vvvpvynnzdcegq4c5u06slq673emarwjy5z0enj2ry53avx0nsmftpx4hhh5rhpgnc
    ```

#### Test connection using CLI tools

If you are comfortable on a command line, there are a number of ways you can test your running configuration with command line interface tools. Here's a summary of these testing methods and some example commands.

First, you'll need a CLI debugging tool for either or both interfaces that the services you're testing make available.

- [`grpcurl`](https://grpcurl.com/) - Command line tool for testing gRPC services. You can install it easily from a number of sources.
    - [Install `grpcurl` with Homebrew](https://formulae.brew.sh/formula/grpcurl)
    - [Install `grpcurl` with asdf](https://github.com/asdf-community/asdf-grpcurl)
- [JSON-RPC Debugger](https://github.com/shanejonas/jsonrpc-debugger) - Terminal-based TUI JSON-RPC debugger with interception capabilities.

Once you have your chosen tool(s) installed, try the following commands.

You can inspect a service via its gRPC API endpoint like this:

```sh
# Let's see if the gRPC debugging tool works at all.
grpcurl zec.rocks:443 list             # Show available gRPC services at zec.rocks on port 443 over TLS.
grpcurl -plaintext localhost:9067 list # Show available gRPC services at localhost on port 9067 over unencrypted gRPC.

grpcurl zec.rocks:443 describe         # Show detailed description of available services.

# Finally, invoke the `GetLightdInfo` method of the
# `cash.z.wallet.sdk.rpc.CompactTxStreamer` service.
grpcurl zec.rocks:443 cash.z.wallet.sdk.rpc.CompactTxStreamer.GetLightdInfo
```

You can inspect a service via its JSON-RPC API endpoint like this:

```sh
# TK-TODO
```

## Relax
![Cartoon image of a person relaxing in an office chair.](images/relax.png)
