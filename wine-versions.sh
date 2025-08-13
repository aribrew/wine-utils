#!/bin/bash

DISTRO_VERSION_CODENAME="bookworm"


REGEXP='wine-(stable|staging)_'
REGEXP+='[0-9]{1,2}(\.[0-9]{1,2}){1,3}'
REGEXP+="~(${DISTRO_VERSION_CODENAME})-1_"
REGEXP+='(i386|amd64)\.deb'


WINE_URL="https://dl.winehq.org/wine-builds"

DEBIAN_STABLE_URL="$WINE_URL/debian/pool/main/w/wine/"
DEBIAN_STAGING_URL="$WINE_URL/debian/pool/main/w/wine-staging/"

TMPFILE="/tmp/winehq_pool.html"


curl -s -L "$DEBIAN_STABLE_URL" > "$TMPFILE"
grep -oE "$REGEXP" "$TMPFILE" | sort -u > /tmp/wine-versions.lst


curl -s -L "$DEBIAN_STAGING_URL" > "$TMPFILE"
grep -oE "$REGEXP" "$TMPFILE" | sort -u >> /tmp/wine-versions.lst

