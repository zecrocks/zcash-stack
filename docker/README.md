# Docker Zcash Light Wallet

Install Docker on your computer and check out this source code repository.

```
git clone https://github.com/zecrocks/zcash-stack.git
cd zcash-stack/docker
docker compose up
```

The blockchain will be synced into the ```data``` directory, which can be useful for copying it to other devices.

It will take several days to sync depending on the speed of your computer and internet connection.

In a hurry? We host a snapshot of the blockchain that you can download faster than synchronizing it from scratch. It's not the purest way to synchronize, but it can save you over a week - especially if you are on a slow device.

```
# Run this to download our blockchain snapshot, then run "docker compose up" after it is complete.
./download-snapshot.sh
```

To connect to it from a wallet, you'll need to expose lightwalletd's port to the world.

There are several ways to do this. The quickest is to use Tailscale Funnel or Cloudflare Tunnel.

For Cloudflare Tunnel, [after installing it](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/), run this:

```
cloudflared tunnel --url http://localhost:9067
```

This is a work in progres. More detailed instructions are on the way!
