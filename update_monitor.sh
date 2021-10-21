#!/bin/bash

source ./.env

user_input() {
case $ynq in
    [Yy]* ) echo "true";;
    [Nn]* ) echo "false";;
    [Qq]* ) echo "X";;
    * ) echo "Please select y/n/q ";
    esac
}
echo; echo

cat << "EOF"
 #   #                       #                                   ###           ##     ##            #                  
 ## ##   ###    ###   # ##   ####    ###    ####  ## #          #   #   ###     #      #     ####  ####    ###   # ##  
 # # #  #   #  #   #  ##  #  #   #  #####  #   #  # # #         #      #   #    #      #    #   #   #     #   #  ##    
 # # #  #   #  #   #  #   #  #   #  #      #  ##  # # #         #   #  #   #    #      #    #  ##   #     #   #  #     
 #   #   ###    ###   #   #  ####    ###    ## #  #   #          ###    ###    ###    ###    ## #    ##    ###   #     
                                                                                                                       
  ###                                        #     #                   #   #                  #     #                     #                 
 #   #   ###   ## #   ## #   #   #  # ##          ####   #   #         ## ##   ###   # ##          ####    ###   # ##          # ##    #### 
 #      #   #  # # #  # # #  #   #  ##  #    #     #     #   #         # # #  #   #  ##  #    #     #     #   #  ##       #    ##  #  #   # 
 #   #  #   #  # # #  # # #  #  ##  #   #    #     #      ####         # # #  #   #  #   #    #     #     #   #  #        #    #   #   #### 
  ###    ###   #   #  #   #   ## #  #   #    #      ##       #         #   #   ###   #   #    #      ##    ###   #        #    #   #      # 
                                                          ###                                                                          ###  
EOF
echo; echo;

cat << "EOF"

What is the Moonbeam Collator Community Monitoring? 

- It is the simple and effective operating system level monitoring used by True Staking.   
- Since we maintain the backend alerting functions already, we might as well share it with the rest of the collating team.
- No network connectivity except outbound https POST to an alerting server. 
- The MCCM service simply runs a shell script that checks various elements every 2 minutes and signals an alarm condition.
- You are alerted via Telegram.
- Basic. Simple. Essential. Free.

System Health Checks include  -- lack of block production, collator service status, network connectivity, disk space, nvme heat, nvme lifespan, nvme selftest, and cpu load average. 

You will need your collator public address and your telegram user name.

EOF

read -n1 -sp "Do you want to be alerted if your collator has failed to produce a block in the normal time window? [y/n/q] " ynq ; echo; echo
#MONITOR_PRODUCING_BLOCKS=$(user_input | tr -d '\n') && if(echo $ynq | grep -qi q); then exit; fi
MONITOR_PRODUCING_BLOCKS=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi

read -n1 -sp "Do you want to be alerted if your collator goes offline or loses network connectivity? [y/n/q] " ynq ; echo; echo
MONITOR_IS_ALIVE=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi

read -n1 -sp "Do you want to be alerted if the moonbeam process fails? [y/n/q] " ynq && if [[ $ynq =~ "q" ]]; then exit; fi ; echo; echo
service=false
if [[ $ynq =~ "y" ]]
  then
  if sudo systemctl is-active moonriver >/dev/null 2>&1; then service="moonriver"; fi
  if sudo systemctl is-active moonbase >/dev/null 2>&1; then service="moonbase"; fi
  if sudo systemctl is-active moonbeam >/dev/null 2>&1; then service="moonbeam"; fi

  shopt -s nocasematch; if [[ $service =~ "moon" ]]
    then echo "found service $service, enabling service check." ; echo ; echo
    MONITOR_PROCESS=$service
    else
    read -p "Please enter the service name you want to monitor? This is usually moonbase, moonriver, or moonbeam but we didn't see those running: " service_input ; service=$(echo $service_input | tr -d '\n');
    if (sudo systemctl is-active $service) ; then MONITOR_PROCESS=$service ; else MONITOR_PROCESS=0; echo "systemctl is-active $service failed, please check service name and rerun setup."; fi
  fi
else MONITOR_PROCESS=$service;
fi

read -n1 -sp "Do you want to be alerted if your CPU load average is overly high? (Note: we use 1/2 the CPU cores as the threshold) [y/n/q] " ynq; echo; echo
MONITOR_CPU=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi
if (echo $MONITOR_CPU | grep -qi y); then
  if ! sudo apt list --installed 2>/dev/null | grep -qi util-linux ; then
     sudo apt install util-linux
  fi
fi

read -n1 -sp "Do you want to be alerted for NVME drive high temperatures? [y/n/q] " ynq; echo; echo
MONITOR_NVME_HEAT=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi

read -n1 -sp "Do you want to be alerted when NVME drive reaches 80% of anticipated lifespan? [y/n/q] " ynq; echo; echo
MONITOR_NVME_LIFESPAN=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi

read -n1 -sp "Do you want to be alerted when an NVME drives fails the self-assessment check? [y/n/q] " ynq; echo; echo
MONITOR_NVME_SELFTEST=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi


read -n1 -sp "Do you want to be alerted when any drive reaches 90% capacity? [y/n/q] " ynq; echo; echo
MONITOR_DRIVE_SPACE=$(user_input | tr -d '\n') && if [[ $ynq =~ "q" ]]; then exit; fi

#if (echo MONITOR_NVME_HEAT | grep -qi y) || (echo MONITOR_NVME_LIFESPAN | grep -qi y) || (echo MONITOR_NVME_SELFTEST | grep -qi y); then
if echo $MONITOR_NVME_HEAT,$MONITOR_NVME_LIFESPAN,$MONITOR_NVME_SELFTEST | grep -qi true
then
  if ! sudo apt list --installed 2>/dev/null | grep -qi nvme-cli ; then
     sudo apt install nvme-cli
  fi
  if ! sudo apt list --installed 2>/dev/null | grep -qi smartmontools ; then
     sudo apt install smartmontools
  fi
fi

read -p "Please enter your telegram username (user names only consist of letters, numbers, and "_" character): " telegram_user_input ; TELEGRAM_USER=$(echo $telegram_user_input | tr -d '\n'); echo; echo

echo -n "Please enter a telegram chat with our bot and say hi! LINK: https://t.me/moonbeamccm_bot"
echo
echo -n "It is IMPORTANT you message the bot some kind of greeting, otherwise the bot cannot contact you with alert messages. After you have initiated the chat with our bot, press enter."
read;

RESP="$('/usr/bin/curl' -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer '$API_KEY'' -d '{"address": "'$COLLATOR_ADDRESS'", "telegram_username": "'$TELEGRAM_USER'", "monitor": {"process": "'$MONITOR_PROCESS'", "nvme_heat": '$MONITOR_NVME_HEAT', "nvme_lifespan": '$MONITOR_NVME_LIFESPAN', "nvme_selftest": '$MONITOR_NVME_SELFTEST', "drive_space": '$MONITOR_DRIVE_SPACE', "cpu": '$MONITOR_CPU', "is_alive": '$MONITOR_IS_ALIVE', "producing_blocks": '$MONITOR_PRODUCING_BLOCKS'}}' https://monitor.truestaking.com/update)"

echo $RESP

#NEED TO CHECK IF THE API  KEY IS A VALID API KEY, MAYBE RETURN SOMETHING LIKE "OK API_KEY" INSTEAD OF JUST "API_KEY" ?

echo -n "Please do not exit the chat with our telegram bot. If you do, you will not be able to receive alerts about your system. If you leave the chat please run update_account.sh"; echo ; echo
sudo mkdir -p /opt/moonbeam/monitor 2>&1 >/dev/null
sudo echo -ne "API_KEY=$API_KEY\nMONITOR_PRODUCING_BLOCKS=$MONITOR_PRODUCING_BLOCKS\nMONITOR_IS_ALIVE=$MONITOR_IS_ALIVE\nMONITOR_PROCESS=$MONITOR_PROCESS\nMONITOR_CPU=$MONITOR_CPU\nMONITOR_DRIVE_SPACE=$MONITOR_DRIVE_SPACE\nMONITOR_NVME_HEAT=$MONITOR_NVME_HEAT\nMONITOR_NVME_LIFESPAN=$MONITOR_NVME_LIFESPAN\nMONITOR_NVME_SELFTEST=$MONITOR_NVME_SELFTEST\nTELEGRAM_USER=$TELEGRAM_USER\nCOLLATOR_ADDRESS=$COLLATOR_ADDRESS" > /opt/moonbeam/monitor/.env



