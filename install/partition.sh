#!/bin/sh

#
# choose partitions for / and swap.
# save info into a file called "config"
#
# elcuco <cuco3001@yahoo.com> 
#

DIALOG=dialog
backtitle="Choose partititons on which you want to install PCLinuxOS"

rootfs=/dev/hda1
swapfs=/dev/hda5

ask_exit()
{
	"$DIALOG" --clear --backtitle "$backtitle" \
	--yesno "Really quit?" 10 30
	
	case $? in
	0)
		break
		;;
	1)
		returncode=99
		;;
	esac
}

edit_partitions()
{
	CMD=$("$DIALOG" --clear --backtitle "$backtitle" \
	--radiolist "Choose which program do you want to use for editing the partitions"  14 60 5 \
	"fdisk"  "Good old CLI"                off \
	"cfdsik" "Nice intuetive alternative"  ON  \
	"qprted" "Advanced command line"       off \
	"None"   "Return to previous menu"     off \
	"Other"  "Specify the command to run"  off \
	2>&1 1>&3
	)
	
	if [ $CMD == "None" ]; then
		return
	fi
	
	#$DIALOG --clear --backtitle "$backtitle" --msgbox "executing $CMD" 10 40
	$CMD
	
}

save_config()
{
	echo install_type.sh> next_item
	echo $value 
	rm -f config
	
	echo "###########################" >> config
	echo "# partitions"                >> config  
	left=1
	
	for i in $value; do
		if [ $left == 1 ]; then
			echo "root_fs=$i" >> config
		else
			echo "swap_fs=$i" >> config
		fi
		
		left=`expr $left + 1`
	done
	echo " " >> config     
}


# main code

returncode=0
while test $returncode != 1 && test $returncode != 250
do

	# this is the main dialog design
	exec 3>&1
	value=$($DIALOG --backtitle "$backtitle" \
	--ok-label "Next" --help-button --help-label "Edit partitions" \
	--form "Choose partitions"  13 60 0 \
	"root"      2 1 "$rootfs"  2 7 40 0 \
	"swap"      3 1 "$swapfs"  3 7 40 0 \
	2>&1 1>&3)
	
	retval=$?
	
	# here we check the result
	case $retval in 
	0) 
		save_config
		returncode=1
	;;
	1) 
		rm -f next_item
		ask_exit
	;;
	
	2)
		edit_partitions
	;;
	esac

done


