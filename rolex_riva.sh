#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $parse_branch == "aosp/android-3.18" ]]; then
     export kernel_type="Pure-CAF"
     export STICKER="CAADBQADfAEAAn1Cwy6aGpFrL8EcbRYE"
elif [[ $parse_branch == "HMP-vdso32" ]]; then
     export kernel_type="HmP"
     export STICKER="CAADBQADeQEAAn1Cwy71MK7Ir5t0PhYE"
elif [[ $parse_branch == "aosp/eas-3.18" ]]; then
     export kernel_type="EaS"
     export STICKER="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE"
elif [[ ! $parse_branch == "aosp/android-3.18" ]] && [[ ! $parse_branch == "HMP-vdso32" ]] && [[ ! $parse_branch == "aosp/eas-3.18" ]]; then
     export kernel_type="Test-Build"
     export STICKER="CAADBQADPwEAAn1Cwy4LGnCzWtePdRYE"
fi

# Device 1
export codename_device1=rolex
export config_device1=rolex_defconfig

# Device 2
export codename_device2=riva
export config_device2=riva_defconfig

mkdir $(pwd)/TEMP
if [[ $kernel_type == "HmP" ]]; then
     mkdir -p $(pwd)/clang
     wget https://kdrag0n.dev/files/redirector/proton_clang-latest.tar.zst
     tar -I zstd -xvf *.tar.zst -C $(pwd)/clang --strip-components=1
elif [[ $kernel_type == "EaS" ]]; then
     git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r50 gcc
     git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r50 gcc32
else
     git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6207600 clang
     git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r50 gcc
     git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r50 gcc32
fi
if [[ -f "*zst" ]]; then
    rm -rf *.tar.zst
fi
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip1
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip2
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram

# Telegram & Github Env Vars
export ARCH=arm64
export TZ=Asia/Jakarta
export pack1=$(pwd)/zip1
export pack2=$(pwd)/zip2
export TEMP=$(pwd)/TEMP
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token
export product_name=GREENFORCE
export KBUILD_BUILD_USER=github.com.fadlyas07
export KBUILD_BUILD_HOST=$CIRCLE_SHA1
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export commit_point=$(git log --pretty=format:'<code>%h: %s by</code> <b>%an</b>' -1)

TELEGRAM=telegram/telegram
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_sendinfo() {
    "$TELEGRAM" -c "784548477" -H \
    "$(
		for POST in "$@"; do
			echo "$POST"
		done
    )"
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="$STICKER" \
	-d chat_id="$TELEGRAM_ID"
}
make_kernel() {
if [[ $kernel_type == "HmP" ]]; then
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1| tee kernel.log
elif [[ $kernel_type == "EaS" ]]; then
make -j$(nproc) O=out \
                ARCH=arm64 \
                CROSS_COMPILE=aarch64-linux-android- \
                CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee kernel.log
else
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-android- \
                CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee kernel.log
}
if [[ $kernel_type == "HmP" ]]; then
      export PATH=$(pwd)/clang/bin:$PATH
      export LD_LIBRARY_PATH=$(pwd)/clang/lib:$LD_LIBRARY_PATH
elif [[ $kernel_type == "EaS" ]]; then
      export PATH=$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH
else
      export PATH=$(pwd)/clang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH
fi
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make O=out ARCH=arm64 "$config_device1"
make_kernel
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
        curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	    tg_sendinfo "$product_name $kernel_type Build Failed!!"
	exit 1;
else
        mv $kernel_img $pack1/zImage
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
cd $pack1
zip -r9 $product_name-$kernel_type-$codename_device1-$date1.zip * -x .git README.md LICENCE
cd ..
rm -rf out/ $TEMP/*.log
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make O=out ARCH=arm64 "$config_device2"
make_kernel
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
        curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
	    tg_sendinfo "$product_name $kernel_type Build Failed!!"
	exit 1;
else
        mv $kernel_img $pack2/zImage
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
cd $pack2
zip -r9 $product_name-$kernel_type-$codename_device2-$date2.zip * -x .git README.md LICENCE
cd ..
export device="Xiaomi Redmi 4A/5A"
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$product_name $kernel_type new build is available</b>!" \
	       "<b>Device :</b> <code>$device</code>" \
	       "<b>Branch :</b> <code>$parse_branch</code>" \
               "<b>Toolchain :</b> <code>$toolchain_ver</code>" \
	       "<b>Latest commit :</b> $commit_point"
curl -F document=@$(echo $pack1/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack2/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
