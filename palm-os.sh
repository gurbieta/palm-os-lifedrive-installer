#! /bin/bash

PALM_DIR=$(pwd)
WORK_DIR="/tmp/palm-os"
BRAHMA_FILE_SIZE=20479778
BRAHMA_MD5="242847c981475636f7b74c7ba9a40379"
ROM_MD5="639952c7a50e8d12d1d9351f3cbe9aa6"

rm -rf $WORK_DIR
mkdir $WORK_DIR

cp LifeDrive_Update_2_0_win.zip $WORK_DIR/

cd $WORK_DIR
unzip LifeDrive_Update_2_0_win.zip
cabextract 'LifeDrive 2.0 Updater.exe'

mkdir data
cd data
unshield x ../Disk1/data1.cab 

cd BrahmaUpdate
cp $PALM_DIR/unpdb.py .
ls brahma-palmos.zip.?.pdb | sort | xargs -ti python unpdb.py {} - | dd skip=1 bs=32 > brahma-palmos.zip

FILE_SIZE=$(du -b brahma-palmos.zip | awk '{print $1}')

if [ $FILE_SIZE = $BRAHMA_FILE_SIZE ]; then
	echo "Brahma file size [$FILE_SIZE]... OK"
else
	echo "Brahma file size incorrect [$FILE_SIZE], required [$BRAHMA_FILE_SIZE]"
	exit 1
fi

MD5=$(md5sum brahma-palmos.zip | awk '{print $1}')

if [ $FILE_SIZE = $BRAHMA_FILE_SIZE ]; then
	echo "Brahma MD5 [$MD5]... OK"
else
	echo "Brahma MD5 incorrect [$MD5], required [$BRAHMA_MD5]"
	exit 1
fi

unzip -l brahma-palmos.zip

cp $PALM_DIR/makecafe.py .

python makecafe.py -c brahma-palmos.zip > rom-partition

MD5=$(md5sum rom-partition | awk '{print $1}')

if [ $MD5 = $ROM_MD5 ]; then
	echo "ROM MD5 [$MD5]... OK"
else
	echo "ROM MD5 incorrect [$MD5], required [$ROM_MD5]"
	exit 1
fi

# Creates expected partition table for PalmOS
echo 'AAAAAAAAAAAAAAAAAAAAAQEABlgPCD8AAACACwIAAFgQCAAoHAu/CwIAgLAAAAAoHQsLz13xP7wCAIBLdwAAAAAAAAAAAAAAAAAAAAAAVao=' | python -c 'import base64,sys;sys.stdout.write("\0"*432+base64.b64decode(sys.stdin.read()))' > table.sct

echo "Enter device name (eg: sdb1 for /dev/sdb1):"
read DEVICE

# Writes partition table to the device
sudo dd if=table.sct of=/dev/$DEVICE conv=notrunc

# Writes ROM to the device
sudo dd if=rom-partition of=/dev/$DEVICE seek=134079 bs=512

echo "********** PalmOS successfully installed **********"
