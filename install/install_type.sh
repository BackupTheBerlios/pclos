#!/bin/sh

dialog --ok-label "Next" --backtitle "Choose which installation type of PCLinuxOS do you want" \
--radiolist "Choose which type of installation do you want to do"  20 100 5 \
"Modern Linux Desktop" "Install a modern PCLinuxOS desktop with KDE, and all the goodies"  ON \
"Good old X"           "Install X, but use console applications, like mutt, vim, link"    OFF \
"Good old console"     "If you dont like GUIs, or just want a server, choose this one"   OFF\



echo do_main_install.sh> next_item
