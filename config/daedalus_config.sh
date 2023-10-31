#!/bin/bash

CONFIG_JRE_MODULES="$ROOT_DIR/jre_modules.daedalus"
CONFIG_PLATFORMS="$ROOT_DIR/platforms.daedalus"
CONFIG_MAIN_CLASS="org.example.Main"

# This is called from daedalus' distribute.sh
function build_project() {
    mvn clean package
    [[ -f "$ROOT_DIR/target/MyApplication.jar" ]]
}

# This is called from daedalus' distribute.sh
function copy_artifacts() {
    local destination="$1"
    cp "$ROOT_DIR/target/MyApplication.jar" "$destination"
    cp "$ROOT_DIR/target/lib/"*.jar "$destination"
}
