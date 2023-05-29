#!/bin/bash

DIR=$(dirname -- "$0";)
IPTABLES=/sbin/iptables
IPLT=$DIR/ipchains
CONF=/etc/iptables/rules.v4

# Create the chain BLACKLIST
$IPTABLES -N BLACKLIST

# Empty the chain BLACKLIST before adding rules
$IPTABLES -F BLACKLIST

# Read $IPLT and add IP into IPTables one by one
/bin/egrep -v "^#|^$|:" $IPLT | sort | uniq | while read IP
do
    $IPTABLES -A JANUS -s $IP -j DROP
done

# Save current configuration to file
if [ ! -d "/etc/iptables/" ]
then
    mkdir /etc/iptables
fi
$IPTABLES-save > $CONF
