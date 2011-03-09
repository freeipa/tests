######################################
#  	fix /etc/hosts		     #
######################################
fixHostFile()
{
    HOSTSFILE="/etc/hosts"
    rm -f $HOSTSFILE.ipabackup
    cp -af $HOSTSFILE $HOSTSFILE.ipabackup
    
    # figure out what my active eth is from the machine's route
    currenteth=$(route | grep ^default | awk '{print $8}')

    # get the ip address of that interface
    ipaddr=$(ifconfig $currenteth | grep inet\ addr | sed s/:/\ /g | awk '{print $3}')
    rlLog "Ip address is $ipaddr"

    # Now, fix the hosts file to work with IPA.
    hostname=$(hostname)
    hostname_s=$(hostname -s)
    cat /etc/hosts | grep -v ^$ipaddr > /dev/shm/hosts
 
    # Remove any existing hostname entries from the hosts file
    sed -i s/$hostname//g /dev/shm/hosts
    sed -i s/$hostname_s//g /dev/shm/hosts
    echo "$ipaddr $hostname_s.$DOMAIN $hostname $hostname_s" >> /dev/shm/hosts
    cat /dev/shm/hosts > /etc/hosts
    rlLog "Hosts file contains:"
    output=`cat /etc/hosts`
    rlLog "$output"

    return
}

######################################
#       fix hostname                 #
######################################
fixhostname()
{
    hostname_s=$(hostname -s)

    # Fix hostname
    rlRun "hostname $hostname_s.$DOMAIN"
    hostname $hostname_s.$DOMAIN
    cat /etc/sysconfig/network | grep -v $hostname_s > /dev/shm/network
    echo "HOSTNAME=$hostname_s.$DOMAIN" >> /dev/shm/network
    mv /etc/sysconfig/network /etc/sysconfig/network-ipabackup
    cat /dev/shm/network > /etc/sysconfig/network
    rlLog "/etc/sysconfig/network contains:"
    output=`cat /etc/sysconfig/network`
    rlLog "$output"

    return
}

#####################################
#  	fix resolv.conf             #
#####################################
fixResolv()
{
   rlLog "Fixing resolv.con to point to master"

   # get the Master's IP address
   ipaddr=$(dig +noquestion $MASTER  | grep $MASTER | grep IN | awk '{print $5}')
   rlLog "MASTER IP address is $ipaddr"
   sed -i s/^nameserver/#nameserver/g /etc/resolv.conf
   echo "nameserver $ipaddr" >> /etc/resolv.conf
   rlLog "/etc/resolv.conf contains:"
   output=`cat /etc/resolv.conf`
   rlLog "$output"

   return
}

######################################
#       Append env.sh                #
######################################
appendEnv()
{
  ipaddr=$(dig +noquestion $MASTER  | grep $MASTER | grep IN | awk '{print $5}')
  # Adding MASTER and SLAVE bits to env.sh
  master_short=`echo $MASTER | cut -d "." -f1`
  slave_short=`echo $SLAVE | cut -d "." -f1`
  client_short=`echo $CLIENT | cut -d "." -f1`
  MASTER=$master_short.$DOMAIN
  SLAVE=$slave_short.$DOMAIN
  CLIENT=$client_short.$DOMAI
  echo "export MASTER=$MASTER" >> /dev/shm/env.sh
  echo "export MASTERIP=$ipaddr" >> /dev/shm/env.sh
  echo "export SLAVE=$SLAVE" >> /dev/shm/env.sh
  echo "export CLIENT=$CLIENT" >> /dev/shm/env.sh
  rlLog "Contents of env.sh are"
  output=`cat /dev/shm/env.sh`
  rlLog "$output"

  return
}


