#!/bin/bash

# ALPINE_VERSION should exist in the env vars
# either way if it doesn't we just use latest-stable
if [ -z "$ALPINE_VERSION" ]; then
    ALPINE_VERSION="latest-stable"
fi

pkg_name="x86_64_linux_musl"
pkg_url="https://github.com/userdocs/qbt-musl-cross-make/releases/download/2550/aarch64-x86_64-linux-musl.tar.xz"

pkg_download() {
    if [ "$(uname -m)" != "aarch64" ]; then
        echo "skipping $pkg_name: requires an aarch64 host"
        return 0
    fi
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/tmp" || return 1
    wget -q --show-progress -O "$BUILDENV_DIR/tmp/$pkg_name.tar.xz" "$pkg_url" || return 1
}

pkg_extract() {
    if [ "$(uname -m)" != "aarch64" ]; then
        echo "skipping $pkg_name: requires an aarch64 host"
        return 0
    fi
    BUILDENV_DIR="$1"
    mkdir -p "$BUILDENV_DIR/opt/cross" || return 1
    tar -xJf "$BUILDENV_DIR/tmp/$pkg_name.tar.xz" -C "$BUILDENV_DIR/opt/cross/" || return 1
    rm -f "$BUILDENV_DIR/tmp/$pkg_name.tar.xz"
}

pkg_postinst(){
    if [ "$(uname -m)" != "aarch64" ]; then
        echo "skipping $pkg_name: requires an aarch64 host"
        return 0
    fi
    BUILDENV_DIR="$1"
    echo 'export PATH=/opt/cross/x86_64-linux-musl/bin:$PATH' >> "${BUILDENV_DIR}/root/.bashrc" || return 1

    mkdir -p "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/usr" || return 1
    ln -sf "/opt/cross/x86_64-linux-musl/x86_64-linux-musl" "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/usr" || return 1

    mkdir -p "$BUILDENV_DIR/opt/cross/x86_64-linux-musl/bin" || return 1
    cat <<EOF > "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config" || return 1
#!/bin/sh
export PKG_CONFIG_LIBDIR=/opt/cross/x86_64-linux-musl/x86_64-linux-musl/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/opt/cross/x86_64-linux-musl/x86_64-linux-musl
export PKG_CONFIG_PATH=/opt/cross/x86_64-linux-musl/x86_64-linux-musl/lib/pkgconfig
pkg-config "\$@"
EOF
    chmod +x "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config" || return 1

    cat <<EOF > "${BUILDENV_DIR}/opt/cross/x86_64-linux-musl/x86_64-linux-musl-file" || return 1
[binaries]
c = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-gcc'
cpp = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-g++'
ar = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-ar'
pkgconfig = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config'
pkg-config = '/opt/cross/x86_64-linux-musl/bin/x86_64-linux-musl-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '/opt/cross/x86_64-linux-musl/x86_64-linux-musl'
EOF

    # --- extract linux headers ---
    tmpdir="$BUILDENV_DIR/tmp/linux-headers"
    mkdir -p "$tmpdir" || return 1

    apk_index="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main/x86_64/"
    headers_pkg=$(wget -qO- "$apk_index" | grep -o 'linux-headers-[^"]*\.apk' | sort -V | tail -n1)
    if [ -z "$headers_pkg" ]; then
        echo "unable to resolve linux-headers package for $pkg_name"
        return 1
    fi
    wget -q --show-progress -O "$tmpdir/linux-headers.apk" "${apk_index}${headers_pkg}" || return 1

    tar -xf "$tmpdir/linux-headers.apk" -C "$BUILDENV_DIR/opt/cross/x86_64-linux-musl" 2> >(grep -v "APK-TOOLS.checksum.SHA1" >&2) || return 1
    rm -rf "$tmpdir"
}
