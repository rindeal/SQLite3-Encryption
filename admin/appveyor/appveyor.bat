rem automatically go to particular toolset based in where compiler is by defaults.
goto %TOOLSET%

:mingw32
cd build
gcc -v
dir C:\Qt\5.13.0\mingw73_32
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
gcc -v
dir C:\Qt\5.13.0\mingw73_64
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
