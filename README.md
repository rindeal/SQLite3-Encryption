SQLite3 with encryption
============================

What?
------
- SQLite3 with a key based transparent encryption layer (128/256*-bit AES), which encrypts everything including metadata
- drop-in/drop-out
  - you may for example encrypt your current databases, use them as long as you wish, then decide to decrypt them back to plain text and use them from the standard SQLite3 library, also you may use this library just as a standard SQLite3 library
- no external dependencies like _OpenSSL_, _Microsoft Visual C++ Redistributable Packages_, _Microsoft .NET Framework_, ...

_\*Support for 256 bit AES encryption is still experimental_

How to?
-----

### Compile it

Build script currently generates only solution _(*.sln)_ files for Microsoft Visual Studio IDE, but as SQLite3 and wxSQLite3 are cross-platform, you may try to [download the original wxSQLite3 source code][wxsqlite3-dl] and built it yourself for your platform.

#### 1. Requirements

- Windows with [MS Visual Studio](https://www.visualstudio.com/products/visual-studio-express-vs) 2012+ *(2010 not tested but should work too)*

#### 2. Steps

1. [Download snapshot of this repository][repo-dl], unzip and open it
2. Run `premake.bat` or `premake4.bat`
3. The script should generate a solution file (_.sln_) in the project root dir, open it in VS as usual and upgrade the solution when needed, eg. if you have VS2013 and the script created VS2012 solution (automatic prompt or `Project -> Upgrade Solution`)
4. `Build -> Configuration Manager` and choose configurations and platforms you want to build
5. And here we go `Build -> Build Solution`, which should produce binaries in the `bin` dir

**Following these steps and building all binaries in their _Release_ versions took me ~2 minutes on my laptop.**

### Download prebuilt binaries
Try to look for them [here](https://github.com/rindeal/SQLite3-Encryption/releases)

### Update to the latest version of SQLite
Because developers of the wxSQLite extension needs to incorporate changes with every new version of SQLite, there is a time lag between a new version of SQLite and wxSQLite. If you want to update to the latest version of wxSQLite, you can do so in two ways:

#### 1. Automatic

- Run `premake update` or `tools\update.bat`

> *Requires _PowerShell_

#### 2. Manual

1. [Download the source code][wxsqlite3-dl] of the latest release of _wxsqlite3_
2. Extract the `wxsqlite3-*/sqlite3/secure/src` dir from the archive to `src` dir in the project root dir.

#### Notes
- `VERSIONS` file in the repo root dir keeps an overview of versions of individual components provided in the repo

Alternatives
-----

There are more ways how to add a _native_ on-the-fly encryption layer to your SQLite3 DBs. Namely:

- [SQLite Encryption Extension](https://www.sqlite.org/see) - from authors of SQLite, commercial, $2000
- [SQLiteCrypt](https://sqlite-crypt.com) - commercial, $128
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - partially opensource (I didn't manage to get it working on Windows though), depends on OpenSSL

So after a few hours spent trying to build _SQLCipher_, I dived more deeply into the internet and found [wxSQLite3][wxsqlite3], did some scripting to ease the build and this is the result. 

SQLite3 Encryption API
=====

Functions
-----------

```c
#define SQLITE_HAS_CODEC
#include <sqlite3.h>
```

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

PRAGMAs
-------

### PRAGMA key
- it's wrapper around [sqlite3_key_v2](#sqlite3_key-sqlite3_key_v2)
- example usage: `PRAGMA key='passphrase';`

### PRAGMA rekey
- it's wrapper around [sqlite3_rekey_v2](#sqlite3_rekey-sqlite3_rekey_v2)
- example usage: `PRAGMA rekey='passphrase';`
- example of decrypting: `PRAGMA rekey='';`

Tutorials
----------

### Encrypting a new db
```c
open          // <-- db is still plain text
key           // <-- db is now fully encrypted
use as usual
```

### Opening an encrypted DB
```c
open          // <-- db is fully encrypted
key           // <-- db is still fully encrypted
use as usual  // <-- read/written pages are fully encrypted and only decrypted in-memory
```

### Changing the key
```c
open          // <-- db is fully encrypted
key           // <-- db is still fully encrypted
rekey         // <-- db is still fully encrypted
use as usual  
```

### Decrypting
```c
open              // <-- db is fully encrypted
key               // <-- db is still fully encrypted
rekey with null   // <-- db is now fully decrypted to plain text
use as usual
```

----------
## Read more
- [sqlcipher-api]
- [wxsqlite3-source]
- [wxsqlite3-docs]

[sqlcipher-api]: https://sqlcipher.net/sqlcipher-api/ "SQLCipher API"
[wxsqlite3]: https://utelle.github.io/wxsqlite3 "wxSQLite3 Homepage"
[wxsqlite3-source]: https://github.com/utelle/wxsqlite3 "wxSQLite3 Source Code"
[wxsqlite3-docs]: https://utelle.github.io/wxsqlite3/docs/html/index.html "wxSQLite3 Docs"
[wxsqlite3-dl]: https://github.com/utelle/wxsqlite3/releases "wxSQLite3 Download"
[repo-dl]: https://github.com/rindeal/SQLite3-Encryption/archive/master.zip "Download repository"
