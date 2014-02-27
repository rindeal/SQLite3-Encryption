-- Build SQLite3
--   static or shared library
--   AES 128 bit or AES 256 bit encryption support
--   Debug or Release

if _ACTION == nil then _ACTION = "vs2012" end

if _ACTION == "clean" then
  os.rmdir("bin")
  os.rmdir("build")
  os.execute('for /d %d in (src\\*.tlog) do rd /q /s "%d"')
  os.execute('del /Q /S /F /A *Log.htm thumbs.db *bak.def 2> NUL')
  extensions = { 
    "dll", "lib", "exe",
    "pdb", "exp", "obj", "manifest",
    "sln", "suo", "sdf", "opensdf",
    "bak", "tmp", "log", "tlog",
  }
  os.execute('@echo off && for %e in ('.. table.concat(extensions," ") ..') do del /Q /S /F /A *.%e 2> NUL')
   -- remove empty directories
   -- http://blogs.msdn.com/b/oldnewthing/archive/2008/04/17/8399914.aspx
  os.execute('@echo off && for /f "usebackq" %d in (`"dir /ad/b/s | sort /R"`) do rd "%d" 2> NUL ')
  os.exit()
end

io.write "Getting SQLite version... "
fh = io.open("src/sqlite3.h","r")

while true do
  line = fh.read(fh)
  if not line then break end
  if line:sub(0,23) == "#define SQLITE_VERSION " then 
    SQLITE_VERSION = line:sub(line:find("%d.%d.%d"))
	break
  end
end
fh:close()

-- create #define string
SQLITE_VERSION_DEF=""
for i in SQLITE_VERSION:gmatch("%d") do
  SQLITE_VERSION_DEF = SQLITE_VERSION_DEF .. i .. ","
end
SQLITE_VERSION_DEF = SQLITE_VERSION_DEF .. "0"

printf ("%s -> %s",SQLITE_VERSION,SQLITE_VERSION_DEF)
		
solution "SQLite3"
  language "C++"
  configurations { "Debug_AES128", "Release_AES128", "Debug_AES256", "Release_AES256" }
  platforms { "x32", "x64" }
  targetname "sqlite3"
  targetdir "$(SolutionDir)/bin/$(ProjectName)/$(Configuration)"
  files { "src/sqlite3.rc" }
  defines { 'SQLITE_VERSION_DEF='..SQLITE_VERSION_DEF }
  flags { 
    "Unicode", 
    "OptimizeSpeed", 
    "NoFramePointer", 
    "FloatFast",
	-- "FloatStrict",
	"NoPCH",
	"StaticRuntime"
  }
  defines { 
    "_WINDOWS", 
	"THREADSAFE=1", 
	"SQLITE_HAS_CODEC", -- enable encryption
	"SQLITE_SOUNDEX",
    "SQLITE_ENABLE_COLUMN_METADATA",
    "SQLITE_SECURE_DELETE",
    "SQLITE_ENABLE_FTS4",
    "SQLITE_ENABLE_FTS3_PARENTHESIS",
    "SQLITE_ENABLE_RTREE",
    "SQLITE_CORE",
    "SQLITE_USE_URI",
  }
  buildoptions {
    "/Qpar", -- Parallel Code Generation
    "/Ot",   -- Favor Speed
    "/GL",   -- Whole Optimization (requires /LTCG for linker)
	"/MP",   -- Multi-processor Compilation (faster compilation))
  }
  linkoptions "/LTCG" -- Link Time Code Generation

  configuration "x32"
  defines "WIN32"
    flags "EnableSSE2" -- SSE2 instructions
  
  configuration "x64"
    targetname "sqlite3_x64"
	defines "WIN64"
	buildoptions "/arch:AVX" -- AVX instructions

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
projectname="sqlite3lib"
project (projectname)
  uuid "5104BC68-6E98-864B-9DBC-8D87F537B771"
  kind "StaticLib"
  location ("build/"..projectname)
  vpaths {
    ["Header Files"] = { "**.h" },
    ["Source Files"] = { "**.c" }
  }	
  files { "src/sqlite3secure.c", "src/*.h" }
  defines "_LIB"

-- SQLite3 as shared library
projectname="sqlite3dll"
project (projectname)
  uuid "DA8570DF-BED3-8844-BF37-CBBACB650F31"
  kind "SharedLib"
  location ("build/"..projectname)
  vpaths {
    ["Header Files"] = { "**.h" },
    ["Source Files"] = { "**/sqlite3secure.c", "**.def" }
  }
  files { "src/sqlite3secure.c", "src/*.h", "src/sqlite3.def" }
  defines "_USRDLL"

-- SQLite3 Shell   
projectname="sqlite3shell"
project (projectname)
  uuid "BA98AAC1-AACD-2F4F-8EDB-CF7C62668BC4"
  kind "ConsoleApp"
  location ("build/"..projectname)
  files { "src/sqlite3.h", "src/shell.c" }
  links { "sqlite3lib" }
  defines "SQLITE_THREADSAFE=0" -- CLI is single threaded
