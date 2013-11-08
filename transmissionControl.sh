#!/bin/bash
####################################################################################
####################################################################################
# A Transmission (http://www.transmissionbt.com/) script that 
# will set alternate speed limits ON/OFF based on the
# number of hosts currently active on the LAN.
#
# An adaptation on the script from:
# Jaime Bosque jaboto(at)gmail(dot)com
#
# Requirements:
# transmission-remote, transmission, grep, nmap, cron 
#
####################################################################################
####################################################################################
#-----------------------------------------------------------------------------------
# Transmission and network variables.
# -hosts should be 2 if you are using typical network config (router + mediabox) 
#  but may  vary if is in the same box or you have an always-active host
#-----------------------------------------------------------------------------------
transmission=/usr/bin/transmission-daemon
config_file=/etc/transmission-daemon/settings.json
t_remote=/usr/bin/transmission-remote
user=transmission
pass=transmission
lan=192.168.1
server=localhost
port=9091
log=/home/selex/Playground/log/transmission_limits.log
hosts=2
DEBUG=1

# Detect if transmission is running
running=`pidof transmission-daemon | wc -l`
pid=`pidof transmission-daemon`

if [ "$running" == "1" ]; then
    # Use nmap to retrieve the number of hosts in lan 
    hosts_up=`nmap -sP $lan.* | grep $lan | wc -l`
    last_read=`tail -n1 $log`
    hosts_up_before=`tail -n1 $log | grep -o -E "H[0-9]+" | grep -o -E [0-9]+`
    if [ -z "$hosts_up_before" ]; then hosts_up_before=0; fi

    # When DEBUG, always change things
    if [ "$DEBUG" -eq "1" ]; then
        echo "DEBUG: Found $hosts_up";
        echo "DEBUG: Host to trigger $hosts_up";
        if [ "$hosts_up" -gt "$hosts" ]; then
            $t_remote $server:$port -n $user:$pass -as
            echo "DEBUG: Setting turtle mode (alternate speed ON) "
        else
            $t_remote $server:$port -n $user:$pass -AS
            echo "DEBUG: Unsetting turtle mode (alternate speed OFF) "
        fi
    fi

    # If something has changed in the lan update limits
    #echo "Hosts up $hosts_up  vs $hosts_up_before"
    if [ "$hosts_up" -ne "$hosts_up_before" ]; then
        if [ "$hosts_up" -gt "$hosts" ]; then
            $t_remote $server:$port -n $user:$pass -as
            echo `date +"%d/%m/%y -- %H:%M"` "S$running H$hosts_up turtle:ON P$pid" >> $log
        else
            $t_remote $server:$port -n $user:$pass -AS
            echo `date +"%d/%m/%y -- %H:%M"` "S$running H$hosts_up turtle:OFF P$pid" >> $log
        fi

        #Log that changes were done!
    fi
else
    # Log that daemon is not running :_(
    echo `date +"%d/%m/%y -- %H:%M"` "Transmission-daemon is not running!" >> $log

    # Start transmission daemon with the specified config file
    $transmission -g $config_file
    echo `date +"%d/%m/%y -- %H:%M"` "Transmission-daemon was lunched!" >> $log
fi
exit 0
