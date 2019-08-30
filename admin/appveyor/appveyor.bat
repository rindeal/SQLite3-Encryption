cd build
echo %INCLUDE%
echo %LIB%
make -f Makefile
goto :eof

:error
echo.
echo --- Build failed !
echo.
