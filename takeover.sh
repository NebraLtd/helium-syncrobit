#!/bin/bash

set -e  # exit on first error

function msg() {
    echo " * $1"
}

TAKEOVER_DIR=/data/nebra-takeover
TAKEOVER_FILES_ARCHIVE="https://github.com/NebraLtd/helium-syncrobit/archive/refs/heads/takeover.tar.gz"
FIRMARE_IMAGE_URL="https://api.balena-cloud.com/download?deviceType=raspberrypicm4-ioboard&version=2.112.12&fileType=.gz"
MIN_FREE_SPACE=$((1024 * 2))  # MB
LOOP_DEV=/dev/loop2

# Prevent panic reboots during takeover procedure
panic_inhibit

# Do some cleanups & ensure we've got enough space
rm -f /data/snapshot.bin
rm -rf /var/lib/miner/

free_space=$(df -m /data | tail -n 1 | tr -s ' ' | cut -d ' ' -f 4)
if [[ ${free_space} -lt ${MIN_FREE_SPACE} ]]; then
    msg "Not enough free space on data partition: ${free_space} MB"
    exit 1
fi
msg "Free space on data partition: ${free_space} MB"

msg "Preparing takeover dir ${TAKEOVER_DIR}"
mkdir -p ${TAKEOVER_DIR}

msg "Downloading the firmware image archive from ${FIRMARE_IMAGE_URL}"
curl -L --fail "${FIRMARE_IMAGE_URL}" -o ${TAKEOVER_DIR}/firmware.img.gz

msg "Extracting the firmware image"
gunzip -f ${TAKEOVER_DIR}/firmware.img.gz

msg "Downloading the takeover files archive from ${TAKEOVER_FILES_ARCHIVE}"
curl -L --fail "${TAKEOVER_FILES_ARCHIVE}" -o ${TAKEOVER_DIR}/takeover-files.tar.gz

msg "Extracting the takeover files"
tar --strip-components=1 -xvf ${TAKEOVER_DIR}/takeover-files.tar.gz -C ${TAKEOVER_DIR}

# Detect Wi-Fi connection parameters
conn_name=$(connmanctl services | grep "*AO" | tr -s " " | rev | cut -d " " -f 1 | rev)
test -n "${conn_name}" || conn_name=$(connmanctl services | grep "*AR" | tr -s " " | rev | cut -d " " -f 1 | rev)
test -n "${conn_name}" || { msg "failed to determine current network connection"; exit 1; }
if [[ ${conn_name} = wifi* ]]; then
    ssid=$(cat /var/lib/connman/${conn_name}/settings | grep Name= | cut -b 6-1000)
    psk=$(cat /var/lib/connman/${conn_name}/settings | grep Passphrase= | cut -b 12-1000)
    msg "Got Wi-Fi SSID=${ssid}, PSK=*****"
fi

# Some units may have the external Wi-Fi antenna enabled. We want to preserve this setting.
if grep -qE '^dtparam=ant2' /boot/config.txt; then
    ant2=true
    msg "External Wi-Fi antenna is used"
fi

msg "Mounting firmware boot partition"
losetup -d ${LOOP_DEV} &>/dev/null || true
losetup -P ${LOOP_DEV} ${TAKEOVER_DIR}/firmware.img || true
mkdir -p ${TAKEOVER_DIR}/boot
umount ${TAKEOVER_DIR}/boot &>/dev/null || true
mount ${LOOP_DEV}p1 ${TAKEOVER_DIR}/boot

msg "Injecting config.json"
cp ${TAKEOVER_DIR}/config.json ${TAKEOVER_DIR}/boot

msg "Injecting config.txt"
test -n "${ant2}" && echo "dtparam=ant2" >> ${TAKEOVER_DIR}/config.txt
cp ${TAKEOVER_DIR}/config.txt ${TAKEOVER_DIR}/boot

msg "Injecting Wi-Fi config"
if [[ -n "${ssid}" ]] && [[ -n "${psk}" ]]; then
    export ssid psk
    mkdir -p ${TAKEOVER_DIR}/boot/system-connections
    cat ${TAKEOVER_DIR}/resin-wifi-01 | envsubst > ${TAKEOVER_DIR}/boot/system-connections/resin-wifi-01
fi

msg "Unmounting firmware boot partition"
umount ${LOOP_DEV}p1
sync
losetup -d ${LOOP_DEV}

msg "Setting up initramfs boot"

mount -o remount,rw /boot
echo >> /boot/config.txt
echo "initramfs initrd.gz" >> /boot/config.txt
cp ${TAKEOVER_DIR}/initrd.gz /boot

msg "Rebooting"
reboot
