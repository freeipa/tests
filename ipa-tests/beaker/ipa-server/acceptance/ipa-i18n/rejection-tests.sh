# Do not edit this script directly, edit create-tests.bash
# Generated by Michael Gregg
# 3-15-2011
. ./testenv.sh

run_rejection_tests()
{

rlPhaseStartTest "ipa-i18n-29: Changing firstname of $uname2 to Rôséñe"
    rlRun "ipa user-mod --first='Rôséñe' $uname2" 0 "Modifying firstname of $uname2 to Rôséñe"
rlPhaseEnd

rlPhaseStartTest "ipa-i18n-30: checking to ensuer that the firstname of $uname2 is Rôséñe"
        rlRun "ipa user-find --all $uname2 | grep 'Rôséñe'" 0 "Checking to ensure that the firstname of $uname1 is Rôséñe"
rlPhaseEnd


rlPhaseStartTest "ipa-i18n-31: Changing firstname of $uname2 to Tàrqùinio"
    rlRun "ipa user-mod --first='Tàrqùinio' $uname2" 0 "Modifying firstname of $uname2 to Tàrqùinio"
rlPhaseEnd

rlPhaseStartTest "ipa-i18n-32: checking to ensuer that the firstname of $uname2 is Tàrqùinio"
        rlRun "ipa user-find --all $uname2 | grep 'Tàrqùinio'" 0 "Checking to ensure that the firstname of $uname1 is Tàrqùinio"
rlPhaseEnd


rlPhaseStartTest "ipa-i18n-33: Changing firstname of $uname2 to PASSWÖRD"
    rlRun "ipa user-mod --first='PASSWÖRD' $uname2" 0 "Modifying firstname of $uname2 to PASSWÖRD"
rlPhaseEnd

rlPhaseStartTest "ipa-i18n-34: checking to ensuer that the firstname of $uname2 is PASSWÖRD"
        rlRun "ipa user-find --all $uname2 | grep 'PASSWÖRD'" 0 "Checking to ensure that the firstname of $uname1 is PASSWÖRD"
rlPhaseEnd


rlPhaseStartTest "ipa-i18n-35: Changing firstname of $uname2 to Nomeuropéen"
    rlRun "ipa user-mod --first='Nomeuropéen' $uname2" 0 "Modifying firstname of $uname2 to Nomeuropéen"
rlPhaseEnd

rlPhaseStartTest "ipa-i18n-36: checking to ensuer that the firstname of $uname2 is Nomeuropéen"
        rlRun "ipa user-find --all $uname2 | grep 'Nomeuropéen'" 0 "Checking to ensure that the firstname of $uname1 is Nomeuropéen"
rlPhaseEnd



}

