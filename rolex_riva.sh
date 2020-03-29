#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)

# Environment Vars
export ARCH=arm64
export TZ="Asia/Jakarta"
export TELEGRAM_ID=$chat_id
export pack=$(pwd)/anykernel-3
export TELEGRAM_TOKEN=$token
export product_name=GreenForce
export device="Xiaomi Redmi 4A/5A"
export KBUILD_BUILD_USER=$(whoami)
export KBUILD_BUILD_HOST=Mhmmdfadlyas
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export commit_point=$(git log --pretty=format:'%h: %s (%an)' -1)
if [ $parse_branch == "aosp/gcc-lto" ]; then
    export GCC="$(pwd)/gcc/bin/aarch64-linux-gnu-"
    export GCC32="$(pwd)/gcc32/bin/arm-linux-gnueabi-"
elif [ $parse_branch == "aosp/clang-lto" ]; then
    export PATH="$(pwd)/clang/bin:$PATH"
else
    export PATH=$(pwd)/clang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH
fi
export LD_LIBRARY_PATH=$(pwd)/clang/bin/../lib:$PATH

mkdir $(pwd)/TEMP
export TEMP=$(pwd)/TEMP
if [ $parse_branch == "aosp/gcc-lto" ]; then
    git clone --depth=1 https://github.com/chips-project/priv-toolchains -b non-elf/gcc-9.2.0/arm gcc32
    git clone --depth=1 https://github.com/chips-project/priv-toolchains -b non-elf/gcc-9.2.0/arm64 gcc
    git clone --depth=1 https://github.com/chips-project/priv-toolchains -b non-elf/gcc-9.2.0/arm gcc32
elif [ $parse_branch == "aosp/clang-lto" ]; then
    git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
else
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r36 gcc
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r36 gcc32
    git clone --depth=1 https://github.com/crdroidmod/android_prebuilts_clang_host_linux-x86_clang-5900059 clang
fi
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 https://github.com/fadlyas07/anykernel-3

# Device 1
export codename_device1=rolex
export config_device1=rolex_defconfig

# Device 2
export codename_device2=riva
export config_device2=riva_defconfig

TELEGRAM=telegram/telegram
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
      make -j$(nproc) O=out \
                      ARCH=arm64 \
                      CROSS_COMPILE="$GCC" \
                      CROSS_COMPILE_ARM32="$GCC32"
    }
elif [ $parse_branch == "aosp/clang-lto" ]; then
    tg_build() {
      make -j$(nproc) O=out \
		      ARCH=arm64 \
		      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
		      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    }
    tg_build() {
      make -j$(nproc) O=out \
		      ARCH=arm64 \
		      CC=clang \
		      CLANG_TRIPLE=aarch64-linux-gnu- \
		      CROSS_COMPILE=aarch64-linux-android- \
		      CROSS_COMPILE_ARM32=arm-linux-androideabi-
    }
fi
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAxkBAAEYl9pee0jBz-DdWSsy7Rik8lwWE6LARwACmQEAAn1Cwy4FwzpKLPPhXRgE" \
	-d chat_id="$TELEGRAM_ID"
}
tg_sendinfo() {
    "$TELEGRAM" -c "784548477" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_makedevice1() {
make ARCH=arm64 O=out "$config_device1"
tg_build
}
tg_makedevice2() {
make ARCH=arm64 O=out "$config_device2"
tg_build
}

# Compile device 1
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice1 2>&1| tee build.log
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-$codename_device1-$date1.zip * -x .git README.md LICENCE
cd ..

# * clean out, log, & zImage *
rm -rf out/ $TEMP/*.log $pack/zImage

# Compile device 2
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice2 2>&1| tee build.log
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-$codename_device2-$date2.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..

toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$product_name new build is available</b>!" \
		"<b>Device :</b> <code>$device</code>" \
		"<b>Branch :</b> <code>$parse_branch</code>" \
		"<b>Toolchain :</b> <code>$toolchain_ver</code>" \
		"<b>Latest commit :</b> <code>$commit_point</code>"
curl -F document=@$(echo $pack/$product_name-$codename_device1-$date1.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack/$product_name-$codename_device2-$date2.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
