#!/bin/bash
######################################################
# test suite  : ipa-autorenewcert
# description : IPA auto-renew certificate test suite
# created by  : Yi Zhang (yzhang@redhat.com)
# created date: Tue Aug  7 09:37:45 PDT 2012
######################################################

# time period used in this test
# [pre-autorenew] [auto-renew] [ post-autorenew] [ certs expiration time ] [postExpire]
# preAutorenew  : before auto renew being triggered
# autorenew     : 1 day to 1 hour before cert expires
# postAutorenew : after autorenew period but before certs expires
# certExpire    : exact point when certs expires
# postExpire    : after cert expires

. ./lib.autorenewcert.sh

# calculate dynamic variables
host=`hostname`
CAINSTANCE="pki-ca"
DSINSTANCE="`find_dirsrv_instance ds`"
CA_DSINSTANCE="`find_dirsrv_instance ca`"


cert_sanity_check(){
    restore_hosts
    restore_resolv_conf
    test_ipa_via_kinit_as_admin "$@"
    test_dirsrv_via_ssl_based_ldapsearch "$@"
    #test_dogtag_via_cert_show "$@"
    #test_ipa_via_creating_new_cert "$@"
}

autorenewcert()
{
        record_cert_expires_epoch_time
        print_test_header
        cert_sanity_check "Before auto renew triggered"

        calculate_autorenew_date $soonTobeRenewedCerts

        stop_ipa_certmonger_server "Before autorenew, stop ipa, adjust system to trigger automatic cert renew"
        adjust_system_time $autorenew autorenew    
        start_ipa_certmonger_server "After autorenew, start ipa, expect automatic cert renew happening in background"

        go_to_sleep
        #restart_ipa_certmonger_server "After autorenew, restart ipa, give ipa serverr second chance to kick off automatic renew"
        #go_to_sleep
        #restart_ipa_certmonger_server "After autorenew, 2nd restart ipa, give ipa serverr third  chance to kick off automatic renew"
        #go_to_sleep

        stop_ipa_certmonger_server "Before postExpire, system time will change soon, to verify the renewed certs"
        adjust_system_time $postExpire postExpire
        start_ipa_certmonger_server "After postExpire, system time has been changed, expect new certs are in use"
        echo "sleep 60 seconds..."
        sleep 60
        #go_to_sleep # give ipa server some time to refresh everything
        check_actually_renewed_certs $soonTobeRenewedCerts
        compare_expires_epoch_time_of_certs
        compare_expected_renewal_certs_with_actual_renewed_certs "After postExpire"

        cert_sanity_check  "After auto renew triggered"
        test_status_report 
}

############## main test #################
main_autorenewcert_test(){
    testroundCounter=1
    # conditions for test to continue (continue_test returns "yes")
    # 1. all ipa certs are valid
    # 2. if there are some certs haven't get chance to be renewed, test should be continue
    #enable_ipa_debug_mode
    prepare_preserv_dir
    preserve_resolv_conf
    preserve_hosts
    while [ "`continue_test`" = "yes" ]
    do
        certReport="$TmpDir/cert.report.$testroundCounter.txt"
        echo "" > $testResult  # reset test result from last round
        list_all_ipa_certs
        find_soon_to_be_renewed_certs
        autorenewcert $round
        prepare_for_next_round
        testroundCounter=$((testroundCounter + 1))
    done
    final_cert_status_report 
}
################ end of main ###########
