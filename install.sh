#!/bin/bash

echo This script will install the mysql-node-manager software on this server

install=3

# Create user and grant permissions to manage iptables without promt password
if [ ! $(getent group mysql-node-manager) ] 
then
	addgroup mysql-node-manager
	useradd -g mysql-node-manager -s /bin/bash -m -G sudo mysql-node-manager
	cp mysql-node-manager.sudoers /etc/sudoers.d/mysql-node-manager
	
	install=2
else
	echo "It seems that mysql-node-manager already installed on this server. Please, select action which you want to run."
	echo "1. Update"
	echo "2. Reinstall"
	echo "3. Exit"
	read -p "Your choice: " install
fi

if [ $install -eq 1 ] 
then
	# Pull changes from server
	git pull
fi

if [ $install -eq 2 ] 
then
	# Install iptables and cron
	apt --yes install iptables cron

 	# Write cluster type into script
	echo "Select type of your multi-master setup"
	echo "1. MySQL Group Replication"
	echo "2. Galera Cluster"
	read -p "Your choice: " type
	sed -i "s/SETUP_TYPE=[1-2]/SETUP_TYPE=$type/g" mysql-node-manager.sh
	
	# Set user for accesing to mysql
	rm -f /home/mysql-node-manager/.my.cnf
	read -p "Enter username for the mysql-node-manager to access to MySQL: " username
	read -p "Enter password for the mysql-node-manager to access to MySQL: " password
	echo "[client]" >> /home/mysql-node-manager/.my.cnf
	echo "user = $username" >> /home/mysql-node-manager/.my.cnf
	echo "password = $password" >> /home/mysql-node-manager/.my.cnf
	echo "host = 127.0.0.1" >> /home/mysql-node-manager/.my.cnf
	chown -R mysql-node-manager:mysql-node-manager /home/mysql-node-manager/.my.cnf
fi

# In case of install/reinstall/update
if [ $install -eq 1 ] || [ $install -eq 2 ]
then
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
