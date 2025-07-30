#!/bin/bash

set -eu

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils-with-gold-2.44'

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
	'20'
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

declare -r ndk_archive='/tmp/ndk.zip'
declare -r ndk_directory='/tmp/android-ndk-r29-beta2'
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

	# "/tmp/bin/${1}-objcopy" \
	# --redefine-sym '__stack_chk_fail=liaf_khc_kcats__' \
	# --redefine-sym '__stack_chk_fail_local=lacol_liaf_khc_kcats__' \
	# "${2}"
	
	"/tmp/bin/${1}-objcopy" \
		--strip-symbol '__stack_chk_fail_local' \
		"${2}"
	
}

if ! [ -f "${ndk_archive}" ]; then
	curl \
		--url 'https://dl.google.com/android/repository/android-ndk-r29-beta2-linux.zip' \
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
	
	patch \
		--directory="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include" \
		--strip='1' \
		--input="${workdir}/patches/0001-I-have-no-clue-what-I-m-doing.patch"
	
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
	
	ln \
		--symbolic \
		"${unsupported_ndk_directory}/platforms/android-24" \
		"${unsupported_ndk_directory}/platforms/android-25"
	
	ln \
		--symbolic \
		"${unsupported_ndk_directory}/platforms/android-19" \
		"${unsupported_ndk_directory}/platforms/android-20"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/binutils/binutils-with-gold-2.44.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${binutils_tarball}"
	
	tar \
		--directory="$(dirname "${binutils_directory}")" \
		--extract \
		--file="${binutils_tarball}"
fi

for target in "${targets[@]}"; do
	[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--target="${target}" \
		--prefix='/tmp' \
		--disable-gold \
		--disable-ld \
		CFLAGS='-Oz' \
		CXXFLAGS='-Oz' \
		LDFLAGS='-Xlinker -s'
	
	make all --jobs
	make install
done

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
			include_directory="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include"
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
			remove_symbols "${target}" "${sysroot_directory}/lib/crtbegin_dynamic.o"
			remove_symbols "${target}" "${sysroot_directory}/lib/crtbegin_so.o"
			remove_symbols "${target}" "${sysroot_directory}/lib/crtbegin_static.o"
			
			patch --directory="${sysroot_directory}/include" --strip='1' --input="${workdir}/patches/0001-Header-fixes.patch"
		fi
		
		rm "${sysroot_directory}/lib/lib"{compiler,stdc++,c++}* || true
		rm --force --recursive "${sysroot_directory}/include/c++"
		
		declare tarball_filename="${sysroot_directory}.tar.xz"
		
		tar --directory='/tmp' --create --file=- "$(basename "${sysroot_directory}")" | xz --compress -9 > "${tarball_filename}"
		sha256sum "${tarball_filename}" | sed 's|/tmp/||' > "${tarball_filename}.sha256"
	done
done
