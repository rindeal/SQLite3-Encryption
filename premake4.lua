-- Copyright (c) Jan Chren 2014
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

SRC_DIR="src"
PRJ_NAME_LIB="sqlite3_lib"
PRJ_NAME_DLL="sqlite3_dll"
PRJ_NAME_SHELL="sqlite3_shell"

function getSQLiteVersion()
  fh = io.open(SRC_DIR.."/sqlite3.h","r")
  local version=""
  while true do
   line = fh.read(fh)
   if not line then break end
   if line:sub(0,23) == "#define SQLITE_VERSION " then
     version=line:sub(line:find("%d.%d.%d"))
     break
   end
  end
  fh:close()
  return version
end

function getScriptDir( )
  return debug.getinfo(1).source:match("@(.*[\\/]).+$")
end

if _ACTION == nil then _ACTION = "vs2012" end -- set a default action

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

if _ACTION == "update" then
  os.execute('powershell "'..getScriptDir()..'tools/update.ps1"')
  os.exit()
end

if _ACTION == "compress" then
  os.execute('"'..getScriptDir()..'tools\\_compress.bat"')
  os.exit()
end

SQLITE_VERSION_DEF=""

if string.match(_ACTION, 'vs20') then
  io.write "Getting SQLite version... "

  SQLITE_VERSION=getSQLiteVersion()

  -- create #define string
  for i in SQLITE_VERSION:gmatch("%d") do
    SQLITE_VERSION_DEF = SQLITE_VERSION_DEF .. i .. ","
  end
  SQLITE_VERSION_DEF = SQLITE_VERSION_DEF .. "0"

  printf ("%s -> %s",SQLITE_VERSION,SQLITE_VERSION_DEF)
end

solution "SQLite3"
  language "C++"
  configurations { "Debug_AES128", "Release_AES128", "Debug_AES256", "Release_AES256" }
  platforms { "x32", "x64" }
  targetdir "$(SolutionDir)/bin/$(ProjectName)/$(Configuration)"
  files { SRC_DIR.."/sqlite3.rc" }
  flags {
    "Unicode",
    "OptimizeSpeed",
    "NoFramePointer",
    -- "FloatFast",
    "FloatStrict",
    "NoPCH",
    "StaticRuntime"
  }
  defines {
    "_WINDOWS",
    "THREADSAFE=1",
    "SQLITE_VERSION_DEF="..SQLITE_VERSION_DEF,
    "SQLITE_HAS_CODEC", -- enable encryption
    "SQLITE_SOUNDEX",
    "SQLITE_ENABLE_COLUMN_METADATA",
    -- "SQLITE_SECURE_DELETE", -- https://www.sqlite.org/compile.html#secure_delete
    "SQLITE_ENABLE_FTS3",
    "SQLITE_ENABLE_FTS3_PARENTHESIS",
    "SQLITE_ENABLE_FTS4",
    "SQLITE_ENABLE_RTREE",
    -- "SQLITE_ENABLE_ICU",
    "SQLITE_CORE",
    "SQLITE_USE_URI",
    "SQLITE_DEFAULT_PAGE_SIZE=4096", -- best performance
  }
  includedirs {
    -- "include/icu",
  }
  buildoptions {
    "/MP",   -- Multi-processor Compilation
    "/Ot",   -- Favor Speed
    "/GL",   -- Whole Optimization (requires /LTCG for linker)
    "/O2",   -- just /O2
  }
  linkoptions {
    "/LTCG" -- Link Time Code Generation
  }

  configuration "x32"
    targetname "sqlite3"
    defines "WIN32"
    flags "EnableSSE2" -- SSE2 instructions
    libdirs { 
      -- "lib/icu",
    }

  configuration "x64"
    targetname "sqlite3_x64"
    defines "WIN64"
    buildoptions "/arch:AVX" -- AVX instructions
    libdirs {
      -- "lib/icu64",
    }

  configuration "Debug_AES128 or Debug_AES256"
    defines { "DEBUG", "_DEBUG" }
    flags { "Symbols" }

  configuration "Release_AES128 or Release_AES256"
    defines { "NDEBUG" }

  configuration "Debug_AES128 or Release_AES128"
    defines { "CODEC_TYPE=CODEC_TYPE_AES128" }

  configuration "Debug_AES256 or Release_AES256"
    defines { "CODEC_TYPE=CODEC_TYPE_AES256" }

  -- SQLite3 as static library
  project (PRJ_NAME_LIB)
    uuid "E24BB52B-63B2-4B08-A3AF-39727F47EE3B"
    kind "StaticLib"
    location ("build/"..PRJ_NAME_LIB)
    vpaths {
      ["Header Files"] = { "**.h" },
      ["Source Files"] = { "**.c" }
    }
    files { SRC_DIR.."/sqlite3secure.c", SRC_DIR.."/*.h" }
    defines "_LIB"

  -- SQLite3 as shared library
  project (PRJ_NAME_DLL)
    uuid "DC071BDB-3DA0-4777-ACFE-B7C4607FF017"
    kind "SharedLib"
    location ("build/"..PRJ_NAME_DLL)
    vpaths {
      ["Header Files"] = { "**.h" },
      ["Source Files"] = { "**/sqlite3secure.c", "**.def" }
    }
    files { SRC_DIR.."/sqlite3secure.c", SRC_DIR.."/*.h", SRC_DIR.."/sqlite3.def" }
    defines "_USRDLL"

  -- SQLite3 Shell
  project (PRJ_NAME_SHELL)
    uuid "84DB93F6-E8D8-487A-9A31-1E2CF60EB09F"
    kind "ConsoleApp"
    location ("build/"..PRJ_NAME_SHELL)
    files { SRC_DIR.."/sqlite3.h", SRC_DIR.."/shell.c" }
    links { PRJ_NAME_LIB }
    defines "SQLITE_THREADSAFE=0" -- CLI is single threaded
