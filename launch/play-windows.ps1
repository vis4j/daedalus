$APP_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

if (-Not (Test-Path "$APP_DIR\jre\bin\java.exe")) {
    Write-Host "Java Runtime not found in the specified directory."
    return
}
elseif (-Not (Test-Path "$APP_DIR\lib\")) {
    Write-Host "Library folder not found."
    return
}

$CLASSPATH = ""
Get-ChildItem "$APP_DIR\lib\*.jar" | ForEach-Object {
    $CLASSPATH += ";" + $_.FullName
}

$CLASSPATH = $CLASSPATH.Substring(1)

if ([string]::IsNullOrEmpty($CLASSPATH)) {
    Write-Host "No JAR files found in the library folder."
    return
}

& "$APP_DIR\jre\bin\java.exe" -cp $CLASSPATH "{{MainClass}}"
