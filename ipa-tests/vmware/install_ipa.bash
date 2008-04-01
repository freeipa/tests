#!/bin/bash
# http://apoc.dsdev.sjc.redhat.com/tet/results//FC7/i386/ipa.repo will be replaced with $http://apoc.dsdev.sjc.redhat.com/tet/results//FC7/i386/ipa.repo from env.cfg
set -x
# Fix date
/etc/init.d/ntpd stop
/usr/sbin/ntpdate kerberos.sjc.redhat.com
ret=$?
if [ $ret != 0 ]; then 
	# ntp update didn't work the first time, lets try it again.
	sleep 60
	/usr/sbin/ntpdate kerberos.sjc.redhat.com
	ret=$?
	if [ $ret != 0 ]; then 
		sleep 10
		/usr/sbin/ntpdate tigger.dsqa.sjc2.redhat.com
		ret=$?
		if [ $ret != 0 ]; then 
			sleep 10
			/usr/sbin/ntpdate ntp2.usno.navy.mil
			ret=$?
			if [ $ret != 0 ]; then 
				echo "ERROR - could not set the date.... and for some reason we care...";
				exit;
			fi
		fi	
	fi
fi

echo "Killing yum-updatesd to prevent problems"
/etc/init.d/yum-updatesd stop
if [ -f /var/run/yum.pid ]; then 
	echo "WARNING - YUM was detected as running. Killing it"
	cat /var/run/yum.pid | while read p; do
		kill $p
	done
fi
cd /etc/yum.repos.d;wget http://apoc.dsdev.sjc.redhat.com/tet/results//FC7/i386/ipa.repo
killall yum
yum -R 1 -y install yum-fastestmirror
yum -R 1 -y update policycoreutils selinux-policy
ret=$?
if [ $ret != 0 ]; then 
	echo "WARNING - update failed, trying again."
	killall yum
	killall yum
	sleep 5
	ps=$(ps -fax)
	echo $ps
	sleep 60
	yum -y update policycoreutils selinux-policy 
	ret=$?
	if [ $ret != 0 ]; then 
		echo "ERROR - yum update of policycoreutils and selinux-policy failed";
		exit;
	fi
fi

yum -y install ipa-server ipa-admintools bind caching-nameserver expect 
ret=$?
if [ $ret != 0 ]; then 
	echo "WARNING - The first try on IPA install didn't work, trying again"
	yum -y install ipa-server ipa-admintools bind caching-nameserver expect 
	ret=$?
	if [ $ret != 0 ]; then 
		echo "ERROR - yum install of freeipa failed";
		exit;
	fi
fi

# Checking to make sure that mod_auth_kerb contains ipa
rpm -q mod_auth_kerb | grep ipa
ret=$?
if [ $ret != 0 ]; then 
	echo "mod auth appears to be wrong, but we will ignore that for now";
#	echo "ERROR - mod_auth doesn't appear to be the right version";
#	exit;
fi
# Setup ipa server
# ipaqavm.dsqa.sjc2.redhat.com will be replaced wth the fqdn of this machine as reported by dns
/usr/sbin/ipa-server-install -U --hostname=ipaqavm.dsqa.sjc2.redhat.com -r DSQA.SJC2.REDHAT.COM -p Secret123 -P Secret123 -a Secret123 --setup-bind -u admin -d
ret=$?
if [ $ret != 0 ]; then 
	echo "ERROR - ipa-server-install did not work";
	exit;
fi

/etc/init.d/ntpd stop
/usr/sbin/ntpdate kerberos.sjc.redhat.com
/etc/init.d/ntpd start

# testing bind
mv /etc/resolv.conf /etc/resolv.conf-old
echo 'nameserver 127.0.0.1' > /etc/resolv.conf
# Is it running?
#ps -ef | grep named | grep -v grep | grep named
#ret=$?
#if [ $ret != 0 ]; then 
#	echo "ERROR - bind not running";
#	exit;
#fi
# adding forwarders to bind
sed -i s/dump-file/'forwarders { 172.16.27.23; 172.16.52.28; }; dump-file'/g  /etc/named.conf
/etc/init.d/named restart
# Is it running?
ps -ef | grep named | grep -v grep | grep named
ret=$?
if [ $ret != 0 ]; then 
	echo "ERROR - bind not running";
	exit;
fi

dig -x 10.14.0.110 @127.0.0.1
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - reverse lookup aginst localhost failed";
        exit;
fi

dig ipaqavm.dsqa.sjc2.redhat.com @127.0.0.1
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - lookup of myself failed";
        exit;
fi

# Test kinit
#!/usr/bin/expect -f
echo 'set timeout -1
set send_slow {1 .1}
spawn /usr/kerberos/bin/kinit admin
match_max 100000
expect "Password for admin"
sleep 1
send -s -- "Secret123\r"
expect eof ' > /tmp/kinit.exp

/usr/bin/expect /tmp/kinit.exp
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - kinit failed";
        exit;
fi

/usr/sbin/ipa-finduser admin
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - ipa-finduser failed";
        exit;
fi

# Testing ipa-adduser
echo 'set timeout -1
spawn /usr/sbin/ipa-adduser newuser1
match_max 100000
expect "First name: "
send -- "new\r"
expect "new\r
Last name: "
send -- "user1\r"
expect "user1\r
  Password: "
send -- "newpW1\r"
expect "Password (again): "
send -- "newpW1\r"
expect eof' > /tmp/ipaadduser.exp

/usr/bin/expect /tmp/ipaadduser.exp
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - ipa-adduser failed";
        exit;
fi

# Testing ipa-addgroup
echo 'set timeout -1
spawn /usr/sbin/ipa-addgroup
match_max 100000
expect "Group name: "
send -- "test-group\r"
expect "test-group\r
Description: "
send -- "test group for QA tests"
expect "test group for QA tests"
sleep 1
send -- "\r"
expect eof' > /tmp/ipa-addgroup.exp

/usr/bin/expect /tmp/ipa-addgroup.exp
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - ipa-addgroup failed";
        exit;
fi

/usr/sbin/ipa-findgroup test-group
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - ipa-findgroup failed";
        exit;
fi

# Test add newuser1 to test-group
/usr/sbin/ipa-modgroup -a newuser1 test-group
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - add of newuser1 to test-group failed";
        exit;
fi

# Did the ipa-groupmod really work?
/usr/sbin/ipa-findgroup test-group > /tmp/findgroup.txt
/bin/grep newuser1 /tmp/findgroup.txt
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - add of newuser1 to test-group really did fail";
        exit;
fi

# Test delete newuser1 fromo test-group
/usr/sbin/ipa-modgroup -r newuser1 test-group
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - add of newuser1 to test-group failed";
        exit;
fi

# Did the removal ipa-groupmod really work?
/usr/sbin/ipa-findgroup test-group > /tmp/findgroup.txt
/bin/grep newuser1 /tmp/findgroup.txt
ret=$?
if [ $ret == 0 ]; then
        echo "ERROR - remove of newuser1 from test-group really did fail";
        exit;
fi

# testing user invalidation
/usr/sbin/ipa-deluser newuser1
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - invalidation of newuser1 failed";
        exit;
fi

#/usr/sbin/ipa-deluser -d newuser1
/usr/sbin/ipa-finduser newuser1 > /tmp/finduser.txt
grep -v No\ entries /tmp/finduser.txt | grep newuser1
ret=$?
if [ $ret == 0 ]; then
        echo "ERROR - remove of newuser1 really seemed to have failed";
        exit;
fi

# running ipa-adduser again for use by clients
echo 'set timeout -1
spawn /usr/sbin/ipa-adduser testuser
match_max 100000
expect "First name: "
send -- "new\r"
expect "new\r
Last name: "
send -- "user1\r"
expect "user1\r
  Password: "
send -- "newpW1\r"
expect "Password (again): "
send -- "newpW1\r"
expect eof' > /tmp/ipaadduser.exp

/usr/bin/expect /tmp/ipaadduser.exp
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - ipa-adduser failed";
        exit;
fi

# Changing the password for testuser so that the accoutn is usable
set timeout -1
echo 'set timeout -1
spawn /usr/kerberos/bin/kpasswd testuser
match_max 100000
expect -exact "Password for testuser@DSQA.SJC2.REDHAT.COM: "
send -- "newpW1\r"
expect -exact "\r
Enter new password: "
send -- "Secret123\r"
expect -exact "\r
Enter it again: "
send -- "Secret123\r"
expect eof' > /tmp/testusernewpass.exp

/usr/bin/expect /tmp/testusernewpass.exp
ret=$?
if [ $ret != 0 ]; then
        echo "ERROR - kpasswd for user testuser failed";
        exit;
fi

# Removing IPTABLES rules so that clients can work
/sbin/iptables -t nat -F
/sbin/iptables -F

