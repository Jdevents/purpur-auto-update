#!/bin/sh
service_name="mc-fish"
WORK_DIR="/home/mc"
PURUR-BACKUP="/home/mc/purpur-builds"

#Gets current minecraft version from official site
MCRELEASE=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')
#Gets the lates purpur build
PURPUR-CURRENT=$(curl -s https://api.purpurmc.org/v2/purpur/${MCRELEASE} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n")
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
    echo "Purpur Build To Download: ${PURPUR-CURRENT}"
    echo "Set Build Branch: ${BUILD}"
    sudo rm version.json
}

UpdateMc () {
	echo  "--- Purpur Update Found ----"    
    echo  "Old Purpur Build: ${DOWN}"
	echo  "New Purpur Build: ${PURPUR-CURRENT}"
	echo  "----------------------------"
	echo  "Update needed!"
	echo  "----------------------------"
    if systemctl is-active --quiet "$service_name.service" ; then
	    echo  "Service is running stopping service! Updating server jar file please wait 5 mins"
	    /home/mc/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p rconpassword "say mc server stopping in 15 seconds to update! Join back in 5-10 mins", "save-all"
	    sleep 15
	    sudo systemctl stop mc-fish
    else
        echo -e "Service not running startting update!"
    fi
	echo  "-----------------------------------------[Downloading File]----------------------------------------"
	sleep 0.5
	curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURBACK}/build-list.txt

	wget -P /tmp/purpur/ https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download --content-disposition

	cd /tmp/purpur
	if [ -d "$PURBACK" ]; then
		cp purpur-${VERSION}-${PURPUR-CURRENT}.jar ${PURUR-BACKUP}/purpur-${VERSION}-${PURPUR-CURRENT}.jar
	else
		mkdir ${PURBACK}
		cp purpur-${VERSION}-${PURPUR-CURRENT}.jar ${PURUR-BACKUP}/purpur-${VERSION}-${PURPUR-CURRENT}.jar
	fi
	mv purpur-${VERSION}-${PURPUR-CURRENT}.jar server.jar
	#run as root
	sudo mv server.jar /opt/minecraft/server
	echo  "  "
	echo  "Server file moved to /opt/minecraft/server"
	echo "Starting server..."
	sleep 2
	sudo systemctl start mc-fish
}


if [ ${CURRENT} != ${DOWN} ]; then
    UpdateMc
else
    echo "Local Purpur Build: ${DOWN}"
    echo "Remote Purpur Build: ${CURRENT}"
fi
exit
