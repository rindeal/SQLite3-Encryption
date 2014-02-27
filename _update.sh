#!/usr/bin/env bash -i

export CYGWIN="nodosfilewarning $CYGWIN"

OUTPUT_DIR="src"

WGET="wget -q"
UNZIP="unzip -jo"

WXSQLITE_SF_API_URL="http://sourceforge.net/api/file/index/project-id/51305/crtime/desc/limit/1/path/Components%2fwxSQLite3/rss"
WXSQLITE_VERSION="$( wget -qO - "$WXSQLITE_SF_API_URL" | sed -rn 's/.*wxsqlite3-([0-9.]*)\..*/\1/p' | head -1 )"
WXSQLITE_URL="http://sourceforge.net/projects/wxcode/files/Components/wxSQLite3/wxsqlite3-$WXSQLITE_VERSION.zip/download"
TMP_FILE="/tmp/tmp$RANDOM$RANDOM"

$WGET -O "$TMP_FILE" "$WXSQLITE_URL"
$UNZIP -d "$OUTPUT_DIR" "$TMP_FILE" "*secure/src/*"
rm -f "$TMP_FILE" 
