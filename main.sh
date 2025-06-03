#!/bin/bash

set -eu

declare -ra targets=(
	'aarch64-linux-android'
	'riscv64-linux-android'
	'arm-linux-androideabi'
	'x86_64-linux-android'
	'i686-linux-android'
)

declare -r pkg_file='/tmp/pkg.deb'

declare -r ndk_archive='/tmp/ndk.zip'
declare -r ndk_directory='/tmp/android-ndk-r27c'

if ! [ -f "${ndk_archive}" ]; then
	curl \
		--url 'https://dl.google.com/android/repository/android-ndk-r27c-linux.zip' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${ndk_archive}"
	
	unzip \
		-d "$(dirname "${ndk_directory}")" \
		-q \
		"${ndk_archive}"
fi

if ! [ -f "${pkg_file}" ]; then
	curl \
		--url 'https://github.com/termux-user-repository/dists/releases/download/0.1/ndk-sysroot-gcc-compact_27b-3_arm.deb' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${pkg_file}"
	
	ar x "${pkg_file}"
	
	tar \
		--touch \
		--no-overwrite-dir \
		--no-same-permissions \
		--directory="$(dirname "${pkg_file}")" \
		--extract \
		--file='./data.tar.xz'
fi


for target in "${targets[@]}"; do
	declare sysroot_directory="/tmp/${target}"
	
	rm --recursive --force "${sysroot_directory}"
	
	mkdir --parent "${sysroot_directory}/lib"
	
	cp \
		--recursive \
		'/tmp/data/data/com.termux/files/usr/include' \
		"${sysroot_directory}"
	
	cd "${sysroot_directory}/include"
	
	for name in *-linux-android*; do
		if [ "${name}" != "${target}" ]; then
			rm --recursive "${name}"
			continue
		fi
		
		mv "${name}/"* './' && rmdir "${name}"
	done
	
	cp \
		"${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${target}/35/"* \
		"${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${target}/"*.{a,so} \
		"${sysroot_directory}/lib"
	
	declare tarball_filename="/tmp/${target}.tar.xz"
	
	tar --directory='/tmp' --create --file=- "${target}" | xz --compress -9 > "${tarball_filename}"
	sha256sum "${tarball_filename}" | sed 's|/tmp/||' > "${tarball_filename}.sha256"
done
