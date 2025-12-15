# build-env

>[!IMPORTANT]
>You can only build the architecture that your machine is running! If you want to build a different architecture, use a VM.

Repository with tarballed build environments that developers can use to only have to support one OS with the dependencies already installed or the names already known.

This is intended for building static binaries, although they can be used for linking dynamically as well.

## cross compiling inside a build-env
Cross-compilers are pre-installed via musl.cc tarballs

- If you're using a x86_64 build-env, the aarch64-linux-musl toolchain comes preinstalled.
- If you're using an aarch64 build-env, the x86_64-linux-musl toolchain comes preinstalled.

## package list
For a build-env's package list, see `scripts/<distro>/packages.sh`. This might not include packages installed externally outside of the distro's package manager. (e.g: cross-compilers depending on the distro)