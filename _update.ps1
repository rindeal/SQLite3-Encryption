# Copyright (c) Jan Chren 2014
# Licensed under BSD 3

# This script updates wxSQLite3 sqlite3 source code

"Updating of sqlite3 started"

$OUTPUT_DIR = "$PSScriptRoot\src"
$TMP_FILE   = "$env:TMP\wxsqlite.zip"

$CP_HERE_YES_TO_ALL=16

$WebClient  = New-Object System.Net.WebClient
$Shell      = New-Object -com Shell.Application

$WXSQLITE_SF_API_URL = "http://sourceforge.net/api/file/index/project-id/51305/crtime/desc/limit/2/path/Components%2fwxSQLite3/rss"
$WXSQLITE_SF_API_SRC = $WebClient.DownloadString($WXSQLITE_SF_API_URL)
$WXSQLITE_URL        = $WXSQLITE_SF_API_SRC -replace "`n|`r" -replace '.*<link>([^<]*\.zip\/download).*','$1'


function get_sqlite_version(){
    Get-Content "$OUTPUT_DIR\sqlite3.h" | where { $_ -match "#define SQLITE_VERSION " } | %{$_ -replace '.*"([\d.]{5,})".*', '$1'}
}

$OLD_VERSION = get_sqlite_version

$WebClient.DownloadFile($WXSQLITE_URL,$TMP_FILE)

$zip = $Shell.Namespace($TMP_FILE)
foreach($item in $zip.items())
{
    if ( $item.Name -like "wxsqlite3-*" ){
            $items = $Shell.NameSpace("$TMP_FILE\"+$item.Name+"\sqlite3\secure\src").Items()
            $shell.Namespace($OUTPUT_DIR).Copyhere($items, $CP_HERE_YES_TO_ALL)
    }
    
}

Remove-Item $TMP_FILE

"Sqlite has been updated from {0} to {1}" -f $OLD_VERSION, $(get_sqlite_version)