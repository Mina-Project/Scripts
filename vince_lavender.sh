#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)
# Copyright (C) 2020 ToniStark | 미나 (@MoveAngel)

export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_ID="-1001323983226"
export pack=$(pwd)/anykernel3
export TELEGRAM_TOKEN="MTI5MDc5MjQxNDpBQUY4QWJQVWc4QkpQcG5rVjhLTUV5ZW5FNnlZeW1od0ljZw=="
export product_name=Mina-미나
export PATH=$(pwd)/clang/bin:$PATH
export device="Xiaomi Redmi Note 7/7S"
export codename_device=lavender
export config_device=lavender-perf_defconfig
export KBUILD_BUILD_HOST=$(whoami)
export KBUILD_BUILD_USER=MoveAngel
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export commit_point=$(git log --pretty=format:'%h: %s (%an)' -1)
export parse_branch=$(git rev-parse --abbrev-ref HEAD)

mkdir $(pwd)/temp
git clone --depth=1 https://github.com/Haseo97/Avalon-Clang-11.0.1 -b 11.0.1 clang
git clone --depth=1 https://github.com/Mina-Project/AnyKernel3 anykernel3
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram

TELEGRAM=telegram/telegram
tg_channelcast() {
    "${TELEGRAM}" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_build() {
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1| tee kernel.log
}
tg_sendinfo() {
    "${TELEGRAM}" -c "680900214" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAx0CTSOkewABAUFiXpUfjOjsAAEfQNmvRyD-YvTLM8f7AAIjAQACdraVKKbzsP1n4T8kGAQ" \
	-d chat_id="$TELEGRAM_ID"
}
date=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make O=out ARCH=arm64 "$config_device"
tg_build
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
        curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="680900214"
	tg_sendinfo "$product_name $device Build Failed!!"
	exit 1
else
        mv $kernel_img $pack/zImage
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="680900214"
cd $pack && zip -r9q $product_name-$codename_device-$date.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..

kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$product_name new build is available</b>!" \
		"<b>Device :</b> <code>$device</code>" \
		"<b>Branch :</b> <code>$parse_branch</code>" \
		"<b>Kernel Version :</b> Linux <code>$kernel_ver</code>" \
		"<b>Toolchain :</b> <code>$toolchain_ver</code>" \
		"<b>Latest commit :</b> <code>$commit_point</code>"
curl -F document=@$(echo $pack/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
