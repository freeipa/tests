#!/bin/bash

. /dev/shm/ipa-automember-cli-lib.sh
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh
. /dev/shm/ipa-group-cli-lib.sh
. /dev/shm/ipa-hostgroup-cli-lib.sh
. /dev/shm/ipa-host-cli-lib.sh
. /dev/shm/ipa-server-shared.sh
. /dev/shm/env.sh

addAutomember()
{
	type=$1
	name=$2
	rc=0
	options=""
	expect_name=0
	expect_type=0

	if [ $(echo $name|grep "^P:"|wc -l) -eq 0 ]; then
		options="$name"
	else
		expect_name=1
		name=$(echo $name|sed 's/^P://')
	fi
	
	if [ $(echo $type|grep "^P:"|wc -l) -eq 0 ]; then
		options="$options --type=$type"
	else
		expect_type=1
		type=$(echo $type|sed 's/^P://')
	fi

	cat <<- EOF > /tmp/automember-add-test.sh
	#!/usr/bin/expect
	set timeout 30
	match_max 100000
	spawn ipa automember-add $options
	EOF

	if [ $expect_name -eq 1 ]; then
		cat <<- EOF >> /tmp/automember-add-test.sh
		expect "Automember Rule: "
		send -- "$name\r"
		EOF
	fi
	
	if [ $expect_type -eq 1 ]; then
		cat <<- EOF >> /tmp/automember-add-test.sh
		expect "Grouping Type: "
		send -- "$type\r"
		EOF
	fi
	
	cat <<- EOF >> /tmp/automember-add-test.sh
	expect eof
	EOF

	chmod 755 /tmp/automember-add-test.sh
	rlLog "Executing: ipa automember-add $options"
	#ipa automember-add $options
	/tmp/automember-add-test.sh
	rc=$?
	if [ $rc -ne 0 ]; then
		rlLog "WARNING: Adding new Automember Rule \"$name\" failed."
	else
		rlLog "Adding new Automember Rule \"$name\" successful."
	fi

	return $rc
}

kinitAs $ADMINID $ADMINPW

rlRun "addAutomember hostgroup   hg1"
rlRun "addAutomember P:hostgroup hg2"
rlRun "addAutomember hostgroup   P:hg3"
rlRun "addAutomember P:hostgroup P:hg4"

rlRun "addAutomember group   g1"
rlRun "addAutomember P:group g2"
rlRun "addAutomember group   P:g3"
rlRun "addAutomember P:group P:g4"

