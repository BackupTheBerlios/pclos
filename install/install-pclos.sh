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
#                           dowmloads old verions of mklivecd and installs it
#                           actually boots :)
# 9-19-2004                 public domain license, 
#                           split apt install
#                           added root check (thanks tom!)
# 10-03-2004                almost rewrite... i now use functions :)
#                           all config files are saved in a temp dir
#                           more flexible options (delete before, delete after... )   
#                           added a lrger set of repositories to instal from
# 10-4-2004                 rpm backup is back :)
#                           save config into a file
#                           tmp dir is always deleted


# some internal used functions...
# look for "main"
exec_cmd() 
{
echo -en "\\033[1;31m"
echo $1
echo -en "\\033[0;39m"

echo "> $1 " >>  $LOG_FILE
$1      &>  $LOG_FILE.tmp

cat $LOG_FILE.tmp >> $LOG_FILE
rm -f $LOG_FILE.tmp
echo    >>  $LOG_FILE
}

explain()
{
echo -en "\\033[1;34m"
echo "*** $1"
echo -en "\\033[0;39m"
}


make_config_files()
{
explain "Making new config files for apt "
cat >tmp/new-apt-sources.list<<EOF
#PCLINUXOS apt repository
#rpm ftp://ftp-linux.cc.gatech.edu/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm ftp://ftp.nluug.nl/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm ftp://ftp.gwdg.de/pub/linux/mirrors/sunsite/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/                          pclinuxos/2004 os updates texstar 

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
# This is the configuration for the PCLinuxOS installer
# If you want to install PCLinuxOS using this installer, please edit the variables bellow

# You can run automated installations using this script:
# Before you run this script, just wite this file, and set it up with correct values for your
# installation type



# This variable tell the installer where you want to install PCLinuxOS to.
# If you want to install PCLinuxOS, set it to the directory in which you mounted the
# new root device. 
# For example, if you want to install into /dev/hda1 and /dev/hda1 is mount into
# /mnt/hda1, set this variable to "/mnt/hda1"
# Default: is is a direcoty called new-pclos under the directory of this script.
NEW_ROOT=$NEW_ROOT


# The log file to be used. Each operation done by this script will be recorded there.
LOG_FILE=$LOG_FILE


# Clean the target dir before?
# Default: "1"
CLEAN_BEFORE=$CLEAN_BEFORE


# Clean the target dir after?
# Default: "0"
CLEAN_AFTER=$CLEAN_AFTER


# This script is smart enough to back up the RPMs downloaded by apt-get. 
# This way, if you are testing the script, you will probably run it several times.
# Downloading is a pain, this hack takes care of this. The next time you run it, the install
# will be faster :)
# Would you like to use the RPMs from the last session?
# Default: "1"
USE_BACKUP_RPMS=1


# Would you like to save the RPMs from next session?
# Default: "1"
SAVE_RPMS=1
EOF
}


init_config()
{
NEW_ROOT=`pwd`/new-pclos
LOG_FILE=tmp/make-install.log
CLEAN_BEFORE=1
CLEAN_AFTER=0

USE_BACKUP_RPMS=1
SAVE_RPMS=1

if [ ! -e install.config ]; then
	explain "No config found. Generating a default one."
	explain "You need to edit the config file (install.config) before you run this script again"
	explain "In that script you can setup where to install PCLinuxOS into."
	explain "Quiting now..."
	
	save_config
	
	exit
fi

# this will load the user config, if he forgor something,
# the deault values will be used
. install.config

mkdir -p tmp
rm -f $LOG_FILE
touch $LOG_FILE
}


clean_up()
{
mv $LOG_FILE .

# from now on, we cannot use exec_cmd, since it logs, 
# and the log file was removed

if [ $SAVE_RPMS != 0 ]; then
	explain "Backing up rpms for next time!"
	cp -f $NEW_ROOT/var/cache/apt/*.rpm rpms/
fi

if [ $CLEAN_AFTER != 0 ]; then
	explain "Cleaning \$NEW_ROOT: $NEW_ROOT"
	rm -fr $NEW_ROOT
fi

explain "Cleaning tmp"
rm -fr tmp

save_config
}

update_apt()
{
if [ $CLEAN_BEFORE != 0 ]; then
explain "Cleaning \$NEW_ROOT"
exec_cmd "rm -fr $NEW_ROOT" 
fi

explain "Making some needed dirs for the new root"$LOG_FILE.tmp
exec_cmd "mkdir -p $NEW_ROOT/var/state/apt/lists/partial"
exec_cmd "mkdir -p $NEW_ROOT/var/lib/rpm"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/archives"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/partial"
exec_cmd "mkdir -p $NEW_ROOT/etc/apt"

explain "updating apt cache in the new root"
exec_cmd "apt-get -c tmp/new-apt.conf update "

# now. this is a little hack... 
# if there are some rpms available from the last install... copy them to the cache of the new system
if [ $USE_BACKUP_RPMS != 0 ]; then
	explain "restoring backup rpms"
	cp -r rpms/*.rpm  $NEW_ROOT/var/cache/apt/
fi

}

install_system()
{
explain "installing basesystem on the new root"
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install basesystem"
explain "done!"
}


# <-- main -->

init_config
make_config_files
update_apt
install_system
clean_up
