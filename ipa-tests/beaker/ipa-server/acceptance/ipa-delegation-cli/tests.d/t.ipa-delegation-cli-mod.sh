#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   t.ipa-delegation-cli-mod.sh of /CoreOS/ipa-tests/acceptance/ipa-delegation-cli
#   Description: IPA delegation cli command acceptance tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following ipa delegation cli commands need to be tested:
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

######################################################################
#   delegation-mod [positive]:
######################################################################
delegation_mod_positive()
{
	delegation_mod_positive_envsetup
	delegation_mod_positive_1001
	delegation_mod_positive_envcleanup
}

delegation_mod_positive_envsetup()
{
	rlPhaseStartTest "delegation_mod_positive_envsetup: "
		KinitAsAdmin
	rlPhaseEnd
}

delegation_mod_positive_envcleanup()
{
	rlPhaseStartTest "delegation_mod_positive_envcleanup: "
		KinitAsAdmin
	rlPhaseEnd
}

delegation_mod_positive_1001()
{
	rlPhaseStartTest "delegation_mod_positive_1001: delete existing delegation"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
#       NAME1
		[ -f $tmpout ] && rm $tmpout
	rlPhaseEnd
}

######################################################################
#   delegation-mod [negative]:
######################################################################
delegation_mod_negative()
{
	delegation_mod_negative_envsetup
	delegation_mod_negative_1001
	delegation_mod_negative_envcleanup
}


delegation_mod_negative_envsetup()
{
	rlPhaseStartTest "delegation_mod_negative_envsetup: "
		KinitAsAdmin
	rlPhaseEnd
}

delegation_mod_negative_envcleanup()
{
	rlPhaseStartTest "delegation_mod_negative_envcleanup: "
		KinitAsAdmin
	rlPhaseEnd
}

delegation_mod_negative_1001()
{
	rlPhaseStartTest "delegation_mod_negative_1001: fail to delete non-existent delegation"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
#       badname
		[ -f $tmpout ] && rm $tmpout
	rlPhaseEnd
}
