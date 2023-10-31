#!/bin/bash

main() {
    echo "Building project..."
    build_project

    echo "Removing old release directory..."
    rm -rf "$OUTPUT_DIR"

    echo "Copying artifacts to lib..."
    if [ -d "$LIB_DIR" ]; then
        rm -rf "$LIB_DIR"
    fi
    mkdir -p "$LIB_DIR"
    copy_artifacts "$LIB_DIR"

    for platform in "${CONFIG_PLATFORMS}"; do
        create_distribution "$platform"
    done

    echo "Cleaning up..."
    rm -rf "$WORK_DIR"
    rm -rf "$LIB_DIR"
}

prepare_directories() {
    for dir in "$@"; do
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    done
}

function create_distribution() {
    echo "Creating distribution for $platform..."
    local platform="$1"
    local jdk_packed_dest="${JDK_DEST_ARRAY[$platform]}"
    local jdk_unpacked_dest="$WORK_DIR/unpacked-$platform"
    local jmod_dest="$WORK_DIR/jmod-$platform"

    prepare_directories "$(dirname "$jdk_packed_dest")" "$jdk_unpacked_dest" "$jmod_dest"
    download_and_validate_jdk "$platform" "$jdk_packed_dest"
    unpack_jdk "$platform" "$jdk_packed_dest" "$jdk_unpacked_dest"
    copy_jmods_to_destination "$jdk_unpacked_dest" "$jmod_dest"

    local jre_dir="$WORK_DIR/jre-$platform"
    rm -rf "$jre_dir"
    create_minimized_jre "$jmod_dest" "$jre_dir"

    local platform="$1"
    local target_dir="$WORK_DIR/target-$platform"

    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir"
    fi

    prepare_directories "$target_dir" "$target_dir/jre" "$target_dir/lib"

    cp -r "$WORK_DIR/jre-$platform/"* "$target_dir/jre/"
    cp -r "$LIB_DIR/"* "$target_dir/lib/"

    local matching_files
    matching_files=("$DAEDALUS_DIR/launch/play-$platform."*)
    if [ ${#matching_files[@]} -gt 0 ]; then
        for file in "${matching_files[@]}"; do
            local ext="${file##*.}"
            cp "$file" "$target_dir/play.$ext"
            sed -i "s/{{MainClass}}/$CONFIG_MAIN_CLASS/g" "$target_dir/play.$ext"
        done
    else
        echo "Error: Zero files match the pattern: $DAEDALUS_DIR/launch/play-$platform.*"
        exit 1
    fi

    mkdir -p "$OUTPUT_DIR"

    local dist_release
    if [ "$platform" = "windows" ]; then
        dist_release="$OUTPUT_DIR/$platform.zip"
    else
        dist_release="$OUTPUT_DIR/$platform.tar.xz"
    fi

    if [ -f "$dist_release" ]; then
        rm "$dist_release"
    fi

    echo "Creating release: $dist_release"
    if [ "$platform" = "windows" ]; then
        (cd "$target_dir" && zip -rq "${dist_release}" .)
    else
        tar -cJf "$dist_release" -C "$target_dir" .
    fi

    echo "Completed: $dist_release"
}

download_and_validate_jdk() {
    echo "Downloading and validating JDK..."
    local platform="$1"
    local jdk_packed_dest="$2"
    if [ ! -f "$jdk_packed_dest" ] || ! validate_hash "$jdk_packed_dest" "${JDK_SHA_ARRAY[$platform]}"; then
        local jre_download_url="${JDK_DOWNLOAD_ARRAY[$platform]}"
        echo "Downloading JDK $jre_download_url -> $jdk_packed_dest"
        wget -O "$jdk_packed_dest" "$jre_download_url"
        if ! validate_hash "$jdk_packed_dest" "${JDK_SHA_ARRAY[$platform]}"; then
            echo "Corrupted JDK file: $jdk_packed_dest"
            exit 1
        fi
    fi
    echo "JDK validated."
}

unpack_jdk() {
    echo "Unpacking JDK..."
    local platform="$1"
    local jdk_packed_dest="$2"
    local jdk_unpacked_dest="$3"
    rm -rf "$jdk_unpacked_dest"
    mkdir -p "$jdk_unpacked_dest"
    if [ "$platform" = "windows" ]; then
        unzip -qo "$jdk_packed_dest" -d "$jdk_unpacked_dest"
    else
        tar -xf "$jdk_packed_dest" -C "$jdk_unpacked_dest"
    fi
    echo "JDK unpacked."
}

copy_jmods_to_destination() {
    local jdk_unpacked_dest="$1"
    local jmod_dest="$2"

    if [ -d "$jdk_unpacked_dest/jdk-21.0.1.jdk/Contents/Home/jmods" ]; then
        cp -r "$jdk_unpacked_dest/jdk-21.0.1.jdk/Contents/Home/jmods" "$jmod_dest"
    elif [ -d "$jdk_unpacked_dest/jdk-21.0.1/jmods" ]; then
        cp -r "$jdk_unpacked_dest/jdk-21.0.1/jmods" "$jmod_dest"
    else
        echo "Could not locate jmods in $jdk_unpacked_dest"
        exit 1
    fi
}

create_minimized_jre() {
    local jmod_dest="$1"
    local jre_dir="$2"

    local prev_ifs="$IFS"
    IFS=","

    local jre_modules="${CONFIG_JRE_MODULES[*]}"
    IFS="$prev_ifs"

    echo "Creating minimized JRE with modules:"
    echo "$jre_modules"
    jlink --add-modules "$jre_modules" --module-path "$jmod_dest" --output "$jre_dir" --strip-debug --no-header-files --no-man-pages
}

validate_hash() {
    local file_path="$1"
    local expected_hash="$2"

    local raw_hash
    raw_hash=$(sha256sum "$file_path")
    local actual_hash
    actual_hash=$(echo "$raw_hash" | cut -d' ' -f1)

    if [ "$expected_hash" != "$actual_hash" ]; then
        echo "SHA256 mismatch for $file_path: expected $expected_hash, got $actual_hash"
        rm "$file_path"
        exit 1
    fi
}

set -euo pipefail

ROOT_DIR="$(pwd)"
DAEDALUS_DIR="$(dirname "$(readlink -f "$0")")"
CACHE_DIR="$DAEDALUS_DIR/.cache"

OUTPUT_DIR="$ROOT_DIR/release"
LIB_DIR="$OUTPUT_DIR/lib"

WORK_DIR="$OUTPUT_DIR/work"

declare -A JDK_DOWNLOAD_ARRAY=(
    ["linux"]="https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_linux-x64_bin.tar.gz"
    ["macos"]="https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_macos-x64_bin.tar.gz"
    ["windows"]="https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip"
)

declare -A JDK_SHA_ARRAY=(
    ["linux"]="7e80146b2c3f719bf7f56992eb268ad466f8854d5d6ae11805784608e458343f"
    ["macos"]="1ca6db9e6c09752f842eee6b86a2f7e51b76ae38e007e936b9382b4c3134e9ea"
    ["windows"]="77ea464f4fa7cbcbffe0124af44707e8e5ad8c1ce2373f1d94a64d9b20ba0c69"
)

declare -A JDK_DEST_ARRAY=(
    ["linux"]="$CACHE_DIR/jdk-linux.tar.gz"
    ["macos"]="$CACHE_DIR/jdk-macos.tar.gz"
    ["windows"]="$CACHE_DIR/jdk-windows.zip"
)

. "$ROOT_DIR/daedalus_config.sh"

if [ -z "${CONFIG_JRE_MODULES:-}" ]; then
    echo "CONFIG_JRE_MODULES is not set"
    exit 1
fi

if [ -z "${CONFIG_PLATFORMS:-}" ]; then
    echo "CONFIG_PLATFORMS is not set"
    exit 1
fi

if [ -z "${CONFIG_MAIN_CLASS:-}" ]; then
    echo "CONFIG_MAIN_CLASS is not set"
    exit 1
fi

main
