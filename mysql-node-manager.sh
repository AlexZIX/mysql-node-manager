#!/bin/bash

TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

MYSQL_ERROR=$(mysql -Bse "SELECT 1;" 2>&1) 
if [[ "$MYSQL_ERROR" =~ "ERROR 1045" ]]
then
	echo "[$TIMESTAMP] Access to MySQL server denied. Check credentials in /home/mysql-node-manager/my.cnf" >> /var/log/mysql-node-manager/mysql-node-manager.log
	exit 1
fi

MYSQL_AVAILABLE=$((`mysql -Bse "SELECT 1;"`))

SETUP_TYPE=2

SUPER_READ_ONLY=1

# SETUP_TYPE = 1 means its MySQL Group Replication and we read SUPER_READ_ONLY
# SETUP_TYPE = 2 means its Galera Cluster and we read wsrep_ready, wsrep_cluster_size and wsrep_cluster_status
if [ $SETUP_TYPE -eq 1 ]
then
	SUPER_READ_ONLY=$((`mysql -Bse "SELECT @@super_read_only;"`))
else
	WSREP_READY=$(mysql -Bse "SHOW STATUS LIKE 'wsrep_ready';" | awk '{print $2}')
	WSREP_PRIMARY=$(mysql -Bse "SHOW STATUS LIKE 'wsrep_cluster_status';" | awk '{print $2}')

	if [ "$WSREP_READY" = "ON" ] && [ "$WSREP_PRIMARY" = "Primary" ]
	then
		SUPER_READ_ONLY=0
	fi
fi

# Check if rule already exists
sudo iptables -t nat -C PREROUTING -p tcp -m tcp --dport 3307 -j REDIRECT --to-ports 3306
RULE_NOT_EXISTS=$?

if [ $SUPER_READ_ONLY -eq 1 ] || [ $MYSQL_AVAILABLE -eq 0 ]
then	
	if [ $RULE_NOT_EXISTS -eq 0 ]
	then
		# Add if not
		sudo iptables -t nat -D PREROUTING -p tcp -m tcp --dport 3307 -j REDIRECT --to-ports 3306
		
		echo "[$TIMESTAMP] This node lost cluster connectivity or goes down. Remove redirect rule from iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
else
	if [ $RULE_NOT_EXISTS -eq 1 ]
	then
		# Add if not
		sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 3307 -j REDIRECT --to-ports 3306
		
		echo "[$TIMESTAMP] This node recover cluster connectivity. Add redirect rule to iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
fi
