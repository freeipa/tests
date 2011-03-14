#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/ipa-server/acceptance/quickinstall
#   Description: Quick install for master slave and client acceptance tests
#   Author: Jenny Galipeau <jgalipea@redhat.com>
#
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

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh
. /dev/shm/ipa-server-shared.sh
. /dev/shm/env.sh
. ./install-lib.sh

# include tests
. ./t-install.sh

SERVER_PACKAGES="ipa-server ipa-client ipa-admintools ds-replication bind expect krb5-workstation bind-dyndb-ldap ntpdate krb5-pkinit-openssl ds-replication"
CLIENT_PACKAGES="ipa-admintools ipa-client httpd mod_nss mod_auth_kerb 389-ds-base expect"

rlJournalStart
        myhostname=`hostname`
        rlLog "hostname command: $myhostname"
        rlLog "HOSTNAME: $HOSTNAME"
        rlLog "MASTER: $MASTER"
        rlLog "SLAVE: $SLAVE"
        rlLog "CLIENT: $CLIENT"

	#####################################################################
	# 		IS THIS MACHINE A MASTER?                           #
	#####################################################################
	rc=0
	echo $MASTER | grep $HOSTNAME
	if [ $? -eq 0 ] ; then
		yum -y install $SERVER_PACKAGES
		for item in $SERVER_PACKAGES ; do
			rpm -qa | grep $item
			if [ $? -eq 0 ] ; then
				rlLog "$item package is installed"
			else
				rlLog "ERROR: $item package is NOT installed"
				rc=1
			fi
		done

		if [ $rc -eq 0 ] ; then
			installMaster
			rhts-sync-set -s READY
		fi
	else
		rlLog "Machine in recipe in not a MASTER"
	fi

	#####################################################################
	# 		IS THIS MACHINE A SLAVE?                            #
	#####################################################################
	rc=0
        echo $SLAVE | grep $HOSTNAME
        if [ $? -eq 0 ] ; then
		yum -y install $SERVER_PACKAGES
                for item in $SERVER_PACKAGES ; do
                        rpm -qa | grep $item
                        if [ $? -eq 0 ] ; then
                                rlLog "$item package is installed"
                        else
                                rlLog "ERROR: $item package is NOT installed"
                                rc=1
                        fi
                done

		if [ $rc -eq 0 ] ; then
			rhts-sync-block -s READY $MASTER
                	installSlave
        	fi
        else
                rlLog "Machine in recipe in not a SLAVE"
        fi

	#####################################################################
	# 		IS THIS MACHINE A CLIENT?                           #
	#####################################################################
	rc=0
        echo $CLIENT | grep $HOSTNAME
        if [ $? -eq 0 ] ; then
		yum -y install $CLIENT_PACKAGES
                for item in $CLIENT_PACKAGES ; do
		rpm -qa | grep $item
                        if [ $? -eq 0 ] ; then
                                rlLog "$item package is installed"
                        else
                                rlLog "ERROR: $item package is NOT installed"
                                rc=1
                        fi
                done

		if [ $rc -eq 0 ] ; then
                        rhts-sync-block -s READY $MASTER
                	installClient
        	fi
        else
                rlLog "Machine in recipe in not a CLIENT"
        fi

   rlJournalPrintText
   report=/tmp/rhts.report.$RANDOM.txt
   makereport $report
   rhts-submit-log -l $report
rlJournalEnd

