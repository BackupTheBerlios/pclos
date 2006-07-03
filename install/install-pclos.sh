#!/bin/sh

# elcuco, elcuco@kdemail.net
#
# license, public domain :)

# history:
# 2006-04-23		    Re-ordered sections, minor updates, etjr changes 
# 2006-04-17		    Better network - thanks to etjr
#			    Make partition bootable with lilo
# 2006-04-15		    Resynchronize with PCLOS
# 1-7-2005                  Changelog reordered (newer at top) (diego)
#                           Config file can be renamed (no command line yet) (diego)
#                           Config files are saved on clean (diego)
#                           New mode: read only config files
#                           Removed Iglu from mirrors list
# 2005-06-22                Updates: kernel, use squashfs, update ibiblio, mklivecd 
# 10-6-2004                 config for making a livecd is saved in the config, Tom Kelly
#                           config file name can be changed
# 10-5-2004                 grammar fixes by Tom Kelly, + fix bug (rpm backups)
#                           root check available again, Tom Kelly
#                           option in config to change the repository (thanks etjr)
#                           by default install basesystem and apt
#                           function for making a bootable livecd
# 10-4-2004                 rpm backup is back :)
#                           save config into a file
#                           tmp dir is always deleted
# 10-03-2004                almost rewrite... i now use functions :)
#                           all config files are saved in a temp dir
#                           more flexible options (delete before, delete after... )   
#                           added a larger set of repositories to install from
# 9-19-2004                 public domain license, 
#                           split apt install
#                           added root check (thanks tom!)
# 9-18-2003 fourth version,  uses ibiblio instead of iglu
#                           backs up rpms for next usage
#                           finally read the faq of mklivecd :)
#                           downloads old verions of mklivecd and installs it
#                           actually boots :)
# 9-13-2004                 rpms are saved locally
#                           made base system tgz
# 9-11-2004 third version,  [cdrecord stuff]
#                           I verified it works by chroot
# 9-10-2004 second version, [apt,vim,mc,dialog]
#                           added minimal network
# 9-9-2004  first version,


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

Dir {
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
# Write default values to the config file
cat >$CONFIG_FILE<<EOF
# This is the auto generated configuration file for the 
# PCLinuxOS mini installer (install-pclos.sh)

# If you want to install PCLinuxOS using this installer, please review 
# the options below and change them here, or in the main script if desired.

# You can run automated installations using this script:
# Before you run this script, edit this file, and set it up with 
# the correct values for your installation.

############### INSTALLER OPTIONS ########################
#### This section explains them				##
#### Manually change in install-pclos.sh below at 	##
#### init_config() 					##
# 
# This variable tells the installer where you want to install PCLinuxOS.
# If you want install to a partition, set it to the directory where you mounted the
# partion which will become the bootable new installation. 
# For example, if you want to install into /dev/hda1 and /dev/hda1 is mounted at
# /mnt/hda1, set this variable to "/mnt/hda1".
# Where do you want the target directory to be?
# Default: a directory called new-pclos beneath this script's directory.
NEW_ROOT=$NEW_ROOT

# Install to a /dev/hdaX partition. This device will be mounted
# at NEW_ROOT && COMPLETELY ERASED!!!! Use caution 
ROOT_DEV=$ROOT_DEV

# Name of the log file to record the operations done by this script?
# Default: install.log
LOG_FILE=$LOG_FILE

# If you want this config to be updated on each run leave it on 0
# If the value is "1" the file will not be modified at all
# Default: 0 (rewrite this config)
READONLY_CONFIG=$READONLY_CONFIG

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

###
# Apt file sources. Usually it will be some online repository.
# For the main installer, it will be somewhere on the cdrom.
#
# Georgia Tech, USA
# APT_REPOSITORY="ftp://ftp-linux.cc.gatech.edu/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 93 os updates texstar"
#
# Netherlands Unix Users Group, Netherlands
# APT_REPOSITORY="http://ftp.nluug.nl/ibiblio/distributions/texstar/pclinuxos/apt/ pclinuxos/2004 93 os updates texstar unstable"
#
# Die Gesellschaft fur wissenschaftliche Datenverarbeitung mbH Gottigen, Germany
# APT_REPOSITORY="ftp://ftp.gwdg.de/pub/linux/mirrors/sunsite/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 93 os updates texstar"
#
# Ibiblio, US and various
# APT_REPOSITORY="http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 93 os updates texstar"
#
APT_REPOSITORY="$APT_REPOSITORY"

### Configuration of LiveCD options  ###########
# This script can also generate a bootable livecd iso file.
# The next part is dedicated to livecd, if the MAKE_LIVECD option is zero,
# The rest of the config file is ignored. See mklivecd or try 
# 'mklivecd --help' for more information.

# Would you like to generate a livecd?
# default: "0" = no
MAKE_LIVECD=$MAKE_LIVECD

# Resolution of the livecd.
# default : 1024x768
LIVECD_RESOLUTION=$LIVECD_RESOLUTION

# Compression type <clp|sqfs|iso> (only sqfs)
# Default : sqfs 
LIVECD_LOOPTYPE=$LIVECD_LOOPTYPE

# Kernel to be used while booting.
# This may be subject to repository dependencies
# old: 2.6.15-oci4.mdk
# current default: 2.6.15-oci4.lve
LIVECD_KERNEL=$LIVECD_KERNEL

# Keyboard to be used in the livecd.
# default : us
LIVECD_KEYBOARD=$LIVECD_KEYBOARD

# Image filename
# default : livecd.iso
LIVECD_NAME=$LIVECD_NAME
EOF
}
##### End of options, the variables are set below and saved to config file

init_config()
{
######################### Load default variables #####################
#### Manually edit here to set the default values
#### This script can "reload" them from the config file by
#### modifying itself. Not recommended.

NEW_ROOT=`pwd`/new-pclos
ROOT_DEV=""
LOG_FILE=make-install.log
CLEAN_BEFORE=1
CLEAN_AFTER=0
USE_BACKUP_RPMS=1
SAVE_RPMS=1
APT_REPOSITORY="http://ftp.nluug.nl/ibiblio/distributions/texstar/pclinuxos/apt/ pclinuxos/2004 93 os updates texstar unstable"

READONLY_CONFIG=1

MAKE_LIVECD=1
LIVECD_RESOLUTION="1024x768"
LIVECD_LOOPTYPE="sqfs"
LIVECD_KERNEL="2.6.15-oci4.lve"
LIVECD_KEYBOARD="us"
LIVECD_NAME="livecd.iso"

if [ ! -e $CONFIG_FILE ]; then
        explain "No config file found. Generating a default one."
        explain "Please review the config file (install.config) before you run this script again"
	explain "In the file you can indicate where to install PCLinuxOS, and other preferences."
        explain "Quiting now..."
        
       	save_config

        exit
fi

## Load and use the config file to replace the
## above default values with the config file values
. $CONFIG_FILE

mkdir -p tmp
rm -f tmp/$LOG_FILE
touch tmp/$LOG_FILE
}


update_apt()
{
explain "Root dev = $ROOT_DEV"
if [ $ROOT_DEV != 0 ]; then
	explain "Mounting $ROOT_DEV at $NEW_ROOT"
	exec_cmd "mount $ROOT_DEV $NEW_ROOT"
fi
if [ $CLEAN_BEFORE != 0 ]; then
	explain "Cleaning \$NEW_ROOT"
	exec_cmd "rm -fr $NEW_ROOT" 
fi

explain "Making some needed dirs for the new root." 
exec_cmd "mkdir -p $NEW_ROOT/var/state/apt/lists/partial"
exec_cmd "mkdir -p $NEW_ROOT/var/lib/rpm"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/archives"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/partial"
exec_cmd "mkdir -p $NEW_ROOT/etc/apt"
exec_cmd "mkdir -p $NEW_ROOT/sys"

explain "Updating apt cache in the new root."
exec_cmd "apt-get -c tmp/new-apt.conf update "

# Reuse rpms, if available from the last install... 
# Copy them to the cache of the new system
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
# Optional editor
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install vim-minimal"

# lets setup for group and shadow passwd
exec_cmd "touch $NEW_ROOT/etc/group"
exec_cmd "touch $NEW_ROOT/etc/shadow"
echo "root::::::::" > $NEW_ROOT/etc/shadow
}


make_fstab()
{
cat >"$NEW_ROOT/etc/fstab"<<EOF
## FSTAB auto-generated from install-pclos.sh script
none    /proc   proc    defaults        0 0
none    /dev/pts        devpts  mode=0620       0 0
none    /proc/bus/usb   usbfs   defaults        0 0

# Self default as root partition (assume ext3)
$ROOT_DEV      /       ext3    defaults        0 0
EOF
}


make_boot()
{
exec_cmd "chroot $NEW_ROOT mkinitrd /boot/initrd-$LIVECD_KERNEL.img $LIVECD_KERNEL"
cat >"$NEW_ROOT/etc/lilo.conf"<<EOF
boot="$ROOT_DEV"
map=/boot/map
default="$LIVECD_KERNEL"
#keytable=/boot/livecd.klt
prompt
nowarn
timeout=100
menu-scheme=wb:bw:wb:bw
image=/boot/vmlinuz-$LIVECD_KERNEL
	initrd=/boot/initrd-$LIVECD_KERNEL.img
        label="$LIVECD_KERNEL"
        root="$ROOT_DEV"
	vga=794
EOF
exec_cmd "chroot $NEW_ROOT lilo -v"
} 


make_network()
### use "dhclient eth0" after boot -- FIX AUTO?
{
# Install network programs
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install dhcp-client dhcp-common locales loca
les-en pump"

# Setup dhcp and networking
exec_cmd "mkdir -p $NEW_ROOT/etc/sysconfig/network-scripts"
exec_cmd "touch $NEW_ROOT/etc/sysconfig/network-scripts/ifcfg-eth0"
chmod 755 $NEW_ROOT/etc/sysconfig/network-scripts/ifcfg-eth0
cat > "$NEW_ROOT/etc/sysconfig/network-scripts/ifcfg-eth0"<<EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
EOF

exec_cmd "touch $NEW_ROOT/etc/sysconfig/network"
echo "NETWORKING=yes" > $NEW_ROOT/etc/sysconfig/network

# Setup resolv.conf
exec_cmd "touch $NEW_ROOT/etc/resolv.conf"
echo "nameserver 127.0.0.1" > $NEW_ROOT/etc/resolv.conf

# Setup for localhost
exec_cmd "touch $NEW_ROOT/etc/hosts"
echo "127.0.0.1 localhost.localdomain localhost" > $NEW_ROOT/etc/hosts

}


auto_nethd()
{
exec_cmd "cp -f $NEW_ROOT/etc/rc.d/rc.local $NEW_ROOT/et/rc.d/rc.local.bak"
cat >"$NEW_ROOT/etc/rc.d/rc.local"<<EOF
touch /var/lock/subsys/local
hwdetect
mv -f /etc/rc.d/rc.local.bak /etc/rc.d/rc.local
mv -f /etc/fstab.hwdetect.save /etc/fstab
EOF

exec_cmd "chroot $NEW_ROOT chkconfig dkms off"
}


make_livecd()
{
if [ $MAKE_LIVECD == 0 ]; then
	return
fi

explain "Creating a livecd! You are lucky!!!"

# some setup for the livecd, not strictly needed, but looks cool :)
# ok, i dont know why i cannot do this with "exec_cmd"
echo "export PS1=\"[\u@pclos-install \W] \$ \"" > $NEW_ROOT/etc/profile.d/newprompt.sh
chmod +x $NEW_ROOT/etc/profile.d/newprompt.sh
# exec_cmd "cp /etc/resolv.conf $NEW_ROOT/etc"

exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install uClibc busybox cdrecord mkisofs squashfs-tools mediacheck"

# since mklivecd is not on the repositories, and it depends on X, which we dont have
# now, we must D/L by hand, and then install by force

exec_cmd "wget http://download.berlios.de/livecd/mklivecd-0.6.0-20060422.1mdk.noarch.rpm"

exec_cmd "rpm -Uhv --root $NEW_ROOT mklivecd*.rpm --nodeps"
exec_cmd "rm -f mklivecd*.rpm"

explain  "Making the LIVECD iso file..."
exec_cmd "mount none $NEW_ROOT/proc -t proc"
exec_cmd "chroot $NEW_ROOT mklivecd --resolution $LIVECD_RESOLUTION --kernel $LIVECD_KERNEL --looptype $LIVECD_LOOPTYPE --keyboard $LIVECD_KEYBOARD $LIVECD_NAME"
exec_cmd "mv $NEW_ROOT/$LIVECD_NAME ."
exec_cmd "umount $NEW_ROOT/proc"

explain "Created $LIVECD_NAME"

}


clean_up()
{
if [ $READONLY_CONFIG == 0 ]; then
        save_config
else
        explain "Warning: Config file is in read-only mode"
        explain "-----------------------------------------"
fi

mv tmp/$LOG_FILE .

# from now on, we cannot use exec_cmd, since it logs,
# and the log file was removed

if [ $SAVE_RPMS != 0 ]; then
        explain "Backing up rpms for next time."
        mkdir -p rpms
        mv -f $NEW_ROOT/var/cache/apt/*.rpm rpms/
	# cp -f $NEW_ROOT/var/cache/apt/*.rpm rpms/
fi

if [ $CLEAN_AFTER != 0 ]; then
        explain "Cleaning \$NEW_ROOT: $NEW_ROOT"
        rm -fr $NEW_ROOT
fi

explain "Cleaning tmp."
rm -fr tmp

}

#################### <-- main --> #########################

# Only root may Run this script.
check_root

# If you want to read another config file, this is the line
# TODO run tim parameter to change this
CONFIG_FILE="pclos.config"

init_config

# At this stage the script is runnning, or it can exit at init_config
make_config_files
update_apt
install_system
make_network
auto_nethd
make_livecd
make_fstab
make_boot
clean_up
explain "All done! The script is finished!"
exit
