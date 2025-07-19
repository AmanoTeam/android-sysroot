#!/bin/bash

set -eu

declare -ra targets=(
	'aarch64-unknown-linux-android'
	'riscv64-unknown-linux-android'
	'arm-unknown-linux-androideabi'
	'x86_64-unknown-linux-android'
	'i686-unknown-linux-android'
	'mipsel-unknown-linux-android'
	'mips64el-unknown-linux-android'
)

declare -r versions=(
	'14'
	'15'
	'16'
	'17'
	'18'
	'19'
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
declare -r unsupported_ndk_directory='/tmp/android-ndk-r16b'

declare -r workdir="${PWD}"

function get_arch() {
	
	if [ "${1}" = 'aarch64-unknown-linux-android' ]; then
		echo 'arm64'
	fi
	
	if [ "${1}" = 'riscv64-unknown-linux-android' ]; then
		echo 'riscv64'
	fi
	
	if [ "${1}" = 'arm-unknown-linux-androideabi' ]; then
		echo 'arm'
	fi
	
	if [ "${1}" = 'x86_64-unknown-linux-android' ]; then
		echo 'x86_64'
	fi
	
	if [ "${1}" = 'i686-unknown-linux-android' ]; then
		echo 'x86'
	fi
	
	if [ "${1}" = 'mipsel-unknown-linux-android' ]; then
		echo 'mips'
	fi
	
	if [ "${1}" = 'mips64el-unknown-linux-android' ]; then
		echo 'mips64'
	fi

}

function remove_symbols() {

	objcopy \
		--redefine-sym '__stack_chk_fail=liaf_khc_kcats__' \
		--redefine-sym '__stack_chk_fail_local=lacol_liaf_khc_kcats__' \
		"${1}"
	
}

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
	
	curl \
		--url 'https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip' \
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
	
	sed \
		--in-place \
		'/#warning/d' \
		'/tmp/data/data/com.termux/files/usr/include/sys/cdefs.h'
	
	sed \
		--in-place \
		's/__ANDROID_API__ 24/__ANDROID_API__ __ANDROID_API_FUTURE__/g' \
		'/tmp/data/data/com.termux/files/usr/include/sys/cdefs.h'
fi

for target in "${targets[@]}"; do
	declare arch="$(get_arch ${target})"
	declare triplet="${target/-unknown/}"
	declare unsupported_ndk='0'
	
	for version in "${versions[@]}"; do
		if [ -d "${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/${version}" ]; then
			unsupported_ndk='0'
		elif [ -d "${unsupported_ndk_directory}/platforms/android-${version}/arch-${arch}" ]; then
			unsupported_ndk='1'
		else
			continue
		fi
		
		echo "${target}${version}"
		
		declare sysroot_directory="/tmp/${target}${version}"
		
		rm --recursive --force "${sysroot_directory}"
		
		mkdir --parent "${sysroot_directory}/lib"
		
		declare include_directory=''
		
		if (( unsupported_ndk )); then
			include_directory="${unsupported_ndk_directory}/sysroot/usr/include"
		else
			include_directory='/tmp/data/data/com.termux/files/usr/include'
		fi
		
		cp \
			--recursive \
			"${include_directory}" \
			"${sysroot_directory}"
		
		cd "${sysroot_directory}/include"
		
		for name in *-linux-android*; do
			if [ "${name}" != "${triplet}" ]; then
				rm --recursive "${name}"
				continue
			fi
			
			mv "${name}/"* './' && rmdir "${name}"
		done
		
		declare library_directory=''
		declare library_directory2=''
		
		if (( unsupported_ndk )); then
			library_directory="${unsupported_ndk_directory}/platforms/android-${version}/arch-${arch}/usr/lib"
			library_directory2="${unsupported_ndk_directory}/platforms/android-${version}/arch-${arch}/usr/lib64"
		else
			library_directory="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/${version}"
			library_directory2="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}"
		fi
		
		if (( unsupported_ndk )); then
			cp \
				"${library_directory}/"* \
				"${library_directory2}/"* \
				"${sysroot_directory}/lib" || true
		else
			cp \
				"${library_directory}/"* \
				"${library_directory2}/"*.{a,so} \
				"${sysroot_directory}/lib" || true
		fi
		
		if (( unsupported_ndk )); then
			remove_symbols "${sysroot_directory}/lib/crtbegin_dynamic.o"
			remove_symbols "${sysroot_directory}/lib/crtbegin_so.o"
			remove_symbols "${sysroot_directory}/lib/crtbegin_static.o"
			
			patch --directory="${sysroot_directory}/include" --strip='1' --input="${workdir}/patches/0001-Header-fixes.patch"
		fi
		
		rm "${sysroot_directory}/lib/lib"{compiler,stdc++,c++}* || true
		rm --force --recursive "${sysroot_directory}/include/c++"
		
		declare tarball_filename="${sysroot_directory}.tar.xz"
		
		tar --directory='/tmp' --create --file=- "$(basename "${sysroot_directory}")" | xz --compress -9 > "${tarball_filename}"
		sha256sum "${tarball_filename}" | sed 's|/tmp/||' > "${tarball_filename}.sha256"
	done
done
