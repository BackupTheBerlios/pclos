#! /bin/sh -i

rootfs=/dev/hda1
swapfs=/dev/hda5

returncode=0
DIALOG=dialog
exec 3>&1
value="`$DIALOG  \
--ok-label "Next" --backtitle "Choose partititons on which you want to install PCLinuxOS" \
--form "Choose partitions"  20 60 0 \
"root"      3 1 "$rootfs"  3 10 40 0 \
"swap"      4 1 "$swapfs"  4 10 40 0 \
2>&1 1>&3`"

retval=$?
case $retval in 
0) echo install_type.sh> next_item;;
1) rm -f next_item;;
esac


exit

dialog \
--ok-label "Next" --backtitle "Choose partititons on which you want to install PCLinuxOS" \
--form "Choose partitions"  20 60 0 \
"root"      3 1 "$rootfs"  3 10 40 0 \
"swap"      4 1 "$swapfs"  4 10 40 0 \

retval=$?

case $retval in 
0) echo install_type.sh> next_item;;
1) rm -f next_item;;
esac
