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
echo "              *** $1"
echo -en "\\033[0;39m"
}


make_config_files()
{
explain "Making new config files for apt "
cat >tmp/new-apt-sources.list<<EOF
#PCLINUXOS apt repository
#rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm ftp://ftp-linux.cc.gatech.edu/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm ftp://ftp.nluug.nl/pub/metalab/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm ftp://ftp.gwdg.de/pub/linux/mirrors/sunsite/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
#rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar
rpm http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/                          pclinuxos/2004 os updates texstar 

EOF

#rpm http://ftp.ibiblio.org/pub/Linux/distributions/contrib/texstar/pclinuxos/apt/ pclinuxos/2004 os updates texstar stable
#rpm http://iglu.org.il/pub/mirrors/texstar/pclinuxos/apt/ pclinuxos/2004 stable os updates



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


init_config()
{
NEW_ROOT=`pwd`/new-pclos
LOG_FILE=tmp/make-install.log
CLEAN_BEFORE=1
CLEAN_AFTER=0

mkdir -p tmp
rm -f $LOG_FILE
touch $LOG_FILE
}

clean_up()
{
mv $LOG_FILE .


if [ $CLEAN_AFTER != 0 ]; then
	explain "Cleaning \$NEW_ROOT: $NEW_ROOT"
	exec_cmd "rm -fr $NEW_ROOT" 
	explain "Cleaning tmp"
	exec_cmd rm -fr tmp
fi
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
}

install_system()
{
explain "installing basesystem on the new root"
#exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install basesystem"
exec_cmd "apt-get -c tmp/new-apt.conf -y -o=RPM::RootDir=$NEW_ROOT install setup filesystem sed rpm"
}


# <-- main -->

init_config
make_config_files
#update_apt
install_system
clean_up

less make-install.log
clear