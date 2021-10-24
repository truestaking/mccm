#!/bin/bash
cd /opt/moonbeam/mccm
FILE=./env

if ! test -f "$FILE"
then
    logger "MCCM cannot find $FILE -- does not exist"
    exit;
fi
#get hostname
HOST=$(hostname -f)
source ./env

# get number of cores
cpu_cores=$( lscpu -p | grep -v \# | wc -l )

### set CPU load average target
### defaults to 3/4 the avaiable cores
#see if the user desires a custom peak load average

if ( ! echo peak_load_avg | grep -qi [0-9] )
then peak_load_avg=$(echo ".75*$cpu_cores")
fi
# get current CPU load average
cpu_load_avg=$(cat /proc/loadavg | awk '{print $1}')

### check process
alert_type=""
alert_message=""

generate_data(){
cat << EOF
{
"type": "$alert_type",
"to_send": "$alert_message"
}
EOF
}

send_data() {
    sent=$('/usr/bin/curl' -s -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer '$API_KEY'' -d "$(generate_data)"  https://monitor.truestaking.com/alert) 
    if ! [[ $sent =~ "OK" ]]
    then logger "MCCM failed to send alert message to monitor.truestaking.com: $sent"
    fi
}

###############################
### Begin monitoring checks ###
###############################

### send is_alive message
logger "MCCM sending is alive message"
sent=$('/usr/bin/curl' -s -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer '$API_KEY'' -d '{}' https://monitor.truestaking.com/is_alive) 
if ! [[ $sent =~ "OK" ]]
then logger "MCCM failed to send heartbeat message to monitor.truestaking.com: $sent"
fi

### check process
if ! [[ $MONITOR_PROCESS =~ "true" ]]
then
    alert_type=process
    logger "MCCM service status checked"
    if ( ! systemctl is-active $MONITOR_PROCESS >/dev/null 2>&1 )
    then 
        alert_message="$MONITOR_PROCESS is dead"
        send_data
    fi
fi

### check CPU
if [[ $MONITOR_CPU =~ "true" ]]
then
    alert_type=cpu
    logger "MCCM checking load average" 
    load_check=$(echo "$cpu_load_avg > $peak_load_avg" | bc)
    if (( $load_check > 0 )) 
    then
        alert_message="CPU load avg is $cpu_load_avg"
        send_data
        logger "MCCM warning CPU load is $cpu_load_avg"
        
   fi
fi


### check NVME heat
if [[ $MONITOR_NVME_HEAT =~ "true" ]]
then
    alert_type=nvme_heat
    logger "MCCM NVME temperature checked"
    for i in `nvme list | grep dev | cut -f 1 -d " "`
    do
        high_temp_time=$(smartctl -a $i | grep "Warning  Comp. Temperature Time:" | cut -f 2 -d ":" | sed 's/[ \t]*//' | cut -f 1 -d "%" | cut -f 1 -d ".")
        if (( high_temp_time > 0 ))
	then
            alert_message="NVME heat alert $i"
            send_data 
            logger "MCCM NVME heat warning - use smartctl -a $i and view the Comp. Temperature Time"
        fi

    done
fi


### check NVME life span
if [[ $MONITOR_NVME_LIFESPAN =~ "true" ]]
then
    alert_type=nvme_lifespan
    logger "MCCM NVME lifespan checked"
    for i in `nvme list | grep dev | cut -f 1 -d " "`
    do
        used=$(smartctl -a $i | grep percentage_used | cut -f 2 -d ":" | sed 's/[ \t]*//' | cut -f 1 -d "%" | cut -f 1 -d ".")
        if (( used > 80 ))
        then
           alert_message="NVME lifespan warning $i"
           send_data
           logger "MCCM NVME warning - use smartctl -a $i to view remaining lifespan"
        fi
    done
fi


### check NVME selftest results
if [[ $MONITOR_NVME_SELFTEST =~ "true" ]]
then
    alert_type=nvme_selftest
    logger "MCCM NVME self test checked"
    for i in `nvme list | grep dev | cut -f 1 -d " "`
    do
        if ( ! smartctl -a $i | grep self-assessment | grep -q PASSED )
        then
            alert_message="NVME selftest failure $i"
            send_data
            logger "MCCM NVME warning - use smartctl -a $i to view selftest status"
        fi
    done
fi


### check disk space
if [[ $MONITOR_DRIVE_SPACE =~ "true" ]]
then
    alert_type=drive_space
    logger "MCCM disk space checked"
    ALERT=90
    used=$(df --output=pcent,target | grep -v snap | grep -v Mounted | sed "s/[ \t]*//" | cut -f 1 -d "%" | sort -n | tail -n 1)
    if(( $used >= $ALERT ))
    then 
        alert_message="drive space warning"
        send_data
        logger "MCCM disk space warning - use df -h to see available disk space"
    fi
fi
