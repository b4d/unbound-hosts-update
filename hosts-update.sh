#!/bin/bash

DIR=/var/unbound
FILENAME=ads.conf

echo -e "Backing up old generated file..."
#rm -v $DIR/$FILENAME-old
cp -vbu $DIR/$FILENAME $DIR/$FILENAME-old
echo

#echo -e "Removing old source file..."
#rm -v $DIR/hosts
#echo

mkdir -p $DIR/lists

echo -e "Downloading new source file..."
wget -c -N -O $DIR/lists/stevenblack  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
#wget -c -N -O $DIR/lists/malwaredom   https://mirror1.malwaredomains.com/files/justdomains
wget -c -N -O $DIR/lists/cameleon     http://sysctl.org/cameleon/hosts
wget -c -N -O $DIR/lists/zeustracker  https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
wget -c -N -O $DIR/lists/discontrack  https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
wget -c -N -O $DIR/lists/disconad     https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
wget -c -N -O $DIR/lists/hostsfile    https://hosts-file.net/ad_servers.txt
echo

echo -e "Removing old generated file..."
rm -v $DIR/$FILENAME
echo

echo -e "Generating new file from the downloaded source..."
echo -e "This will take some time..."

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

echo -e "Total number of blocked hosts:"
echo "$CLEAN" | wc -l

echo -e "Reloading unbound service configuration..."
service unbound reload
