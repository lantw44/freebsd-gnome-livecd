steps="system packages user config uzip ramdisk boot image"
pwdir="$(realpath $(dirname "$0"))"

system () {
	install -o root -g wheel -m 755 -d "${root}"
	cd "${src}" || return 1
	make installworld  DESTDIR="${root}" || return 1
	make installkernel DESTDIR="${root}" || return 1
	make distribution  DESTDIR="${root}" || return 1
}

packages () {
	sed -i.bak 's|yes|no|' "${root}/etc/pkg/FreeBSD.conf"
	cat << EOF > "${root}/etc/pkg/packages.conf"
packages: {
   url: "file:///packages",
   enabled: yes
}
EOF
	install -d "${root}/packages"
	mount_nullfs "${repo}" "${root}/packages"
	pkg -c "${root}" install -fy ${pkgs} || {
		umount "${root}/packages"
		return 1
	}
	rm -rf "${root}/var/cache/pkg/All"
	umount "${root}/packages"
	rm -f "${root}/etc/pkg/packages.conf"
	mv -f "${root}/etc/pkg/FreeBSD.conf.bak" "${root}/etc/pkg/FreeBSD.conf"
}

user () {
	install -o root -g wheel -m 755 -d "${root}/home"
	cat << EOF > "${root}/users"
#!/bin/sh
set -x
for user in liveuser; do
	pw add user \$user -G wheel -s /bin/tcsh -M 755
	chpass -p '' \$user
	install -o \$user -g \$user -m 755 -d /home/\$user
	echo 'limit coredumpsize 0' > /home/\$user/.login
	chown \$user:\$user /home/\$user/.login
done
EOF
	chmod 755 "${root}/users"
	chroot "${root}" "/users"
	rm -f "${root}/users"
}

config () {
	cd "${pwdir}"
	install -o root -g wheel -m 644 "rc.conf" "${root}/etc/"
	cat << EOF > "${root}/etc/fstab"
fdesc   /dev/fd         fdescfs         rw      0       0
EOF
	cat << EOF > "${root}/etc/sysctl.conf"
kern.coredump=0
EOF
}

uzip () {
	install -o root -g wheel -m 755 -d "${cdroot}"
	mkdir "${cdroot}/data"
	makefs "${cdroot}/data/system.ufs" "${root}"
	mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
	rm -f "${cdroot}/data/system.ufs"
}

ramdisk () {
	ramdisk_root="${cdroot}/data/ramdisk"
	mkdir -p "${ramdisk_root}"
	cd "${root}"
	tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
	cd "${pwdir}"
	install -o root -g wheel -m 755 "init.sh.in" "${ramdisk_root}/init.sh"
	sed "s/@VOLUME@/${vol}/" "init.sh.in" > "${ramdisk_root}/init.sh"
	mkdir "${ramdisk_root}/dev"
	mkdir "${ramdisk_root}/etc"
	touch "${ramdisk_root}/etc/fstab"
	makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
	gzip "${cdroot}/data/ramdisk.ufs"
	rm -rf "${ramdisk_root}"
}

boot () {
	cd "${root}"
	tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
	for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
		tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
	done
	cd "${pwdir}"
	install -o root -g wheel -m 644 "loader.conf" "${cdroot}/boot/"
}

image () {
	cd "${cdroot}"
	mkisofs -iso-level 4 -R -l -ldots -allow-lowercase -allow-multidot -V \
		"${vol}" -o "${image}" -no-emul-boot -b boot/cdboot .
}


if [ "`id -u`" '!=' "0" ]; then
	echo "Sorry, you are not root ..."
	exit 1
fi

# This check cannot be done reliably, but it should be able to catch the
# most common mistake.
if [ "$(basename "$0")" = "build.sh" ] && [ "${pwdir}" = "$(realpath $(pwd))" ]; then
	echo "This script cannot be run directly."
	echo "Please create a wrapper script that sources this file instead."
	echo "You can use build-release.sh and build-debug.sh as examples."
	exit 1
fi

# Check whether required variables are defined.
assert_dir_or_file () {
	if [ -z "$2" ] || [ "$(realpath "$2" 2>/dev/null)" = "/" ]; then
		echo "Variable '$1' is unset or set to the root directory."
		exit 1
	fi
}
assert_empty () {
	if [ -z "$2" ]; then
		echo "Variable '$1' is empty."
		echo "If no package have to be installed, set it to 'pkg'."
		exit 1
	fi
}
assert_dir_or_file src "${src}"
assert_dir_or_file root "${root}"
assert_dir_or_file cdroot "${cdroot}"
assert_dir_or_file image "${image}"
assert_dir_or_file repo "${repo}"
assert_empty pkgs "${pkgs}"
assert_empty vol "${vol}"
unset assert_dir_or_file
unset assert_empty

# Check whether the volume name is too long
if [ "${#vol}" -gt "31" ]; then
	echo "Variable 'vol' is too long. The length must not exceed 31 bytes."
	exit 1
fi

printf "All steps: \033[1;33m%s\033[m\n" "${steps}"
printf "(E)dit or (R)un? "
read edit_or_run

case "${edit_or_run}" in
	E*|e*)
		printf "New steps: "
		read steps
		;;
	R*|r*)
		;;
	*)
		echo "Unknown action ..."
		exit 1
		;;
esac

for task in ${steps}; do
	if type "${task}" >/dev/null 2>/dev/null; then :; else
		printf "==> Task \033[1;31m%s\033[m not found\n" "${task}"
		exit 1
	fi
done

for task in ${steps}; do
	printf "==> Running task \033[1;33m%s\033[m\n" "${task}"
	set -x
	if ${task}; then
		set +x
		printf "=> Task \033[1;32m%s\033[m OK\n" "${task}"
	else
		set +x
		printf "=> Task \033[1;31m%s\033[m failed\n" "${task}"
		exit 1
	fi
done
