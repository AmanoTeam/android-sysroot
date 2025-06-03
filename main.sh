#!/bin/bash

set -eu

declare -ra targets=(
	'aarch64-unknown-linux-android'
	# 'riscv64-unknown-linux-android'
	'arm-unknown-linux-androideabi'
	'x86_64-unknown-linux-android'
	'i686-unknown-linux-android'
)

declare -r versions=(
	'21'
	'22'
	'23'
	'24'
	'25'
	'26'
	'27'
	'28'
	'29'
	'30'
	'31'
	'32'
	'33'
	'34'
	'35'
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
	
	sudo tar \
		--dereference \
		--no-same-owner \
		--no-overwrite-dir \
		--no-same-permissions \
		--directory="$(dirname "${pkg_file}")" \
		--extract \
		--file='./data.tar.xz'
	
	sudo chown "${USER}:${USER}" -R '/tmp'
	
	sed --in-place '/#warning/d' '/tmp/data/data/com.termux/files/usr/include/sys/cdefs.h'
fi


for target in "${targets[@]}"; do
	declare triplet="${target/-unknown/}"
	
	for version in "${versions[@]}"; do
		echo "${target}${version}"
		
		declare sysroot_directory="/tmp/${target}${version}"
		
		rm --recursive --force "${sysroot_directory}"
		
		mkdir --parent "${sysroot_directory}/lib"
		
		cp \
			--recursive \
			'/tmp/data/data/com.termux/files/usr/include' \
			"${sysroot_directory}"
		
		cd "${sysroot_directory}/include"
		
		for name in *-linux-android*; do
			if [ "${name}" != "${triplet}" ]; then
				rm --recursive "${name}"
				continue
			fi
			
			mv "${name}/"* './' && rmdir "${name}"
		done
		
		cp \
			"${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/${version}/"* \
			"${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/"*.{a,so} \
			"${sysroot_directory}/lib"
		
		declare tarball_filename="${sysroot_directory}.tar.xz"
		
		tar --directory='/tmp' --create --file=- "$(basename "${sysroot_directory}")" | xz --compress -9 > "${tarball_filename}"
		sha256sum "${tarball_filename}" | sed 's|/tmp/||' > "${tarball_filename}.sha256"
	done
done
