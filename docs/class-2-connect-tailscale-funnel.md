# Connect via Tailscale Funnel

This document succinctly describes the process of creating a [Tailscale Funnel](https://tailscale.com/kb/1223/funnel) in order to make a lightwallet server such as `lightwalletd` or `zaino` running in a restricted environment such as behind a firewall or on a local network available to client wallet apps such as [Zashi](https://electriccoin.co/zashi/) on the public Internet.

## Before you begin

If you are reading this page, you should already have a fully-synced full node and lightwallet server up and running. The easiest way to do this is to follow these guides from their start, at [Class 1: Sync](./class-1-sync.md).

In the simplest case, this means you have already done something like:

```sh
git clone https://github.com/zecrocks/zcash-stack.git # Check out the source code.
cd zcash-stack                                        # Go to the source directory.
cd docker                                             # Go to the Docker configs directory.
./download-snapshot.sh                                # Use the downloader script to a recent copy of the Zcash blockchain database.
docker compose up --detach                            # Bring up the default service stack configuration.
```

If successful, you will have several services running in your Docker Compose project. Observe:

```sh
docker compose ps
```
```
NAME                    IMAGE                         COMMAND                  SERVICE        CREATED      STATUS                  PORTS
docker-lightwalletd-1   electriccoinco/lightwalletd   "lightwalletd --no-t…"   lightwalletd   2 days ago   Up 24 hours             0.0.0.0:9067-9068->9067-9068/tcp, [::]:9067-9068->9067-9068/tcp
docker-watchtower-1     containrrr/watchtower         "/watchtower --inter…"   watchtower     2 days ago   Up 24 hours (healthy)   8080/tcp
docker-zebra-1          zfnd/zebra:latest             "entrypoint.sh zebrad"   zebra          2 days ago   Up 24 hours (healthy)   0.0.0.0:8232-8233->8232-8233/tcp
```

Without a `zcashd` or `zebrad` process running, your lightwallet server cannot interact with the Zcash network more broadly. Meanwhile, without a lightwallet server process, such as `lightwalletd` or `zainod` process running, your client wallet apps won't be able to interact with Zcash's wallet APIs.

## About Tailscale

Tailscale is an easy-to-use virtual private network (VPN) service that implements an overlay mesh network between devices connected to the VPN and provides several additional facilities to streamline administration of those devices and the services they may provide. One of these is a built-in reverse proxy or tunneling service called Tailscale Funnel, which makes it easy to tunnel requests from clients on the public Internet to a server running in a restricted environment. In combination with Tailscale's DNS management features ("MagicDNS"), and its TLS certificate provisioning services (automating Let's Encrypt), Tailscale thus provides a complete solution for making a Zcash stack such as ours available to clients across the globe.

If you are interested in exploring what Tailscale has to offer more generally, read the official [Tailscale Quick Start](https://tailscale.com/kb/1017/install) guide. The rest of this page walks you through only what you need to do to set up a Tailscale Funnel for your new Zcash node.

## Configure Tailscale Funnel from start to finish

**Do this** to set up a new Tailscale network ("tailnet") and configure a Tailscale Funnel to work with your lightwallet server.

1. [Sign up for or log in to](https://login.tailscale.com/admin/machines) a Tailscale account via your Web browser.
1. [Install Tailscale](https://tailscale.com/kb/1347/installation)'s client software appropriate for the machine running your node.
1. [Add the machine ("device")](https://tailscale.com/kb/1316/device-add) hosting your Zcash service stack.
1. Optionally:
    - [Rename your Tailnet](https://tailscale.com/kb/1217/tailnet-name) to something more fun than the default. The name you set here will be the domain part of the public DNS name of the domain hosting your public endpoints.
    - [Rename your device](https://tailscale.com/kb/1098/machine-names#renaming-a-machine) to something more descriptive, meaningful, or less sensitive or revealing. The name you use here will be the host portion of the public DNS name for the fully-qualified domain name hosting your public endpoints.
1. [Ensure MagicDNS is enabled](https://tailscale.com/kb/1081/magicdns#enabling-magicdns) (this is the default for tailnets created after October 20, 2022).
1. [Ensure HTTPS certificate provisioning is enabled](https://tailscale.com/kb/1153/enabling-https).
1. [Create a device tag](https://tailscale.com/kb/1068/tags#define-a-tag) that you can use in your Tailscale policy file to target the device(s) hosting your Zcash node. You can do this with JSON or using the visual policy file editor provided via the Tailscale administration Web console:
    1. Access the [Tags tab of the Tailscale access control administration screen](https://login.tailscale.com/admin/acls/visual/tags).
    1. Click the "+ Create tag" button.
    1. In the "Tag name" field, enter a meaningful tag name, such as `zcash-infra`.
    1. In the "Tag owner" field, choose an appropriate user or group from the list. We suggest `autogroup:it-admin` or `autogroup:network-admin`.
    1. Optionally, in the "Note" field, enter a meaningful description to describe the purpose of this tag.
1. Designate your new tag as a policy target that assigns the `funnel` node attribute within your tailnet. This permits your machine to make use of the Tailscale Funnel facility. This can be done in the visual policy editor:
    1. Access the [Node Attributes tab of the Tailscale access control administration screen](https://login.tailscale.com/admin/acls/visual/node-attributes).
    1. Click the "+ Add node attribute" button.
    1. In the "Targets" field, choose your new tag value. It will be named `tag:*` where `*` is replaced by the name of the tag you picked in the prior step.
    1. In the "Notes" field, enter a meaningful description to describe the purpose of this attribute.
    1. In the "Attributes" field, choose `funnel` from the drop down menu.
    1. Leave all other fields blank.
    1. Click the "Save node attribute" button at the bottom of the adding a node attribute form.
1. [Provision a TLS certificate for your device](https://tailscale.com/kb/1153/enabling-https#provision-tls-certificates-for-your-devices):
    1. Note the fully-qualified DNS name (FQDN) of the machine from which you'll be hosting the Tailscale Funnel.
        - For example, if your tailnet name is `example-1a2b3c.ts.net`, and the device on which you'll be hosting the Zcash services and Tailscale Funnel is named `zcash`, then your FQDN is `zcash.example-1a2b3c.ts.net`.
    1. From a command line on your Zcash host machine, invoke the `tailscale cert` command with the FQDN of the device you'd like to provision the certificate for. For example:
    ```sh
    tailscale cert zcash.example-1a2b3c.ts.net
    ```
    This will create two files, a `.crt` and `.key`. You may want to move these to a safe/canonical location, such as `~/.config/pki/tls` or whatever is appropriate for your machine.
1. Finally, [create the Tailscale Funnel](https://tailscale.com/kb/1223/funnel#create-a-funnel) by pointing the funnel at the service you want to expose.
    - For example, if you are exposing the gRPC API of the `lightwalletd` process, which runs on port `9067` of `localhost` of the Zcash host machine, run the following command from that same machine where the `tailscale` client is installed:
    ```sh
    tailscale funnel 9067
    ```

Once up, you should see output like this:

```
Available on the internet:

https://zcash.example-1a2b3c.ts.net/
|-- proxy http://127.0.0.1:9067

Press Ctrl+C to exit.
```

Now, you can [test your connection](./class-2-connect.md#testing-your-connection-set-up) and see if your Tailscale Funnel is working by using any gRPC client, including `grpcurl` or a wallet app configured to use your custom server.
