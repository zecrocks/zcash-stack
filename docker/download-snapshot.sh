SNAPSHOT_URL=https://link.storjshare.io/s/jv62jmwhs3n6c7usknlv4ux4lbza/nodedumps/zec/zebra-2024-03-25.tar?download=1

echo "Downloading blockchain snapshot to speed up sync time..."
wget -qO- $SNAPSHOT_URL | tar --strip-components=1 -xvf - -C ./data/zebrad-cache
echo "Snapshot download finished."
