#!/bin/bash
# YIFY movies downloader, using YTS.ag Web API, by Lutarisco (GNU GPLv3)

# Joint the input.
QUERY="$@"

if [ -z "$QUERY" ]
then echo 'Usage: yify [string]'
exit 1
fi

# If the server is unavailable, exit.
HTTPCODE=$(curl --write-out %{http_code} --silent --output /dev/null https://yts.ag/api/v2/list_movies.json)
if [ "$HTTPCODE" != 200 ]
then echo "HTTP Error: $HTTPCODE"
exit 1
fi

# Parse the API's json to get the first result's data.
DATA=$(curl -s "https://yts.ag/api/v2/list_movies.json?query_term=${QUERY// /+}")
SLUG=$(echo $DATA | jshon -e data -e movies -e 1 -e slug -u)
TITLE_LONG=$(echo $DATA | jshon -e data -e movies -e 1 -e title_long -u)
TORRENTS=$(curl -s "https://yts.ag/api/v2/list_movies.json?query_term=Inside+Out" | jshon -e data -e movies -e 1 -e torrents)

# Verify results. If zero, exit.
RESULTS=$(echo $DATA | jshon -e data -e movie_count -u)
if [ "$RESULTS" -eq 0 ]
then echo Sorry, no results found.
exit 1
elif [ "$RESULTS" -eq 1 ]
then echo "1 movie found."
else echo "$RESULTS movies found."
fi

# Extract torrents data
TORRENTNUMBERS=$(echo $TORRENTS | jshon -l)
for v in $(seq 1 $TORRENTNUMBERS)
do
export TORRENTQUALITY"$v"=$(echo $TORRENTS | jshon -e $v -e quality -u)
done

# Prompt movie confirmation.
RC=1
while [ "$RC" -ne 0 ]
do
echo "Is this movie correct? (y/yes)(n/no)(s/summary)"$'\n'"$TITLE_LONG"
read -sn 1 BOOL
if [ $BOOL = y ]
then $(exit 0)
elif [ $BOOL = n ]
then echo Sorry.
exit 0
elif [ $BOOL = s ]
then echo $DATA | jshon -e data -e movies -e 1 -e summary -u
echo
$(exit 1)
else echo "Sorry, please try again."
$(exit 1)
fi
RC=$?
done

# Prompt quality confirmation.
RC=1
while [ "$RC" -ne 0 ]
do
echo "Available qualities:"$'\n'"$(echo "($(for v in $(seq 1 $TORRENTNUMBERS); do echo $TORRENTS | jshon -e $v -e quality -u; done | while read v; do echo -n "$v/"; done | sed "s+/+)+$TORRENTNUMBERS")")"
read -e QUALITY
IFOPTIONS=$(for v in $(seq 1 $TORRENTNUMBERS); do echo $TORRENTS | jshon -e $v -e quality -u; done | while read v; do echo -n "$QUALITY = $v -o "; done)
IFOPTIONS=${IFOPTIONS::${#IFOPTIONS}-4}
if [ $IFOPTIONS ]
then $(exit 0)
else echo "Sorry, please try again."
$(exit 1)
fi
RC=$?
done

# Finally, construct Magnet URL and download.
for v in ${!TORRENTQUALITY*}
do
if [ "$QUALITY" = "${!v}" ]
then TORRENTNUMBER=${v#TORRENTQUALITY}
fi
done
HASH=$(echo $TORRENTS | jshon -e $TORRENTNUMBER -e hash -u)
SIZE=$(echo $TORRENTS | jshon -e $TORRENTNUMBER -e size -u)
MAGNET="magnet:?xt=urn:btih:$HASH&dn=${SLUG//-/+}&tr=udp://glotorrents.pw:6969/announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://torrent.gresille.org:80/announce&tr=udp://tracker.openbittorrent.com:80&tr=udp://tracker.coppersurfer.tk:6969&tr=udp://tracker.leechers-paradise.org:6969&tr=udp://p4p.arenabg.ch:1337&tr=udp://tracker.internetwarriors.net:1337"
echo "Now downloading..."
aria2c --seed-time=0 $MAGNET
