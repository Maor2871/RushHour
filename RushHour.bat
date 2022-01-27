xcopy /y "%~dp0""dosboxconftemplate.txt" "%~dp0""dosbox.conf"
ECHO mount %CD:~0,1% "%~dp0">>"%~dp0\dosbox.conf"
ECHO %CD:~0,2%>>"%~dp0\dosbox.conf"
ECHO RushHour>>"%~dp0\dosbox.conf"
dosbox.exe
