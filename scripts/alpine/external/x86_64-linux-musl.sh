#!/bin/bash

pkg_name="aarch64_linux_musl"
pkg_url="https://github.com/userdocs/qbt-musl-cross-make/releases/download/2550/aarch64-x86_64-linux-musl.tar.xz"

pkg_download() {
    [ "$(uname -m)" != "aarch64" ] && echo "host arch not aarch64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/tmp"
    wget -O "$BUILDENV_DIR/tmp/$pkg_name.tgz" "$pkg_url"
}

pkg_extract() {
    [ "$(uname -m)" != "aarch64" ] && echo "host arch not aarch64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/opt/cross"
    tar -xzf "$BUILDENV_DIR/tmp/$pkg_name.tgz" -C "$BUILDENV_DIR/opt/cross/"
    rm -f "$BUILDENV_DIR/tmp/$pkg_name.tgz"
}

pkg_postinst(){
    [ "$(uname -m)" != "aarch64" ] && echo "host arch not aarch64, unable to install $pkg_name" && return 1
    BUILDENV_DIR="$1"
    echo 'export PATH=/opt/cross/x86_64-linux-musl/bin:$PATH' >> "${BUILDENV_DIR}/root/.bashrc"
    
    # you never know, extract could've failed or our postinst is broken
    # prevent the postinst script from failing
    mkdir -p "$BUILDENV_DIR/opt/cross/x86_64-linux-musl/bin"
    cat <<EOF > "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config"
#!/bin/sh
PKG_CONFIG_LIBDIR=/opt/cross/x86_64-linux-musl/x86_64-linux-musl/lib/pkgconfig \
PKG_CONFIG_SYSROOT_DIR=/opt/cross/x86_64-linux-musl/x86_64-linux-musl \
pkg-config "\$@"

EOF

    chmod +x "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config"
    cat <<EOF > "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/x86_64-linux-musl-file"
[binaries]
c = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-gcc'
cpp = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-g++'
ar = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-ar'
pkgconfig = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '/opt/cross/x86_64-linux-musl/x86_64-linux-musl'
EOF
}
