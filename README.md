wxSQLite3 in Visual Studio
============================

What?
------

wxSQLite3 is a C++ wrapper around the public domain **SQLite 3.x database** and is specifically designed for use in programs based on the wxWidgets library. wxSQLite3 includes an optional extension for SQLite supporting key based database file encryption using **128/256 bit AES encryption**. The encryption extension is **compatible** with the SQLite amalgamation source.

Long story short: 
> **SQLite3 with encryption**

With this solution you can build anything or all of the below and use it anywhere with whatever you want:

##### Dynamically linked library
- sqlite3.dll (128-bit AES)
- sqlite3-x64.dll (128-bit AES)
- sqlite3.dll (256-bit AES)
- sqlite3-x64.dll (256-bit AES)

##### Statically linked library
- sqlite3.lib (128-bit AES)
- sqlite3-x64.lib (128-bit AES)
- sqlite3.lib (256-bit AES)
- sqlite3-x64.lib (256-bit AES)

##### Command line shell
- sqlite3.exe (128-bit AES)
- sqlite3-x64.exe (128-bit AES)
- sqlite3.exe (256-bit AES)
- sqlite3-x64.exe (256-bit AES)

Why?
-----

There are more ways how to add a native on-the-fly encryption layer to your SQLite3 DBs. This is, however, absolutely the most convenient solution I've found/built for Windows.

How?
-----

### How to get from this page to a successful build?

#### Requirements

- Windows 7 and up
- [MS Visual Studio](http://www.visualstudio.com/products/visual-studio-express-vs) 2012/13 *(2010 not tested)*
- [Premake4](http://industriousone.com/premake/download) version **4.4+**

#### Steps

1. [Download this repository](https://github.com/rindeal/wxSQLite3-VS/archive/master.zip)
2. Extract the dir `wxSQLite3-VS-master` from the archive wherever you want and rename it to whatever you want
3. Open CMD
4. `cd` into that folder
5. type one of:
  - `premake4` - *recommended*, by default it creates MS VS 2012 files, which can be upgraded upwards
  - `premake4 vs2010`
  - `premake4 vs2012`
  - `premake4 vs2013` *(returns errors in my case)*
6. the solution file (`.sln`) should be now in the project root folder, open it in VS as usual
7. upgrade the solution if needed, eg. if you have VS2013 and you created 2012 solution (automatic prompt or `Project -> Upgrade Solution`)
8. `Build -> Configuration Manager` and choose configurations and platforms you want to build
9. And here we go `Build -> Build Solution` 
10. There should be a `bin` dir in the project root folder where you'll find all required files

### How to update it to the most recent version of SQLite?
- Because the developers of the wxSQLite extension needs to incorporate the changes with every new version of SQLite, there is a time lag between a new version of SQLite and wxSQLite, but if you want to update this project to the most recent version of wxSQLite you can do this in two ways:

#### Automatic

- **Requires: bash, wget, tar, gzip**
- if you have all these utilities in `%PATH%` (for CMD) or `$PATH` (for Cygwin, MSYS...), then just run `premake4 update`


#### Manual

1. Download the latest [wxsqlite3](http://sourceforge.net/projects/wxcode/files/Components/wxSQLite3/)
2. Extract the `wxsqlite3-*/sqlite3/secure/src` dir from the archive to `src` in the project root dir.

API
=====

Functions
-----------

### sqlite3_key, sqlite3_key_v2
> Set the key for use with the database

- This routine should be called right after `sqlite3_open`.
- The `sqlite3_key_v2` call performs the same way as `sqlite3_key`, but sets the encryption key on a named database instead of the main database.

```c
int sqlite3_key(
  sqlite3 *db,                   /* Database to be rekeyed */
  const void *pKey, int nKey     /* The key, and the length of the key in bytes */
);
int sqlite3_key_v2(
  sqlite3 *db,                   /* Database to be rekeyed */
  const char *zDbName,           /* Name of the database */
  const void *pKey, int nKey     /* The key, and the length of the key in bytes */
);
```

#### Testing the key
When opening an existing database, `sqlite3_key` will not immediately throw an error if the key provided is incorrect. To test that the database can be successfully opened with the provided key, it is necessary to perform some operation on the database (i.e. read from it) and confirm it is success.

The easiest way to do this is select off the `sqlite_master` table, which will attempt to read the first page of the database and will parse the schema.

```sql
SELECT count(*) FROM sqlite_master; -- if this throws an error, the key was incorrect. If it succeeds and returns a numeric value, the key is correct;
```

### sqlite3_rekey, sqlite3_rekey_v2
> Change the encryption key for a SQLCipher database

- If the current database is not encrypted, this routine will encrypt it.
- If `pNew==0` or `nNew==0`, the database is **decrypted**.
- The `sqlite3_rekey_v2` call performs the same way as `sqlite3_rekey`, but sets the encryption key on a named database instead of the main database.

```c
int sqlite3_rekey(
  sqlite3 *db,                   /* Database to be rekeyed */
  const void *pKey, int nKey     /* The new key, and the length of the key in bytes */
);
int sqlite3_rekey_v2(
  sqlite3 *db,                   /* Database to be rekeyed */
  const char *zDbName,           /* Name of the database */
  const void *pKey, int nKey     /* The new key, and the length of the key in bytes */
);
```

Tutorials
----------

### Encrypting a new db
```c
open
key
use as usual
```

### Opening an encrypted DB
```c
open
key
use as usual
```

### Changing the key
```c
open
key
rekey
use as usual
```

### Decrypting
```c
open
key
rekey with null
use as usual
```

#### [Read more](http://sqlcipher.net/sqlcipher-api/)

----------



