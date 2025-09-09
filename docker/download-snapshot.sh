#!/bin/bash -
#
# Simple download script to speed up the process of downloading the
# entire content of the Zcash blockchain.

snapshot_url="https://link.storjshare.io/s/jx6hrssshp3rbpdmrxjiybjm3cnq/nodedumps/zec/zebra-2025-04-08.tar?download=1"
download_dir="./data/zebrad-cache"

echo "Ensuring download directory '${download_dir}' exists..."
mkdir -p "$download_dir"

echo "Downloading blockchain snapshot from $snapshot_url to speed up sync time..."
wget -qO- "$snapshot_url" | tar --strip-components=1 -xvf - -C "$download_dir"
echo "Snapshot download finished."
