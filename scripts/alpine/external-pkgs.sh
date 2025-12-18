#!/bin/bash

source "$(dirname "$0")/packages.sh"
BUILDENV_DIR="$1"
ALPINE_VER="$3"

# cross-compilers expect this for linux headers
# e.g: 3.23.2 -> 3.23
if [ ! -z "$ALPINE_VER" ]; then
    export ALPINE_VERSION="v$ALPINE_VER"
else
    export ALPINE_VERSION=""
fi

if [ "$2" == "--postinst" ]; then
    for pkg in "${external_package_list[@]}"; do
        pkg_script="$(dirname "$0")/external/${pkg}.sh"

        unset pkg_download pkg_extract pkg_name pkg_url

        source "$pkg_script"

        pkg_postinst "$BUILDENV_DIR"
    done
    exit 0
elif [ "$2" == "--install" ]; then
    for pkg in "${external_package_list[@]}"; do
        pkg_script="$(dirname "$0")/external/${pkg}.sh"

        unset pkg_download pkg_extract pkg_name pkg_url

        source "$pkg_script"

        pkg_download "$BUILDENV_DIR"
        pkg_extract "$BUILDENV_DIR"
    done
    exit 0
fi