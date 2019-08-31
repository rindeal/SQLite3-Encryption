rem automatically go to particular toolset based in where compiler is by defaults.
set MSBUILD_LOGGER=/logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"
goto %TOOLSET%

:msbuild
cd build
msbuild /m:2 /v:n /p:Platform=%ARCH% /p:Configuration="%CONFIGURATION%" SQLite3Secure_vc15.sln %MSBUILD_LOGGER% /T:Package /P:PackageLocation="c:\projects\sqlite3enc\sqlite3enc-%CONFIGURATION%-%ARCH%.zip"
goto :eof

:error
echo.
echo --- Build failed !
echo.
