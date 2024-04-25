#!/bin/bash

echo This script will install the mysql-node-manager software on this server

install="no"

# Create user and grant permissions to manage iptables without promt password
if [ ! $(getent group mysql-node-manager) ] 
then
	addgroup mysql-node-manager
	useradd -g mysql-node-manager -s /bin/bash -m -G sudo mysql-node-manager
	cp mysql-node-manager.sudoers /etc/sudoers.d/mysql-node-manager
	
	install="yes"
else
	read -p "It seems that mysql-node-manager already installed on this server. Do you want to reinstall it (yes/no)? " install
fi

if [ $install = "yes" ] 
then
	# Install iptables and cron
	apt --yes install iptables cron
	
	echo "Select type of your multi-master setup"
	echo "1. MySQL Group Replication"
	echo "2. Galera Cluster"
	read -p "Your choice: " type
	
	if [ "$type" -eq 1 ]; then
		sed -i 's/SETUP_TYPE=[1-2]/SETUP_TYPE=1/g' mysql-node-manager.sh;
	else
		sed -i 's/SETUP_TYPE=[1-2]/SETUP_TYPE=2/g' mysql-node-manager.sh;
	fi
	
	# Set user for accesing to mysql
	rm -f /home/mysql-node-manager/.my.cnf
	read -p "Enter username for the mysql-node-manager to access to MySQL: " username
	read -p "Enter password for the mysql-node-manager to access to MySQL: " password
	echo "[client]" >> /home/mysql-node-manager/.my.cnf
	echo "user = $username" >> /home/mysql-node-manager/.my.cnf
	echo "password = $password" >> /home/mysql-node-manager/.my.cnf
	echo "host = 127.0.0.1" >> /home/mysql-node-manager/.my.cnf
	chown -R mysql-node-manager:mysql-node-manager /home/mysql-node-manager/.my.cnf

	# Create working directory and copy script into it
	mkdir -p /opt/mysql-node-manager
	cp mysql-node-manager.sh /opt/mysql-node-manager
	chown -R mysql-node-manager:mysql-node-manager /opt/mysql-node-manager
	chmod 700 -R /opt/mysql-node-manager/
	
	# Create directory for logs
	mkdir -p /var/log/mysql-node-manager
	chown -R mysql-node-manager:mysql-node-manager /var/log/mysql-node-manager
	chmod 700 -R /var/log/mysql-node-manager
	
	# Install cron job
	cp mysql-node-manager.crontab /etc/cron.d/mysql-node-manager
	chown root:root /etc/cron.d/mysql-node-manager
	chmod 0644 /etc/cron.d/mysql-node-manager
	systemctl restart cron
fi