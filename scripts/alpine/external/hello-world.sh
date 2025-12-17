#!/bin/bash

pkg_name="hello_world"
pkg_url="https://github.com/kxtzownsu/build-env/raw/refs/heads/main/scripts/alpine/external/pkgs/hello-world.tgz"

pkg_download() {
    BUILDENV_DIR="$1"
    echo "downloading $pkg_name..."
    wget -O "$BUILDENV_DIR/tmp/$pkg_name.tgz" "$pkg_url"
}

pkg_extract() {
    BUILDENV_DIR="$1"
    echo "extracting $pkg_name..."
    tar -xzf "$BUILDENV_DIR/tmp/$pkg_name.tgz" -C "$BUILDENV_DIR/"
    rm -rf "$BUILDENV_DIR/tmp/$pkg_name.tgz"
}

pkg_postinst() {
    :
}