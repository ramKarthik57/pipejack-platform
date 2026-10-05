#!/bin/bash
# Scenario 1 — build the tarball for upload
# Layout of the tarball:
#   pom.xml       (attack-triggering pom)
#   attack.sh     (payload)
#   src/...       (Banking API source)
set -e

BANKING=~/banking-api
SRC="$(dirname "$(realpath "$0")")"
OUT=/tmp/attack-01-shell-exec.tar.gz

if [ ! -d "$BANKING/src" ]; then
    echo "ERROR: $BANKING/src not found" >&2
    exit 1
fi

STAGE=$(mktemp -d)
mkdir -p "$STAGE/src"
cp -r "$BANKING/src/." "$STAGE/src/"
cp "$SRC/pom.xml"    "$STAGE/pom.xml"
cp "$SRC/attack.sh"  "$STAGE/attack.sh"

tar -czf "$OUT" -C "$STAGE" .

echo "built $OUT"
ls -la "$OUT"
echo
echo "contents (top 8):"
tar -tzf "$OUT" | head -8

rm -rf "$STAGE"
