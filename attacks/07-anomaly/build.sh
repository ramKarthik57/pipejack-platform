#!/bin/bash
set -e
BANKING=~/banking-api
SRC="$(dirname "$(realpath "$0")")"
OUT=/tmp/attack-07-anomaly.tar.gz
[ -d "$BANKING/src" ] || { echo "ERROR: $BANKING/src missing" >&2; exit 1; }
STAGE=$(mktemp -d)
mkdir -p "$STAGE/src"
cp -r "$BANKING/src/." "$STAGE/src/"
cp "$SRC/pom.xml"    "$STAGE/pom.xml"
cp "$SRC/attack.sh"  "$STAGE/attack.sh"
tar -czf "$OUT" -C "$STAGE" .
echo "built $OUT"
ls -la "$OUT"
rm -rf "$STAGE"
