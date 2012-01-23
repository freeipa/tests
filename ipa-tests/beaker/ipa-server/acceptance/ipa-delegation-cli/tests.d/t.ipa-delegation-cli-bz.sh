#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   t.ipa-delegation-cli-bz.sh of /CoreOS/ipa-tests/acceptance/ipa-delegation-cli
#   Description: IPA delegation cli BZ acceptance tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following ipa BZ's need to be tested:
#  BZ 783307 -- ipa delegation-add is not failing when membergroup does not exist
#  BZ 783473 -- ipa delegation-find --membergroup= with no value returns internal error
#  BZ 783475 -- ipa delegation-find --membergroup="" with no value returns internal error
#  BZ 783489 -- ipa delegation-find --permissions= returns internal error
#  BZ 783501 -- ipa delegation-find --attrs= returns internal error
#  BZ 783543 -- ipa delegation-mod --membergroup= returns internal error
#  BZ 783548 -- ipa delegation-mod is not failing when membergroup does not exist
#  BZ 783554 -- ipa delegation-mod --attrs= removes Attributes from delegation instead of failing
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
# test suite
######################################################################
ipa_delegation_cli_bz()
{
	ipa_delegation_cli_bz_783307
	ipa_delegation_cli_bz_783473
	ipa_delegation_cli_bz_783475
	ipa_delegation_cli_bz_783489
	ipa_delegation_cli_bz_783501
	ipa_delegation_cli_bz_783543
	ipa_delegation_cli_bz_783548
	ipa_delegation_cli_bz_783554
}

######################################################################
# BZ 783307 -- ipa delegation-add is not failing when membergroup does not exist
######################################################################
ipa_delegation_cli_bz_783307()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783307: ipa delegation-add is not failing when membergroup does not exist"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa group-add --desc=gr1000 gr1000 > /dev/null 2>&1
		ipa delegation-add $FUNCNAME --membergroup=badgroup --group=gr1000 --attrs=mobile > $tmpout 2>&1
		if [ $(egrep "Added delegation \"$FUNCNAME\"|badgroup" $tmpout|wc -l) -eq 2 ]; then     
			rlFail "BZ 783307 found...ipa delegation-add is not failing when membergroup does not exist"
			ipa delegation-del $FUNCNAME > /dev/null 2>&1
		else
			rlPass "BZ 783307 not found"
		fi
		ipa group-del gr1000 > /dev/null 2>&1
	rlPhaseEnd
}

######################################################################
# BZ 783473 -- ipa delegation-find --membergroup= with no value returns internal error
######################################################################
ipa_delegation_cli_bz_783473()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783473: ipa delegation-find --membergroup= with no value returns internal error"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-find --membergroup= > $tmpout 2>&1
		if [ $(egrep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783473 found...ipa delegation-find --membergroup= with no value returns internal error"
		else
			rlPass "BZ 783473 not found"
		fi	
	rlPhaseEnd
}

######################################################################
# BZ 783475 -- ipa delegation-find --membergroup="" with no value returns internal error
######################################################################
ipa_delegation_cli_bz_783475()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783475: ipa delegation-find --membergroup=\"\" with no value returns internal error"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-find --membergroup= > $tmpout 2>&1
		if [ $(egrep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783475 found...ipa delegation-find --membergroup=\"\" with no value returns internal error"
		else
			rlPass "BZ 783475 not found"
		fi	
	rlPhaseEnd
}

######################################################################
# BZ 783489 -- ipa delegation-find --permissions= returns internal error
######################################################################
ipa_delegation_cli_bz_783489()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783489: ipa delegation-find --permissions= returns internal error"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-add $FUNCNAME --membergroup=admins --group=ipausers --attrs=mobile > /dev/null 2>&1
		ipa delegation-find --permissions= > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783489 found...ipa delegation-find --permissions= returns internal error"
		else
			rlPass "BZ 783489 not found"
		fi	

		ipa delegation-find --permissions=\"\" > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783489 found...ipa delegation-find --permissions= returns internal error...also affects --permissions=\"\""
		fi

		ipa delegation-find --permissions=\" \" > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783489 found...ipa delegation-find --permissions= returns internal error...also affects --permissions=\" \""
		fi

		ipa delegation-del $FUNCNAME
	rlPhaseEnd
}

######################################################################
# BZ 783501 -- ipa delegation-find --attrs= returns internal error
######################################################################
ipa_delegation_cli_bz_783501()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783501: ipa delegation-find --attrs= returns internal error"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-add $FUNCNAME --membergroup=admins --group=ipausers --attrs=mobile > /dev/null 2>&1
		ipa delegation-find --attrs= > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783501 found...ipa delegation-find --attrs= returns internal error"
		else
			rlPass "BZ 783501 not found"
		fi	

		ipa delegation-find --attrs=\"\" > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783501 found...ipa delegation-find --attrs= returns internal error...also affects --attrs=\"\""
		fi

		ipa delegation-find --attrs=\" \" > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783501 found...ipa delegation-find --attrs= returns internal error...also affects --attrs=\"\""
		fi
		
		ipa delegation-del $FUNCNAME > /dev/null 2>&1
	rlPhaseEnd
}

######################################################################
# BZ 783543 -- ipa delegation-mod --membergroup= returns internal error
######################################################################
ipa_delegation_cli_bz_783543()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783543: ipa delegation-mod --membergroup= returns internal error"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-add $FUNCNAME --membergroup=admins --group=ipausers --attrs=mobile > /dev/null 2>&1
		ipa delegation-mod $FUNCNAME --membergroup= > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783543 found...ipa delegation-mod --membergroup= returns internal error"
		else
			rlPass "BZ 783543 not found"
		fi	

		ipa delegation-mod $FUNCNAME --membergroup=\"\" > $tmpout 2>&1
		if [ $(grep "ipa: ERROR: an internal error has occurred" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783543 found...ipa delegation-mod --membergroup= returns internal error...also affects --membergroup=\"\""
		fi

		ipa delegation-del $FUNCNAME > /dev/null 2>&1
	rlPhaseEnd
}

######################################################################
# BZ 783548 -- ipa delegation-mod is not failing when membergroup does not exist
######################################################################
ipa_delegation_cli_bz_783548()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783548: ipa delegation-mod is not failing when membergroup does not exist"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out > /dev/null 2>&1
		ipa delegation-add $FUNCNAME --membergroup=admins --group=ipausers --attrs=mobile > /dev/null 2>&1
		ipa delegation-mod $FUNCNAME --membergroup=badmembergroup > $tmpout 2>&1
		if [ $(grep "Modified delegation \"$FUNCNAME\"" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783548 found...ipa delegation-mod is not failing when membergroup does not exist"
		else
			rlPass "BZ 783548 not found"
		fi	

		ipa delegation-del $FUNCNAME > /dev/null 2>&1
	rlPhaseEnd
}

######################################################################
# BZ 783554 -- ipa delegation-mod --attrs= removes Attributes from delegation instead of failing
######################################################################
ipa_delegation_cli_bz_783554()
{
	rlPhaseStartTest "ipa_delegation_cli_bz_783554: ipa delegation-mod --attrs= removes Attributes from delegation instead of failing"
		KinitAsAdmin
		local tmpout=$TmpDir/$FUNCNAME.$RANDOM.out
		ipa delegation-add $FUNCNAME --membergroup=admins --group=ipausers --attrs=mobile > /dev/null 2>&1
		ipa delegation-mod $FUNCNAME --attrs= > $tmpout 2>&1
		if [ $(grep "Modified delegation \"$FUNCNAME\"" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783554 found...ipa delegation-mod --attrs= removes Attributes from delegation instead of failing"
		else
			rlPass "BZ 783554 not found"
		fi	
		
		ipa delegation-mod $FUNCNAME --attrs=l > /dev/null 2>&1
		ipa delegation-mod $FUNCNAME --attrs=\"\" > $tmpout 2>&1
		if [ $(grep "Modified delegation \"$FUNCNAME\"" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783554 found...ipa delegation-mod --attrs= removes Attributes from delegation instead of failing also affects --attrs=\"\" with empty value"
		fi

		ipa delegation-mod $FUNCNAME --attrs=st
		ipa delegation-mod $FUNCNAME --attrs=\" \" > $tmpout 2>&1
		if [ $(grep "Modified delegation \"$FUNCNAME\"" $tmpout|wc -l) -gt 0 ]; then
			rlFail "BZ 783554 found...ipa delegation-mod --attrs= removes Attributes from delegation instead of failing also affects --attrs=\" \" with space value"
		fi

		ipa delegation-del $FUNCNAME > /dev/null 2>&1
	rlPhaseEnd
}
