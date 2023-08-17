#!/bin/sh
set -e

getServiceIP () {
    dig "$1" +short
}

waitOrFail () {
    maxTries=24
    i=0
    while [ $i -lt $maxTries ]; do
        outStr="$($@)"
        if [ $? -eq 0 ];then
            echo "$outStr"
            return
        fi
        i=$((i+1))
        echo "==> waiting for a dependent service $i/$maxTries" >&2
        sleep 5
    done
    echo "Too many failed attempts" >&2
    exit 1
}

UNBOUND_SERVICE_HOST=${UNBOUND_SERVICE_HOST-"9.9.9.11"}
UNBOUND_SERVICE_PORT=${UNBOUND_SERVICE_PORT-"53"}
while getopts "h?d" opt; do
    case "$opt" in
        h|\?) echo "-d  domain lookup for service discovery"; exit 0;;
        d) UNBOUND_SERVICE_HOST="$(waitOrFail getServiceIP unbound)"
        ;;
    esac
done
shift $((OPTIND-1))
export RESOLVER="$UNBOUND_SERVICE_HOST:$UNBOUND_SERVICE_PORT"

if [ $# -eq 0 ]; then
    echo "doh-proxy - resolver: $RESOLVER"
    exec /usr/local/bin/doh-proxy --server-address "${RESOLVER}" --listen-address 0.0.0.0:3000
fi

[ "$1" = '--' ] && shift

exec /usr/local/bin/doh-proxy "$@"