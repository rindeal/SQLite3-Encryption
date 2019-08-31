rem automatically go to particular toolset based in where compiler is by defaults.
goto %TOOLSET%

:mingw32
cd build
gcc -v
dir C:\Qt\5.13.0\mingw73_32\bin
set PATH=C:\Qt\5.13.0\mingw73_32\bin;%PATH%
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
gcc -v
dir C:\Qt\5.13.0\mingw73_64\bin
set PATH=C:\Qt\5.13.0\mingw73_64\bin;%PATH%
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
