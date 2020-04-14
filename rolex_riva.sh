#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)

export ARCH=arm64
build_start=$(date +"%s")
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token
export pack=$(pwd)/anykernel-3
export product_name=GreenForce
export device="Xiaomi Redmi 4A/5A"
export KBUILD_BUILD_HOST=$(whoami)
export KBUILD_BUILD_USER=Mhmmdfadlyas
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export KBUILD_COMPILER_STRING=$($(pwd)/clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/ */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')

mkdir $(pwd)/temp && export TEMP=$(pwd)/temp
if [ $parse_branch == "aosp/gcc-lto" ]; then
    git clone --depth=1 --single-branch https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_arm_arm-eabi -b master gcc32
    git clone --depth=1 --single-branch https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_aarch64_aarch64-elf -b master gcc
else
    git clone --depth=1 --single-branch https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6364210 clang
    git clone --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r55 gcc32
    git clone --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r55 gcc
fi
git clone --depth=1 --single-branch https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 --single-branch https://github.com/fadlyas07/anykernel-3

tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAxkBAAEYl9pee0jBz-DdWSsy7Rik8lwWE6LARwACmQEAAn1Cwy4FwzpKLPPhXRgE" \
	-d chat_id="$TELEGRAM_ID"
}
TELEGRAM=telegram/telegram
tg_sendinfo() {
    "$TELEGRAM" -c "784548477" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
if [ $parse_branch == "aosp/gcc-lto" ]; then
    tg_build() {
      export GCC="$(pwd)/gcc/bin/aarch64-elf-"
      export GCC32="$(pwd)/gcc32/bin/arm-eabi-"
      make -j$(nproc --all) O=out \
                            ARCH=arm64 \
                            CROSS_COMPILE="$GCC" \
                            CROSS_COMPILE_ARM32="$GCC32"
    }
else
    tg_build() {
      PATH=$(pwd)/clang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH \
      make -j$(nproc --all) O=out \
		            ARCH=arm64 \
		            CC=clang \
		            CLANG_TRIPLE=aarch64-linux-gnu- \
		            CROSS_COMPILE=aarch64-linux-android- \
		            CROSS_COMPILE_ARM32=arm-linux-androideabi-
    }
fi

date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out rolex_defconfig && \
tg_build 2>&1| tee build_kernel.log
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-rolex-$date1.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..

**clean out, log, & zImage**
rm -rf out/ $TEMP/* $pack/zImage

date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out riva_defconfig && \
tg_build 2>&1| tee build_kernel.log
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-riva-$date2.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> using <b>$toolchain_ver</b> for <b>$device</b> with the newest commit <b>$(git log --pretty=format:'%s' -1)</b>. Build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$(echo $pack/$product_name-rolex-$date1.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack/$product_name-riva-$date2.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
