#!/bin/sh

wget https://github.com/NebraLtd/helium-syncrobit/files/11213112/takeover-files.tgz
tar -xzf takeover-files.tgz
cd takeover-files
chmod +x takeover
sudo mkdir /mnt/old_root
sudo mount /dev/mmcblk0p2 /mnt/old_root
sudo ./takeover --download-only -c helium-syncrobit.config.json --version 2.112.2
sudo ./takeover -c helium-syncrobit.json --no-os-check --no-nwmgr-check --version 2.112.12 --image balena-cloud-raspberrypicm4-ioboard-2.112.12.img.gz --no-ack
