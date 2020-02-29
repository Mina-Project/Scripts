#!/usr/bin/env bash
# Circle CI/CD - kernel build script
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r40 gcc
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r40 gcc32
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip1
git clone --depth=1 https://github.com/fadlyas07/AnyKernel3-1 zip2
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token

# Device 1
export codename_device1="rolex"
export config_device1="rolex_defconfig"

# Device 2
export codename_device2="riva"
export config_device2="riva_defconfig"

# Github Env Vars
KERNEL_NAME="GREENFORCE"
KERNEL_DIR="$(pwd)"
UNIFIED="Xiaomi Redmi 4A/5A"
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git log --pretty=format:'<code>%h: %s by</code> <b>%an</b>' -1)"
pack1="$KERNEL_DIR/zip1"
pack2="$KERNEL_DIR/zip2"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"

# create temp dir for kernel log
mkdir $KERNEL_DIR/TEMP
TEMP="$KERNEL_DIR/TEMP"

export ARCH=arm64
export TZ=":Asia/Jakarta"
export KERNEL_TYPE=EaS
export KBUILD_BUILD_USER=github.com.fadlyas07
export KBUILD_BUILD_HOST=$CIRCLE_SHA1

TELEGRAM=telegram/telegram
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_makegcc() {
	make -j$(nproc) O=out \
                ARCH=arm64 \
                CROSS_COMPILE=aarch64-linux-android- \
                CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee kernel.log
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE" \
	-d chat_id="$TELEGRAM_ID"
}
tg_sendinfo() {
    "$TELEGRAM" -c "$fadlyas" -H \
	"$(
		for POST in "$@"; do
			echo "$POST"
		done
	)"
}
tg_pushlog() {
   curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
	-F chat_id="$fadlyas"
}
tg_makedevice1() {
make O=out ARCH=arm64 $config_device1
PATH="$KERNEL_DIR/gcc/bin:$KERNEL_DIR/gcc32/bin:$PATH" \
tg_makegcc
}
tg_makedevice2() {
make O=out ARCH=arm64 $config_device2
PATH="$KERNEL_DIR/gcc/bin:$KERNEL_DIR/gcc32/bin:$PATH" \
tg_makegcc
}

# Make device 1
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice1
mv *.log $TEMP
if [[ ! -f "$KERNEL_IMG" ]]; then
	tg_pushlog
	tg_sendinfo "<b>$KERNEL_NAME $KERNEL_TYPE Build Failed</b>!!"
	exit 1;
fi
tg_pushlog
mv $KERNEL_IMG $pack1/zImage
cd $pack1
zip -r9q $KERNEL_NAME-$codename_device1-$KERNEL_TYPE-$date1.zip * -x .git README.md LICENCE
cd ..

# clean out & log for anticipation dirty build
rm -rf out/ $TEMP/*.log

# Make device 2
date2=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice2
mv *.log $TEMP
if [[ ! -f "$KERNEL_IMG" ]]; then
	tg_pushlog
	tg_sedtemplate
	exit 1;
fi
tg_pushlog
mv $KERNEL_IMG $pack2/zImage
cd $pack2
zip -r9q $KERNEL_NAME-$codename_device2-$KERNEL_TYPE-$date2.zip * -x .git README.md LICENCE
cd ..
toolchain_ver=$(cat $KERNEL_DIR/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "<b>$KERNEL_NAME new build is available</b>!" \
		"<b>Device :</b> <code>$UNIFIED</code>" \
		"<b>Kernel Type :</b> <code>$KERNEL_TYPE</code>" \
		"<b>Branch :</b> <code>$PARSE_BRANCH</code>" \
		"<b>Toolchain :</b> <code>$toolchain_ver</code>" \
		"<b>Latest commit :</b> $COMMIT_POINT"
curl -F document=@$(echo $pack1/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack2/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
