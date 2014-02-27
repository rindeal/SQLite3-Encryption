wxSQLite3 with Visual Studio solution
=======================================

## What?

wxSQLite3 is a C++ wrapper around the public domain **SQLite 3.x database** and is specifically designed for use in programs based on the wxWidgets library. wxSQLite3 includes an optional extension for SQLite supporting key based database file encryption using **128/256 bit AES encryption**. The encryption extension is compatible with the SQLite amalgamation source.

## Why?

There are more ways how to add encryption to your SQLite3 DBs. However, this absolutely the most no-pain solution I've found for Windows.

## How?

### Build

#### Requirements

- MS Visual Studio 2013 *(2012 may also work)*

#### Steps

1. `Build -> Configuration manager`, choose `Win32` or `x64` platform
2. `Build -> Build sqlite3`
3. In the project root folder you'll find a new folder `Release` containing all required files

### Update

#### Automatic

- **Requires: bash, wget, zip**
- if you have all these utilities in `%PATH%`, then just run `update.bat`


#### Manual

1. Download the latest [wxsqlite3](http://sourceforge.net/projects/wxcode/files/Components/wxSQLite3/)
2. Extract the `wxsqlite3-3.x.x/sqlite3/secure/src` folder from the archive to `sqlite3` under the project root dir.

## API


