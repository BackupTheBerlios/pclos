#!/bin/bash

rm -f config

menu=welcome.sh
while [ ! "x$menu" == "x" ]; do
    #kdialog --msgbox "running $menu " 60 20
    . $menu

    if [ -e next_item ] ; then
        menu=$(cat next_item)
        rm -f next_item
        touch next_item
    else
	menu=""
    fi
done

rm -f next_item
rm -f config
clear