#!/bin/bash
### test_location.sh ###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
# DESCRIPTION:  This script is used to test that a system is reaching the 
#               internet through a VPN connection.  To be more precise, it is 
#               actually just testing to ensure that the IP a system is reaching
#               the internet from is NOT a location specified in badLocation. If
#               the test fails, this script will attempt to restart the VPN 
#               service maxTries times and reboot it in the extreme case that 
#               restarting the VPN service is not sufficient.
#
#               In addition to testing the connectivity of the system, it will 
#               also ensure any docker containers running on the system are also
#               accessing the internet NOT FROM badLocation and restart them if 
#               so.
# DEPENDANCY:   A VPN must be configured otherwise this script will continue to 
#               reboot the system.
# RESULT:       Assurance that system and any running containers will be 
#               accessing the internet from a location other than specified in
#               the badLocation variable.
# USE:		    It is likely that this will be called in a cronjob so that it is
#               run routinely on a system. 
# REFERENCE:    N/A
# CONTACT:      dswhitley@gmail.com [2018-04-17]
#------------------------------------------------------------------------------#
## these global variables can be used throughout ##++++++++++++++++++++++++++++#
badLocation="Raleigh";
maxTries="5";
sleepTime="5";
internetTest="8.8.8.8";
logFile="/root/vpn.log"; # this will need to be changed if viewed by container
restartVpnCmd="";
tries="0";

## these variables will be used for errors and messages ##+++++++++++++++++++++#
#eHeader="#-! $(date +%Y-%m-%d:%H:%M:%S) | [$tries] ";
eSysNoInternet="Unable to ping $internetTest...waiting...";
eSysUnkLocation="Unable to determine location of IP ($IP)...restarting VPN";
eSysBadLocation="Bad location ($location)...restarting VPN";
eCntrBadLocation="Bad location ($location) in $cntrName...restarting $cntrName";


## GETTING STARTED with main() ##++++++++++++++++++++++++++++++++++++++++++++++#
main() {
  while [[ $tries -lt $maxTries ]]; do
    if !testInternet; then
      printError $eSysNoInternet | /usr/bin/tee -a $logFile;
      exit $returnCode;
    fi
    getLocation
    if [[ -z $location ]]; then
      printError $eSysUnkLocation | /usr/bin/tee -a $logFile;
      restartVpn
      (( tries++ ));  
      sleep $sleepTime;
    elif [[ "$location" =~ "$badLocation" ]]; then
      printError $eSysBadLocation | /usr/bin/tee -a $logFile;
      restartVpn
      (( tries++ ));  
      sleep $sleepTime;
    elif dockerInstalled; then
      for cntrName in $(docker ps --format '{{.Names}}'); do 
        getCntrLocation $cntrName;
        if [[ "$cntrLocation" =~ "$badLocation" ]]; then
          printError eCntrBadLocation | /usr/bin/tee -a $logFile;
          docker restart $cntrName
        fi
        (( tries++ ));  
        sleep $sleepTime;
      done;
    else 
      break;
    fi;
  done;

  exit $returnCode;
}; export -f main; ##> end of main() -------------------------------------------

main "$@"
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<### test_location.sh ###

On the NAS it looks like I'll have to just run a cron job...

But I have have the script write out a log file and then have a container to display it?

1) check to see if internet is accessible
2) check to see if the host IP goes through VPN; restart service if not AND restart all containers
3) check each container to see if IP is through VPN; restart container if not

root@htpc:/bigboy/data# for CONTAINER in $(docker ps --format '{{.Names}}'); do echo -en "#| $CONTAINER:\t"; docker exec $CONTAINER curl -ks https://www.dnsleaktest.com | awk '/flag/ {gsub(",","",$2); print $2}'; done

root@htpc:/bigboy/data# crontab -l
#Ansible: None
*/10 * * * * /root/check_vpn.sh
You have new mail in /var/mail/root
root@htpc:/bigboy/data# cat /root/check_vpn.sh 
#!/bin/bash
# This script will check to see if the system is getting network connectivity 
# through the VPN.  If the network is either inaccessible or if the IP I am 
# talking out of is in Raleigh, I will attempt to restart openvpn a set number
# of times and then reboot.  Sort of extreme, but it should come back up with 
# the correct network information.  
##
# This script will likely be called from a cronjob

max_tries="5";
tries="0";
bad_location="Raleigh";

restart_vpn_cmd="";

while [[ $tries -lt $max_tries ]]; do
  location=$(curl -ks https://www.dnsleaktest.com | awk '/flag/ {gsub(",","",$2); print $2}');
  if [[ -z $location ]]; then
    echo "#-! $(date +%Y-%m-%d:%H:%M:%S) | [$tries] Unable to determine location...restarting VPN" >> /root/vpn.log;
    #systemctl restart openvpn; # for some reason this isn't working
    /usr/sbin/openvpn /etc/openvpn/client.conf &
    (( tries++ ));  sleep 5;
  elif [[ "$location" =~ "$bad_location" ]]; then
    echo "#-! $(date +%Y-%m-%d:%H:%M:%S) | [$tries] Bad location ($location)...restarting VPN" >> /root/vpn.log;
    /usr/sbin/openvpn /etc/openvpn/client.conf &
    (( tries++ ));  sleep 5;
  else 
    break;
  fi;
done;

# at this point, we've attempted to restart the VPN a few times...reboot!
if [[ $tries -eq $max_tries ]]; then
  echo "#-! $(date +%Y-%m-%d:%H:%M:%S) | The VPN has been restarted $tries times yet it is not working.  Rebooting!" >> /root/reboot.log;
  # configure rc.local to send an email when the system comes back online:
  echo "echo -e \"Subject: htpc rebooted - $(date)\r\n\r\n$(tail -n1 /root/reboot.log)\" | /usr/sbin/sendmail -F htpc camellia.email@gmail.com" >> /etc/rc.local;
  echo "sed -i '/email/d' /etc/rc.local;" >> /etc/rc.local;
  /sbin/reboot;
fi;

exit;
root@htpc:/bigboy/data# 