# mysql-node-manager
This project for manage iptables rules for MySQL group replication in multi-primary mode

What this project for.

In multi-primary setup each mysql node accept writes and reads. In case of network failure node state switches to ERROR and node enable super_read_only mode. In this state node still accept reads but disallow writes. Typically administrators uses routers such as MySQL Router or ProxySQL which can determine each node state and change reads/writes routes accordingly. Routers usage makes mysql multi primary setup more complex and less convenient. For ex. in case of using ProxySQL we need to duplicate MySQL users on each ProxySQL instance. Also we need to create an additional virtual machines for such proxies. At the same time many hardware routers and XTM devices which uses as enterprise networks borders like WatchGuard, Fortinet, etc. have built-in load-balancers which allows to balance load between few servers using different algorithms like round-robin, least connection, etc, using servers weights. Of course this devices can makes servers probes for understand if server alive or not. But this probes usually very simpe like TCP SYN. So the hardware router can't understand if MySQL node was switched into super_read_only mode and continue establish sessions with this node. This project solves this problem using iptables on each node. It reads value of super_read_only from node and add lock rule in case of value equals 1. So nobody include hardware load-balancer can't connect to this node. Router  exclude it from group and new sessions establishes only wich alive nodes. Hardware load-balancer also can notify administrators about nodes avalability. MySQL Group Replication in multi primary setup becomes more simple without using additional components.

What this project contains.

- install.sh - installation script which allows to simple install of this project
- check_mysql_node.sh - script which monitors node state and manage iptables rules
- mysql-node-manager - cron.d task which run check_mysql_node.sh every 30 seconds

Where it will work.

Written and tested in Ubuntu Server 22.04.
