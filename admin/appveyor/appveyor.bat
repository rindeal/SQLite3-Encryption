rem automatically go to particular toolset based in where compiler is by defaults.
goto %TOOLSET%

:mingw32
cd build
gcc -v
dir C:\mingw-w64\i686-6.3.0-posix-dwarf-rt_v5-rev1\mingw32\bin
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
gcc -v
dir C:\mingw-w64\x86_64-6.3.0-posix-seh-rt_v5-rev1\mingw64\bin
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
