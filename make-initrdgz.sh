#!/bin/bash
#
# This script is used to put modified 'preseed.cfg' under initrd/ and zip it
# as the new 'initrd.gz'. This process will be executed frequently.
#
# Mare sure that:
#    pwd: /var/lib/tftpboot/ubuntu-installer/amd64
#
#    If it's the first time executing this script, there must be an original
#    'initrd.gz' and no file named 'initrd.img' under pwd.
#    
#    This script should be run as root.
#
# Author: Yu Zenghui (zenghuiyu96@gmail.com)
#

INITRDIMG="initrd.img"

if [ ! -f "$INITRDIMG" ]; then
    # The first time to execute this script.
    echo "The first time!"
    echo "gunzip..."
    gunzip initrd.gz
    echo "    done"
    mv initrd initrd.img
    mkdir initrd
    cd initrd
    cpio -id < ../initrd.img
else
    echo "Not the first time!"
    rm initrd.gz
    cd initrd
fi

cp ../preseed.cfg .
echo "gzip..."
find . | cpio -o -H newc | gzip -9 > ../initrd.gz
echo "    done"
cd ..
chmod 555 initrd.gz
