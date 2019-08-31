rem automatically go to particular toolset based in where compiler is by defaults.
goto %TOOLSET%

:mingw32
cd build
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:error
echo.
echo --- Build failed !
echo.
