#!/bin/bash
#
# Simple download script to speed up the process of downloading the
# entire content of the Zcash blockchain.
#
# The restore is idempotent and safe to cancel mid-flight: it writes an
# in-progress marker before extracting and only writes the complete marker after
# tar exits 0, so an interrupted download is re-done on the next run instead of
# leaving a half-extracted (corrupt) dataset behind.

set -euo pipefail

snapshot_url="https://link.storjshare.io/s/jvwzyxteyqlmbfayt6jgmhaaus3a/nodedumps/zec/zebra-2025-09-12.tar?download=1"
download_dir="./data/zebrad-cache"

complete="${download_dir}/.snapshot-complete"
inprogress="${download_dir}/.snapshot-inprogress"

echo "Ensuring download directory '${download_dir}' exists..."
mkdir -p "$download_dir"

is_empty() {
  [ -z "$(ls -A "$download_dir" 2>/dev/null | grep -v '^lost+found$' || true)" ]
}

restore() {
  echo "Downloading blockchain snapshot from $snapshot_url to speed up sync time..."
  find "$download_dir" -mindepth 1 -maxdepth 1 ! -name 'lost+found' -exec rm -rf {} +
  : > "$inprogress"
  wget -qO- "$snapshot_url" | tar --strip-components=1 -xf - -C "$download_dir"
  rm -f "$inprogress"
  : > "$complete"
  echo "Snapshot download finished."
}

if [ -f "$complete" ]; then
  echo "Complete marker present. Snapshot already downloaded. Skipping."
elif [ -f "$inprogress" ]; then
  echo "Interrupted download detected. Wiping and re-downloading."
  restore
elif is_empty; then
  restore
else
  echo "Directory is non-empty without markers: adopting existing dataset as complete."
  : > "$complete"
fi
