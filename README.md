wxSQLite3 with Visual Studio
============================

What?
------

wxSQLite3 is a C++ wrapper around the public domain **SQLite 3.x database** and is specifically designed for use in programs based on the wxWidgets library. wxSQLite3 includes an optional extension for SQLite supporting key based database file encryption using **128/256 bit AES encryption**. The encryption extension is compatible with the SQLite amalgamation source.

Why?
-----

There are more ways how to add encryption to your SQLite3 DBs. However, this absolutely the most no-pain solution I've found for Windows.

How?
-----

### Build

#### Requirements

- MS Visual Studio 2012/13 *(2010 not tested)*
- Premake4 version **4.4+**

#### Steps

1. `cd` into the project folder
2. type one of:
  - `premake4` - by default it creates MS VS 2012 files *(`premake4 vs2013` returns error for me)*
  - `premake4 vs2010`
3. the solution file (`.sln`) is now in the project root folder, open it as usual
4. upgrade the solution if needed (automatic prompt or `Project -> Upgrade Solution`)
5. `Build -> Configuration Manager` and choose configurations and platforms
6. `Build -> Build Solution`
7. In the project root folder you'll find a new folder `bin` containing all required files

### Update

#### Automatic

- **Requires: bash, wget, zip**
- if you have all these utilities in `%PATH%`, then just run `_update.bat`


#### Manual

1. Download the latest [wxsqlite3](http://sourceforge.net/projects/wxcode/files/Components/wxSQLite3/)
2. Extract the `wxsqlite3-3.x.x/sqlite3/secure/src` folder from the archive to `src` under the project root dir.

API
=====

## sqlite3_rekey
### Set the key for use with the database
```c
int sqlite3_key(
  sqlite3 *db,                   /* Database to be rekeyed */
  const void *pKey, int nKey     /* The key, and the length of the key in bytes */
);
```
## sqlite3_rekey
### Change the encryption key for a SQLCipher database
```c
int sqlite3_rekey(
  sqlite3 *db,                   /* Database to be rekeyed */
  const void *pKey, int nKey     /* The new key, and the length of the key in bytes */
);
```


