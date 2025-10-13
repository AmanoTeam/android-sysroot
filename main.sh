#!/bin/bash

set -eu

declare -r debian_sysroot_tarball='/tmp/sysroot.tar.xz'

declare -r mipsel_sysroot='/tmp/mipsel-unknown-linux-gnu2.31'
declare -r mips64_sysroot='/tmp/mips64el-unknown-linux-gnuabi642.31'

declare -ra targets=(
	'aarch64-unknown-linux-android'
	'riscv64-unknown-linux-android'
	'armv7-unknown-linux-androideabi'
	'armv5-unknown-linux-androideabi'
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
declare -r ndk_directory='/tmp/android-ndk-r29'
declare -r unsupported_ndk_directory='/tmp/android-ndk-r16b'

declare -r include_dir="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include"

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
	
	if [ "${1}" = 'armv5-unknown-linux-androideabi' ]; then
		echo 'arm'
	fi
	
	if [ "${1}" = 'armv7-unknown-linux-androideabi' ]; then
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
	
	"${1}-objcopy" \
		--strip-symbol '__stack_chk_fail_local' \
		"${2}"
	
}

function merge_libraries() {
	
	local cwd="${PWD}"
	
	cd "${1}"
	
	mkdir 'tmp'
	cd 'tmp'
	
	ar x '../libpino-math.a'
	ar rcs '../libm.a' *'.o'
	
	rm --force --recursive ./*
	
	if [ -f '../libpino-mman.a' ]; then
		ar x '../libpino-mman.a'
		ar rcs '../libc.a' *'.o'
	fi
	
	rm --force '../libpino-'*
	rm --force --recursive "${PWD}"
	
	cd "${cwd}"
	
}

if ! [ -f "${ndk_archive}" ]; then
	curl \
		--url 'https://dl.google.com/android/repository/android-ndk-r29-linux.zip' \
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
		--directory="${include_dir}" \
		--strip='1' \
		--input="${workdir}/patches/0001-Android-NDK-r29-Beta-3.patch"
	
	mv "${include_dir}/sys/cdefs.h" './cdefs.h'
	
	while read file; do
		sed \
			--in-place \
			--expression 's/__INTRODUCED_IN(9)/__INTRODUCED_IN_API_G__/g; s/__INTRODUCED_IN(__ANDROID_API_G__)/__INTRODUCED_IN_API_G__/g' \
			--expression 's/__INTRODUCED_IN(14)/__INTRODUCED_IN_API_I__/g; s/__INTRODUCED_IN(__ANDROID_API_I__)/__INTRODUCED_IN_API_I__/g' \
			--expression 's/__INTRODUCED_IN(16)/__INTRODUCED_IN_API_J__/g; s/__INTRODUCED_IN(__ANDROID_API_J__)/__INTRODUCED_IN_API_J__/g' \
			--expression 's/__INTRODUCED_IN(17)/__INTRODUCED_IN_API_J_MR1__/g; s/__INTRODUCED_IN(__ANDROID_API_J_MR1__)/__INTRODUCED_IN_API_J_MR1__/g' \
			--expression 's/__INTRODUCED_IN(18)/__INTRODUCED_IN_API_J_MR2__/g; s/__INTRODUCED_IN(__ANDROID_API_J_MR2__)/__INTRODUCED_IN_API_J_MR2__/g' \
			--expression 's/__INTRODUCED_IN(19)/__INTRODUCED_IN_API_K__/g; s/__INTRODUCED_IN(__ANDROID_API_K__)/__INTRODUCED_IN_API_K__/g' \
			--expression 's/__INTRODUCED_IN(21)/__INTRODUCED_IN_API_L__/g; s/__INTRODUCED_IN(__ANDROID_API_L__)/__INTRODUCED_IN_API_L__/g' \
			--expression 's/__INTRODUCED_IN(22)/__INTRODUCED_IN_API_L_MR1__/g; s/__INTRODUCED_IN(__ANDROID_API_L_MR1__)/__INTRODUCED_IN_API_L_MR1__/g' \
			--expression 's/__INTRODUCED_IN(23)/__INTRODUCED_IN_API_M__/g; s/__INTRODUCED_IN(__ANDROID_API_M__)/__INTRODUCED_IN_API_M__/g' \
			--expression 's/__INTRODUCED_IN(24)/__INTRODUCED_IN_API_N__/g; s/__INTRODUCED_IN(__ANDROID_API_N__)/__INTRODUCED_IN_API_N__/g' \
			--expression 's/__INTRODUCED_IN(25)/__INTRODUCED_IN_API_N_MR1__/g; s/__INTRODUCED_IN(__ANDROID_API_N_MR1__)/__INTRODUCED_IN_API_N_MR1__/g' \
			--expression 's/__INTRODUCED_IN(26)/__INTRODUCED_IN_API_O__/g; s/__INTRODUCED_IN(__ANDROID_API_O__)/__INTRODUCED_IN_API_O__/g' \
			--expression 's/__INTRODUCED_IN(27)/__INTRODUCED_IN_API_O_MR1__/g; s/__INTRODUCED_IN(__ANDROID_API_O_MR1__)/__INTRODUCED_IN_API_O_MR1__/g' \
			--expression 's/__INTRODUCED_IN(28)/__INTRODUCED_IN_API_P__/g; s/__INTRODUCED_IN(__ANDROID_API_P__)/__INTRODUCED_IN_API_P__/g' \
			--expression 's/__INTRODUCED_IN(29)/__INTRODUCED_IN_API_Q__/g; s/__INTRODUCED_IN(__ANDROID_API_Q__)/__INTRODUCED_IN_API_Q__/g' \
			--expression 's/__INTRODUCED_IN(30)/__INTRODUCED_IN_API_R__/g; s/__INTRODUCED_IN(__ANDROID_API_R__)/__INTRODUCED_IN_API_R__/g' \
			--expression 's/__INTRODUCED_IN(31)/__INTRODUCED_IN_API_S__/g; s/__INTRODUCED_IN(__ANDROID_API_S__)/__INTRODUCED_IN_API_S__/g' \
			--expression 's/__INTRODUCED_IN(33)/__INTRODUCED_IN_API_T__/g; s/__INTRODUCED_IN(__ANDROID_API_T__)/__INTRODUCED_IN_API_T__/g' \
			--expression 's/__INTRODUCED_IN(34)/__INTRODUCED_IN_API_U__/g; s/__INTRODUCED_IN(__ANDROID_API_U__)/__INTRODUCED_IN_API_U__/g' \
			--expression 's/__INTRODUCED_IN(35)/__INTRODUCED_IN_API_V__/g; s/__INTRODUCED_IN(__ANDROID_API_V__)/__INTRODUCED_IN_API_V__/g' \
			--expression 's/__INTRODUCED_IN(36)/__INTRODUCED_IN_API_W__/g; s/__INTRODUCED_IN(__ANDROID_API_W__)/__INTRODUCED_IN_API_W__/g' \
			"${file}"
	done <<< $(find "${include_dir}" -type 'f')
	
	mv './cdefs.h' "${include_dir}/sys/cdefs.h"
	
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

if ! [ -f "${debian_sysroot_tarball}" ]; then
	curl \
		--url 'https://github.com/AmanoTeam/debian-sysroot/releases/latest/download/mipsel-unknown-linux-gnu2.31.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${debian_sysroot_tarball}"
	
	tar \
		--directory="$(dirname "${mipsel_sysroot}")" \
		--extract \
		--file="${debian_sysroot_tarball}"
	
	curl \
		--url 'https://github.com/AmanoTeam/debian-sysroot/releases/latest/download/mips64el-unknown-linux-gnuabi642.31.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${debian_sysroot_tarball}"
	
	tar \
		--directory="$(dirname "${mips64_sysroot}")" \
		--extract \
		--file="${debian_sysroot_tarball}"
	
	sed \
		--in-place \
		's/ sigaction / __kernel_sigaction /g' \
		"${mips64_sysroot}/include/asm/signal.h" \
		"${mipsel_sysroot}/include/asm/signal.h"
fi

declare -r include_directory_old="${unsupported_ndk_directory}/sysroot/usr/include"
declare -r include_directory_new="${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include"

for target in "${targets[@]}"; do
	declare arch="$(get_arch ${target})"
	
	declare triplet="${target/-unknown/}"
	declare triplet="${triplet/armv7/arm}"
	declare triplet="${triplet/armv5/arm}"
	
	declare unsupported_ndk='0'
	
	for version in "${versions[@]}"; do
		if [ "${target}" != 'armv5-unknown-linux-androideabi' ] && [ -d "${ndk_directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/${version}" ]; then
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
			"${include_directory_new}" \
			"${sysroot_directory}"
		
		cd "${sysroot_directory}/include"
		
		if [[ "${target}" = 'mips'* ]]; then
			rm --recursive 'asm'*
			
			if [ "${target}" = 'mips64el-unknown-linux-android' ]; then
				declare sysroot="${mips64_sysroot}"
			else
				declare sysroot="${mipsel_sysroot}"
			fi
			
			cp \
				--recursive \
				"${sysroot}/include/asm"* \
				'./'
			
			rm --recursive *'-linux-android'*
			
			patch \
				--directory='./' \
				--strip='1' \
				--input="${workdir}/patches/0001-Rename-SIOCGSTAMP-and-SIOCGSTAMPNS.patch"
		else
			for name in *'-linux-android'*; do
				if [ "${name}" != "${triplet}" ]; then
					rm --recursive "${name}"
					continue
				fi
				
				mv "${name}/"* './' && rmdir "${name}"
			done
		fi
		
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
		fi
		
		rm "${sysroot_directory}/lib/lib"{compiler,stdc++,c++}* || true
		rm "${sysroot_directory}/lib/lib"*'.a'
		rm --force --recursive "${sysroot_directory}/include/c++"
		
		declare tarball_filename="${sysroot_directory}.tar.xz"
		
		declare source="https://github.com/AmanoTeam/libpino/releases/latest/download/${target}.tar.xz"
		declare destination='/tmp/libpino.tar.xz'
		
		echo "Fetching prebuilts from '${source}'"
		
		curl \
			--url "${source}" \
			--retry '30' \
			--retry-delay '0' \
			--retry-all-errors \
			--retry-max-time '0' \
			--location \
			--silent \
			--output "${destination}"
		
		tar \
			--directory="${sysroot_directory}/lib" \
			--extract \
			--file="${destination}"
		
		if (( version >= 21 )); then
			rm --force "${sysroot_directory}/lib/libpino-mman.a"
		fi
		
		merge_libraries "${sysroot_directory}/lib"
		
		tar --directory='/tmp' --create --file=- "$(basename "${sysroot_directory}")" | xz --compress -9 > "${tarball_filename}"
		sha256sum "${tarball_filename}" | sed 's|/tmp/||' > "${tarball_filename}.sha256"
	done
done
