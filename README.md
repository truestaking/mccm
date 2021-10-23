# Moonbeam Collator Community Monitoring
brought to you by [True Staking](https://truestaking.com)

## What is it?

Just basic Linux server monitoring. Sometimes, the simplest solution is the best solution. For all the trends, graphs, metrics, statistics you might need, there is Prometheus. For knowing your server has no issues, there is MCCM. We already maintain the solution and use it ourselves, so we might as well share it with the community.

It is free for the collator community. 

In a nutshell, we create a service (mccm.service) triggered every 2 minutes by mccm.timer. You select what you want to monitor, and the checks are run every 2 minutes. At the beginning of each check series, an "I'm alive" message is sent (https via curl) to the backend server. When a check fails (should be rare, right?) an additional outbound https call via curl to monitor.truestaking.com submits the alert, and our backend forwards the alert to you via telegram or email.

Note: If the backend server doesn't receive an "I'm alive" message from your collator within 5 minutes, then it sends the "Is Alive Error" alert.

Server checks include:
- block production warning
- collator service status
- loss of network connectivity
- disk space
- nvme heat, lifespan, and selftest
- cpu load average

If you want to use a commercial service like iLert -- just create an email rule to forward email from monitor.truestaking.com to your call out service.

Feedback is welcome, and we hope this benefits the Moonbeam Collator Community!

## Install 

To install, run:
```
curl -s https://raw.githubusercontent.com/truestaking/mccm/main/setup.sh > setup.sh;
chmod +x ./setup.sh;
./setup.sh;
```

Installing creates the folder structure:
```
/opt/moonbeam/mccm        # Top level folder
...
- env                     # Environment variables
- monitor.sh              # Monitor script ran every 2 minutes by mccm.service, triggered by mccm.timer
- update_monitor.sh       # Update script used to start/stop monitoring and change local and remote variables 
```
