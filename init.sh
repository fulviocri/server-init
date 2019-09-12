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

if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

function StartTheProcess() {
	read -r -p "Do you want to upgrade PHP 5 to PHP 7? [y/N] " vPhp7
	read -r -p "Do you want to upgrade MariaDB 5 to MariaDB 10? [y/N] " vMariaDB10
	read -r -p "Do you want to harden sysctl.conf? [y/N] " vSysctl
	read -r -p "What is your hostname? " vHostname

	localectl set-keymap it
	timedatectl set-timezone Europe/Rome
	curl https://raw.githubusercontent.com/fulviocri/server-init/master/wordpress.sh > /root/wordpress.sh
	chmod +x /root/wordpress.sh
	
	yum clean all
	yum -y install bind-utils wget tmux nano htop iotop unzip
	IPAddress=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
	#IPAddress=$(hostname -i)
	DigResult=$(dig @8.8.8.8 +short $vHostname)

	if [ "$IPAddress" != "$DigResult" ]; then
	    echo 'Error: Hostname does not match IP address yet, please wait otherwise LetsEncrypt will not work.'
	    exit 1
	fi

	echo " "
	echo " "
	read -r -p "Enter new password for root user: " ROOT_PWD
	echo "$ROOT_PWD" | passwd --stdin root
	
	echo " "
	read -r -p "Enter the new admin username: " NADMIN
	useradd -m $NADMIN
	usermod -aG wheel $NADMIN
	
	echo " "
	read -r -p "Enter new admin password: " NADMIN_PWD
	echo "$NADMIN_PWD" | passwd --stdin $NADMIN
	
	echo " "
	read -r -p "What is the IP Address for shared services? " vSharedIPAddress
	read -r -p "What is the IP Address for BIND9 DNS Server " vDNSIPAddress
	read -r -p "What e-mail address would you like to receive Monit and VestaCP alerts to? " vEmail
	read -r -p "Please type a password to use with VestaCP and Monit: " vPassword
	read -r -p "Monit needs an SMTP server to use to send email alerts properly. What's your SMTP Hostname? " vSMTPHostname
	read -r -p "What port does the SMTP Hostname listen on (usually 25 or 587)? " vSMTPPort
	read -r -p "What's your SMTP Username (usually a full email address)? " vSMTPEmail
	read -r -p "What's your SMTP Password? " vSMTPPassword

	# ---------------------------------

		# Set the hostname and stop it from being edited

		hostname $vHostname
		echo $vHostname > /etc/hostname
		chattr +i /etc/hostname

	# ---------------------------------

		# Make the server use local DNS and stop it from being edited

		echo 'nameserver 127.0.0.1' | cat - /etc/resolv.conf > temp && mv temp /etc/resolv.conf
		chattr +i /etc/resolv.conf
		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/named.conf > /etc/named.conf
		/sbin/service named restart

	# ---------------------------------

		# Disable IPV6
		
		echo ''
		sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="ipv6.disable=1 crashkernel=auto rhgb quiet"/g' /etc/default/grub
		grub2-mkconfig -o /boot/grub2/grub.cfg
		echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
		echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
		sysctl -p

	# ---------------------------------

		# Setting TMUX preferences

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

	# ---------------------------------

		# Setting BASHRC alias

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

	# ---------------------------------

		# Setting SWAP partition

		if ! grep -q "/swapfile" /etc/fstab; then
			fallocate -l 4G /swapfile
			chmod 600 /swapfile
			mkswap /swapfile
			swapon /swapfile
			echo "/swapfile none swap sw 0 0" >> /etc/fstab
		fi

	# ---------------------------------

		# Securing SSH

		sed -i "s/#ListenAddress 0.0.0.0/ListenAddress $IPAddress/g" /etc/ssh/sshd_config
		sed -i "s/#AddressFamily any/AddressFamily inet/g" /etc/ssh/sshd_config

		sed -i "s/#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
		sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

	# ---------------------------------

		# Harden sysctl.conf
		
		if [ $vSysctl == "y" ] || [ $vSysctl == "Y" ]; then
			a="`netstat -i | cut -d' ' -f1 | grep eth0`";
			b="`netstat -i | cut -d' ' -f1 | grep venet0:0`";
			if [ "$a" == "eth0" ]; then
				curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/sysctl.conf-eth0 > /etc/sysctl.conf
			elif [ "$b" == "venet0:0" ]; then
				curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/sysctl.conf-venet0 > /etc/sysctl.conf
			fi
			sysctl -p
		fi

	# ---------------------------------

		# Installing VestaCP

		curl -O http://vestacp.com/pub/vst-install.sh
		bash vst-install.sh --nginx yes --phpfpm yes --apache no --vsftpd no --proftpd no --exim yes --dovecot yes --spamassassin yes --clamav yes --named yes --iptables yes --fail2ban yes --mysql yes --postgresql no --remi yes --softaculous no --quota yes --hostname $vHostname --email $vEmail --password $vPassword
		export VESTA=/usr/local/vesta/
		source /etc/profile
		/usr/local/vesta/bin/v-change-web-domain-ip admin $vHostname $IPAddress y
		/usr/local/vesta/bin/v-change-dns-domain-ip admin $vHostname $IPAddress

		/usr/local/vesta/bin/v-add-sys-ip $vSharedIPAddress 255.255.255.255
		/usr/local/vesta/bin/v-add-sys-ip $vDNSIPAddress 255.255.255.255
		
		sed -i 's/8083;/8443;/' /usr/local/vesta/nginx/conf/nginx.conf
		/usr/local/vesta/bin/v-add-firewall-rule ACCEPT 0.0.0.0/0 8443 TCP
		/usr/local/vesta/bin/v-delete-firewall-rule 2
		systemctl restart vesta
		
		echo "local_interfaces = <; 127.0.0.1 ; $vSharedIPAddress" >> /etc/exim/exim.conf
		systemctl restart exim

	# ---------------------------------

		# Set SpamAssassin Rules + Extras

		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/dnsbl.conf > /etc/exim/dnsbl.conf
		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/custom_SA-rules.cf > /etc/mail/spamassassin/custom_SA-rules.cf
		sed -i 's/rfc1413_query_timeout = 5s/rfc1413_query_timeout = 0s/' /etc/exim/exim.conf
		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/90-quota.conf > /etc/dovecot/conf.d/90-quota.conf
		sed -i 's/mail_plugins = .*/mail_plugins = $mail_plugins autocreate quota imap_quota/' /etc/dovecot/conf.d/20-imap.conf
		echo "mail_max_userip_connections = 50" >> /etc/dovecot/conf.d/10-mail.conf
		echo "mail_fsync = never" >> /etc/dovecot/conf.d/10-mail.conf

	# ---------------------------------

		# Let's fix LetsEncrypt and secure our own server!

		yum -y install vim-common
		#sed -i 's/agreement=.*/agreement="https:\/\/letsencrypt.org\/documents\/LE-SA-v1.1.1-August-1-2016.pdf"/' /usr/local/vesta/bin/v-add-letsencrypt-user
		/usr/local/vesta/bin/v-add-letsencrypt-domain admin $vHostname

		if [ -f /home/admin/conf/web/ssl.$vHostname.pem ]; then
			rm -f /usr/local/vesta/ssl/certificate.crt
			ln -s /home/admin/conf/web/ssl.$vHostname.pem /usr/local/vesta/ssl/certificate.crt
			chown -h root:mail /usr/local/vesta/ssl/certificate.crt
		fi

		if [ -f /home/admin/conf/web/ssl.$vHostname.key ]; then
			rm -f /usr/local/vesta/ssl/certificate.key
			ln -s /home/admin/conf/web/ssl.$vHostname.key /usr/local/vesta/ssl/certificate.key
			chown -h root:mail /usr/local/vesta/ssl/certificate.key
		fi

	# ---------------------------------

		# Let's fix NGINX up! This will take a very long time.

		if [ ! -f /etc/nginx/dhparams.pem ]; then
			openssl dhparam -dsaparam -out /etc/nginx/dhparams.pem 4096
		fi

		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/nginx.conf > /etc/nginx/nginx.conf

	# ---------------------------------

		# Let's fix PHP-FPM

		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/default.tpl > /usr/local/vesta/data/templates/web/php-fpm/default.tpl
		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/socket.tpl > /usr/local/vesta/data/templates/web/php-fpm/socket.tpl
		/usr/local/vesta/bin/v-rebuild-web-domains admin
		
	# ---------------------------------

		# Make it HTTP2 and SPDY
		
		sed -i 's/\%web_ssl_port\%/\%web_ssl_port\% ssl http2/' /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl
		#sed -i 's/\%web_port\%/\%web_port\% spdy/' /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl

	# ---------------------------------

		# Let's install Monit & Configure it

		yum -y install monit
		curl https://raw.githubusercontent.com/SS88UK/VestaCP-Server-Installer/master/CentOS7/monitrc > /etc/monitrc
		sed -i "s/vPassword/$vPassword/" /etc/monitrc
		sed -i "s/vEmail/$vEmail/" /etc/monitrc
		sed -i "s/IPAddress/$IPAddress/" /etc/monitrc
		sed -i "s/vSMTPEmail/$vSMTPEmail/" /etc/monitrc
		sed -i "s/vSMTPPassword/$vSMTPPassword/" /etc/monitrc
		sed -i "s/vSMTPHostname/$vSMTPHostname/" /etc/monitrc
		sed -i "s/vSMTPPort/$vSMTPPort/" /etc/monitrc
		chkconfig monit on

	# ---------------------------------

		# Install PHP 7

		if [ $vPhp7 == "y" ] || [ $vPhp7 == "Y" ]; then
			service php-fpm stop
			yum -y --enablerepo=remi install php73-php php73-php-pear php73-php-bcmath php73-php-pecl-jsond-devel php73-php-mysqlnd php73-php-gd php73-php-common php73-php-fpm php73-php-intl php73-php-cli php73-php php73-php-xml php73-php-opcache php73-php-pecl-apcu php73-php-pecl-jsond php73-php-pdo php73-php-gmp php73-php-process php73-php-pecl-imagick php73-php-devel php73-php-mbstring
			rm -f /usr/bin/php
			ln -s /usr/bin/php73 /usr/bin/php
			sed -i 's/include=.*/include=\/etc\/php-fpm.d\/\*\.conf/' /etc/opt/remi/php73/php-fpm.conf
			sed -i 's/;pid/pid/' /etc/opt/remi/php73/php-fpm.conf
			service php73-php-fpm restart
			rm -f /usr/lib/systemd/system/php-fpm.service
			ln -s /usr/lib/systemd/system/php73-php-fpm.service /usr/lib/systemd/system/php-fpm.service
			systemctl daemon-reload
			yum -y install yum-utils
			yum-config-manager --disable remi-php56 remi-php55 remi-test
			sed -i "s/\/var\/run\/php-fpm\/php-fpm.pid/\/var\/opt\/remi\/php73\/run\/php-fpm\/php-fpm.pid/" /etc/monitrc
		fi

	# ---------------------------------

		# Install MariaDB 10

		if [ $vMariaDB10 == "y" ] || [ $vMariaDB10 == "Y" ]; then
			systemctl stop mariadb
			yum -y remove mariadb mariadb-server
			yum -y install epel-release
			curl https://raw.githubusercontent.com/fulviocri/server-init/master/mariadb.repo > /etc/yum.repos.d/mariadb.repo
			yum -y install MariaDB-server MariaDB-client
			systemctl enable mariadb
			systemctl start mariadb
			mysql_upgrade
		fi

		echo "bind-address=127.0.0.1" >> /etc/my.cnf
		systemctl restart mariadb

	# ---------------------------------	
		
		echo "Done!";
		echo " ";
		echo "You can access VestaCP here: https://$vHostname:8083/";
		echo "Username: admin";
		echo "Username: $vPassword";
		echo " ";
		echo " ";
		echo "You can access Monit here (always best to use IP address: http://$IPAddress:2812/";
		echo "Username: admin";
		echo "Username: $vPassword";
		echo " ";
		echo "Have fun! Visit https://blog.ss88.uk/ for more great tutorials!";
		echo " ";
		echo "PLEASE REBOOT THE SERVER ONCE YOU HAVE COPIED THE DETAILS ABOVE. REBOOT COMMAND:    shutdown -r now";
}

echo "IMPORTANT! Make sure you have VestaCP install and are running CentOS 7.x";
read -r -p "Do you want to continue? [y/N] " response
case $response in
    [yY][eE][sS]|[yY]) 
        StartTheProcess
        ;;
    *)
        echo "OK. Bye bye.";
        ;;
esac
