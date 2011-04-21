#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/ipa-tests/acceptance/nis-cli
#   Description: IPA nis-cli acceptance tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following ipa will be tested:
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Michael Gregg <mgregg@redhat.com>
#   Date  : Sept 10, 2010
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
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

# Include data-driven test data file:

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh
. /dev/shm/ipa-server-shared.sh
. /dev/shm/ipa-netgroup-cli-lib.sh
. /dev/shm/env.sh

# Include test case file
. ./t.nistests.sh

rlJournalStart
        myhostname=`hostname`
        rlLog "hostname command: $myhostname"
        rlLog "HOSTNAME: $HOSTNAME"
        rlLog "MASTER: $MASTER"
        rlLog "SLAVE: $SLAVE"
        rlLog "CLIENT: $CLIENT"

        #####################################################################
        #               IS THIS MACHINE A MASTER?                           #
        #####################################################################
        rc=0
        echo $MASTER | grep $HOSTNAME
        rc=$?
        if [ $rc -eq 0 ] ; then
		pwdfile=/dev/shm/password.txt
		echo $ADMINPW > $pwdfile
		yum -y install rpcbind
        	ipa-compat-manage -y $pwdfile enable
        	rlRun "ipa-nis-manage -y $pwdfile enable" 0 "Enable the NIS plugin"
        	/etc/init.d/rpcbind restart
        	/etc/init.d/dirsrv restart
		setup
        	runtests
        	cleanup
        else
                rlLog "Machine in recipe is not the MASTER - not running setup"
        fi

	rhts-sync-set -s READY

        #####################################################################
        #               IS THIS MACHINE A SLAVE?                           #
        #####################################################################
        rc=0
        echo $SLAVE | grep $HOSTNAME
        rc=$?
        if [ $rc -eq 0 ] ; then
		rhts-sync-block -s READY $MASTER
		setup
		runtests
		cleanup
		rhts-sync-set -s READY
	fi

        #####################################################################
        #               IS THIS MACHINE A CLIENT?                           #
        #####################################################################
        rc=0
        echo $CLIENT | grep $HOSTNAME
        rc=$?
        if [ $rc -eq 0 ] ; then
                rhts-sync-block -s READY $SLAVE
                setup
                runtests
                cleanup
        fi

   rlJournalPrintText
   report=/tmp/rhts.report.$RANDOM.txt
   makereport $report
   rhts-submit-log -l $report
rlJournalEnd

