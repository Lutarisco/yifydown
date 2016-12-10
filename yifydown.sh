#!/bin/bash
#
# YIFY movies downloader, using yts.ag web api, by Lutarisco (GNU GPLv3)

# define usage
function usage () {
  cat <<eof
  usage: $(basename "${0}") [options] [query]
  options:
  -h | help
  -q | quality [720p|1080p|3D]
  -f | just download first result"
eof
  exit 0
}

# parse options
while getopts ":fq:h" opt; do
  case "${opt}" in
    f ) result='0' ;;
    q ) quality="${OPTARG}" ;;
    h ) usage ;;
    \?) usage ;;
  esac
done
shift "$((${OPTIND} - 1))"

if [ -z "${1}" ]; then
  echo "error: no query given"
  usage
  exit 1
fi

query="${@}"
url="https://yts.ag/api/v2/list_movies.json?query_term=${query// /+}&sort_by=year&order_by=asc&limit=50"
api='https://yts.ag/api/v2/list_movies.json'

# if get doesn't return successfully (200), exit.
get="$(curl -sw %{http_code} -o /dev/null "${api}")"
if [ "${get}" != 200 ]; then
  echo "error: http status ${get}"
  exit 1
fi


data="$(curl -s "${url}")"
results="$(echo "${data}" | jshon -e data -e movie_count -u)"

if [ -n "${result}" ]; then
  echo "$(echo "${data}" | jshon -e data -e movies -e 0 -e title_long -u)"
elif [ "${results}" -eq 0 ]; then
  echo 'sorry, no results found.'
  exit 1
elif [ "${results}" -eq 1 ]; then
  echo '1 movie found.'
else
  echo "${results} movies found."
fi

# prompt movie confirmation.
until [ -n "${result}" ]; do
  for v in $(seq 0 "$((${results} - 1))"); do
    while [ $? = 0 ]; do
      echo "is this the correct movie? (y/yes)(n/no)(s/summary)(q/quit)"
      movies="$(echo "${data}" | jshon -e data -e movies)"
      echo "$(echo "${movies}" | jshon -e "${v}" -e title_long -u)"
      read -sn 1 bool
      if [ "${bool}" = y ]; then
        result="${v}"
        break 3
      elif [ "${bool}" = n ]; then
        echo "sorry, please try again."
        break 1
      elif [ "${bool}" = s ]; then
        echo "${data}" | jshon -e data -e movies -e ${v} -e summary -u
        echo
      elif [ "${bool}" = q ]; then
        exit 0
      else
        echo "sorry, please try again."
        break 1
      fi
    done
  done
done

slug="$(echo "${data}" | jshon -e data -e movies -e "${result}" -e slug -u)"
torrents="$(echo "${data}" | jshon -e data -e movies -e "${result}" -e torrents)"
torrentnumbers="$(echo "${torrents}" | jshon -l)"
imdb="$(echo "${data}" | jshon -e data -e movies -e "${result}" -e imdb_code -u)"

# prompt quality confirmation.
if [ -n "${quality}" ]; then
  for v in $(seq 1 "${torrentnumbers}"); do
    if [ "${quality}" = "$(echo "${torrents}" | jshon -e "${v}" -e quality -u)" ]; then
      torrentnumber="${v}"
    fi
  done
  if [ -z "${torrentnumber}" ]; then
  echo "sorry, there is not such quality available."
  quality=""
  fi
fi
until [ -n "${quality}" ]; do
  echo "available qualities:"
  echo "("$(for v in $(seq 1 ${torrentnumbers}); do echo "${torrents}" \
    | jshon -e "${v}" -e quality -u; done \
    | while read v; do echo -n "${v}/"; done \
    | sed "s+/+)+${torrentnumbers}")"(quit)"
  read quality

  for v in $(seq 1 "${torrentnumbers}"); do
    torrqual="$(echo "${torrents}" | jshon -e "${v}" -e quality -u)"
    if [ "${quality}" = "${torrqual}" ]; then
      torrentnumber="${v}"
    fi
  done

  if [ "${quality}" = "quit" ]; then
    exit 0
  elif [ -z "${torrentnumber}" ]; then
    quality=""
    echo "sorry, please try again."
  elif [ -z "${quality}" ]; then
    echo "sorry, please try again."
  fi
done

# download spanish subs if any.
subsdata="$(curl -s "http://api.yifysubtitles.com/subs/${imdb}")"
if [ "$(echo "${subsdata}" | jshon -e success -u)" == true ]; then
  subs="$(echo "${subsdata}"| jshon -e subs -e "${imdb}")"
  spanishsub="$(echo "${subs}" | jshon -e spanish -e 1 -e url -u)"
  echo -n "downloading spanish subtitles..."
  curl -LOs "http://www.yifysubtitles.com${spanishsub}"
  echo ' done.'
fi

# finally, construct magnet url and download.
hash="$(echo "${torrents}" | jshon -e "${torrentnumber}" -e hash -u)"
size="$(echo "${torrents}" | jshon -e "${torrentnumber}" -e size -u)"
magnet="magnet:?xt=urn:btih:${hash}&dn=${slug//-/+}&tr=udp://tracker.opentrackr.org:13\
37/announce&tr=udp://torrent.gresille.org:80/announce&tr=udp://tracker.openbittorren\
t.com:80&tr=udp://tracker.coppersurfer.tk:6969&tr=udp://tracker.leechers-paradise.or\
g:6969&tr=udp://p4p.arenabg.ch:1337&tr=udp://tracker.internetwarriors.net:1337"

echo "file size: ${size}"
echo "now downloading..."
aria2c --file-allocation=none --seed-time=0 "${magnet}"
