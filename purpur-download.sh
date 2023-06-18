service_name="mc-fish"
WORK_DIR="/home/mc"
PURBACK="/home/mc/purpur-builds"
CURRENT=$(curl -s https://api.purpurmc.org/v2/purpur/1.19.4 | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n")
MCVERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')
MCSNAP=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep -e 'snapshot' | sed 's/snapshot//g' |tr -d ':", ')
VERSION=${MCVERSION} #1.19.4
BUILD=latest
cd ${WORK_DIR}
sleep 0.5
DOWN=$(cat ${PURBACK}/build-list.txt)
#extract version file from current server
sudo jar -xvf /opt/minecraft/server/server.jar version.json
RUNNING=$(jq -r '.id' version.json | sed 's/[a-z]//g' | tr -d ':",')
clear
echo -e "---------------------------------------[Minecraft Information]---------------------------------------"
echo -e "Latest Minecraft Version: ${MCVERSION}"
echo -e "Latest Minecraft Snapshot Version: ${MCSNAP}"
echo -e "Current Running Minecraft Version: ${RUNNING}"
echo -e "-----------------------------------------[Purpur Information]----------------------------------------"
echo -e "Current Set Purpur Version: ${VERSION}"
echo -e "Purpur Build To Download: ${CURRENT}"
echo -e "Set Build Branch: ${BUILD}"
sudo rm version.json
echo -e "-----------------------------------------[Server Information]----------------------------------------"

if [ ${CURRENT} != ${DOWN} ]; then
	echo -e "Old Purpur Build: ${DOWN}"
	echo -e "New Purpur Build: ${CURRENT}"
	echo -e "----------------------------"
	echo -e "Update needed!"
	echo -e "----------------------------"
    if systemctl is-active --quiet "$service_name.service" ; then
	    echo -e "Service is running stopping service! Updating server jar file please wait 5 mins"
	    /home/mc/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p AlphaBataDelta259 "say mc server stopping in 15 seconds to update! Join back in 5-10 mins", "save-all"
	    sleep 15
	    sudo systemctl stop mc-fish
    else
        echo -e "Service not running startting update!"
    fi
	echo -e "-----------------------------------------[Downloading File]----------------------------------------"
	sleep 0.5
	curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURBACK}/build-list.txt

	wget -P /tmp/purpur/ https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download --content-disposition

	cd /tmp/purpur
	if [ -d "$PURBACK" ]; then
		cp purpur-${VERSION}-${CURRENT}.jar ${PURBACK}/purpur-${VERSION}-${CURRENT}.jar
	else
		mkdir ${PURBACK}
		cp purpur-${VERSION}-${CURRENT}.jar ${PURBACK}/purpur-${VERSION}-${CURRENT}.jar
	fi
	mv purpur-${VERSION}-${CURRENT}.jar server.jar
	#run as root
	sudo mv server.jar /opt/minecraft/server
	echo -e "  "
	echo -e "Server file moved to /opt/minecraft/server"
	echo -e "Starting server..."
	sleep 2
	sudo systemctl start mc-fish
else
    echo -e "Local Purpur Build: ${DOWN}"
    echo -e "Remote Purpur Build: ${CURRENT}"
    echo -e "-------------------------------------------[No New Updates!]-----------------------------------------"
fi
exit
