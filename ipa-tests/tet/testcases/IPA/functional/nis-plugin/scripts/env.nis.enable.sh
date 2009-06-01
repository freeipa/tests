#!/bin/bash

server=$1
echo "config $server"
ssh root@$server "echo redhat123 | ipa-compat-manage enable"
ssh root@$server "echo redhat123 | ipa-nis-manage enable"
ssh root@$server "service dirsrv restart"
ssh root@$server "service portmap restart"
ssh root@$server "service iptables stop"
echo "remote server [$server] nis plugin enabling finished. The firewall also closed"
