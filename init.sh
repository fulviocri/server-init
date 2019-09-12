#!/bin/bash
# TRUSTeK Server Init Script v3.0
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
echo '                                                                                             by TRUSTeK'
echo '********************************************************************************************************'
echo ''
echo ''

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
	echo 'Error: this script can only be executed by root'
	exit 1
fi

read -p 'Would you like to continue with Server INIT? [y/N] ' CONT
if [ "$CONT" != "y" ] && [ "$CONT" != "Y" ]; then
	echo 'Goodbye'
	exit 1
fi

PUBLIC_IP=$(hostname -i)
localectl set-keymap it
timedatectl set-timezone Europe/Rome

echo ''
read -sp 'Enter new password for root user: ' ROOT_PWD
echo ''
read -sp 'Retype new password: ' ROOT_PWD_CHECK

if [ "$ROOT_PWD" == "$ROOT_PWD_CHECK" ]; then
	echo ''
	echo "$ROOT_PWD" | passwd --stdin root
else
	echo ''
	echo "Sorry, password do not match."
fi

echo ''
read -p 'Enter the new admin username: ' NADMIN
useradd -m $NADMIN
usermod -aG wheel $NADMIN

echo ''
read -sp 'Enter new password: ' NADMIN_PWD
echo ''
read -sp 'Retype new password: ' NADMIN_PWD_CHECK

if [ "$NADMIN_PWD" == "$NADMIN_PWD_CHECK" ]; then
	echo ''
	echo "$NADMIN_PWD" | passwd --stdin $NADMIN
else
	echo ''
	echo "Sorry, password do not match."
fi

echo ''
yum -y update
yum -y install wget tmux nano htop iotop unzip

echo ''
sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="ipv6.disable=1 crashkernel=auto rhgb quiet"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p

echo ''
[ -e /root/.tmux.conf ] && rm -rf /root/.tmux.conf > /dev/null 2>&1
curl https://raw.githubusercontent.com/fulviocri/server-init/master/tmux.conf > /root/.tmux.conf

if ! grep -q "tmux attach" /root/.bashrc; then
	echo '' >> /root/.bashrc
	echo 'if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then' >> /root/.bashrc
	echo '	tmux attach -t default || tmux new -s default' >> /root/.bashrc
	echo 'fi' >> /root/.bashrc
	echo '' >> /root/.bashrc
	echo 'cd' >> /root/.bashrc
	echo 'w' >> /root/.bashrc
fi

if ! grep -q "/swapfile" /etc/fstab; then
	fallocate -l 4G /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

if ! grep -q "extip" /etc/bashrc; then
	echo "alias cls='clear'" >> /etc/bashrc
	echo "alias ll='ls -lah --color=auto'" >> /etc/bashrc
	echo "alias ld='ls -lahd'" >> /etc/bashrc
	echo "alias df='df -h'" >> /etc/bashrc
	echo "alias nw='tmux new-window'" >> /etc/bashrc
	echo "alias shutdown='shutdown -h now'" >> /etc/bashrc
	echo "alias extip='curl ipinfo.io/ip'" >> /etc/bashrc
	source /etc/bashrc
fi

sed -i "s/#ListenAddress 0.0.0.0/ListenAddress $PUBLIC_IP/g" /etc/ssh/sshd_config
sed -i "s/#AddressFamily any/AddressFamily inet/g" /etc/ssh/sshd_config

sed -i "s/#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

wget https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7.sh -O ./CentOS7.sh
chmod 777 ./CentOS7.sh
sudo ./CentOS7.sh
