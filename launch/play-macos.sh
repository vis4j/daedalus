#!/bin/sh
APP_DIR="$(dirname "$0")"
CLASSPATH=$(echo "$APP_DIR/lib/"*.jar | tr ' ' ':')
"$APP_DIR/jre/bin/java" -cp "$CLASSPATH" "{{MainClass}}"
