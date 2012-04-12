#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   t.ipa_uninstall.sh of /CoreOS/ipa-tests/acceptance/ipa-upgrade
#   Description: IPA multihost uninstall scripts
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following needs to be tested:
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
uninstall()
{
	ipa_uninstall_client
	ipa_uninstall_slave
	ipa_uninstall_master
}

ipa_uninstall_master()
{
	TESTORDER=$(( TESTORDER += 1 ))
	rlPhaseStartTest "ipa_uninstall_master: Uninstall IPA Master software"
	case "$MYROLE" in
	"MASTER")
		rlLog "Machine in recipe is MASTER"
		ipa_quick_uninstall
		[ -n $MASTER_IP ] && MASTER=$(dig +short -x $MASTER_IP|sed 's/\.$//g')

		if [ -f /var/log/ipaserver-uninstall.log ]; then
			DATE=$(date +%Y%m%d-%H%M%S)
			cp -f /var/log/ipaserver-uninstall.log /var/log/ipaserver-uninstall.log.$DATE
			rhts-submit-log -l /var/log/ipaserver-uninstall.log.$DATE
		fi
		rlRun "rhts-sync-set -s '$FUNCNAME.$TESTORDER' -m $MASTER_IP"
		;;
	"SLAVE")
		rlLog "Machine in recipe is SLAVE"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER' $MASTER_IP"
		;;
	"CLIENT")
		rlLog "Machine in recipe is CLIENT"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER' $MASTER_IP"
		;;
	*)
		rlLog "Machine in recipe is not a known ROLE...set MYROLE variable"
		;;
	esac
	rlPhaseEnd
}

ipa_uninstall_slave()
{
	TESTORDER=$(( TESTORDER += 1 ))
	rlPhaseStartTest "ipa_uninstall_slave: Uninstall IPA Replica/Slave Software"
	case "$MYROLE" in
	"MASTER")
		rlLog "Machine in recipe is MASTER"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.1' $SLAVE_IP"
		rlRun "ipa host-del $SLAVE_S.$DOMAIN --updatedns"
		rlRun "rhts-sync-set -s '$FUNCNAME.$TESTORDER.2' -m $MASTER_IP"
		;;
	"SLAVE")
		rlLog "Machine in recipe is SLAVE"
		ipa_quick_uninstall
		[ -n $SLAVE_IP ] && SLAVE=$(dig +short -x $SLAVE_IP|sed 's/\.$//g')

		if [ -f /var/log/ipaserver-uninstall.log ]; then
			DATE=$(date +%Y%m%d-%H%M%S)
			cp -f /var/log/ipaserver-uninstall.log /var/log/ipaserver-uninstall.log.$DATE
			rhts-submit-log -l /var/log/ipaserver-uninstall.log.$DATE
		fi
		rlRun "rhts-sync-set -s '$FUNCNAME.$TESTORDER.1' -m $SLAVE_IP"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.2' $MASTER_IP"
		;;
	"CLIENT")
		rlLog "Machine in recipe is CLIENT"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.1' $SLAVE_IP"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.2' $MASTER_IP"
		;;
	*)
		rlLog "Machine in recipe is not a known ROLE...set MYROLE variable"
		;;
	esac
	rlPhaseEnd
}

ipa_uninstall_client()
{
	TESTORDER=$(( TESTORDER += 1 ))
	rlPhaseStartTest "ipa_uninstall_client: Uninstall IPA Client Software"
	case "$MYROLE" in
	"MASTER")
		rlLog "Machine in recipe is MASTER"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.1' $CLIENT_IP"
		rlRun "ipa host-del $CLIENT_S.$DOMAIN --updatedns"
		rlRun "rhts-sync-set -s '$FUNCNAME.$TESTORDER.2' -m $MASTER_IP"
		;;
	"SLAVE")
		rlLog "Machine in recipe is SLAVE"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.1' $CLIENT_IP"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.2' $MASTER_IP"
		;;
	"CLIENT")
		rlLog "Machine in recipe is CLIENT"
		ipa_quick_uninstall

		yum -y downgrade curl nss* openldap* libselinux* nspr* libcurl*
		yum -y remove http*

		[ -n $CLIENT_IP ] && CLIENT=$(dig +short -x $CLIENT_IP|sed 's/\.$//g')
		rlRun "rhts-sync-set -s '$FUNCNAME.$TESTORDER.1' -m $CLIENT_IP"
		rlRun "rhts-sync-block -s '$FUNCNAME.$TESTORDER.2' $MASTER_IP"
		;;
	*)
		rlLog "Machine in recipe is not a known ROLE...set MYROLE variable"
		;;
	esac
	rlPhaseEnd
}
