#!/bin/sh

# elcuco, elcuco@kdemail.net
#
# license, public domain :)

# history:
# 9-9-2004  first version,
# 9-10-2004 second version, [apt,vim,mc,dialog]
#                           added minimal network
# 9-11-2004 third version,  [cdrecord stuff]
#                           I verified it works by chroot
# 9-13-2004                 rpms are saved locally
#                           made base system tgz
# 9-18-2003 forth version,  uses ibiblio instead of iglu
#                           backs up rpms for next usage
#                           finally read the faq of mklivecd :)
#                           downloads old verions of mklivecd and installs it
#                           actually boots :)
# 9-19-2004                 public domain license, 
#                           split apt install
#                           added root check (thanks tom!)
# 10-03-2004                almost rewrite... i now use functions :)
#                           all config files are saved in a temp dir
#                           more flexible options (delete before, delete after... )   
#                           added a larger set of repositories to install from
# 10-4-2004                 rpm backup is back :)
#                           save config into a file
#                           tmp dir is always deleted
# 10-5-2004                 grammar fixes by Tom Kelly, + fix bug (rpm backups)
#                           root check available again, Tom Kelly
#                           option in config to change the repository (thanks etjr)
#                           by default install basesystem and apt
#                           function for making a bootable livecd
# 10-6-2004                 config for making a livecd is saved in the config, Tom Kelly
#                           config file name can be changed



# some internal used functions...
# look for "main"

check_root() 
{
if [ $UID != 0 ]; then
	explain "This script must be run as root."
	exit
fi
}

exec_cmd() 
{
	echo -en "\\033[1;31m"
	echo $1
	echo -en "\\033[0;39m"
	
	echo "> $1 " >>  tmp/$LOG_FILE
	$1      &>  tmp/$LOG_FILE.tmp
	
	cat tmp/$LOG_FILE.tmp >> tmp/$LOG_FILE
	rm -f tmp/$LOG_FILE.tmp
	echo    >>  tmp/$LOG_FILE
}

explain()
{
	echo -en "\\033[1;34m"
	echo "*** $1"
	echo -en "\\033[0;39m"
}


make_config_files()
{
explain "Making new config files for apt."
cat >tmp/new-apt-sources.list<<EOF
#PCLINUXOS apt repository
rpm $APT_REPOSITORY

EOF


cat >tmp/new-apt.conf<<EOF
APT {
    Clean-Installed "false";
    Get {
        Assume-Yes "true";
        Download-Only "false";
        Show-Upgraded "true";
        Fix-Broken "false";
        Ignore-Missing "false";
        Compile "false";
    };
};

Acquire {
    Retries "0";
    Http {
        Proxy ""; // http://user:pass@host:port/
    }
};

RPM {
    Ignore { };
    Hold { };    Allow-Duplicated { "^kernel$"; "^kernel-"; "^gpg-pubkey$" };
    Options { };
    Install-Options "";
    Erase-Options "";
    Source {
        Build-Command "rpmbuild --rebuild";
    };
    RootDir "$NEW_ROOT";
};

Dir{
   State "$NEW_ROOT/var/state/apt/";
   
   Etc{
       SourceList "`pwd`/tmp/new-apt-sources.list";       
   }
   Cache{
        archives "$NEW_ROOT/var/cache/apt/";
   }
}
EOF
}

save_config()
{
cat >install.config<<EOF
# This is the configuration file for the PCLinuxOS installer.
# If you want to install PCLinuxOS using this installer, please review the options below
# and change them if desired.

# You can run automated installations using this script:
# Before you run this script, just write this file, and set it up with the correct values for your
# installation type.



# This variable tells the installer where you want to install PCLinuxOS.
# If you want install to a partition, set it to the directory where you mounted the
# partion which will become the new root device. 
# For example, if you want to install into /dev/hda1 and /dev/hda1 is mounted at
# /mnt/hda1, set this variable to "/mnt/hda1".
# Default: a directory called new-pclos beneath this script's directory.
NEW_ROOT=$NEW_ROOT


# The log file to be used. Each operation done by this script will be recorded there.
LOG_FILE=$LOG_FILE


# Clean the target dir before?
# Default: "1" = yes
CLEAN_BEFORE=$CLEAN_BEFORE


# Clean the target dir after?
# Default: "0" = no
CLEAN_AFTER=$CLEAN_AFTER


# This script is smart enough to back up the RPMs downloaded by apt-get. 
# If you are testing the script, you will probably run it several times.
# Downloading is a pain, this hack takes care of this, by backing up the RPMS
# and reusing them. Thus, the next time you run it, the install will be faster :)
# Would you like to use the RPMs from the last session?
# Default: "1" = yes
USE_BACKUP_RPMS=$USE_BACKUP_RPMS


# Would you like to save the RPMs for the next session?
# Default: "1" = yes
SAVE_RPMS=$SAVE_RPMS

# File sources. Usually it will be some online repository.
# For the main installer, it will be somewhere on the cdrom.
#
# Some examples:
# "ftp://ftp-linux.cc.gatech.edu/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
# "ftp://ftp.nluug.nl/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
# "ftp://ftp.gwdg.de/pub/linux/mirrors/sunsite/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
# "http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
# "http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
#
# default: "http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"
APT_REPOSITORY="$APT_REPOSITORY"

# The next part is dedicated to livecd, if the MAKE_LIVECD option is zero, this part of the config is ignored
# See mklivecd or try 'mklivecd --help' for more information.

# This script can also generate a bootable livecd iso file (livecd.iso).
# Would you like to generate a livecd?
# default: "0" = no
MAKE_LIVECD=$MAKE_LIVECD

# Resolution of the livecd.
# default : 800x600
LIVECD_RESOLUTION=$LIVECD_RESOLUTION

# Compression type <clp|sqfs|iso>
# Default : clp
LIVECD_LOOPTYPE=$LIVECD_LOOPTYPE

# Kernel to be used while booting.
# default : 2.4.22-32tex
LIVECD_KERNEL=$LIVECD_KERNEL

# Keyboard to be used in the livecd.
# default : us
LIVECD_KEYBOARD=$LIVECD_KEYBOARD

# Image filename
# default : livecd.iso
LIVECD_NAME=$LIVECD_NAME
EOF
}


init_config()
{
NEW_ROOT=`pwd`/new-pclos
LOG_FILE=make-install.log
CLEAN_BEFORE=1
CLEAN_AFTER=0
USE_BACKUP_RPMS=1
SAVE_RPMS=1
APT_REPOSITORY="http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar"

MAKE_LIVECD=0
LIVECD_RESOLUTION="800x600"
LIVECD_LOOPTYPE="clp"
LIVECD_KERNEL="2.4.22-32tex"
LIVECD_KEYBOARD="us"
LIVECD_NAME="livecd.iso"

if [ ! -e install.config ]; then
        explain "No config file found. Generating a default one."
        explain "Please review the config file (install.config) before you run this script again"
	explain "In the file you can indicate where to install PCLinuxOS, and other preferences."
        explain "Quiting now..."
        
        save_config
        
        exit
fi

# this will load the user config, if he forgot something,
# the default values will be used
. install.config

mkdir -p tmp
rm -f tmp/$LOG_FILE
touch tmp/$LOG_FILE
}


clean_up()
{
mv tmp/$LOG_FILE .

# from now on, we cannot use exec_cmd, since it logs, 
# and the log file was removed

if [ $SAVE_RPMS != 0 ]; then
        explain "Backing up rpms for next time."
        mkdir -p rpms
        cp -f $NEW_ROOT/var/cache/apt/*.rpm rpms/
fi

if [ $CLEAN_AFTER != 0 ]; then
        explain "Cleaning \$NEW_ROOT: $NEW_ROOT"
        rm -fr $NEW_ROOT
fi

explain "Cleaning tmp."
rm -fr tmp

save_config
}

update_apt()
{
if [ $CLEAN_BEFORE != 0 ]; then
explain "Cleaning \$NEW_ROOT"
exec_cmd "rm -fr $NEW_ROOT" 
fi

explain "Making some needed dirs for the new root " 
exec_cmd "mkdir -p $NEW_ROOT/var/state/apt/lists/partial"
exec_cmd "mkdir -p $NEW_ROOT/var/lib/rpm"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/archives"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/partial"
exec_cmd "mkdir -p $NEW_ROOT/etc/apt"

explain "Updating apt cache in the new root."
exec_cmd "apt-get -c tmp/new-apt.conf update "

# now. this is a little hack... 
# if there are some rpms available from the last install... copy them to the cache of the new system
if [ $USE_BACKUP_RPMS != 0 ]; then
        explain "Restoring backup rpms."
        cp -r rpms/*.rpm  $NEW_ROOT/var/cache/apt/
fi

}

install_system()
{
explain "Installing basesystem on the new root."
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install basesystem"
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install apt"
}

make_livecd()
{
if [ $MAKE_LIVECD == 0 ]; then
	return
fi

explain "Creating a livecd! You are lucky!!!"

# some setup for the livecd, not striclty needed, but looks cool :)
# ok, i dont know why i cannot do this with "exec_cmd"
echo "export PS1=\"[\u@pclos-install \W] \$ \"" > $NEW_ROOT/etc/profile.d/newprompt.sh
chmod +x $NEW_ROOT/etc/profile.d/newprompt.sh
exec_cmd "cp /etc/resolv.conf $NEW_ROOT/etc"


exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install uClibc busybox cdrecord mkisofs cloop-utils"

# since mklivecd is not on the repositories, and it depends on X, which we dont have
# now, we must D/L by hand, and then install by force
#exec_cmd "wget http://download.berlios.de/livecd/mklivecd-0.5.7-0.cvs.20031118.1mdk.noarch.rpm"
exec_cmd "wget http://download.berlios.de/livecd/mklivecd-0.5.8-1mdk.noarch.rpm"
exec_cmd "rpm -Uhv --root $NEW_ROOT mklivecd*.rpm --nodeps"
exec_cmd "rm -f mklivecd*.rpm"

explain  "Making the LIVECD iso file..."
exec_cmd "mount none $NEW_ROOT/proc -t proc"
exec_cmd "chroot $NEW_ROOT mklivecd --resolution $LIVECD_RESOLUTION --kernel $LIVECD_KERNEL --looptype $LIVECD_LOOPTYPE --keyboard $LIVECD_KEYBOARD $LIVECD_NAME"
exec_cmd "mv $NEW_ROOT/$LIVECD_NAME ."
exec_cmd "umount $NEW_ROOT/proc"

explain "Created $LIVECD_NAME"

}

# <-- main -->

# run this script only as root
check_root
init_config

# at this stage the script is runnning, ir can exit at init_config
make_config_files
update_apt
install_system
make_livecd
clean_up
explain "All done! The script is finished!"
