# Welcome to the Zcash Node Workshop: Monitor Week!

This continues our dicussion of hosting a Zcash full node. If you are just starting here, perhaps you missed the [workshop overview](./README.md). 

## Workshop TL;DR
1. [Sync](./class-1-sync.md) - Prepare your Zcash node for operation.
1. [Connect](./class-2-connect.md) - Connect your node to the Zcash network.
1. **Observe** - Monitor and report the reliability of your Zcash node.

This document covers Observe.

## Table of Contents
1. [Observability overview](#observability-overview)
1. [Monitoring methods](#monitoring-methods)
    1. [Manual monitoring](#manual-monitoring)
    1. [`hosh` monitoring tool](#hosh-monitoring-tool)

## Observability overveiw

Just because a server is brought online doesn't mean the job of a system reliability engineer (SRE) is over. Far from it, in fact. Now is when the work of making sure that server remains a reliable part of the network begins.

** Record scratch **

(!) Spit your Red Bull all over the keyboard, get your feet off the desk, and stare open-mouthed at the screen...the servers are going down!

![Confused](images/shrek_confused.jpg)

The part of the job involving watching to make sure things don't change for the worse is called observability, and there are a lot of different ways to do it. The more automated methods are often thought to be better, but there is a tradeoff to be struck between automation and attention. Sometimes, the more automated something becomes, the less attention is paid to it.

In this document, we'll discuss a couple of methods that are useful for monitoring your new Zcash full node.

## Manual monitoring

The simplest method to observe your new node is to just monitor it manually. This means periodically logging into the server and running a few commands to check that everything you care about is still working the way you expect it to.

For example, use the `ps` subcommand to return a process listing from the operating system for the containers that are currently executing:

```sh
# List running containers in Docker Compose project.
docker compose ps -a
```

The output of this command might look something like the following: 

```
NAME                        IMAGE                              COMMAND                  SERVICE            CREATED        STATUS                    PORTS
docker-init-zaino-perms-1   busybox:latest                     "sh -c 'mkdir -p /ho…"   init-zaino-perms   23 hours ago   Exited (0) 15 hours ago   
docker-zebra-1              zfnd/zebra:latest                  "entrypoint.sh zebrad"   zebra              23 hours ago   Up 15 hours (healthy)    0.0.0.0:8232-8233->8232-8233/tcp, [::]:8232-8233->8232-8233/tcp
zaino                       emersonian/zcash-zaino:0.1.2-zr4   "/app/zainod --confi…"   zaino              23 hours ago   Up 15 hours               8137/tcp
```

Another useful but manual way to monitor a service is to follow along as it writes new information to its log files. Here are some commands that will do that:

```sh
# Show last 20 lines of Zebra's logs.
docker compose logs zebra --tail=20

# Show last 20 lines of lightwalletd's logs.
docker compose logs lightwalletd --tail=20

# Continuously monitor logs in real-time by "following" their output
# starting from the last 100 lines written to it.
docker compose logs --follow --tail=100
```

Since these commands are manual, you won't actually be notified if something goes wrong, but you will at least be able to see if the service is running or not.

## `hosh` monitoring tool

Another way to check if your node is online is by registering it with an uptime checker. [`hosh`](https://hosh.zec.rocks/) is our own lightwallet server uptime monitoring tool built [specifically for the Zcash lightwallet server ecosystem](https://hosh.zec.rocks/zec). We encourage you to register your new full node with `hosh` so that we can monitor it for you.

At the time of this writing, the way to do this is to [create a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) against [this Rust array in the `hosh` source code that contains a list of tuples](https://github.com/zecrocks/hosh/blob/0b30f4f401001f4f143265216ed9d96508c31523/discovery/src/main.rs#L84-L139). Once you add your full node's hostname, port, and boolean flag indicating that it is a community-run server to the above Rust code, and your pull request is merged, `hosh` will begin monitoring your service.

With `hosh` now aware of your full node, occasionally return to the `hosh` status page to check if your server is running.

## Good night friend

Slip away into the night, knowing your server is running and you've done a small service to Zcash ecosystem by ensuring the Right to Transact for future generations. Find a cozy spot, sit back, and sip a Celsius knowing you are providing diversity and reliability to the Zcash privacy coin ecosystem.
