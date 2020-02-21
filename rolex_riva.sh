#!/usr/bin/env bash
# Circle CI/CD - kernel build script
# Support for Xiaomi Redmi 4A & Xiaomi Redmi 5A
git clone -q -j32 https://github.com/fadlyas07/AnyKernel3-1 --depth=1 zip1
git clone -q -j32 https://github.com/fadlyas07/AnyKernel3-1 --depth=1 zip2
git clone -q -j32 https://github.com/fabianonline/telegram.sh --depth=1 telegram
TELEGRAM_ID=$chat_id
TELEGRAM_TOKEN=$token
export TELEGRAM_TOKEN TELEGRAM_ID

# Device 1
codename_device1="rolex"
config_device1="rolex_defconfig"

# Device 2
codename_device2="riva"
config_device2="riva_defconfig"

# Github Env Vars
KERNEL_NAME="GREENFORCE"
KERNEL_DIR="$(pwd)"
UNIFIED="Xiaomi Redmi 4A/5A"
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git log --pretty=format:'<code>%h: %s by</code> <b>%an</b>' -1)"
TOOLCHAIN_DIR="/root/toolchain"
TOOLCHAIN_DIRNAME="clang"
pack1="$KERNEL_DIR/zip1"
pack2="$KERNEL_DIR/zip2"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"

# Find kernel branch
if [ "$PARSE_BRANCH" == "HMP-vdso32" ]; then
	KERNEL_TYPE=HmP
	export $KERNEL_TYPE
	STICKER="CAADBQADeQEAAn1Cwy71MK7Ir5t0PhYE"
	export $STICKER
elif [ "$PARSE_BRANCH" == "EAS" ]; then
	KERNEL_TYPE=EaS
	export $KERNEL_TYPE
	STICKER="CAADBQADIwEAAn1Cwy5pf2It72fNXBYE"
	export $STICKER
elif [ "$PARSE_BRANCH" == "aosp/android-3.18" ]; then
	KERNEL_TYPE=Pure-CaF
	export $KERNEL_TYPE
	STICKER="CAADBQADfAEAAn1Cwy6aGpFrL8EcbRYE"
	export $STICKER
elif [ ! "$KERNEL_TYPE" ]; then
	KERNEL_TYPE=Test
	export $KERNEL_TYPE
	STICKER="CAADBQADPwEAAn1Cwy4LGnCzWtePdRYE"
	export $STICKER
fi

# create temp dir for kernel log
mkdir $KERNEL_DIR/TEMP
TEMP="$KERNEL_DIR/TEMP"

export STICKER
export KERNEL_TYPE
export ARCH=arm64
export TZ=":Asia/Jakarta"
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
tg_sedtemplate() {
tg_channelcast "<b>$KERNEL_NAME $KERNEL_TYPE Build Failed</b>!!"
}
tg_makeclang() {
	make -j$(nproc) O=out \
			ARCH=arm64 \
			CC=clang \
			CLANG_TRIPLE=aarch64-linux-gnu- \
			CROSS_COMPILE=aarch64-linux-android- \
			CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee kernel.log
}
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="$STICKER" \
	-d chat_id="$TELEGRAM_ID"
}
tg_pushlog() {
	curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
	-F chat_id="$fadlyas"
}
tg_makedevice1() {
make -j$(nproc) O=out ARCH=arm64 $config_device1
PATH="$TOOLCHAIN_DIR/$TOOLCHAIN_DIRNAME/bin:$TOOLCHAIN_DIR/gcc/bin:$TOOLCHAIN_DIR/gcc32/bin:$PATH" \
tg_makeclang
}
tg_makedevice2() {
make -j$(nproc) O=out ARCH=arm64 $config_device2
PATH="$TOOLCHAIN_DIR/$TOOLCHAIN_DIRNAME/bin:$TOOLCHAIN_DIR/gcc/bin:$TOOLCHAIN_DIR/gcc32/bin:$PATH" \
tg_makeclang
}

# Make device 1
date1=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
tg_makedevice1
mv *.log $TEMP
if [[ ! -f "$KERNEL_IMG" ]]; then
	tg_pushlog
	tg_sedtemplate
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
tg_channelcast 	"<b>$KERNEL_NAME new build is available</b>!" \
		"<b>Device :</b> <code>$UNIFIED</code>" \
		"<b>Kernel Type :</b> <code>$KERNEL_TYPE</code>" \
		"<b>Branch :</b> <code>$PARSE_BRANCH</code>" \
		"<b>Toolchain :</b> <code>$toolchain_ver</code>" \
		"<b>Latest commit :</b> $COMMIT_POINT"
curl -F document=@$(echo $pack1/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -F document=@$(echo $pack2/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" -d sticker="CAACAgQAAxkBAAEUuSReR6voi-DDaqP6FoqEG-pfBdeO9gACnjgAAjGNRgABOsdMK2pVZ7kYBA" -d chat_id="$TELEGRAM_ID"
