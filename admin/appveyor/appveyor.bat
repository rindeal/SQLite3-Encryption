rem automatically go to particular toolset based in where compiler is by defaults.
if exist "C:\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev1\mingw32\bin\g++.exe" set TOOLSET=mingw64 && set PATH="C:\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev1\mingw32\bin";%PATH%

:mingw64
cd build
echo %INCLUDE%
echo %LIB%
echo %PATH%
dir C:\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev1\
make -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
