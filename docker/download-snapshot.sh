SNAPSHOT_URL=https://link.storjshare.io/s/jx6hrssshp3rbpdmrxjiybjm3cnq/nodedumps/zec/zebra-2025-04-08.tar?download=1

echo "Downloading blockchain snapshot to speed up sync time..."
wget -qO- $SNAPSHOT_URL | tar --strip-components=1 -xvf - -C ./data/zebrad-cache
echo "Snapshot download finished."
