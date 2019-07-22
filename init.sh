#!/bin/bash
# TRUSTeK Server Init Script v1.5
# https://trustek.it

clear
echo ''
echo '********************************************************************************************************'
echo '  $$$$$$\                                                          $$$$$$\ $$\   $$\ $$$$$$\ $$$$$$$$\ '
echo ' $$  __$$\                                                         \_$$  _|$$$\  $$ |\_$$  _|\__$$  __|'
echo ' $$ /  \__| $$$$$$\   $$$$$$\ $$\    $$\  $$$$$$\   $$$$$$\          $$ |  $$$$\ $$ |  $$ |     $$ |   '
echo ' \$$$$$$\  $$  __$$\ $$  __$$\\$$\  $$  |$$  __$$\ $$  __$$\         $$ |  $$ $$\$$ |  $$ |     $$ |   '
echo '  \____$$\ $$$$$$$$ |$$ |  \__|\$$\$$  / $$$$$$$$ |$$ |  \__|        $$ |  $$ \$$$$ |  $$ |     $$ |   '
echo ' $$\   $$ |$$   ____|$$ |       \$$$  /  $$   ____|$$ |              $$ |  $$ |\$$$ |  $$ |     $$ |   '
echo ' \$$$$$$  |\$$$$$$$\ $$ |        \$  /   \$$$$$$$\ $$ |            $$$$$$\ $$ | \$$ |$$$$$$\    $$ |   '
echo '  \______/  \_______|\__|         \_/     \_______|\__|            \______|\__|  \__|\______|   \__|   '
echo ''
echo '********************************************************************************************************'
echo ''
echo ''

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

read -p 'Would you like to continue? [y/n] ' CONT
if [ "$CONT" != 'y' ] && [ "$CONT" != 'Y'  ]; then
    echo 'Goodbye'
    exit 1
fi

echo ''
echo '************************************************************'
echo '--> CHANGING ROOT PASSWORD...'
echo '************************************************************'
echo ''

read -p "Do you want to change the password for user root? [y/n] " CONT
if [ "$CONT" = "y" ]; then
  read -sp 'Enter the new password for root user: ' npasswd
  echo "$npasswd" | passwd --stdin root
fi

echo ''
echo '************************************************************'
echo '--> INSTALLING NEW PACKAGES AND SYSTEM UPDATES...'
echo '************************************************************'
echo ''

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*								> /dev/null
echo '01- Installing update' && yum -y update								> /dev/null
echo '02- Installing wget' && yum -y install wget							> /dev/null
echo '03- Installing tmux' && yum -y install tmux							> /dev/null
echo '04- Installing nano' && yum -y install nano							> /dev/null
echo '05- Installing htop' && yum -y install htop							> /dev/null
echo '06- Installing deltaparm' && yum -y install deltarpm						> /dev/null
echo '07- Installing yum-utils' && yum -y install yum-utils						> /dev/null
echo '08- Installing epel-release' && yum -y install epel-release					> /dev/null
echo '09- Installing iptables-services' && yum -y install iptables-services				> /dev/null
echo '10- Installing fail2ban' && yum -y install fail2ban						> /dev/null
echo '11- Installing fail2ban-systemd' && yum -y install fail2ban-systemd				> /dev/null
echo '12- Installing rkhunter' && yum -y install rkhunter						> /dev/null

echo ''
echo '************************************************************'
echo '--> CONFIGURING NETWORK INTERFACES...'
echo '************************************************************'
echo ''

echo 'Setting eth0:0...'
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:0
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:0
cat <<EOT >> /etc/sysconfig/network-scripts/ifcfg-eth0:0
DEVICE="eth0:0"
BOOTPROTO=static
IPADDR="94.23.69.56"
NETMASK="255.255.255.255"
ONBOOT=yes
EOT
ifup eth0:0

echo 'Setting eth0:1...'
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:1
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:1
cat <<EOT >> /etc/sysconfig/network-scripts/ifcfg-eth0:1
DEVICE="eth0:1"
BOOTPROTO=static
IPADDR="94.23.69.125"
NETMASK="255.255.255.255"
ONBOOT=yes
EOT
ifup eth0:1

echo 'Setting eth0:2...'
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:2
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:2
cat <<EOT >> /etc/sysconfig/network-scripts/ifcfg-eth0:2
DEVICE="eth0:2"
BOOTPROTO=static
IPADDR="94.23.69.171"
NETMASK="255.255.255.255"
ONBOOT=yes
EOT
ifup eth0:2

echo ''
echo 'IP Address Currently Configured:'
ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1

echo ''
echo '************************************************************'
echo '--> CONFIGURING HOSTNAME...'
echo '************************************************************'
echo ''

public_ip=$(hostname -i)

cat /dev/null > /etc/hosts
cat <<EOT >> /etc/hosts
127.0.0.1	localhost
$public_ip	srv1.trustek.it		srv1
EOT

cat /dev/null > /etc/hostname
echo 'srv1.trustek.it' > /etc/hostname

echo ''
echo '************************************************************'
echo '--> CONFIGURING TMUX SETTINGS...'
echo '************************************************************'
echo ''

cat /dev/null > /root/.tmux.conf
cat <<EOT >> /root/.tmux.conf
set -g assume-paste-time 1
set -g base-index 1
set -g bell-action any
set -g bell-on-alert off
set -g default-command ""
set -g default-path ""
set -g default-shell "/bin/bash"
set -g default-terminal "screen"
set -g destroy-unattached off
set -g detach-on-destroy on
set -g display-panes-active-colour red
set -g display-panes-colour blue
set -g display-panes-time 1000
set -g display-time 750
set -g history-limit 2000
set -g lock-after-time 0
set -g lock-command "lock -np"
set -g lock-server on
set -g message-attr none
set -g message-bg yellow
set -g message-command-attr none
set -g message-command-bg black
set -g message-command-fg yellow
set -g message-fg black
set -g message-limit 20
set -g mouse-resize-pane off
set -g mouse-select-pane off
set -g mouse-select-window off
set -g mouse-utf8 on
set -g pane-active-border-bg default
set -g pane-active-border-fg green
set -g pane-border-bg default
set -g pane-border-fg default
set -g prefix C-b
set -g renumber-windows on
set -g repeat-time 500
set -g set-remain-on-exit off
set -g set-titles on
set -g set-titles-string "#S:#I:#W - "#T""
set -g set-titles-string "#S:#I:#W - \"#T\" #{session_alerts}"
set -g status on
set -g status-attr none
set -g status-bg green
set -g status-fg black
set -g status-interval 2
set -g status-justify left
set -g status-keys emacs
set -g status-left " [ #S ] "
set -g status-left-attr none
set -g status-left-bg default
set -g status-left-fg default
set -g status-left-length 20
set -g status-position bottom
set -g status-right ""#22T" %H:%M %d-%b-%y"
set -g status-right "| #(hostname -f) | %T | %d/%m/%Y "
set -g status-right-attr none
set -g status-right-bg default
set -g status-right-fg default
set -g status-right-length 50
set -g status-utf8 on
set -g terminal-overrides "*88col*:colors=88,*256col*:colors=256,xterm*:XT:Ms=\E]52;%p1%s;%p2%s\007:Cc=\E]12;%p1%s\007:Cr=\E]112\007:Cs=\E[%p1%d q:Csr=\E[2 q,screen*:XT"
set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
set -g visual-activity off
set -g visual-bell off
set -g visual-content off
set -g visual-silence off
set -g word-separators " -_@"
EOT

cat /dev/null > /root/.bashrc
cat <<EOT >> /root/.bashrc
# .bashrc
# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach -t default || tmux new -s default
fi
cd
clear
w
EOT

echo ''
echo '************************************************************'
echo '--> CREATING SYSTEM ALIAS...'
echo '************************************************************'
echo ''

cat <<EOT >> /etc/bashrc
alias cls='clear'
alias ll='ls -lah --color=auto'
alias ld='ls -lahd'
alias df='df -h'
alias nw='tmux new-window'
alias shutdown='shutdown -h now'
alias extip='curl ipinfo.io/ip'
EOT

source /etc/bashrc

echo ''
echo '************************************************************'
echo '--> CREATING NEW ADMIN USER...'
echo '************************************************************'
echo ''

read -p "Do you want to create a new admin account? [y/n] " CONT
if [ "$CONT" = "y" ]; then
    read -p 'Enter the new admin username: ' nadmin
    useradd -m $nadmin
    usermod -aG wheel $nadmin
    echo ''
	
    # Change new admin password
    read -p "Do you want to change the password for user $nadmin? [y/n]  " CONT
    if [ "$CONT" = "y" ]; then
	read -sp 'Enter the new password for user: ' npasswd
	echo "$npasswd" | passwd --stdin $nadmin
    fi
fi

echo ''
echo '************************************************************'
echo '--> CONFIGURING SSH SERVER...'
echo '************************************************************'
echo ''

echo '' >> /etc/ssh/sshd_config
echo 'ListenAddress 151.80.145.36' >> /etc/ssh/sshd_config

# Prevent SSH root access
read -p "Do you want to deny ssh access to root account? [y/n] " CONT
if [ "$CONT" = "y" ]; then
    echo 'PermitRootLogin no'  >> /etc/ssh/sshd_config
else
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

systemctl restart sshd

echo ''
echo '************************************************************'
echo '--> CONFIGURING SERVER SECURITY...'
echo '************************************************************'
echo ''

systemctl stop firewalld.service
systemctl mask firewalld.service
systemctl disable firewalld.service
systemctl stop firewalld.service

cat /dev/null > /etc/fail2ban/jail.local
cat <<EOT >> /etc/fail2ban/jail.local
[sshd]
enabled = true
action = iptables[name=sshd, port=ssh, protocol=tcp]
EOT

systemctl enable fail2ban.service
systemctl start fail2ban.service

echo ''
echo '************************************************************'
echo '--> ALL DONE '
echo '************************************************************'
echo ''

read -p "Do you want to reboot the system? [y/n] " CONT
if [ "$CONT" = "y" ]; then
    reboot now
fi
