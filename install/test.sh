#! /bin/sh
# $Id: test.sh,v 1.1 2004/10/04 20:03:24 elcuco Exp $
DIALOG=dialog

rootfs=/dev/hda1
swapfs=/dev/hda5

returncode=0
exec 3>&1
value="`$DIALOG  \
--ok-label "Next" --backtitle "Choose partititons on which you want to install PCLinuxOS" \
--backtitle "An Example for the use of --form:" \
--form "Choose partitions"  20 60 0 \
"root"      3 1 "$rootfs"  3 10 40 0 \
"swap"      4 1 "$swapfs"  4 10 40 0 \
2>&1 1>&3`"


returncode=$?
exec 3>&-

show=`echo "$value" |sed -e 's/^/       /'`

