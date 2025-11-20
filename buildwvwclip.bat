@echo off
rem BUILD WVWClip Library

setlocal

call e:\Projects\HarbourSets.bat

rmdir %HB_PATH%\addons\wvwclip\ /q /s
md  %HB_PATH%\addons\wvwclip

hbmk2 wvwclip.hbp -rebuild
copy libwvwclip.a %HB_PATH%\lib\win\mingw

endlocal