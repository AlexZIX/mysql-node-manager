#!/bin/bash

TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

# Read how many nodes unreachable
SUPER_READ_ONLY=$((`mysql -Bse "SELECT @@super_read_only;"`))

# Check if rule already exists
sudo iptables -C INPUT -p tcp --dport 3306 -j DROP
RULE_NOT_EXISTS=$?

if [ $SUPER_READ_ONLY -eq 1 ] 
then	
	if [ $RULE_NOT_EXISTS -eq 1 ]
	then
		# Add if not
		sudo iptables -A INPUT -p tcp --dport 3306 -j DROP
		
		echo "[$TIMESTAMP] This node lost cluster connectivity. Add lock rule to iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
else
	if [ $RULE_NOT_EXISTS -eq 0 ]
	then
		# Add if not
		sudo iptables -D INPUT -p tcp --dport 3306 -j DROP
		
		echo "[$TIMESTAMP] This node recover cluster connectivity. Delete lock rule from iptables." >> /var/log/mysql-node-manager/mysql-node-manager.log
	fi
fi
