#!/bin/bash
#
# YIFY movies downloader, using YTS.ag Web API, by Lutarisco (GNU GPLv3)

# Define usage.
function usage () {
  cat <<EOF
  Usage: $(basename $0) [options] [query]
  Options:
  -h | help
  -q | quality [720p|1080p|3D]
  -f | just download first result"
EOF
  exit 0
}

# Parse options
while getopts ":fq:h" opt; do
  case $opt in
    f ) RESULT=0 ;;
    q ) QUALITY="$OPTARG" ;;
    h ) usage ;;
    \?) usage ;;
  esac
done
shift $(($OPTIND - 1))

if [ -z "$1" ]; then
  echo "ERROR: no query given"
  usage
  exit 1
fi

QUERY="$@"
URL="https://yts.ag/api/v2/list_movies.json?query_term=${QUERY// /+}&sort_by=year&order_by=asc&limit=50"

# If GET doesn't return successfully (200), exit.
get=$(curl -sw %{http_code} -o /dev/null https://yts.ag/api/v2/list_movies.json)
if [ "$get" != 200 ]; then
  echo "HTTP Error: $get"
  exit 1
fi


DATA="$(curl -s "$URL")"
RESULTS="$(echo "$DATA" | jshon -e data -e movie_count -u)"

if [ -n "$RESULT" ]; then
  true
elif [ "$RESULTS" -eq 0 ]; then
  echo 'Sorry, no results found.'
  exit 1
elif [ "$RESULTS" -eq 1 ]; then
  echo '1 movie found.'
else
  echo "$RESULTS movies found."
fi

# Prompt movie confirmation.
until [ -n "$RESULT" ]; do
  for v in $(seq 0 "$((${RESULTS} - 1))"); do
    while [ $? = 0 ]; do
      echo "Is this the correct movie? (y/yes)(n/no)(s/summary)(q/quit)"
      echo "$(echo "$DATA" | jshon -e data -e movies -e "$v" -e title_long -u)"
      read -sn 1 BOOL
      if [ "$BOOL" = y ]; then
        RESULT="$v"
        break 3
      elif [ "$BOOL" = n ]; then
        echo "Sorry, please try again."
        break 1
      elif [ "$BOOL" = s ]; then
        echo "$DATA" | jshon -e data -e movies -e $v -e summary -u
        echo
      elif [ "$BOOL" = q ]; then
        exit 0
      else
        echo "Sorry, please try again."
        break 1
      fi
    done
  done
done

SLUG="$(echo "$DATA" | jshon -e data -e movies -e "$RESULT" -e slug -u)"
TORRENTS="$(echo "$DATA" | jshon -e data -e movies -e "$RESULT" -e torrents)"
TORRENTNUMBERS="$(echo "$TORRENTS" | jshon -l)"

# Prompt quality confirmation.
if [ -n "$QUALITY" ]; then
  for v in $(seq 1 "$TORRENTNUMBERS"); do
    if [ "$QUALITY" = "$(echo "$TORRENTS" | jshon -e "$v" -e quality -u)" ]; then
      TORRENTNUMBER="$v"
    fi
  done
  if [ -z "$TORRENTNUMBER" ]; then
  echo "Sorry, there is not such quality available."
  QUALITY=""
  fi
fi
until [ -n "$QUALITY" ]; do
  echo "Available qualities:"
  echo "("$(for v in $(seq 1 $TORRENTNUMBERS); do echo "$TORRENTS" \
    | jshon -e "$v" -e quality -u; done \
    | while read v; do echo -n "$v/"; done \
    | sed "s+/+)+$TORRENTNUMBERS")"(quit)"
  read QUALITY

  for v in $(seq 1 "$TORRENTNUMBERS"); do
    if [ "$QUALITY" = "$(echo "$TORRENTS" | jshon -e "$v" -e quality -u)" ]; then
      TORRENTNUMBER="$v"
    fi
  done

  if [ "$QUALITY" = "quit" ]; then
    exit 0
  elif [ -z "$TORRENTNUMBER" ]; then
    QUALITY=""
    echo "Sorry, please try again."
  elif [ -z "$QUALITY" ]; then
    echo "Sorry, please try again."
  fi
done

# Finally, construct Magnet URL and download.
HASH=$(echo $TORRENTS | jshon -e $TORRENTNUMBER -e hash -u)
SIZE=$(echo $TORRENTS | jshon -e $TORRENTNUMBER -e size -u)
MAGNET="magnet:?xt=urn:btih:$HASH&dn=${SLUG//-/+}&tr=udp://glotorrents.pw:6969/\
announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://torrent.gresill\
e.org:80/announce&tr=udp://tracker.openbittorrent.com:80&tr=udp://tracker.coppe\
rsurfer.tk:6969&tr=udp://tracker.leechers-paradise.org:6969&tr=udp://p4p.arenab\
g.ch:1337&tr=udp://tracker.internetwarriors.net:1337"
echo "Now downloading..."$'\n'"File size: $SIZE"
aria2c --seed-time=0 "$MAGNET"
