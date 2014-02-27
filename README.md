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

The process of creating a new, encrypted database is called “keying” the database. This library uses just-in-time key derivation at the point it is first needed for an operation. This means that the key (and any options) must be set before the first operation on the database. As soon as the database is touched (e.g. SELECT, CREATE TABLE, UPDATE, etc.) and pages need to be read or written, the key is prepared for use.

#### Testing the key
When opening an existing database, `sqlite3_key` will not immediately throw an error if the key provided is incorrect. To test that the database can be successfully opened with the provided key, it is necessary to perform some operation on the database (i.e. read from it) and confirm it is success.

The easiest way to do this is select off the `sqlite_master` table, which will attempt to read the first page of the database and will parse the schema.

```sql
SELECT count(*) FROM sqlite_master; -- if this throws an error, the key was incorrect. If it succeeds and returns a numeric value, the key is correct;
```

### sqlite3_rekey, sqlite3_rekey_v2
> Change the encryption key for a SQLCipher database*

- If the current database is not encrypted, this routine will encrypt it.
- If `pNew==0` or `nNew==0`, the database is decrypted.
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

----------

##### [Read more](http://sqlcipher.net/sqlcipher-api/)

