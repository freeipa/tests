#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/ipa-tests/acceptance/ipa-winsync
#   Description: winsync test cases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following ipa will be tested:
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Steeve Goveas <sgoveas@redhat.com>
#   Date  : June 14, 2012
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
. /dev/shm/env.sh

# Include test case file
. ./t.ipa-winsync.sh

PACKAGE="ipa-server"

##########################################
#   Sanity Tests
#########################################

	winsync_connect() {
		"winsync_connect_0001"
	}

	#TODO tests

	winsync_disconnect() {
		""
	}

rlJournalStart

    rlPhaseStartSetup "ipa-winsync-startup: Check for admintools package, setup certificates."
		rlRun "setup"
    rlPhaseEnd

	# tests start...
winsync_connect
#TODO
#winsync_disconnect
	# tests end.

    rlPhaseStartCleanup "ipa-winsync-cleanup: Destroying admin credentials & removing certificates."
		rlRun "cleanup"
    rlPhaseEnd


rlJournalPrintText
report=/tmp/rhts.report.$RANDOM.txt
makereport $report
rhts-submit-log -l $report
rlJournalEnd