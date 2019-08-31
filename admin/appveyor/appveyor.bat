rem automatically go to particular toolset based in where compiler is by defaults.
set MSBUILD_LOGGER=/logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"
goto %TOOLSET%

:mingw32
cd build
mkdir obj-gcc
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof


:mingw64
cd build
mkdir obj-gcc
mingw32-make.exe -f Makefile config=%CONFIGURATIONS% all
goto :eof

:msbuild
cd build
msbuild /m:2 /v:n /p:Platform=%ARCH% /p:Configuration="%CONFIGURATION%" SQLite3Secure_vc15.sln %MSBUILD_LOGGER%
goto :eof

:error
echo.
echo --- Build failed !
echo.
