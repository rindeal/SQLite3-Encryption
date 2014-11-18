wxSQLite3 in Visual Studio
============================

For those in a hurry, click [here](#how)

What?
------
> **SQLite3 with encryption support**

This repository is dedicated to a set of my scripts which drastically decrease the time and effort you need to build SQLite3 DLL, SLL or shell.
It's based on [**wxSQLite3**][wxsqlite3-source] which includes an optional extension for SQLite supporting key based database file encryption using **128/256\* bit AES encryption**. Although wxSQLite3 is specifically designed for use in programs based on the [wxWidgets library](https://www.wxwidgets.org/) it **can be used anywhere**, because the encryption extension is compatible with the [SQLite amalgamation source](https://www.sqlite.org/amalgamation.html).

_\*Support for 256 bit AES encryption is experimental_

### What can be built with this solution?
> sqlite3-x{86, 64}.{dll, lib, exe} - ({128, 256}-bit AES)

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

I should also mention that these binaries are built **without any** special runtime **dependencies** like _Microsoft .NET Framework_ or _Microsoft Visual C++ Redistributable Packages_

Why?
-----

There are more ways how to add a _native_ on-the-fly encryption layer to your SQLite3 DBs. Namely:

- [SQLite Encryption Extension](https://www.sqlite.org/see) - from authors of SQLite, commercial, $2000
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - partially opensource, but I didn't manage to get it working on Windows
- [SQLiteCrypt](http://sqlite-crypt.com/index.htm) - commercial, $128

But I find this solution the most easiest and convenient one.

How?
-----

### How to get from this page to successful build?

#### Requirements

- Windows 7 and up
- [MS Visual Studio](http://www.visualstudio.com/products/visual-studio-express-vs) 2012/13 *(2010 not tested)*
- [Premake4](http://industriousone.com/premake/download) version **4.4+** _(included in the repo)_

#### Steps

1. [Download this repository](https://github.com/rindeal/wxSQLite3-VS/archive/master.zip)
2. Extract the dir `wxSQLite3-VS-master` and open it
3. Run `premake.bat` or `premake4.bat`
4. Open the produced solution file (`.sln`) that should be now in the project root folder, open it in VS as usual and upgrade the solution if needed, eg. if you have VS2013 and you created 2012 solution (automatic prompt or `Project -> Upgrade Solution`)
5. `Build -> Configuration Manager` and choose configurations and platforms you want to build
6. And here we go `Build -> Build Solution` 
7. You should find the produced binaries in `bin` dir in the project root folder

**Following these steps and building all binaries in their _Release_ versions took me ~2 minutes on my laptop.**

> Please note that by default it creates configuration files optimized for speed. Most of the optimizations are compatible with any PC, but eg. AVX CPU instruction sets may not be compatible with some older computers. If you want to remove these compiler/linker switches, please, look at the `premake4.lua` file or disable them in MS Visual Studio before you build the solution.

### How to update it to the most recent version of SQLite?
Because the developers of the wxSQLite extension needs to incorporate the changes with every new version of SQLite, there is a time lag between a new version of SQLite and wxSQLite, but if you want to update this project to the most recent version of wxSQLite you can do this in two ways:

#### Automatic

- Run `tools\update.bat` or `premake update`

> *Requires _PowerShell_

#### Manual

1. Download the latest [wxsqlite3 source code](http://sourceforge.net/projects/wxcode/files/Components/wxSQLite3/)
2. Extract the `wxsqlite3-*/sqlite3/secure/src` dir from the archive to `src` dir in the project root dir.

SQLite3 Encryption API
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
> Change the encryption key for a database

- If the current database is not encrypted, this routine will encrypt it.
- If `pKey==0` or `nKey==0`, the database is **decrypted**.
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

----------
## Read more
- [sqlcipher-api]
- [wxsqlite3-source]
- [wxsqlite3-docs]

[sqlcipher-api]: http://sqlcipher.net/sqlcipher-api/ "SQLCipher API"
[wxsqlite3-source]: http://wxcode.sourceforge.net/components/wxsqlite3/ "wxSQLite3 Source Code"
[wxsqlite3-docs]: http://wxcode.sourceforge.net/docs/wxsqlite3/ "wxSQLite3 Docs"
