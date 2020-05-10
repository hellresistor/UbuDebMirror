#!/bin/bash
## By: hellresistor 2k9-2k20
## V2.1
## This it is a script compatible with DEBIAN & Ubuntu Distros 
## Will setup as a apt-mirror server to delivery updates from network using a FTP server
##
sudo -i

export endc=$'\e[0m'
export sbl=$'\e[4m'
export bld=$'\e[1m'
export blk=$'\e[5m'
export deflt=$'\e[90m'
export bkwhite=${endc}$'\e[48;5;250m'${deflt}
export red=${bkwhite}$'\e[38;5;196m'
export green=${bkwhite}$'\e[38;5;34m'
export blue=${bkwhite}$'\e[38;5;21m'
export yellow=${bkwhite}$'\e[38;5;214m'
export bgrey=${bkwhite}$'\e[1;38;5;240m'

echo -e "${bkwhite}\n\n                         ${bld}${red}%@. \n                      #@@@@.                                         *@@@@@@@@@@@@, \n                 .@@@@@@@@@@@@@@@@@@&  \n                    ,@@@@@@. #@@@@@@@@@. \n           ${bld}${green}*@@@#       ${bld}${red}.@@@,     *@@@@@@@ \n          ${bld}${green}&@@@@@@         /,       ${bld}${red}#@@@@@@ \n        ${bld}${green}(@@@@@%                    ${bld}${red}&@@@@@ \n         ${bld}${green}@@@@@@    ${bld}${yellow}HellRezistor    ${bld}${red}&@@@@@. \n         ${bld}${green}@@@@@@                    ${bld}${red}@@@@@@ \n         ${bld}${green}.@@@@@@        /         ${bld}${red},@@@@@@ \n         ${bld}${green},@@@@@@/      @@@,       ${bld}${red}(@@@@ \n            ${bld}${green}@@@@@@@@&   @@@@@@,      ${bld}${red}. \n              ${bld}${green}%@@@@@@@@@@@@@@@@@@. \n                 .@@@@@@@@@@@@@@, \n                        @@@@@( \n                        @@& \n${bkwhite}"

if [ -f /etc/os-release ] ; then
 source /etc/os-release
 echo -e "${bld}${green}This OS: ${ID,,} Distro: ${VERSION_CODENAME,,} DETECTED !${bkwhite}\n" && sleep 1
else
 echo -e "${bld}${red}This it is NOT Debian OS or Ubuntu OS !!! ${endc}" && exit
fi

#### HOSTS ####
HOSTS=<<EOF
127.0.0.1       localhost
127.0.1.1       ${ID,,} ${ID,,}

EOF
echo "$HOSTS" >> /etc/hosts

#### Install / UPDATE  apt-mirror ####
apt-get update && apt-get -y install apt-mirror proftpd-basic

#### CONFIG ####
CONFIG=<<EOF
set base_path /var/spool/apt-mirror
set mirror_path $base_path/mirror
set skel_path $base_path/skel
set var_path $base_path/var
set defaultarch amd64
set nthreads     20
set _tilde 0
EOF

echo "$CONFIG" > /etc/apt/mirror.list

if [ "${ID,,}" = "debian" ] ; then
 CONFIG=<<EOF
deb http://deb.debian.org/debian ${VERSION_CODENAME,,} main contrib non-free
deb-src http://deb.debian.org/debian ${VERSION_CODENAME,,} main contrib non-free
deb http://deb.debian.org/debian ${VERSION_CODENAME,,}-backports main contrib non-free
deb-src http://deb.debian.org/debian ${VERSION_CODENAME,,}-backports main contrib non-free
deb http://deb.debian.org/debian ${VERSION_CODENAME,,}-updates main contrib non-free
deb-src http://deb.debian.org/debian ${VERSION_CODENAME,,}-updates main contrib non-free
deb http://security.debian.org/debian-security ${VERSION_CODENAME,,}/updates main contrib non-free
deb-src http://security.debian.org/debian-security ${VERSION_CODENAME,,}/updates main contrib non-free

clean http://deb.debian.org/
clean http://security.debian.org/
EOF
 echo "$CONFIG" >> /etc/apt/mirror.list
elif [ "${ID,,}" -eq "ubuntu" ] ; then
 CONFIG=<<EOF
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-backports main restricted universe multiverse

deb-src http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,} main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME,,}-backports main restricted universe multiverse

clean http://archive.ubuntu.com/ubuntu
EOF
 echo "$CONFIG" >> /etc/apt/mirror.list
else
 echo -e "${bld}${red}Nothing to you here ... " && sleep 0.5 && echo "... bye! ${endc}" && sleep 0.5 && exit
fi

#### SETUP ####
echo -e "${bld}${yellow}Syncronizing... Wait what time is needed...${bkwhite}"
apt-mirror /etc/apt/mirror.list
echo -e "${bld}${green}Cool! Finished !!!${bkwhite}" && sleep 2

#### FTP ####
apt-get -y install proftpd-basic

VHOST=<<EOF
<Anonymous ~ftp>
   User                    ftp
   Group                nogroup
   UserAlias         anonymous ftp
   RequireValidShell        off
   <Directory *>
     <Limit WRITE>
       DenyAll
     </Limit>
   </Directory>
 </Anonymous>
EOF
cp /etc/proftpd/conf.d/anonymous.conf /etc/proftpd/conf.d/anonymous.conf.bck
echo "$VHOST" >> /etc/proftpd/conf.d/anonymous.conf

if [ "${ID,,}" = "debian" ] ; then
 mkdir /srv/ftp/debian
 mount --bind /var/spool/apt-mirror/mirror/deb.debian.org/debian/ /srv/ftp/debian/
 update-rc.d proftpd enable
 cp /etc/rc.local /etc/rc.local.bck
 sed '/^exit 0/i sleep 5' /etc/rc.local
 sed '/^exit 0/i sudo mount --bind  /var/spool/apt-mirror/mirror/archive.ubuntu.com/ /srv/ftp/debian/' /etc/rc.local
elif [ "${ID,,}" = "ubuntu" ] ; then
 mkdir /srv/ftp/ubuntu
 mount --bind /var/spool/apt-mirror/mirror/archive.ubuntu.com/  /srv/ftp/ubuntu
 update-rc.d proftpd enable
 cp /etc/rc.local /etc/rc.local.bck
 sed '/^exit 0/i sleep 5' /etc/rc.local
 sed '/^exit 0/i sudo mount --bind  /var/spool/apt-mirror/mirror/archive.ubuntu.com/ /srv/ftp/ubuntu/' /etc/rc.local
else
 echo -e"${bld}${red}Nothing to you here ... " && sleep 0.5 && echo "... bye! ${endc}" && sleep 0.5 && exit
fi

#### Add Crontab ####

(crontab -l 2>/dev/null; \
  echo "0 2 * * * /usr/bin/apt-mirror >> /var/spool/apt-mirror/apt-mirror.log") | crontab -

echo -e "${bld}${yellow}Configure Client with ...\n${bld}${green}ftp://<ip>/debian\nftp://<ip>/ubuntu "

echo -e "${endc}" && exit
