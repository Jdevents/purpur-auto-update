#!/bin/sh
service_name="mc-fish"
WORK_DIR="/home/mc"
PURUR-BACKUP="/home/mc/purpur-builds"

#Gets current minecraft version from official site
MCRELEASE=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')
#Gets the lates purpur build
PURPUR-CURRENT=$(curl -s https://api.purpurmc.org/v2/purpur/1.19.4 | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n")
#Gets the current minecraft snapshot
MCSNAPSHOT=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep -e 'snapshot' | sed 's/snapshot//g' |tr -d ':", ')
VERSION=${MCRELEASE} #1.19.4
BUILD=latest
cd ${WORK_DIR}
sleep 0.5
DOWN=$(cat ${PURUR-BACKUP}/build-list.txt)

#extract version file from current server.jar
sudo jar -xvf /opt/minecraft/server/server.jar version.json
RUNNING=$(jq -r '.id' version.json | sed 's/[a-z]//g' | tr -d ':",')

#functions area

McLocalBuild () {
    clear
    echo "---------------------------------------[Minecraft official Information]---------------------------------------"
    echo "Latest Minecraft Version: ${MCRELEASE}"
    echo "Latest Minecraft Snapshot Version: ${MCSNAPSHOT}"
    echo "Current Running Minecraft Version: ${RUNNING}"
    echo "-----------------------------------------[Purpur official Information]----------------------------------------"
    echo "Current Set Purpur Version: ${VERSION}"
    echo "Purpur Build To Download: ${CURRENT}"
    echo "Set Build Branch: ${BUILD}"
    sudo rm version.json
}

UpdateMc () {
}