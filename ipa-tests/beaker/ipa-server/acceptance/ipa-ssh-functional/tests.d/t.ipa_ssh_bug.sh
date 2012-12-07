#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   t.ipa_ssh_bug.sh of /CoreOS/ipa-tests/acceptance/ipa-ssh-functional
#   Description: IPA Functional SSH Bug Tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following needs to be tested:
#
### host key functional test
# ipa_ssh_bug_bz799928 - [RFE] Hash the hostname/port information in
#                        the known_hosts file.
#   
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Scott Poore <spoore@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

######################################################################
# variables
######################################################################
### Relies on MYROLE variable to be set appropriately.  This is done
### manually or in runtest.sh
######################################################################

######################################################################
# test suite
######################################################################
ipa_ssh_bug_run()
{
	ipa_ssh_bug_bz799928 # Hash the hostname/port information in the known_hosts file.
}

ipa_ssh_bug_bz799928()
{
	TESTCOUNT=$(( TESTCOUNT += 1 ))
	BKRRUNHOST=$(eval echo \$BEAKERMASTER_env${MYENV})
	rlPhaseStartTest "ipa_ssh_bug_bz799928 - Hash the hostname/port information in the known_hosts file."
		case "$MYROLE" in
		MASTER*)
			rlLog "Machine in recipe is MASTER ($(hostname))"
			rlRun "KinitAsAdmin"
			rlRun "authconfig --enablemkhomedir --updateall"

expect <<-EOF
set timeout 3
set force_conservative 0
set send_slow {1 .1}
spawn ssh admin@${MASTER} -q -o StrictHostKeyChecking=no echo 'login successful'
send -s -- "${ADMINPW}\r"
expect eof
EOF

			knownhost="$(ssh-keygen -H -F rhel6-1.testrelm.com -f /var/lib/sss/pubconf/known_hosts |grep ssh-rsa)"
			hostname=$(hostname)
			key=$(echo ${knownhost:3:28} | base64 -d | xxd -ps)
			mac1=$(echo ${knownhost:32:28} | base64 -d | xxd -ps)
			mac2=$(echo -n $hostname | openssl dgst -sha1 -mac HMAC -macopt hexkey:$key | awk '{ print $2 }')
			if [ $mac1 = $mac2 ]; then
				rlPass "BZ 799928 fixed.  sssd known_hosts file using hashes"
			else
				rlFail "BZ 799928 not working."
				rlFail "sssd known_hosts file not using hashes or do not match"
			fi

			rlRun "rhts-sync-set -s '$FUNCNAME.$TESTCOUNT' -m $BKRRUNHOST"
			;;
		REPLICA*)
			rlLog "Machine in recipe is REPLICA ($(hostname))"
			rlRun "authconfig --enablemkhomedir --updateall"
			rlRun "rhts-sync-block -s '$FUNCNAME.$TESTCOUNT' $BKRRUNHOST"
			;;
		CLIENT*)
			rlLog "Machine in recipe is CLIENT ($(hostname))"
			rlRun "authconfig --enablemkhomedir --updateall"
			rlRun "rhts-sync-block -s '$FUNCNAME.$TESTCOUNT' $BKRRUNHOST"
			;;
		*)
			rlLog "Machine in recipe is not a known ROLE...set MYROLE variable"
			;;
		esac
	rlPhaseEnd
}