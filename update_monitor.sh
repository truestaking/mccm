#!/bin/bash

source ./.env

RESP="$('/usr/bin/curl' -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer '$API_KEY'' -d '{"active": "false"}' https://monitor.truestaking.com/update)"
