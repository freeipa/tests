#!/bin/bash
# By  : Automatic Generated by at.3.testcase.pl
# Date: Thu Feb 10 10:50:57 2011

# import local lib file
. ./lib.ipacert.sh

ipacert()
{
    cert_remove_hold
    cert_request
    cert_revoke
    cert_show
    cert_status
} #cert

#############################################
#  test suite: cert-remove-hold (3 test cases)
#############################################
cert_remove_hold()
{
    cert_remove_hold_envsetup
    cert_remove_hold_1001  #test_scenario (positive test): when cert revoked as reason 6 cert can remove hold
    cert_remove_hold_1002  #test_scenario (negative test): when cert revoked not as reason 6 cert cannot remove hold
    cert_remove_hold_1003  #test_scenario (negative test): when invalid cert id is given remove-hold should fail
    cert_remove_hold_envcleanup
} #cert-remove-hold

cert_remove_hold_envsetup()
{
    rlPhaseStartSetup "cert_remove_hold_envsetup"
        #environment setup starts here
        rlPass "no env setup here"
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

cert_remove_hold_envcleanup()
{
    rlPhaseStartCleanup "cert_remove_hold_envcleanup"
        #environment cleanup starts here
        rlPass "no env cleanup here"
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

cert_remove_hold_1001()
{ #test_scenario (positive): --certid
    rlPhaseStartTest "cert_remove_hold_1001"
        local testID="cert_remove_hold_1001"
        local tmpout=$TmpDir/cert_remove_hold_1001.$RANDOM.out
        create_cert
        KinitAsAdmin
        local certid=`tail -n1 $certList | cut -d"=" -f2 | xargs echo`
        rlRun "ipa cert-revoke $certid --revocation-reason=6" 0 "set revoke reason to 6 -- this is only reason we can remove hold"
        ipa cert-show $certid > $tmpout
        reason=`grep -i "Revocation reason" $tmpout | cut -d":" -f2 | xargs echo`
        if [ "$reason" = "6" ];then
            rlLog "revoke reason set to [6] confirmed"
        else
            rlFail "revoke reason expected to be [6], actual [$reason], test can not continue"
            return
        fi
        rlRun "ipa cert-remove-hold $certid " 0 "test options: remove hold " 

        #after remove hold, lets check the content again
        ipa cert-show $certid > $tmpout
        if grep -i "Revocation reason" $tmpout
        then
            rlFail "revocation reason still found in cert-show, test failed"
            cat $tmpout
        else
            rlPass "revocation reason not found in cert-show, test pass"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_remove_hold_1001

cert_remove_hold_1002()
{ #test_scenario (negative): when cert revoked in reason other than 6, remove-hold should fail
    rlPhaseStartTest "cert_remove_hold_1002"
        local testID="cert_remove_hold_1002"
        local tmpout=$TmpDir/cert_remove_hold_1002.$RANDOM.out
        #create_cert
        #local certid=`tail -n1 $certList | cut -d"=" -f2 | xargs echo`
        for revokeCode in 0 1 2 3 4 5 7 8 9 10
        do
            create_cert
            local certid=`tail -n1 $certList | cut -d"=" -f2 | xargs echo`
            KinitAsAdmin
            rlRun "ipa cert-revoke $certid --revocation-reason=$revokeCode" 0 "set revoke reason to [$revokeCode], cert should not be able to reuse"
            ipa cert-show $certid > $tmpout
            reason=`grep -i "Revocation reason" $tmpout | cut -d":" -f2 | xargs echo`
            if [ "$reason" = "$revokeCode" ];then
                rlLog "revoke reason set to [$revokeCode] confirmed"
            else
                rlFail "revoke reason expected to be [$revokeCode], actual [$reason], test can not continue"
                return
            fi
            rlRun "ipa cert-remove-hold $certid " 0 "cert-remove-hold always return 0(succes),we need more test to confirm remove hold fails" 

            #after remove hold, lets check the content again
            ipa cert-show $certid > $tmpout
            if grep -i "Revocation reason: $revokeCode" $tmpout
            then
                rlPass "revocation reason still found in cert-show, test pass"
            else
                rlFail "revocation reason not found in cert-show, test failed"
                cat $tmpout
            fi
            Kcleanup
            rm $tmpout
        done
    rlPhaseEnd
} #cert_remove_hold_1002

cert_remove_hold_1003()
{ #test_scenario (negative):  remove-hold <invalid cert id>
    rlPhaseStartTest "cert_remove_hold_1003"
        local testID="cert_remove_hold_1003"
        local tmpout=$TmpDir/cert_remove_hold_1001.$RANDOM.out
        KinitAsAdmin
        # somehow ipa cert-remove-hold always report success regardless
        # I have to use output msg to determine the pass/fail 
        local certid="9999"
        local errmsg="Record not found"
        ipa cert-remove-hold $certid 2>&1 >$tmpout
        if grep -i "$errmsg" $tmpout 
        then
            rlPass "remove non-exist cert reports 'not found' error"
        else
            rlFail "no match error msg found"
            echo "====== expect ====================="
            echo $errmsg
            echo "====== actual ======================"
            cat $tmpout
            echo "===================================="
        fi

        local certid="abc"
        ipa cert-remove-hold $certid 2>&1 >$tmpout
        local errmsg="Record not found"
        if grep -i "$errmsg" $tmpout ;then
            rlPass "remove-hold an invalid cert failed as expected"
        else
            rlFail "remove-hold: error msg does not match, actual out as below"
            echo "======== expected =================="
            echo $errmsg
            echo "========= actual  =================="
            cat $tmpout
            echo "===================================="
        fi
        Kcleanup
    rlPhaseEnd
} #cert_remove_hold_1003

#END OF TEST CASE for [cert-remove-hold]

#############################################
#  test suite: cert-request (9 test cases)
#############################################
cert_request()
{
    cert_request_envsetup
    cert_request_1001  #test_scenario (negative test): [--add --principal;negative;STR --request-type;positive;STR]
    cert_request_1002  #test_scenario (negative test): [--add --principal;positive;STR --request-type;negative;STR]
    cert_request_1003  #test_scenario (positive test): [--add --principal;positive;STR --request-type;positive;STR]
    cert_request_1004  #test_scenario (negative test): [--principal;negative;STR]
    cert_request_1005  #test_scenario (negative test): [--principal;negative;STR --request-type;positive;STR]
    cert_request_1006  #test_scenario (positive test): [--principal;positive;STR]
    cert_request_1007  #test_scenario (negative test): [--principal;positive;STR --request-type;negative;STR]
    cert_request_1008  #test_scenario (positive test): [--principal;positive;STR --request-type;positive;STR]
    cert_request_1009  #test_scenario (negative): use same cert request file and principle twice, the first will be revoked with reason 4
    cert_request_envcleanup
} #cert-request

cert_request_envsetup()
{
    rlPhaseStartSetup "cert_request_envsetup"
        #environment setup starts here
        rlPass "no env setup necessary"
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

cert_request_envcleanup()
{
    rlPhaseStartCleanup "cert_request_envcleanup"
        #environment cleanup starts here
        rlPass "no env cleanup necessary"
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

cert_request_1001()
{ #test_scenario (negative): --add --principal;negative;STR --request-type;positive;STR
    rlPhaseStartTest "cert_request_1001"
        local testID="cert_request_1001_$RANDOM"
        local tmpout=$TmpDir/cert_request_1001.$RANDOM.out
        local request_type_TestValue="pkcs10" #request-type;positive;STR
        local expectedErrCode=0

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        KinitAsAdmin
        local principal_TestValue_Negative="/$hostname" #principal;negative;STR 
        local expectedErrMsg="Service principal is not of the form: service/fully-qualified"
        qaRun "ipa cert-request $certRequestFile --add  --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        principal_TestValue_Negative="noHostNamePricipal" #principal;negative;STR 
        expectedErrMsg="Service principal is not of the form: service/fully-qualified host name: missing service"
        qaRun "ipa cert-request $certRequestFile --add  --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        principal_TestValue_Negative="whateverservice/does.not.match.csr.host.com" #principal;negative;STR 
        expectedErrMsg="Insufficient access: hostname in subject of request '$hostname' does not match principal hostname 'does.not.match.csr.host.com'"
        qaRun "ipa cert-request $certRequestFile --add  --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1001

cert_request_1002()
{ #test_scenario (negative): --add --principal;positive;STR --request-type;negative;STR
    rlPhaseStartTest "cert_request_1002"
        local testID="cert_request_1002_$RANDOM"
        local tmpout=$TmpDir/cert_request_1002.$RANDOM.out
        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile
        KinitAsAdmin
        local principal_TestValue="sevice$testID/$hostname" #principal;positive;STR 
        local request_type_TestValue_Negative="invalidType100" #request-type;negative;STR
        local expectedErrMsg="Unknown Certificate Request Type"
        local expectedErrCode=0
        qaRun "ipa cert-request $certRequestFile --add  --principal=$principal_TestValue  --request-type=$request_type_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue] [request-type]=[$request_type_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1002

cert_request_1003()
{ #test_scenario (positive): --add --principal;positive;STR --request-type;positive;STR
    rlPhaseStartTest "cert_request_1003"
        local testID="cert_request_1003_$RANDOM"
        local tmpout=$TmpDir/cert_request_1003.$RANDOM.out
        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile
        KinitAsAdmin
        local principal_TestValue="service$testID/$hostname" #principal;positive;STR 
        local request_type_TestValue="pkcs10" #request-type;positive;STR
        rlRun "ipa cert-request $certRequestFile --add  --principal=$principal_TestValue  --request-type=$request_type_TestValue " 0 "test options:  [principal]=[$principal_TestValue] [request-type]=[$request_type_TestValue]" 
        Kcleanup
        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1003

cert_request_1004()
{ #test_scenario (negative): --principal;negative;STR
    rlPhaseStartTest "cert_request_1004"
        local testID="cert_request_1004_$RANDOM"
        local tmpout=$TmpDir/cert_request_1004.$RANDOM.out

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        local expectedErrCode=0
        KinitAsAdmin
        local principal_TestValue_Negative="/$hostname" #principal;negative;STR 
        local expectedErrMsg="Service principal is not of the form: service/fully-qualified host name"
        qaRun "ipa cert-request $certRequestFile  --principal=$principal_TestValue_Negative" "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative]"

        principal_TestValue_Negative="noHostNamePricipal" #principal;negative;STR 
        expectedErrMsg="Service principal is not of the form: service/fully-qualified host name: missing service"
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative" "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative]"

        principal_TestValue_Negative="whateverservice/does.not.match.csr.host.com" #principal;negative;STR 
        expectedErrMsg="Insufficient access: hostname in subject of request '$hostname' does not match principal hostname 'does.not.match.csr.host.com'"
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative" "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative]"

        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1004

cert_request_1005()
{ #test_scenario (negative): --principal;negative;STR --request-type;positive;STR
    rlPhaseStartTest "cert_request_1005"
        local testID="cert_request_1005_$RANDOM"
        local tmpout=$TmpDir/cert_request_1005.$RANDOM.out

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile
        local request_type_TestValue="pkcs10" #request-type;positive;STR
        local expectedErrCode=0
        KinitAsAdmin
        local principal_TestValue_Negative="/$hostname" #principal;negative;STR 
        local expectedErrMsg="Service principal is not of the form: service/fully-qualified host name"
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        principal_TestValue_Negative="noHostNamePricipal" #principal;negative;STR 
        expectedErrMsg="Service principal is not of the form: service/fully-qualified host name: missing service"
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        principal_TestValue_Negative="whateverservice/does.not.match.csr.host.com" #principal;negative;STR 
        expectedErrMsg="Insufficient access: hostname in subject of request '$hostname' does not match principal hostname 'does.not.match.csr.host.com'"
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 

        principal_TestValue_Negative="service$testID/$hostname" # legal principal name, just not pre-exist;negative;STR 
        expectedErrMsg="The service principal for this request doesn't exist"
        expectedErrCode=0
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue_Negative  --request-type=$request_type_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue_Negative] [request-type]=[$request_type_TestValue]" 
        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1005

cert_request_1006()
{ #test_scenario (positive): --principal;positive;STR
    rlPhaseStartTest "cert_request_1006"
        local testID="cert_request_1006_$RANDOM"
        local tmpout=$TmpDir/cert_request_1006.$RANDOM.out

        KinitAsAdmin
        local principal_TestValue="service$testID/$hostname" #principal;positive;STR
        rlRun "ipa service-add $principal_TestValue" 0 "add service principal: [$principal_TestValue] before add cert"

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        rlRun "ipa cert-request $certRequestFile --principal=$principal_TestValue " 0 "test options:  [principal]=[$principal_TestValue]" 
        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1006

cert_request_1007()
{ #test_scenario (negative): --principal;positive;STR --request-type;negative;STR
    rlPhaseStartTest "cert_request_1007"
        local testID="cert_request_1007_$RANDOM"
        local tmpout=$TmpDir/cert_request_1007.$RANDOM.out
        KinitAsAdmin
        local principal_TestValue="service$testID/$hostname" #principal;positive;STR
        rlRun "ipa service-add $principal_TestValue" 0 "add service principal: [$principal_TestValue] before add cert"

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        local request_type_TestValue_Negative="invalidType102" #request-type;negative;STR
        local expectedErrMsg="Unknown Certificate Request Type invalidtype10"
        local expectedErrCode=0
        qaRun "ipa cert-request $certRequestFile --principal=$principal_TestValue  --request-type=$request_type_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [principal]=[$principal_TestValue] [request-type]=[$request_type_TestValue_Negative]" 
        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1007

cert_request_1008()
{ #test_scenario (positive): --principal;positive;STR --request-type;positive;STR
    rlPhaseStartTest "cert_request_1008"
        local testID="cert_request_1008_$RANDOM"
        local tmpout=$TmpDir/cert_request_1008.$RANDOM.out
        KinitAsAdmin
        local principal_TestValue="service$testID/$hostname" #principal;positive;STR
        rlRun "ipa service-add $principal_TestValue" 0 "add service principal: [$principal_TestValue] before add cert"
        local request_type_TestValue="pkcs10" #request-type;positive;STR

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        rlRun "ipa cert-request $certRequestFile --principal=$principal_TestValue  --request-type=$request_type_TestValue " 0 "test options:  [principal]=[$principal_TestValue] [request-type]=[$request_type_TestValue]" 
        Kcleanup

        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
    rlPhaseEnd
} #cert_request_1008

cert_request_1009()
{ #test_scenario (negative): use same cert request file and principle twice, the first will be revoked with reason 4
    rlPhaseStartTest "cert_request_1009"
        local testID="cert_request_1009_$RANDOM"
        local tmpout=$TmpDir/cert_request_1009.$RANDOM.out
        local certfile=$TmpDir/cert_request_1009.$RANDOM.certs
        KinitAsAdmin
        local principal="service$testID/$hostname" #principal;positive;STR
        rlRun "ipa service-add $principal" 0 "add service principal: [$principal_TestValue] before add cert"

        local certRequestFile=$TmpDir/certrequest.$RANDOM.certreq.csr
        local certPrivateKeyFile=$TmpDir/certrequest.$RANDOM.prikey.txt
        create_cert_request_file $certRequestFile $certPrivateKeyFile

        # create the first cert, expect success
        ipa cert-request --principal=$principal $certRequestFile 2>&1 >$tmpout
        local ret=$?
        if [ "$ret" = "0" ];then
            local certid=`grep "Serial number" $tmpout| cut -d":" -f2 | xargs echo` 
            echo "$principal=$certid" > $certfile
            rlLog "create first cert success, cert id :[$certid], principal [$principal]"
        else
            rlFail "create first cert failed, principal [$principal]"
            cat $tmpout
        fi

        # create the second cert with same csr file and principal name, expect success as well
        ipa cert-request --principal=$principal $certRequestFile 2>&1 >$tmpout
        local ret=$?
        if [ "$ret" = "0" ];then
            local certid=`grep "Serial number" $tmpout| cut -d":" -f2 | xargs echo` 
            echo "$principal=$certid" >> $certfile
            rlLog "create second cert success, cert id :[$certid], principal [$principal]"
        else
            rlFail "create second cert failed, principal [$principal]"
            cat $tmpout
            return
        fi

        # verification: (1) total success cert count should be 2 in $certfile
        total=`cat $certfile | wc -l` 
        if [ "$total" = "2" ];then
            rlLog "total certs matches : [$total]";
        else
            rlFail "total certs should be 2, but [$total]"
            cat $certfile
            return
        fi
        oldCert=`cat $certfile | head -n1 | cut -d"=" -f2`
        newCert=`cat $certfile | tail -n1 | cut -d"=" -f2` 
        revokeReasonOld=`ipa cert-show $oldCert | grep "Revocation reason" | cut -d":" -f2 | xargs echo`
        if [ "$revokeReasonOld" = "4" ];then
            rlLog "old cert [$oldCert] revoked as reason 4, this is expected, verification continue"
            revokeReasonNew=`ipa cert-show $newCert | grep "Revocation reason" | cut -d":" -f2 | xargs echo`
            if [ "$revokeReasonNew" = "" ];then
                rlPass "newer cert does not being revoked, this is eppected, test pass"
            else
                rlFail "newer cert revoked, this is not expected"
                echo "==========================================="
                echo "--------------- old cert ------------------"
                ipa cert-show $oldCert
                echo "--------------- new cert ------------------"
                ipa cert-show $newCert
                echo "==========================================="
            fi
        else
            rlFail "first cert [$oldCert] Does not being revoked, or not as reason 4, this is not expected"
        fi

        Kcleanup
        rm $tmpout
        rm $certRequestFile 
        rm $certPrivateKeyFile
        rm $certfile
    rlPhaseEnd
} #cert_request_1009

#END OF TEST CASE for [cert-request]

#############################################
#  test suite: cert-revoke (3 test cases)
#############################################
cert_revoke()
{
    cert_revoke_envsetup
    cert_revoke_1001  #test_scenario (negative test): [--revocation-reason;negative;-1,11]
    cert_revoke_1002  #test_scenario (positive test): [--revocation-reason;positive;0,1,2,3,4,5,6,7,8,9,10]
    cert_revoke_1003  #test_scenario (negative): revoke an non-exist cert
    cert_revoke_envcleanup
} #cert-revoke

cert_revoke_envsetup()
{
    rlPhaseStartSetup "cert_revoke_envsetup"
        #environment setup starts here
        rlPass "no env setup necessare, all certs will be created in each test case"
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

cert_revoke_envcleanup()
{
    rlPhaseStartCleanup "cert_revoke_envcleanup"
        #environment cleanup starts here
        rlPass "no env cleanup necessary, it is already done in each test case"
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

cert_revoke_1001()
{ #test_scenario (negative): valid cert id + --revocation-reason;negative;-1,11
    rlPhaseStartTest "cert_revoke_1001"
        local testID="cert_revoke_1001"
        local tmpout=$TmpDir/cert_revoke_1001.$RANDOM.out
        local expectedErrMsg="invalid 'revocation_reason': must be an integer"
        local expectedErrCode=0
        create_cert
        local validCert=`tail -n1 $certList`
        local certid=`echo $validCert| cut -d"=" -f2`
        rlLog "certid=[$certid]";
        echo "================ cert list =============";
        cat  $certList
        echo "========================================";
        KinitAsAdmin
        # when pass a non-integer
        for invalid_revoke_reason in a abc
        do
            qaRun "ipa cert-revoke $certid --revocation-reason=$invalid_revoke_reason" "$tmpout" "$expectedErrCode" "$expectedErrMsg" "test options:  [revocation-reason]=[$invalid_revoke_reason]" 
        done

        # when interger does pass in, error msg indicates max value
        invalid_revoke_reason=99
        expectedErrMsg="invalid 'revocation_reason': can be at most 10"
        qaRun "ipa cert-revoke $certid --revocation-reason=$invalid_revoke_reason" "$tmpout" "$expectedErrCode" "$expectedErrMsg" "test options:  [revocation-reason]=[$invalid_revoke_reason]" 
        Kcleanup
        delete_cert
        rm $tmpout
    rlPhaseEnd
} #cert_revoke_1001

cert_revoke_1002()
{ #test_scenario (positive): valid cert id + --revocation-reason;positive;0,1,2,3,4,5,6,7,8,9,10
    rlPhaseStartTest "cert_revoke_1002"
        local testID="cert_revoke_1002"
        local tmpout=$TmpDir/certrevoke1002.$RANDOM.out
        for reason in 0 1 2 3 4 5 6 8 9 10
        do
            create_cert
            local validCert=`tail -n1 $certList`
            local certid=`echo $validCert| cut -d"=" -f2`
            rlLog "revoke cert [$certid] with revoke reason [$reason]"
            KinitAsAdmin
            ipa cert-revoke $certid --revocation-reason=$reason
            local ret=$?
            if [ "$ret" = "0" ];then
                ipa cert-show $certid > $tmpout
                rlLog "revocation success, now check the revocation code"
                local actual=`grep -i "Revocation reason" $tmpout | cut -d":" -f2 | xargs echo`
                if [ "$reason" = "$actual" ];then
                    rlPass "revocation code matches with expected [$acutal], pass"
                else
                    rlFail "revocation code doesnot match with expected: expected [$reason], actual [$actual] "
                    ipa cert-show $certid 
                fi
            else
                rlFail "revocation failed, cert show:"
                ipa cert-show $certid 
            fi
            Kcleanup
            delete_cert
        done
        rm $tmpout
    rlPhaseEnd
} #cert_revoke_1002

cert_revoke_1003()
{ #test_scenario (negative):revoke a non-exist cert
    rlPhaseStartTest "cert_revoke_1003"
        local testID="cert_revoke_1003"
        KinitAsAdmin
        for invalid_cert in z abc 100abc 10000000000
        do
            rlRun "ipa cert-revoke $invalid_cert" 1 "revoke non-exist cert should fail certid=[$invalid_cert]"
        done
        Kcleanup
    rlPhaseEnd
} #cert_revoke_1002


#END OF TEST CASE for [cert-revoke]

#############################################
#  test suite: cert-show (2 test cases)
#############################################
cert_show()
{
    cert_show_envsetup
    cert_show_1001  #test_scenario (negative test): give negative cert id 
    cert_show_1002  #test_scenario (positive test): [--out;positive;CertOutFile]
    cert_show_1003  #test_scenario (negative test): valid cert id + --out;negative;CertOutFile]
    cert_show_envcleanup
} #cert-show

cert_show_envsetup()
{
    rlPhaseStartSetup "cert_show_envsetup"
        #environment setup starts here
        create_cert
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

cert_show_envcleanup()
{
    rlPhaseStartCleanup "cert_show_envcleanup"
        #environment cleanup starts here
        delete_cert
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

cert_show_1001()
{ #test_scenario (negative): given invalid cert request id
    rlPhaseStartTest "cert_show_1001"
        local testID="cert_show_1001"
        local tmpout=$TmpDir/cert_show_1001.$RANDOM.out
        KinitAsAdmin
        local expectedErrMsg="not found"
        local expectedErrCode=0
        for invalidCertID in 1000 2000 ;do
            qaRun "ipa cert-show $invalidCertID" "$tmpout" $expectedErrCode "$expectedErrMsg" "test options: $invalidCertID" 
        done

        local expectedErrMsg="Certificate operation cannot be completed"
        local expectedErrCode=0
        for invalidCertID in abc b0a;do
            qaRun "ipa cert-show $invalidCertID" "$tmpout" $expectedErrCode "$expectedErrMsg" "test options: $invalidCertID" 
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_show_1001

cert_show_1002()
{ #test_scenario (positive): --out;positive;CertOutFile
    rlPhaseStartTest "cert_show_1002"
        local testID="cert_show_1002"
        local tmpout=$TmpDir/cert_show_1002.$RANDOM.out
        KinitAsAdmin
        for cert in `cat $certList`;do
            local outfile=$TmpDir/certshow1002.$RANDOM.out.file
            local output=$TmpDir/certshow1002.$RANDOM.output
            local valid_certid=`echo $cert | cut -d"=" -f2`
            rlRun "ipa cert-show $valid_certid --out=$outfile" 0 "output [$valid_certid] to file: [$outfile]"
            if [ -f $outfile ];then
                if     grep "BEGIN CERTIFICATE" $outfile 2>&1 >/dev/null \
                    && grep "END CERTIFICATE" $outfile 2>&1 >/dev/null
                then
                    rlPass "cert-show output to file [$outfile] success"
                else
                    rlFail "cert-show output to file [$outfile] failed"
                fi
            else
                rlFail "can not output cert to file [$outfile]"
            fi
            rm $outfile
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_show_1002

cert_show_1003()
{ #test_scenario (negative): positive cert id + --out;negative;CertOutFile
    rlPhaseStartTest "cert_show_1003"
        local testID="cert_show_1003"
        local tmpout=$TmpDir/cert_show_1003.$RANDOM.out
        local errcode=0;
        KinitAsAdmin
        for cert in `cat $certList`;do
            local valid_certid=`echo $cert | cut -d"=" -f2`
            qaRun "ipa cert-show $valid_certid --out=" "$tmpout" "$errcode" "Filename is empty" "test option: give no argument for --out, expect to fail"
            qaRun "ipa cert-show $valid_certid --out=/" "$tmpout" "$errcode" "Is a directory" "test option: give a directory location instead of file name, expecte to fail"
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_show_1003

#END OF TEST CASE for [cert-show]

#############################################
#  test suite: cert-status (2 test cases)
#############################################
cert_status()
{
    cert_status_envsetup
    cert_status_1001  #test_scenario (positive test): valid cert id
    cert_status_1002  #test_scenario (positive test): invalid cert id
    cert_status_envcleanup
} #cert-status

cert_status_envsetup()
{
    rlPhaseStartSetup "cert_status_envsetup"
        #environment setup starts here
        create_cert 
        create_cert 
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

cert_status_envcleanup()
{
    rlPhaseStartCleanup "cert_status_envcleanup"
        #environment cleanup starts here
        delete_cert 
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

cert_status_1001()
{ #test_scenario (positive): valid cert id
    rlPhaseStartTest "cert_status_1001"
        local testID="cert_status_1001"
        local tmpout=$TmpDir/cert_status_1001.$RANDOM.out
        KinitAsAdmin
        for cert in `cat $certList`
        do
            local cert_principal=`echo $cert | cut -d"=" -f1`
            local certid=`echo $cert | cut -d"=" -f2`
            ipa cert-status $certid 2>&1 >$tmpout
            if     grep -i "Request id: $certid" $tmpout \
                && grep -i "Request status: complete" $tmpout ;then
                rlPass "status check pass for cert id [$certid]"
            else
                rlFail "status check failed for cert id [$certid]"
                echo "=========== output ================"
                cat $tmpout
                echo "==================================="
            fi
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_status_1001

cert_status_1002()
{ #test_scenario (negative): invalid cert id
    rlPhaseStartTest "cert_status_1002"
        local testID="cert_status_1002"
        local tmpout=$TmpDir/cert_status_1002.$RANDOM.out
        KinitAsAdmin
        # scenario 1: give chars and char-integer mix
        for certid in a abc 1a0
        do
            ipa cert-status $certid 2>$tmpout
            local errmsg="Invalid number format"
            if grep -i "$errmsg" $tmpout
            then
                rlPass "error returned as expected for cert id [$certid], errmsg [$errmsg]"
            else
                rlFail "no error returned or error msg not match for cert id [$certid]"
                rlLog "expected errmsg: [$errmsg]"
                echo "=========== output ================"
                cat $tmpout
                echo "==================================="
            fi
        done

        # scenario: give integer, but there are no such cert in ipa
        for certid in 999 1999
        do
            local errmsg="Request ID $certid was not found in the request queue"
            ipa cert-status $certid 2>$tmpout
            local ret=$?
            if grep -i "$errmsg" $tmpout
            then
                rlPass "error returned as expected for cert id [$certid]"
            else
                rlFail "no error returned or error msg not match for cert id [$certid]"
                rlLog "expected errmsg: [$errmsg]"
                echo "=========== output ================"
                cat $tmpout
                echo "==================================="
            fi
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #cert_status_1002


#END OF TEST CASE for [cert-status]
