#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
     export device="Xiaomi Redmi 4A/5A"
     export codename_device1=rolex
     export config_device1=rolex_defconfig
     export codename_device2=riva
     export config_device2=riva_defconfig
mkdir $(pwd)/TEMP
     mkdir -p $(pwd)/clang
     wget https://kdrag0n.dev/files/redirector/proton_clang-latest.tar.zst
     tar -I zstd -xvf *.tar.zst -C $(pwd)/clang --strip-components=1
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip1
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip2
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
export pack1=$(pwd)/zip1
export pack2=$(pwd)/zip2

# Telegram & Github Env Vars
export ARCH=arm64
export TZ=Asia/Jakarta
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
make_kernel() {
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1| tee kernel.log
}
tg_makedevice1() {
make -j$(nproc) O=out ARCH=arm64 $config_device1
make_kernel
}
tg_makedevice2() {
make -j$(nproc) O=out ARCH=arm64 $config_device2
make_kernel
}
tg_sendinfo() {
  curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
       -d chat_id="784548477" \
       -d "parse_mode=markdown" \
       -d "disable_web_page_preview=true" \
       -d text="$1"
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAADBQADPwEAAn1Cwy4LGnCzWtePdRYE" \
	-d chat_id="$TELEGRAM_ID"
}
export PATH=$(pwd)/clang/bin:$PATH
export LD_LIBRARY_PATH=$(pwd)/clang/lib:$LD_LIBRARY_PATH
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice1
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
        curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$fadlyas"
	tg_sendinfo "$product_name $device Build Failed!!"
	exit 1;
else
        mv $kernel_img $pack1/zImage
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
cd $pack1
zip -r9q $product_name-$codename_device1-$date1.zip * -x .git README.md LICENCE
cd ..
rm -rf out/ $TEMP/*.log
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice2
mv *.log $TEMP
if [[ ! -f "$kernel_img" ]]; then
        curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$fadlyas"
	tg_sendinfo "$product_name $device Build Failed!!"
	exit 1;
else
        mv $kernel_img $pack2/zImage
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
cd $pack2
zip -r9q $product_name-$codename_device2-$date2.zip * -x .git README.md LICENCE
cd ..
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$product_name new build is available</b>!" \
	       "<b>Device :</b> <code>$device</code>" \
	       "<b>Branch :</b> <code>$parse_branch</code>" \
               "<b>Toolchain :</b> <code>$toolchain_ver</code>" \
	       "<b>Latest commit :</b> $commit_point"
curl -F document=@$(echo $pack1/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack2/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
