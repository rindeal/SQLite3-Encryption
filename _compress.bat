@echo off

IF "%%~1"=="" GOTO START

for %%F in ("%%~1") do set dirname=%%~dpF
set dirname=%dirname%\compressed
for /F %%i in ("%%~1") do set filename=%%~ni%%~xi


md "%dirname%" 2> NUL
del /F /Q "%dirname%\%filename%" 2> NUL
upx.exe --output="%dirname%\%filename%" -v --brute --no-backup --overlay=strip --compress-icons=1 "%%~1"

goto:EOF

:START
for %%E in ( .dll, .exe ) do forfiles /M %%E /C 

