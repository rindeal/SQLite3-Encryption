set MSBUILD_LOGGER=/logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"
goto %TOOLSET%

:msbuild
cd build
set INCLUDE=%INCLUDE%
set LIB=%LIB%
msbuild /m:2 /v:n /p:Platform=%ARCH% /p:Configuration="%CONFIGURATION%" /p:AdditionalIncludePaths="%AdditionalIncludePaths%" /p:AdditionalLibPaths="%AdditionalLibPaths%" SQLite3Secure_vc15.sln %MSBUILD_LOGGER%
goto :eof

:error
echo.
echo --- Build failed !
echo.
