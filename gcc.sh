#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)
export type=$(cat $(pwd)/version.txt) # do this to determine kernel type
if [ "$type" == "Heterogen-Multi Processing" ]; then
   export kernel_type=Hmp
   export sticker="CAADBQADeQEAAn1Cwy71MK7Ir5t0PhYE"
elif [ "$type" == "Energy Aware Scheduling" ]; then
   export kernel_type=EaS
   export sticker="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE"
elif [ "$type" == "Energy Aware Scheduling" ]; then
   export kernel_type=EaS
   export sticker="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE"
elif [ "$type" == "Code Aurora Forum" ]; then
   export kernel_type="PuRe-CaF"
   export sticker="CAADBQADfAEAAn1Cwy6aGpFrL8EcbRYE"
elif [ ! -f "$type" ]; then
   export kernel_type=Test-Build
   export sticker="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE"
fi

# Environment for Device 1
export codename_device1=rolex
export config_device1=rolex_defconfig

# Environment for Device 2
export codename_device2=riva
export config_device2=riva_defconfig

# Environment Vars
export ARCH=arm64
export TZ="Asia/Jakarta"
export pack1=$(pwd)/zip1
export pack2=$(pwd)/zip2
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token
export product_name=GREENFORCE
export device="Xiaomi Redmi 4A/5A"
export KBUILD_BUILD_HOST=$(whoami)
export KBUILD_BUILD_USER=Mhmmdfadlyas
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export commit_point=$(git log --pretty=format:'%h: %s (%an)' -1)

mkdir $(pwd)/TEMP # this is the place for build.log later
export TEMP=$(pwd)/TEMP
if [ ! -f "$type" ]; then
   git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r54 gcc
   git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r54 gcc32
else
   git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r54 gcc
   git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r54 gcc32
   git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6284175 clang
fi
   git clone --depth=1 https://github.com/fabianonline/telegram.sh $(pwd)/telegram
   git clone --depth=1 https://github.com/fadlyas07/anykernel-3 $(pwd)/zip1
   git clone --depth=1 https://github.com/fadlyas07/anykernel-3 $(pwd)/zip2

TELEGRAM=telegram/telegram # path for telegram.sh
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_makedevice1() {
make O=out ARCH=arm64 "$config_device1"
tg_build
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="$sticker" \
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
tg_makedevice2() {
make O=out ARCH=arm64 "$config_device2"
tg_build
}
if [ "$kernel_type" == "Test-Build" ]; then
    tg_build () { # For GCC 4.9.x only
        make -j$(nproc) O=out \
		        ARCH=arm64 \
		        CROSS_COMPILE=aarch64-linux-android- \
		        CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee build.log
    }
else
    tg_build () { # For All Clang with GCC 4.9.x (except clang + binutils | LLVM )
        make -j$(nproc) O=out \
		        ARCH=arm64 \
		        CC=clang \
		        CLANG_TRIPLE=aarch64-linux-gnu- \
		        CROSS_COMPILE=aarch64-linux-android- \
		        CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee build.log
    }
fi

if [ "$kernel_type" == "Test-Build" ]; then
    export PATH=$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH
else
    export PATH=$(pwd)/clang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH
fi

# Compile Device 1
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice1
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name $kernel_type Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack1/zImage
cd $pack1
zip -r9q $product_name-$codename_device1-$kernel_type-$date1.zip * -x .git README.md LICENCE
cd ..

# clean up output & log
rm -rf out/ $TEMP/*.log

# Compile Device 2
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice2
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	tg_sendinfo "$product_name $kernel_type Build Failed!"
	exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack2/zImage
cd $pack2
zip -r9q $product_name-$codename_device2-$kernel_type-$date2.zip * -x .git README.md LICENCE
cd ..

toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$product_name new build is available</b>!" \
		"<b>Device :</b> <code>$device</code>" \
		"<b>Kernel Type :</b> <code>$kernel_type</code>" \
		"<b>Branch :</b> <code>$parse_branch</code>" \
		"<b>Toolchain :</b> <code>$toolchain_ver</code>" \
		"<b>Latest commit :</b> <code>$commit_point</code>"
curl -F document=@$(echo $pack1/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack2/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
