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

LOG_FILE=make-install.log
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
echo "              *** $1"
echo -en "\\033[0;39m"


#echo $1 >> $LOG_FILE
#echo    >> $LOG_FILE
}


if [ $UID != 0 ]; then
  explain "This script must be run as root"
  exit
fi

NEW_ROOT=`pwd`/new-pclos

rm -f $LOG_FILE
touch $LOG_FILE

explain "Cleaning \$NEW_ROOT"
exec_cmd "rm -fr $NEW_ROOT" 

explain "Making some needed dirs for the new root"$LOG_FILE.tmp
exec_cmd "mkdir -p $NEW_ROOT/var/state/apt/lists/partial"
exec_cmd "mkdir -p $NEW_ROOT/var/lib/rpm"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/archives"
exec_cmd "mkdir -p $NEW_ROOT/var/cache/apt/partial"
exec_cmd "mkdir -p $NEW_ROOT/etc/apt"

explain "Copying rpms frpm a back up dir :) "
exec_cmd "cp -r rpms/*.rpm  $NEW_ROOT/var/cache/apt/"


explain "Making new config files for apt "
cat >new-apt-sources.list<<EOF
rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar 
#rpm http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/ pclinuxos/2004 stable os updates
EOF

#rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar stable
#rpm http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/ pclinuxos/2004 stable os updates



cat >new-apt.conf<<EOF
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
       SourceList "`pwd`/new-apt-sources.list";       
   }
   Cache{
        archives "$NEW_ROOT/var/cache/apt/";
   }
}
EOF

cat >$NEW_ROOT/etc/apt/rpmpriorities<<EOF
Essential:
  apt
  basesystem
  bash
  dev
  e2fsprogs
  filesystem
  glibc
  initscripts
  kernel
  modutils
  mount
  pam
  passwd
  pclinuxos-release
  rpm
  setup
EOF

#some hacks for making apt more quiet
export LC_ALL=C

explain "updating apt cache in the new root"
exec_cmd "apt-get -c new-apt.conf update "

explain "installing basesystem on the new root"
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install basesystem devfsd mingetty"

# lets remove the old $NEW_ROOT/etc/apt/rpmpriorities
exec_cmd "rm -f $NEW_ROOT/etc/apt/rpmpriorities"


# six, install apt-get. Need to do it like this, since the OpenOffice package has some bugs
explain "installing apt on the new root"
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install libgcc1 libreadline4 libstdc++5"
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install apt"


# lets backup the base system 
#exec_cmd "rm -fr $NEW_ROOT/var/cache/apt/*.rpm"

#pushd `pwd`
#cd $NEW_ROOT
#tar cvf - . | bzip2 -f > "../pclinuxos-base.tar.bz2"
#popd


# lets make the system ready for the installer
#exec_cmd "cp -r rpms/*.rpm  $NEW_ROOT/var/cache/apt/"

explain "Preparing new system for mklivecd"
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install vim-minimal mc dialog"

# mklivecd shit
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install cdrecord mkisofs cloop-utils"
exec_cmd "apt-get -c new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install uClibc busybox "

explain  "getting and installing mklivecd from berlios"
exec_cmd "wget http://download.berlios.de/livecd/mklivecd-0.5.7-0.cvs.20031118.1mdk.noarch.rpm"
exec_cmd "rpm -Uhv --root $NEW_ROOT mklivecd*.rpm --nodeps"

explain  "mounting procfs on the new target"
exec_cmd "mount none $NEW_ROOT/proc -t proc"

explain "New config files for installer"
echo "export PS1=\"[\u@pclos-install \W] \$ \"" > $NEW_ROOT/etc/profile.d/newprompt.sh
chmod +x $NEW_ROOT/etc/profile.d/newprompt.sh
exec_cmd "cp /etc/resolv.conf $NEW_ROOT/etc"

exec_cmd "chroot $NEW_ROOT /usr/sbin/pwconv"
exec_cmd "chroot $NEW_ROOT \"echo 'root' | passwd --stdin root\""

explain "Making installer ISO"
exec_cmd "chroot $NEW_ROOT mklivecd --resolution 800x600 --kernel 2.4.22-32tex livecd.iso --looptype cloop"
exec_cmd "mv $NEW_ROOT/livecd.iso ."
exec_cmd "umount $NEW_ROOT/proc"

explain "Backing up rpms"
exec_cmd "mkdir -p rpms"
exec_cmd "cp -f $NEW_ROOT/var/cache/apt/*.rpm rpms/"

explain "Cleaning..."
exec_cmd "rm -f new-apt.conf new-apt-sources.list"
exec_cmd "rm -fr $NEW_ROOT" 
exec_cmd "rm -fr mklivecd*.rpm" 

