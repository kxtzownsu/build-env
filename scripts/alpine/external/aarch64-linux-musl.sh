#!/bin/bash

pkg_name="aarch64_linux_musl"
pkg_url="https://more.musl.cc/11.2.1/x86_64-linux-musl/aarch64-linux-musl-cross.tgz"

pkg_download() {
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/tmp"
    wget -O "$BUILDENV_DIR/tmp/$pkg_name.tgz" "$pkg_url"
}

pkg_extract() {
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/opt/cross"
    tar -xzf "$BUILDENV_DIR/tmp/$pkg_name.tgz" -C "$BUILDENV_DIR/opt/cross"
    rm -f "$BUILDENV_DIR/tmp/$pkg_name.tgz"
}

pkg_postinst(){
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    echo 'export PATH=/opt/cross/aarch64-linux-musl-cross/bin:$PATH' >> "${BUILDENV_DIR}/root/.bashrc"
}
