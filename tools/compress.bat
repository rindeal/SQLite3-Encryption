:: Copyright (c) Jan Chren 2014
:: Licensed under BSD 3

@echo off

:: disable cygwin warnings, if upx comes from cyg repos
set CYGWIN=nodosfilewarning

pushd "%~dp0bin"
call :recurse
goto :eof


:recurse
for %%f in ( *.dll, *.exe ) do call :compress "%CD%" "%%~nf" "%%~xf"
for /D %%d in (*) do (
    cd %%d
    call :recurse
    cd ..
)
exit /b


:compress
set dir=%1
set dir=%dir:"=%
set file=%2
set file=%file:"=%
set ext=%3
set ext=%ext:"=%

set in=%dir%\%file%%ext%
set out=%dir%\%file%_compressed%ext%

:: skip if it's an already compressed file
setlocal enableextensions enabledelayedexpansion
if not x%file:compressed=%==x%file% exit /b
endlocal

del /f "%out%"
upx --output="%out%" -v --best --no-backup --overlay=strip --compress-icons=1 "%in%"

exit /b
