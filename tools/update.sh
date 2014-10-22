#!/usr/bin/env bash -i
# Copyright (c) Jan Chren 2014
# Licensed under BSD 3

export CYGWIN="nodosfilewarning $CYGWIN"

OUTPUT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR+="/../src"

WXSQLITE_SF_API_URL="http://sourceforge.net/api/file/index/project-id/51305/crtime/desc/limit/2/path/Components%2fwxSQLite3/rss"
WXSQLITE_SF_API_SRC="$( wget -qO - "$WXSQLITE_SF_API_URL" | tr -d "\n" )"
WXSQLITE_URL="$( echo "$WXSQLITE_SF_API_SRC" | sed -r 's/.*<link>([^<]*\.tar\.gz\/download).*/\1/' )"

function get_sqlite_version(){
  cat "$OUTPUT_DIR/sqlite3.h" | grep -m 1 "#define SQLITE_VERSION" | sed -r 's/.*"([0-9.]*)".*/\1/'
}

OLD_VERSION="$( get_sqlite_version )"

pushd "$OUTPUT_DIR" &>/dev/null
wget -qO - "$WXSQLITE_URL" \
| tar xvzf - --wildcards "*/secure/src/*" --show-transformed --xform='s/.*\///'
popd &>/dev/null

printf "\nSQLite3 updated from %s to %s\n" "$OLD_VERSION" "$( get_sqlite_version )"
