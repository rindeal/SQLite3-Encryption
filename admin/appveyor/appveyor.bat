rem automatically go to particular toolset based in where compiler is by defaults.
if exist "C:\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev1\mingw64\bin\g++.exe" set TOOLSET=mingw64 && set PATH="C:\mingw-w64\x86_64-7.2.0-posix-seh-rt_v5-rev1\mingw64\bin";%PATH%

:mingw64
cd build
echo %INCLUDE%
echo %LIB%
echo %PATH%
mkdir obj-gcc
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
