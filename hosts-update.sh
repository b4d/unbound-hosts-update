#!/bin/bash

DIR=/var/unbound
FILENAME=ads.conf

DATE=$(date '+%Y-%m-%d')

Color_Off='\033[0m'       # Text Reset
Green='\033[0;32m'        # Green

echo -e "${Green} *****************************${Color_Off}"
echo -e "${Green} *${Color_Off} Unbound blocking script ${Green} *${Color_Off}"
echo -e "${Green} *****************************${Color_Off}"


echo " "
echo -e "${Green} -- Backing up old generated file...${Color_Off}"
#rm -v $DIR/$FILENAME-old
cp -vbu $DIR/$FILENAME $DIR/$FILENAME-$DATE
echo

#echo -e "Removing old source file..."
#rm -v $DIR/hosts
#echo

mkdir -p $DIR/lists

echo -e "${Green} -- Downloading new source file...${Color_Off}"
wget -c -N -O $DIR/lists/stevenblack  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
#wget -c -N -O $DIR/lists/malwaredom   https://mirror1.malwaredomains.com/files/justdomains
#wget -c -N -O $DIR/lists/cameleon     http://sysctl.org/cameleon/hosts
#wget -c -N -O $DIR/lists/zeustracker  https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
#wget -c -N -O $DIR/lists/discontrack  https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
#wget -c -N -O $DIR/lists/disconad     https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
#wget -c -N -O $DIR/lists/hostsfile    https://hosts-file.net/ad_servers.txt
echo

echo -e "${Green} -- Removing old generated file...${Color_Off}"
rm -v $DIR/$FILENAME
echo

echo -e "${Green} -- Generating new file from the downloaded source...${Color_Off}"
echo -e "This will take some time...${Color_Off}"
echo " "

CAMELEON="$(cat lists/cameleon | grep -v 'localhost' | sed 's/\t//g' | sed 's/127.0.0.1/0.0.0.0/g' | grep '^0\.0\.0\.0')"
HOSTSFILE="$(cat lists/hostsfile | grep -v 'localhost' | grep -v '^#' | sed 's/\t/ /g' | sed -e "s/\r//g" | sed 's/127.0.0.1/0.0.0.0/g' | grep '^0\.0\.0\.0')"
DISCONAD="$(cat lists/discontrack | grep -v '^#' | grep -v '^$' | sed 's/^/0.0.0.0 /g')"
DISCONTRACK="$(cat lists/discontrack | grep -v '^#' | grep -v '^$' | sed 's/^/0.0.0.0 /g')"
# malwaredom not working, bad parsing
#MALWAREDOM="$(cat lists/malwaredom | sed 's/^/0.0.0.0 /g')"
ZEUSTRACKER="$(cat lists/zeustracker | grep -v '^#' | grep -v '^$' | sed 's/^/0.0.0.0 /g')"
STEVENBLACK="$(cat lists/stevenblack | grep -v 'localhost' | grep '^0\.0\.0\.0')"

CLEAN=$(echo "$STEVENBLACK" "$DISCONAD" "$DISCONTRACK" "$CAMELEON" "$HOSTSFILE" "$ZEUSTRACKER" | cut -d" " -f1,2 | sort | uniq -u)

echo "$CLEAN" | awk '{print "local-zone: \""$2"\" redirect\nlocal-data: \""$2" A 0.0.0.0\""}' > $DIR/$FILENAME

#diff $DIR/$FILENAME $DIR/$FILENAME-old

echo -e "${Green} -- Total number of blocked hosts:${Color_Off}"
echo "$CLEAN" | wc -l
echo " "

echo -e "${Green} -- Reloading unbound service configuration...${Color_Off}"
service unbound reload
