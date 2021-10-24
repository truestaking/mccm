#!/bin/bash

DEST='/opt/moonbeam/mccm'
cd $DEST

################################
#### CONVENIENCE FUNCTIONS #####
################################

get_input() {
  printf "$1: " "$2" >&2; read -r answer
  if [ -z "$answer" ]; then echo "$2"; else echo "$answer"; fi
}

get_answer() {
  printf "%s (y/n): " "$*" >&2; read -n1 -r answer
  while : 
  do
    case $answer in
    [Yy]*)
      return 0;;
    [Nn]*)
      return 1;;
    *) echo; printf "%s" "Please enter 'y' or 'n' to continue: " >&2; read -n1 -r answer
    esac
  done
}

####################################
#### END CONVENIENCE FUNCTIONS #####
####################################

echo; echo

echo "If you wish to temporarily pause MCCM alerting, please use update_monitor.sh"
echo

echo "In MCCM, every server has a unique API KEY. If you continue with this script, it will remove the server account completely and delete the MCCM installation."
echo

if ! get_answer "Do you wish to continue and remove the server account and MCCM installation?"
then echo; exit;
fi
echo

if [ ! -f $DEST/env ]
  then
  echo "Cannot find MCCM config file!"
  API_KEY=$(get_input "please enter the server API KEY" );
  echo
  if ! [[ $API_KEY =~ [a-z] ]]
  then
    echo "We do not have a valid API key. Contact TrueStaking via discord or TG."
    exit;
  fi
else
  source $DEST/env
fi

if get_answer "Do you want to remove server account $API_KEY? "
  then 
  echo
  RESP="$('/usr/bin/curl' -s -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer '$API_KEY'' -d '{}' https://monitor.truestaking.com/delete_account)"
  if [[ $RESP =~ "OK" ]]
    then
      sudo systemctl stop mccm.timer
      sudo systemctl disable mccm.timer
      sudo systemctl stop mccm.service
      sudo systemctl disable mccm.service
      sudo rm /etc/systemd/system/mccm.timer
      sudo rm /etc/systemd/system/mccm.service
      sudo rm -rf /opt/moonbeam/mccm
      echo "Successs! MCCM account has been removed and the installation removed. "
    else
        echo "error was: $RESP"
        exit; exit
    fi
fi
