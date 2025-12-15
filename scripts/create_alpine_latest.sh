#!/bin/bash
SCRIPT_DIR="$(realpath "$(dirname "$0")")"

source "${SCRIPT_DIR}/alpine/packages.sh"
source "${SCRIPT_DIR}/common.sh"

ALPINE_DOMAIN="dl-cdn.alpinelinux.org"
ALPINE_VERSION="latest-stable"
ALPINE_ARCH="$1"

REAL_VERSION_OVERRIDE="$2"
ARE_WE_SKIPPING_DOWNLOAD_AND_EXTRACTION="$3" # can either be yes or blank for no
ROOTFS_DIR="$(realpath "${SCRIPT_DIR}"/../)/tmp/Alpine_$(randstr)/"
ROOTFS_DIR_OVERRIDE="$4"

if [ "$ROOTFS_DIR_OVERRIDE" != "" ]; then
	rm -rf "${ROOTFS_DIR}" # remove old rootfs_dir to prevent filling /tmp
	ROOTFS_DIR="$ROOTFS_DIR_OVERRIDE"
fi

mkdir -p "$ROOTFS_DIR"

if [ "$ALPINE_ARCH" != "$(uname -m)" ]; then
	echo "!! The system architecture ($(uname -m)) doesn't match the architecture provided ($ALPINE_ARCH). This will likely result in a Exec format error if not properly configured. Continue? !!"
	read -rep "[y/N] " archresp
	if [ "${archresp,,}" == "" ]; then
		archresp="n"
	fi

	if [ "${archresp,,}" == "n" ]; then
		echo " -- exiting! --"
		exit 1
	elif [ "${archresp,,}" == "y" ]; then
		echo "You have been warned! Any bugs past here are not reportable. This building mode is not supported and will likely break."
	else
		echo "unknown response (${archresp}), exiting anyway. please use 'y' or 'n' next time."
		exit 2
	fi
fi

if [ -z "$REAL_VERSION_OVERRIDE" ]; then
# first, we fetch the file list
# then we parse that file list for the tar.gz for minirootfs
# then we remove release canidates
# finally, we sort with release numbers oldest to newest & use tail to get the newest one
ALPINE_REAL_VERSION=$(curl -s "https://${ALPINE_DOMAIN}/${ALPINE_VERSION}/releases/${ALPINE_ARCH}/" \
    | grep -oP "alpine-minirootfs-\K[0-9]+\.[0-9]+\.[0-9]+(?=-${ALPINE_ARCH}\.tar\.gz)" \
    | grep -v '_rc' \
    | sort -V \
    | tail -1)
else
	ALPINE_REAL_VERSION="$REAL_VERSION_OVERRIDE"
	ALPINE_VERSION="v${REAL_VERSION_OVERRIDE%.*}"
fi

MINIROOTFS_FILE_NAME="alpine-minirootfs-${ALPINE_REAL_VERSION}-${ALPINE_ARCH}.tar.gz"

if [ "$ARE_WE_SKIPPING_DOWNLOAD_AND_EXTRACTION" != "yes" ]; then
wget -O "${ROOTFS_DIR}/${MINIROOTFS_FILE_NAME}" "https://${ALPINE_DOMAIN}/${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${MINIROOTFS_FILE_NAME}"
tar -xzf "${ROOTFS_DIR}/${MINIROOTFS_FILE_NAME}" -C "${ROOTFS_DIR}"
rm -rf "${ROOTFS_DIR}/${MINIROOTFS_FILE_NAME}"
fi

if [ $EUID -ne 0 ]; then
	echo " -- the rest of the script requires root permissions, continue? -- "
	read -rep "[Y/n] " rootresp
	if [ "${rootresp,,}" == "" ]; then
		rootresp="y"
	fi

	if [ "${rootresp,,}" != "y" ]; then
		echo " -- exiting! --"
		exit 1
	fi
	exec sudo bash "${SCRIPT_DIR}/$(basename "$0")" ${ALPINE_ARCH} ${ALPINE_REAL_VERSION} yes ${ROOTFS_DIR}
fi

## from now on we have root permissions, be careful! ##

mountpoints=(
	/dev
	/dev/pts
	/sys
	/proc
	/run
)

for mountpoint in "${mountpoints[@]}"; do
	mount --bind $mountpoint "${ROOTFS_DIR}/${mountpoint}"
done

cat <<EOF > "${ROOTFS_DIR}/install-packages"
#!/bin/sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
echo "nameserver 1.1.1.1" > /etc/resolv.conf
ping 1.1.1.1 -c3
ping google.com -c3
apk add ${package_list[@]}

rustup-init -y
EOF

chmod +x "${ROOTFS_DIR}/install-packages"

chroot "${ROOTFS_DIR}" "/install-packages"
bash "${SCRIPT_DIR}/alpine/external-pkgs.sh" "${ROOTFS_DIR}"

# all roads lead to rome
pids=$(lsof +D "$ROOTFS_DIR" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)

if [ -n "$pids" ]; then
    echo "The following processes are using files under $ROOTFS_DIR:"
    for pid in $pids; do
        cmdline=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null)
        exe=$(readlink -f /proc/$pid/exe 2>/dev/null)
        echo "PID: $pid  CMD: $cmdline  EXE: $exe"
    done

    read -p "Do you want to kill these processes? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        kill -9 $pids
    else
        echo "Unmount may fail due to busy files."
    fi
fi

# reverse it because we want to unmount /dev/pts before /dev
for ((i=${#mountpoints[@]}-1; i>=0; i--)); do
    umount "${ROOTFS_DIR}/${mountpoints[i]}"
done

rm -rf "${ROOTFS_DIR}/install_packages"
cat <<EOF >> "${ROOTFS_DIR}/root/.bashrc"
source /etc/profile
source ~/.profile
source /etc/bash/bashrc
source /etc/bash/bash_completion.sh
EOF
chown -R root:root "${ROOTFS_DIR}"
cd "${ROOTFS_DIR}"
mkdir -p "${SCRIPT_DIR}/../Alpine/${ALPINE_ARCH}"
echo "Running post-installation scripts"
bash "${SCRIPT_DIR}/alpine/external-pkgs.sh" "${ROOTFS_DIR}" "--postinst"
echo "Compressing final image"
tar -czf "${SCRIPT_DIR}/../Alpine/${ALPINE_ARCH}/Alpine-${ALPINE_REAL_VERSION}.tgz" .
cd "${SCRIPT_DIR}/../"
echo "Final image built at $(realpath "${SCRIPT_DIR}/../Alpine/${ALPINE_ARCH}/Alpine-${ALPINE_REAL_VERSION}.tgz")"
echo "-- doing cleanup --"
rm -rf "${ROOTFS_DIR}" 