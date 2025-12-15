#!/bin/bash

source "$(dirname "$0")/packages.sh"
BUILDENV_DIR="$1"

for pkg in "${external_package_list[@]}"; do
    pkg_script="$(dirname "$0")/external/${pkg}.sh"

    unset pkg_download pkg_extract pkg_name pkg_url

    source "$pkg_script"

    pkg_download "$BUILDENV_DIR"
    pkg_extract "$BUILDENV_DIR"
done