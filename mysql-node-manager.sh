#!/bin/bash

TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

# Check if rule exists which allows this script to access to server
sudo iptables -C INPUT -p tcp -s 127.0.0.1 --dport 3306 -j ACCEPT
RULE_NOT_EXISTS=$?
if [ $RULE_NOT_EXISTS -eq 1 ]
then
	sudo iptables -I INPUT 1 -p tcp -s 127.0.0.1 --dport 3306 -j ACCEPT
fi

MYSQL_ERROR=$(mysql -Bse "SELECT 1;" 2>&1) 
if [[ "$MYSQL_ERROR" =~ "ERROR 1045" ]]
then
	echo "[$TIMESTAMP] Access to MySQL server denied. Check credentials in /home/mysql-node-manager/my.cnf" >> /var/log/mysql-node-manager/mysql-node-manager.log
	exit 1
fi

MYSQL_AVAILABLE=$((`mysql -Bse "SELECT 1;"`))

SETUP_TYPE=2

# SETUP_TYPE = 1 means its MySQL Group Replication and we read SUPER_READ_ONLY
# SETUP_TYPE = 2 means its Galera Cluster and we read WSREP_READY
if [ $SETUP_TYPE -eq 1 ]
then
	SUPER_READ_ONLY=$((`mysql -Bse "SELECT @@super_read_only;"`))
else
	SUPER_READ_ONLY=$((`mysql -Bse "SELECT VARIABLE_VALUE INTO @wsrep_ready FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME='wsrep_ready'; SELECT CASE WHEN @wsrep_ready='OFF' THEN 1 ELSE 0 END AS value"`))
fi

# Check if rule already exists
sudo iptables -C INPUT -p tcp --dport 3306 -j DROP
RULE_NOT_EXISTS=$?

if [ $SUPER_READ_ONLY -eq 1 ] || [ $MYSQL_AVAILABLE -eq 0 ]
then	
	if [ $RULE_NOT_EXISTS -eq 1 ]
	then
		# Add if not
		sudo iptables -A INPUT -p tcp --dport 3306 -j DROP
		
		echo "[$TIMESTAMP] This node lost cluster connectivity or goes down. Add lock rule to iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
else
	if [ $RULE_NOT_EXISTS -eq 0 ]
	then
		# Add if not
		sudo iptables -D INPUT -p tcp --dport 3306 -j DROP
		
		echo "[$TIMESTAMP] This node recover cluster connectivity. Delete lock rule from iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
fi