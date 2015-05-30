-- Copyright (c) Jan Chren 2014-2015
-- Licensed under BSD 3

-- Build SQLite3
--   static or shared library
--   AES 128 bit or AES 256 bit encryption support
--   Debug or Release

-- TODO:
--    - add cmdline options to:
--        - disable speed optimizations
--        - enable memory/space optimizations
--        - enable ICU

SOL_ROOT_DIR    = "."
SRC_DIR         = SOL_ROOT_DIR.."/src"
BUILD_DIR       = SOL_ROOT_DIR.."/build"
PRJ_NAME_LIB    = "sqlite3_lib"
PRJ_NAME_DLL    = "sqlite3_dll"
PRJ_NAME_SHELL  = "sqlite3_shell"


function getScriptDir( )
  return string.gsub(debug.getinfo(1).source:match("@(.*[\\/]).+$"), '/', '\\')
end

-- set default action
if _ACTION == nil then _ACTION = "vs2012" end
premake.action.list.vs2012.description = "(default) " .. premake.action.list.vs2012.description

-- disable some actions/options
-------------------------------
premake.action.list.xcode3 = nil
premake.action.list.xcode4 = nil
premake.action.list.vs2002 = nil
premake.action.list.vs2003 = nil
premake.action.list.vs2005 = nil
premake.action.list.vs2008 = nil

-- not yet implemented ------
premake.action.list.codeblocks = nil
premake.action.list.codelite = nil
premake.action.list.gmake = nil
-----------------------------

premake.option.list.os = nil
premake.option.list.dotnet = nil
premake.option.list.cc = nil
premake.option.list.platform.allowed = { { "x32", "32-bit" }, { "x64", "64-bit" } }
-------------------------------

-- local inspect = require('inspect')
-- print(inspect(premake))

newaction {
  trigger     = "update",
  description = "Updates the wxSQLite to its newest version",
  execute     = function ()
      os.execute('powershell -ExecutionPolicy Unrestricted -File "'..getScriptDir()..'tools\\update.ps1"')
      os.exit()
    end
}

newaction {
  trigger     = "compress",
  description = "Compresses the produced binaries (.dll, .exe) with UPX",
  execute     = function ()
      os.execute('"'..getScriptDir()..'tools\\compress.bat"')
      os.exit()
    end
}

-- hook for the clean action
if _ACTION == "clean" then
  os.rmdir("bin")
  os.rmdir("build")
  -- os.execute('for /d %d in ('..SRC_DIR..'\\*.tlog) do rd /q /s "%d"')
  -- os.execute('del /Q /S /F /A *Log.htm thumbs.db *bak.def 2> NUL')
  extensions = {
    --[["dll",]] --[["lib",]] "exe",
    "pdb", --[["exp",]] "obj", "manifest",
    "sln", "suo", "sdf", "opensdf",
    "bak", "tmp", "log", "tlog",
  }
  os.execute('@echo off && for %e in ('.. table.concat(extensions," ") ..') do del /Q /S /F /A *.%e 2> NUL')
  -- remove empty directories
  -- http://blogs.msdn.com/b/oldnewthing/archive/2008/04/17/8399914.aspx
  -- os.execute('@echo off && for /f "usebackq" %d in (`"dir /ad/b/s | sort /R"`) do rd "%d" 2> NUL ')
  -- os.exit() -- don NOT exit and let the native premake clean action run
end

-- Solution
--------------------
solution "SQLite3"
  language "C++"
  configurations {
    "Debug_AES128",
    "Release_AES128",
    "Debug_AES256",
    "Release_AES256"
  }
  platforms { "x32", "x64" }
  targetdir "$(SolutionDir)/bin/$(ProjectName)/$(Configuration)"
  flags {
    "Unicode",
    "OptimizeSpeed",
    "NoFramePointer",
    -- "FloatFast",
    "FloatStrict",
    "NoPCH",
    "StaticRuntime",
  }
  defines {
    "_WINDOWS",
    "SQLITE_THREADSAFE=1",                  -- http://www.sqlite.org/compile.html#threadsafe
    "SQLITE_DEFAULT_PAGE_SIZE=4096",        -- better performance
    "SQLITE_TEMP_STORE=2",                  -- http://www.sqlite.org/tempfiles.html#tempstore
    "SQLITE_DEFAULT_TEMP_CACHE_SIZE=1024",  -- http://www.sqlite.org/tempfiles.html#otheropt
    "SQLITE_HAS_CODEC",                     -- enable encryption extension
    "SQLITE_ENABLE_COLUMN_METADATA",
    "SQLITE_ENABLE_FTS4",                   -- includes FTS3
    "SQLITE_ENABLE_FTS3_PARENTHESIS",
    "SQLITE_ENABLE_RTREE",
    -- "SQLITE_ENABLE_ICU",
    "SQLITE_CORE",
    "SQLITE_USE_URI",
    "SQLITE_ALLOW_URI_AUTHORITY",
  }
  includedirs {
    -- "include/icu",
  }
  buildoptions {
    "/MP", -- Multi-processor Compilation
    "/Ot", -- Favor Speed
    "/GL", -- Whole Optimization (requires /LTCG for linker)
    "/O2", -- just /O2
  }
  linkoptions {
    "/LTCG" -- Link Time Code Generation
  }

  -- Configurations
  ------------------

  -- x32
  configuration "x32"
    targetname "sqlite3"
    defines "WIN32"
    libdirs {
      -- "lib/icu",
    }
    flags{
      "EnableSSE2", --- SSE2 instructions, enabled by default for x64
    }

  -- x64
  configuration "x64"
    targetname "sqlite3_x64"
    defines "WIN64"
    libdirs {
      -- "lib/icu64",
    }
    buildoptions{
      -- "/arch:AVX"  -- AVX and lower instructions
    }

  -- Debug
  configuration "Debug_AES128 or Debug_AES256"
    defines { "DEBUG", "_DEBUG" }
    flags { "Symbols" }

  -- Release
  configuration "Release_AES128 or Release_AES256"
    defines { "NDEBUG" }

  -- AES128
  configuration "Debug_AES128 or Release_AES128"
    defines { "CODEC_TYPE=CODEC_TYPE_AES128" }

  -- AES256
  configuration "Debug_AES256 or Release_AES256"
    defines { "CODEC_TYPE=CODEC_TYPE_AES256" }

  -- Projects
  ------------

  -- SQLite3 as static library
  project (PRJ_NAME_LIB)
    uuid "E24BB52B-63B2-4B08-A3AF-39727F47EE3B"
    kind "StaticLib"
    location (BUILD_DIR.."/"..PRJ_NAME_LIB)
    vpaths {
      ["Header Files"] = { "**.h" },
      ["Source Files"] = { "**.c" }
    }
    files {
      SRC_DIR.."/sqlite3secure.c",
      SRC_DIR.."/*.h"
    }
    defines "_LIB"

  -- SQLite3 as shared library
  project (PRJ_NAME_DLL)
    uuid "DC071BDB-3DA0-4777-ACFE-B7C4607FF017"
    kind "SharedLib"
    location (BUILD_DIR.."/"..PRJ_NAME_DLL)
    vpaths {
      ["Header Files"] = { SRC_DIR.."/*.h" },
      ["Source Files"] = {
        SRC_DIR.."/sqlite3secure.c",
        SRC_DIR.."/*.def"
      }
    }
    files {
      SRC_DIR.."/sqlite3secure.c",
      SRC_DIR.."/*.h",
      SRC_DIR.."/sqlite3.def",
      SRC_DIR.."/sqlite3.rc"
    }
    defines "_USRDLL"

  -- SQLite3 Shell
  project (PRJ_NAME_SHELL)
    uuid "84DB93F6-E8D8-487A-9A31-1E2CF60EB09F"
    kind "ConsoleApp"
    location (BUILD_DIR.."/"..PRJ_NAME_SHELL)
    files {
      SRC_DIR.."/sqlite3.h",
      SRC_DIR.."/shell.c",
      SRC_DIR.."/sqlite3shell.rc"
    }
    links { PRJ_NAME_LIB }
    defines {
      -- "SQLITE_THREADSAFE=0", -- CLI is always single threaded, generates warnings because of a collision with previous definitions
      "SQLITE_ENABLE_EXPLAIN_COMMENTS"
    }
