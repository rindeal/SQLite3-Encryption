rem automatically go to particular toolset based in where compiler is by defaults.
goto %TOOLSET%

:mingw32
cd build
gcc -v
dir %PATH_MINGW32%\*-make.exe
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
gcc -v
dir %PATH_MINGW64%\*-make.exe
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
