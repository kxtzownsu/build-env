#!/bin/bash

# ALPINE_VERSION should exist in the env vars
# either way if it doesn't we just use latest-stable
if [ -z "$ALPINE_VERSION" ]; then
    ALPINE_VERSION="latest-stable"
fi

pkg_name="aarch64_linux_musl"
pkg_url="https://github.com/userdocs/qbt-musl-cross-make/releases/download/2550/x86_64-aarch64-linux-musl.tar.xz"

pkg_download() {
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/tmp"
    wget -O "$BUILDENV_DIR/tmp/$pkg_name.tar.xz" "$pkg_url"
}

pkg_extract() {
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/opt/cross"
    tar -xJf "$BUILDENV_DIR/tmp/$pkg_name.tar.xz" -C "$BUILDENV_DIR/opt/cross/"
    rm -f "$BUILDENV_DIR/tmp/$pkg_name.tar.xz"
}

pkg_postinst(){
    [ "$(uname -m)" != "x86_64" ] && echo "host arch not x86_64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    echo 'export PATH=/opt/cross/aarch64-linux-musl/bin:$PATH' >> "${BUILDENV_DIR}/root/.bashrc"

    mkdir -p "${BUILDENV_DIR}/opt/cross/aarch64-linux-musl/usr"
    ln -sf "/opt/cross/aarch64-linux-musl/aarch64-linux-musl" "${BUILDENV_DIR}/opt/cross/aarch64-linux-musl/usr"
    
    mkdir -p "$BUILDENV_DIR/opt/cross/aarch64-linux-musl/bin"
    cat <<EOF > "${BUILDENV_DIR}/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-pkg-config"
#!/bin/sh
export PKG_CONFIG_LIBDIR=/opt/cross/aarch64-linux-musl/aarch64-linux-musl/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/opt/cross/aarch64-linux-musl/aarch64-linux-musl
export PKG_CONFIG_PATH=/opt/cross/aarch64-linux-musl/aarch64-linux-musl/lib/pkgconfig
pkg-config "\$@"
EOF
    chmod +x "${BUILDENV_DIR}/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-pkg-config"

    cat <<EOF > "${BUILDENV_DIR}/opt/cross/aarch64-linux-musl/aarch64-linux-musl-file"
[binaries]
c = '/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-gcc'
cpp = '/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-g++'
ar = '/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-ar'
pkgconfig = '/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '/opt/cross/aarch64-linux-musl/aarch64-linux-musl'
EOF

    # --- extract linux headers ---
    tmpdir="$BUILDENV_DIR/tmp/linux-headers"
    mkdir -p "$tmpdir"

    apk_index="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main/aarch64/"
    pkg_name=$(wget -qO- "$apk_index" | grep -o 'linux-headers-[^"]*\.apk' | sort -V | tail -n1)
    wget -O "$tmpdir/linux-headers.apk" "${apk_index}${pkg_name}"

    tar -xf "$tmpdir/linux-headers.apk" -C "$BUILDENV_DIR/opt/cross/aarch64-linux-musl"
    rm -rf "$tmpdir"
}