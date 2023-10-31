@echo off
setlocal enabledelayedexpansion

set "APP_DIR=%~dp0"

if not exist "%APP_DIR%\jre\bin\java.exe" (
    echo Java Runtime not found in the specified directory.
    goto :EOF
) else if not exist "%APP_DIR%\lib\" (
    echo Library folder not found.
    goto :EOF
)

set "CLASSPATH="

for %%f in ("%APP_DIR%\lib\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%~ff"
)

set "CLASSPATH=!CLASSPATH:~1!"

if "!CLASSPATH!"=="" (
    echo No JAR files found in the library folder.
    goto :EOF
)

"%APP_DIR%\jre\bin\java.exe" -cp "%CLASSPATH%" "{{MainClass}}"

endlocal
