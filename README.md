
# Purpur Download
A shell scripted to automaticly update minecraft servers running purpur. I made this cause i am to lazzy to constently check to see if there is a new build of purpur to download and add to the server, so this scripted does it for me making my life simpler.



## Installation

## __Before Starting the scripted please either have a setup like the guid below or something similar to it__

This shell scripted asumes you have followed or have something similar to this [guid](https://www.shells.com/l/en-US/tutorial/0-A-Guide-to-Installing-a-Minecraft-Server-on-Linux-Ubuntu)

You will also need to have a currently running minecraft server using purpur just to make your life easier. You can go [here](https://purpurmc.org/) to get the lates purpur build.
I have no clue if you can just start off with the normal minecraft server.jar file, I don't see why you couldn't but just to be safe start with a purpur build

To install you can either do the following

`wget https://raw.githubusercontent.com/Jdevents/purpur-auto-update/main/purpur-update.sh`

or you can clone the repo doing

`git clone https://github.com/Jdevents/purpur-auto-update.git`

## Configuration

In the shell scripted I need you to change the following to match your setup

```Shell Scripted
/home/mc/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p rconpassword "say mc server stopping in 15 seconds to update! Join back in 5-10 mins", "save-all"
```
Where it says `rconpassword` you need to change this to be your super secret password you have setup.

You also need to change some variables which are the following

| Change Us | Change To Match Your Setup |
|:---------------:|:----------------------:|
|service_name|Change this to be whatever you named your minecraft service|
|WORK_DIR|For the home user. I found i had to run this from another user (Or you could add the minecraft user to the sudoers group|
|PURUR_BACKUP|This is where it will store backups of the downloaded purpur files|
|Service Name Again| On line **52** and **76** you need to change the service name that is currently there to match yours|
|Current Running version| On line **20** you will see a sudo command `sudo jar -xvf /opt/minecraft/server/server.jar version.json` change the location of the server.jar to match where your server.jar file lives!!|

In my setup I have the update running in the root crontab like so

```
@reboot /bin/bash /home/mc/purpur-download.sh
0 0 * * 0-6 /bin/bash /home/mc/purpur-download.sh
```

so that on reboot the updater runs and very day at midnight the updater also runs as well

## What does everything do?

### The first 15 lines

```shell scripted
service_name="mc-fish"
WORK_DIR="/home/mc"
PURUR_BACKUP="/home/mc/purpur-builds"
MCRCON="/home/mc/mcrcon"

#Gets current minecraft version from official site
MCRELEASE=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')
#Gets the lates purpur build
PURPUR_CURRENT=$(curl -s https://api.purpurmc.org/v2/purpur/${MCRELEASE} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n")
#Gets the current minecraft snapshot
MCSNAPSHOT=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep -e 'snapshot' | sed 's/snapshot//g' |tr -d ':", ')
VERSION=${MCRELEASE} #1.19.4
BUILD=latest
cd ${WORK_DIR}
```

This part is simpley defining variables and getting the current information from each place, each line is more or less the same for example 

``` shell scripted
MCRELEASE=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')
```
this line simpley goes to the following link which anyone can goto to retreave the requiered information then the next bit `jq '.latest' | grep 'release' | sed 's/[a-z]//g' | tr -d ':", ')` simpley looks for the entry .latest and then grabes the value related to release, then it cleans it up by removing the letters to keep the number. So for example it will go from:
1. latest
 - release: "1.20.1"
 - snapshot: "1.20.1"

then it will be turned into just 1.20.1 so that it can then be passed to the purpur url as seen here `https://api.purpurmc.org/v2/purpur/${MCRELEASE}`

After it has got all the information for the 3 main variables it then waits for 0.5 sec then sets the variable DOWN to be the last downloaded build of purpur
`DOWN=$(cat ${PURUR_BACKUP}/build-list.txt)` the release for this is to simpley check to see if the currently running build is new or old.

```shell scripted
sudo jar -xvf /opt/minecraft/server/server.jar version.json
RUNNING=$(jq -r '.id' version.json | sed 's/[a-z]//g' | tr -d ':",')
```
This line is extracting the version.json from the server.jar file which anyone can get if you open the server.jar up with 7-zip, it simpley tells us what the current version, exactly like how it is being done for the curl line but this time just from a file.

```shell scripted
McLocalBuild () {
    clear
    echo "---[Minecraft official Information]---"
    echo "Latest Minecraft Version: ${MCRELEASE}"
    echo "Latest Minecraft Snapshot Version: ${MCSNAPSHOT}"
    echo "Current Running Minecraft Version: ${RUNNING}"
    echo "---[Purpur official Information]---"
    echo "Current Set Purpur Version: ${VERSION}"
    echo "Purpur Build To Download: ${PURPUR_CURRENT}"
    echo "Set Build Branch: ${BUILD}"
    #removes the extracted version file from the server file
    sudo rm version.json
    echo "---[Local Build Information]---"
    echo "Local Purpur Build: ${DOWN}"
    echo "Remote Purpur Build: ${PURPUR_CURRENT}"
}
```

All this is doing is just showing the current builds and removing that version.json that was extracted from the last command. It looks like this when everything is good
```
---[Minecraft official Information]---
Latest Minecraft Version: 1.20.1
Latest Minecraft Snapshot Version: 1.20.1
Current Running Minecraft Version: 1.20.1
---[Purpur official Information]---
Current Set Purpur Version: 1.20.1
Purpur Build To Download: 1996
Set Build Branch: latest
---[Local Build Information]---
Local Purpur Build: 1996
Remote Purpur Build: 1996

```

After all of that we have the update area

```shell scripted
UpdateMc () {
	echo  "--- Purpur Update Found ----"    
        echo  "Old Purpur Build: ${DOWN}"
	echo  "New Purpur Build: ${PURPUR_CURRENT}"
	echo  "----------------------------"
	echo  "Update needed!"
	echo  "----------------------------"
    if systemctl is-active --quiet "$service_name.service" ; then
	    echo  "Service is running stopping service! Updating server jar file please wait 5 mins"
	    ${MCRCON}/mcrcon -H 127.0.0.1 -P 25575 -p rconpassword "say mc server stopping in 15 seconds to update! Join back in 5-10 mins", "save-all"
	    sleep 15
	    sudo systemctl stop mc-fish
    else
      echo -e "Service not running startting update!"
    fi
	echo  "-----------------------------------------[Downloading File]----------------------------------------"
	sleep 15
	if [-d ${PURPUR_BACKUP}]; then
		curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURPUR_BACKUP}/build-list.txt
	else
		mkdir ${PURPUR_BACKUP}
		curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURPUR_BACKUP}/build-list.txt
        fi
	wget -P /tmp/purpur/ https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download --content-disposition

	cd /tmp/purpur
	if [ -d "$PURUR_BACKUP" ]; then
		cp purpur-${VERSION}-${PURPUR_CURRENT}.jar ${PURUR_BACKUP}/purpur-${VERSION}-${PURPUR_CURRENT}.jar
	else
		mkdir ${PURUR_BACKUP}
		cp purpur-${VERSION}-${PURPUR_CURRENT}.jar ${PURUR_BACKUP}/purpur-${VERSION}-${PURPUR_CURRENT}.jar
	fi
	mv purpur-${VERSION}-${PURPUR_CURRENT}.jar server.jar
	#run as root
 	sudo rm /opt/minecraft/server/server.jar
	sudo mv server.jar /opt/minecraft/server
	echo  "  "
	echo  "Server file moved to /opt/minecraft/server"
	echo "Starting server..."
	sleep 2
	sudo systemctl start mc-fish
}
```

The first thing it does is echo's out the new update build number and the local build number as seen here:
```
	echo  "--- Purpur Update Found ----"    
        echo  "Old Purpur Build: ${DOWN}"
	echo  "New Purpur Build: ${PURPUR_CURRENT}"
	echo  "----------------------------"
	echo  "Update needed!"
	echo  "----------------------------"
```

After it has done that it then checks to see if the minecraft service is running, in this case i called my minecraft server fish so the service name is mc-fish.service. If the service is running it will then echo a msg to the user seen here `echo  "Service is running stopping service! Updating server jar file please wait 5 mins"` after that it then calls for mcrcon and connects to the minecraft server telling players that the minecraft server needs to update `${MCRCON}/mcrcon -H 127.0.0.1 -P 25575 -p rconpassword "say mc server stopping in 15 seconds to update! Join back in 5-10 mins", "save-all"` We then wait 15 seconds for players to get off then we stop the service running this `sudo systemctl stop mc-fish`

In the event the service isn't running it will tell the user that the service isn't running as seen here `echo -e "Service not running startting update!"`

Once the service check has been done we wait another 15 sec before starting the download.

To get the download the following gets run

```shell scripted 
	curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURUR_BACKUP}/build-list.txt

	wget -P /tmp/purpur/ https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download --content-disposition

	cd /tmp/purpur
	if [ -d "$PURUR_BACKUP" ]; then
		cp purpur-${VERSION}-${PURPUR_CURRENT}.jar ${PURUR_BACKUP}/purpur-${VERSION}-${PURPUR_CURRENT}.jar
	else
		mkdir ${PURUR_BACKUP}
		cp purpur-${VERSION}-${PURPUR_CURRENT}.jar ${PURUR_BACKUP}/purpur-${VERSION}-${PURPUR_CURRENT}.jar
	fi
	mv purpur-${VERSION}-${PURPUR_CURRENT}.jar server.jar
	#run as root
        sudo rm /opt/minecraft/server/server.jar
	sudo mv server.jar /opt/minecraft/server
	echo  "  "
	echo  "Server file moved to /opt/minecraft/server"
	echo "Starting server..."
	sleep 2
	sudo systemctl start mc-fish

```

The first part `curl -s https://api.purpurmc.org/v2/purpur/${VERSION} | jq '.' | grep -e 'latest' |cut -d ' ' -f 3,6 | tr -d ',' | tr -dc "1-9\n" > ${PURUR_BACKUP}/build-list.tx` this goes to the purpur api using the minecraft version found from the minecraft website. It gets cleaned up to just get the build number and sends that output to a file called build=list.txt.

After that we wget the new build like so `wget -P /tmp/purpur/ https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download --content-disposition` we then check to see if the folder /tmp/purpur and if the folder isn't there then it makes one like so `mkdir ${PURUR_BACKUP}` after that we copy the new purpur jar file. The backup check happens twice.

We proceed to rename the new build .jar file to server.jar using this line `mv purpur-${VERSION}-${PURPUR_CURRENT}.jar server.jar` and then remove the old server.jar from its folder like so `sudo rm /opt/minecraft/server/server.jar` after that we move the new file to the old server.jar folder `sudo mv server.jar /opt/minecraft/server` then tell the user what is happaning and then start the service up again after a 2 sec wait time

```shell scripted
	echo  "  "
	echo  "Server file moved to /opt/minecraft/server"
	echo "Starting server..."
	sleep 2
	sudo systemctl start mc-fish
```

And the last few lines being **84-92** we have a check to see if the current up to date purpur build is the same as the last downloaded one and if it isn't we call the updatemc. If it is up to date then we simpley say "No new updates :)"

```shell scripted
McLocalBuild

if [ ${PURPUR_CURRENT} != ${DOWN} ]; then
    UpdateMc
else
    echo "                "
    echo "No New Update :)"
fi
exit
```
