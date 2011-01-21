#!/bin/bash
# By  : Automatic Generated by at.3.testcase.pl
# Date: Thu Jan 20 10:38:36 2011

. ./lib.permission.sh

privilege()
{
    privilege_add
    privilege_add_permission
    privilege_del
    privilege_find
    privilege_mod
    privilege_remove_permission
    privilege_show
} #privilege

#############################################
#  test suite: privilege-add (5 test cases)
#############################################
privilege_add()
{
    privilege_add_envsetup
    privilege_add_1001  #test_scenario (negative test): [--addattr;negative;STR]
    privilege_add_1002  #test_scenario (positive test): [--addattr;positive;STR]
    privilege_add_1003  #test_scenario (positive test): [--desc;positive;auto_generated_description_data_$testID]
    privilege_add_1004  #test_scenario (negative test): [--setattr;negative;STR]
    privilege_add_1005  #test_scenario (positive test): [--setattr;positive;STR]
    privilege_add_envcleanup
} #privilege-add

privilege_add_envsetup()
{
    rlPhaseStartSetup "privilege_add_envsetup"
        #environment setup starts here
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_add_envcleanup()
{
    rlPhaseStartCleanup "privilege_add_envcleanup"
        #environment cleanup starts here
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_add_1001()
{ #test_scenario (negative): --addattr;negative;STR
    rlPhaseStartTest "privilege_add_1001"
        local testID="privilege_add_1001"
        local tmpout=$TmpDir/privilege_add_1001.$RANDOM.out
        KinitAsAdmin
        local addattr_TestValue_Negative="badFormat" #addattr;negative;STR
        local expectedErrMsg="invalid 'addattr': Invalid format. Should be name=value"
        local expectedErrCode=1
        qaRun "ipa privilege-add $testID  --desc=4_$testID --addattr=$addattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [addattr]=[$addattr_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_1001

privilege_add_1002()
{ #test_scenario (positive): --addattr;positive;STR
    rlPhaseStartTest "privilege_add_1002"
        local testID="privilege_add_1002"
        local tmpout=$TmpDir/privilege_add_1002.$RANDOM.out
        KinitAsAdmin
        local addattr_TestValue="memberof=$testPemission_addgrp" #addattr;positive;STR
        rlRun "ipa privilege-add $testID --desc=4_$testID --addattr=$addattr_TestValue " 0 "test options:  [addattr]=[$addattr_TestValue]" 
        checkPrivilegeInfo "$testID" "permissions" "$p_id"
        rlRun "ipa privilege-del $testID"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_1002

privilege_add_1003()
{ #test_scenario (positive): --desc;positive;auto_generated_description_data_$testID
    rlPhaseStartTest "privilege_add_1003"
        local testID="privilege_add_1003"
        local tmpout=$TmpDir/privilege_add_1003.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        rlRun "ipa privilege-add $testID  --desc=$desc_TestValue " 0 "test options:  [desc]=[$desc_TestValue]" 
        checkPrivilegeInfo $testID "Description" "$desc_TestValue"
        rlRun "ipa privilege-del $testID"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_1003

privilege_add_1004()
{ #test_scenario (negative): --setattr;negative;STR
    rlPhaseStartTest "privilege_add_1004"
        local testID="privilege_add_1004"
        local tmpout=$TmpDir/privilege_add_1004.$RANDOM.out
        KinitAsAdmin
        local setattr_TestValue_Negative="STR" #setattr;negative;STR
        local expectedErrMsg="invalid 'setattr': Invalid format. Should be name=value"
        local expectedErrCode=1
        qaRun "ipa privilege-add $testID --desc=4_$testID --setattr=$setattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [setattr]=[$setattr_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_1004

privilege_add_1005()
{ #test_scenario (positive): --setattr;positive;STR
    rlPhaseStartTest "privilege_add_1005"
        local testID="privilege_add_1005"
        local tmpout=$TmpDir/privilege_add_1005.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="newDesc$testID"
        local setattr_TestValue="description=$desc_TestValue" #setattr;positive;STR
        rlRun "ipa privilege-add $testID --desc=4_$testID --setattr=$setattr_TestValue " 0 "test options:  [setattr]=[$setattr_TestValue]" 
        checkPrivilegeInfo $testID "Description" "$desc_TestValue"
        rlRun "ipa privilege-del $testID"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_1005

#END OF TEST CASE for [privilege-add]

#############################################
#  test suite: privilege-add-permission (2 test cases)
#############################################
privilege_add_permission()
{
    privilege_add_permission_envsetup
    privilege_add_permission_1001  #test_scenario (negative test): [--permissions;negative;nonListValue]
    privilege_add_permission_1002  #test_scenario (positive test): [--permissions;positive;read,write,delete,add,all]
    privilege_add_permission_envcleanup
} #privilege-add-permission

privilege_add_permission_envsetup()
{
    rlPhaseStartSetup "privilege_add_permission_envsetup"
        #environment setup starts here
        createTestPrivilege $testPrivilege 
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_add_permission_envcleanup()
{
    rlPhaseStartCleanup "privilege_add_permission_envcleanup"
        #environment cleanup starts here
        deleteTestPrivilege $testPrivilege
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_add_permission_1001()
{ #test_scenario (negative): --permissions;negative;nonListValue
    rlPhaseStartTest "privilege_add_permission_1001"
        local testID="privilege_add_permission_1001"
        local tmpout=$TmpDir/privilege_add_permission_1001.$RANDOM.out
        KinitAsAdmin
        local permissions_TestValue_Negative="nonListValue" #permissions;negative;nonListValue
        local expectedErrMsg="permission not found"
        ipa privilege-add-permission $testPrivilege  --permissions=$permissions_TestValue_Negative > $tmpout
        if grep -i "$expectedErrMsg" $tmpout;then
            rlPass "add permission failed as expected"
        else
            rlFail "no match error msg found"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_permission_1001

privilege_add_permission_1002()
{ #test_scenario (positive): --permissions;positive;read,write,delete,add,all
    rlPhaseStartTest "privilege_add_permission_1002"
        local testID="privilege_add_permission_1002"
        local tmpout=$TmpDir/privilege_add_permission_1002.$RANDOM.out
        KinitAsAdmin
        local permissions_TestValue="readTest" #permissions;positive;read,write,delete,add,all
        rlRun "ipa permission-add $permissions_TestValue --desc=4_$permissions_TestValue --permissions=read --type=user" 0 "create test permission"
        rlRun "ipa privilege-add-permission $testPrivilege --permissions=$permissions_TestValue " 0 "test options:  [permissions]=[$permissions_TestValue]" 
        checkPrivilegeInfo $testPrivilege "Permissions" $permissions_TestValue
        rlRun "ipa permission-del $permissions_TestValue"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_add_permission_1002

#END OF TEST CASE for [privilege-add-permission]

#############################################
#  test suite: privilege-del (1 test cases)
#############################################
privilege_del()
{
    privilege_del_envsetup
    privilege_del_1001  #test_scenario (positive test): [--continue]
    privilege_del_envcleanup
} #privilege-del

privilege_del_envsetup()
{
    rlPhaseStartSetup "privilege_del_envsetup"
        #environment setup starts here
        KinitAsAdmin
        for id in 1 2 3 4
        do
            rlRun "ipa privilege-add privilege_del_$id --desc=privilege_del_$id" 0 "create privileges for delete test id=[$id]"
        done
        Kcleanup
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_del_envcleanup()
{
    rlPhaseStartCleanup "privilege_del_envcleanup"
        #environment cleanup starts here
        # up to this point, all delete related test data suppose to be removed from ipa server
        rlPass "no special cleanup required"
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_del_1001()
{ #test_scenario (positive): --continue
    rlPhaseStartTest "privilege_del_1001"
        local testID="privilege_del_1001"
        local tmpout=$TmpDir/privilege_del_1001.$RANDOM.out
        KinitAsAdmin
        rlRun "ipa privilege-del --continue $testID " 0 "delete a privilege that does not exist" 
        rlRun "ipa privilege-del --continue privilege_del_1 $testID" 0 "delete mixed list of privileges"
        rlRun "ipa privilege-del --continue $testID privilege_del_2" 0 "delete mixed list of privileges"
        rlRun "ipa privilege-del --continue privilege_del_3 $testID privilege_del_4" 0 "delete mixed list of privileges"
        total=`ipa privilege-find privilege_del_ | grep -i "Privilege name: privilege_del_" | wc -l`
        if [ "$total" = "0" ];then
            rlPass "all test privilege_del_[1234] deleted as expected"
        else
            rlFail "not all test privilege deleted"
            echo "============================="
            ipa privilege-find privilege_del_
            echo "============================="
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_del_1001

#END OF TEST CASE for [privilege-del]

#############################################
#  test suite: privilege-find (14 test cases)
#############################################
privilege_find()
{
    privilege_find_envsetup
    privilege_find_1001  #test_scenario (positive test): [--all]
#    privilege_find_1002  #test_scenario (negative test): [--all --desc;positive;auto_generated_description_data_$testID --name;negative;STR --raw --sizelimit;positive;2 --timelimit;positive;2]
#    privilege_find_1003  #test_scenario (negative test): [--all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;negative;-2,a,abc --timelimit;positive;2]
#    privilege_find_1004  #test_scenario (negative test): [--all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;positive;2 --timelimit;negative;-2,a,abc]
#    privilege_find_1005  #test_scenario (positive test): [--all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;positive;2 --timelimit;positive;2]
    privilege_find_1006  #test_scenario (positive test): [--desc;positive;auto_generated_description_data_$testID]
    privilege_find_1007  #test_scenario (negative test): [--name;negative;STR]
    privilege_find_1008  #test_scenario (positive test): [--name;positive;$testID]
    privilege_find_1009  #test_scenario (boundary test): [--sizelimit;boundary;0]
    privilege_find_1010  #test_scenario (negative test): [--sizelimit;negative;-2,a,abc]
    privilege_find_1011  #test_scenario (positive test): [--sizelimit;positive;2]
    privilege_find_1012  #test_scenario (boundary test): [--timelimit;boundary;0]
    privilege_find_1013  #test_scenario (negative test): [--timelimit;negative;-2,a,abc]
    privilege_find_1014  #test_scenario (positive test): [--timelimit;positive;2]
    privilege_find_envcleanup
} #privilege-find

privilege_find_envsetup()
{
    rlPhaseStartSetup "privilege_find_envsetup"
        #environment setup starts here
        createTestPrivilege $testPrivilege
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_find_envcleanup()
{
    rlPhaseStartCleanup "privilege_find_envcleanup"
        #environment cleanup starts here
        deleteTestPrivilege $testPrivilege
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_find_1001()
{ #test_scenario (positive): --all
    rlPhaseStartTest "privilege_find_1001"
        local testID="privilege_find_1001"
        local tmpout=$TmpDir/privilege_find_1001.$RANDOM.out
        KinitAsAdmin
        ipa privilege-find $testPrivilege --all 2>&1 >$tmpout
        if grep -i "$testPrivilege" $tmpout 2>&1 >/dev/null ;then
            rlPass "found test privilege"
        else
            rlFail "test privilege not found when --all is given"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1001

privilege_find_1002()
{ #test_scenario (negative): --all --desc;positive;auto_generated_description_data_$testID --name;negative;STR --raw --sizelimit;positive;2 --timelimit;positive;2
    rlPhaseStartTest "privilege_find_1002"
        local testID="privilege_find_1002"
        local tmpout=$TmpDir/privilege_find_1002.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        local name_TestValue_Negative="STR" #name;negative;STR
        local sizelimit_TestValue="2" #sizelimit;positive;2
        local timelimit_TestValue="2" #timelimit;positive;2
        local expectedErrMsg=replace_me
        local expectedErrCode=1
        qaRun "ipa privilege-find $testID --all  --desc=$desc_TestValue  --name=$name_TestValue_Negative --raw  --sizelimit=$sizelimit_TestValue  --timelimit=$timelimit_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [desc]=[$desc_TestValue] [name]=[$name_TestValue_Negative] [sizelimit]=[$sizelimit_TestValue] [timelimit]=[$timelimit_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1002

privilege_find_1003()
{ #test_scenario (negative): --all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;negative;-2,a,abc --timelimit;positive;2
    rlPhaseStartTest "privilege_find_1003"
        local testID="privilege_find_1003"
        local tmpout=$TmpDir/privilege_find_1003.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        local name_TestValue="$testID" #name;positive;$testID
        local sizelimit_TestValue_Negative="-2,a,abc" #sizelimit;negative;-2,a,abc
        local timelimit_TestValue="2" #timelimit;positive;2
        local expectedErrMsg=replace_me
        local expectedErrCode=1
        qaRun "ipa privilege-find $testID --all  --desc=$desc_TestValue  --name=$name_TestValue --raw  --sizelimit=$sizelimit_TestValue_Negative  --timelimit=$timelimit_TestValue " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [desc]=[$desc_TestValue] [name]=[$name_TestValue] [sizelimit]=[$sizelimit_TestValue_Negative] [timelimit]=[$timelimit_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1003

privilege_find_1004()
{ #test_scenario (negative): --all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;positive;2 --timelimit;negative;-2,a,abc
    rlPhaseStartTest "privilege_find_1004"
        local testID="privilege_find_1004"
        local tmpout=$TmpDir/privilege_find_1004.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        local name_TestValue="$testID" #name;positive;$testID
        local sizelimit_TestValue="2" #sizelimit;positive;2
        local timelimit_TestValue_Negative="-2,a,abc" #timelimit;negative;-2,a,abc
        local expectedErrMsg=replace_me
        local expectedErrCode=1
        qaRun "ipa privilege-find $testID --all  --desc=$desc_TestValue  --name=$name_TestValue --raw  --sizelimit=$sizelimit_TestValue  --timelimit=$timelimit_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [desc]=[$desc_TestValue] [name]=[$name_TestValue] [sizelimit]=[$sizelimit_TestValue] [timelimit]=[$timelimit_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1004

privilege_find_1005()
{ #test_scenario (positive): --all --desc;positive;auto_generated_description_data_$testID --name;positive;$testID --raw --sizelimit;positive;2 --timelimit;positive;2
    rlPhaseStartTest "privilege_find_1005"
        local testID="privilege_find_1005"
        local tmpout=$TmpDir/privilege_find_1005.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        local name_TestValue="$testID" #name;positive;$testID
        local sizelimit_TestValue="2" #sizelimit;positive;2
        local timelimit_TestValue="2" #timelimit;positive;2
        rlRun "ipa privilege-find $testID --all  --desc=$desc_TestValue  --name=$name_TestValue --raw  --sizelimit=$sizelimit_TestValue  --timelimit=$timelimit_TestValue " 0 "test options:  [desc]=[$desc_TestValue] [name]=[$name_TestValue] [sizelimit]=[$sizelimit_TestValue] [timelimit]=[$timelimit_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1005

privilege_find_1006()
{ #test_scenario (positive): --desc;positive;auto_generated_description_data_$testID
    rlPhaseStartTest "privilege_find_1006"
        local testID="privilege_find_1006"
        local tmpout=$TmpDir/privilege_find_1006.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="4_$testPrivilege" #desc;positive;auto_generated_description_data_$testID
        total=`ipa privilege-find --desc=$desc_TestValue | grep -i "$desc_TestValue" | wc -l`
        if [ "$total" = "1" ];then
            rlPass "found privilege based on desc"
        else
            rlFail "no privilege found based on desc -- when 1 is expected"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1006

privilege_find_1007()
{ #test_scenario (negative): --name;negative;STR
    rlPhaseStartTest "privilege_find_1007"
        local testID="privilege_find_1007"
        local tmpout=$TmpDir/privilege_find_1007.$RANDOM.out
        KinitAsAdmin
        local expectedErrMsg="name option requires an argument"
        local expectedErrCode=2
        qaRun "ipa privilege-find --name " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [name]=[$name_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1007

privilege_find_1008()
{ #test_scenario (positive): --name;positive;$testID
    rlPhaseStartTest "privilege_find_1008"
        local testID="privilege_find_1008"
        local tmpout=$TmpDir/privilege_find_1008.$RANDOM.out
        KinitAsAdmin
        local name_TestValue="$testPrivilege" #name;positive;$testID
        total=`ipa privilege-find --name=$testPrivilege | grep "Privilege name" | grep -i "$testPrivilege" | wc -l`
        if [ "$total" = "1" ];then
            rlPass "found privilege based on desc"
        else
            rlFail "no privilege found based on desc -- when 1 is expected, actual [$total]"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1008

privilege_find_1009()
{ #test_scenario (boundary): --sizelimit;boundary;0
    rlPhaseStartTest "privilege_find_1009"
        local testID="privilege_find_1009"
        local tmpout=$TmpDir/privilege_find_1009.$RANDOM.out
        KinitAsAdmin
        local allPrivileges=""
        local i=0
        while [ $i -lt 4 ];do
            name="testPri_$RANDOM"
            allPrivileges="$allPrivileges $name"
            rlRun "ipa privilege-add $name --desc=testPrivileges"
            i=$((i+1))
        done
        local sizelimit_TestValue="0" #sizelimit;boundary;0
        total=`ipa privilege-find testPri_ | grep "Privilege name" | grep -i "testPri_" | wc -l`
        if [ $total -eq 4 ];then
            found=`ipa privilege-find testPri_ --sizelimit=$sizelimit_TestValue  | grep -i "testPri_" | wc -l`
            if [ $found -eq $total ];then
                rlPass "total returned as we expected"
            else
                rlFail "set limit to [$sizelimit_TestValue], but returned: [$found]"
            fi
        else
            rlFail "total created test privileges not right, test failed due to env total=[$total], expect [4]"
        fi
        for privilege in $allPrivileges;do
            rlRun "ipa privilege-del $privilege"
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1009

privilege_find_1010()
{ #test_scenario (negative): --sizelimit;negative;-2,a,abc
    rlPhaseStartTest "privilege_find_1010"
        local testID="privilege_find_1010"
        local tmpout=$TmpDir/privilege_find_1010.$RANDOM.out
        KinitAsAdmin
        local sizelimit_TestValue_Negative="abc" #sizelimit;negative;-2,a,abc
        local expectedErrMsg="invalid 'sizelimit': must be an integer"
        local expectedErrCode=1
        qaRun "ipa privilege-find $testID  --sizelimit=$sizelimit_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [sizelimit]=[$sizelimit_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1010

privilege_find_1011()
{ #test_scenario (positive): --sizelimit;positive;2
    rlPhaseStartTest "privilege_find_1011"
        local testID="privilege_find_1011"
        local tmpout=$TmpDir/privilege_find_1011.$RANDOM.out
        KinitAsAdmin
        local sizelimit_TestValue="2" #sizelimit;positive;2
        total=`ipa privilege-find --sizelimit=$sizelimit_TestValue | grep "Privilege name" | wc -l`
        if [ $total -eq $sizelimit_TestValue ];then
            rlPass "returned total matches as expected [$total]"
        else
            rlFail "expect [$sizelimit_TestValue], but actual [$total] returned"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1011

privilege_find_1012()
{ #test_scenario (boundary): --timelimit;boundary;0
    rlPhaseStartTest "privilege_find_1012"
        local testID="privilege_find_1012"
        local tmpout=$TmpDir/privilege_find_1012.$RANDOM.out
        KinitAsAdmin
        local timelimit_TestValue="0" #timelimit;boundary;0
        local errorMsg=replaceme
        qaRun "ipa privilege-find --timelimit=$timelimit_TestValue " 1 "$errorMsg" "test options:  [timelimit]=[$timelimit_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1012

privilege_find_1013()
{ #test_scenario (negative): --timelimit;negative;-2,a,abc
    rlPhaseStartTest "privilege_find_1013"
        local testID="privilege_find_1013"
        local tmpout=$TmpDir/privilege_find_1013.$RANDOM.out
        KinitAsAdmin
        local timelimit_TestValue_Negative="abc" #timelimit;negative;-2,a,abc
        local expectedErrMsg="invalid 'timelimit': must be an integer"
        local expectedErrCode=1
        qaRun "ipa privilege-find $testID  --timelimit=$timelimit_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [timelimit]=[$timelimit_TestValue_Negative]" 
        timelimit_TestValue_Negative="-2"
        expectedErrMsg="invalid 'timelimit': must be at least 0"
        expectedErrCode=1
        qaRun "ipa privilege-find $testID  --timelimit=$timelimit_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [timelimit]=[$timelimit_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1013

privilege_find_1014()
{ #test_scenario (positive): --timelimit;positive;2
    rlPhaseStartTest "privilege_find_1014"
        local testID="privilege_find_1014"
        local tmpout=$TmpDir/privilege_find_1014.$RANDOM.out
        KinitAsAdmin
        local timelimit_TestValue="2" #timelimit;positive;2
        rlRun "ipa privilege-find --timelimit=$timelimit_TestValue " 0 "test options:  [timelimit]=[$timelimit_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_find_1014

#END OF TEST CASE for [privilege-find]

#############################################
#  test suite: privilege-mod (9 test cases)
#############################################
privilege_mod()
{
    privilege_mod_envsetup
    privilege_mod_1001  #test_scenario (negative test): [--addattr;negative;STR]
    privilege_mod_1002  #test_scenario (positive test): [--addattr;positive;STR]
    privilege_mod_1003  #test_scenario (positive test): [--desc;positive;auto_generated_description_data_$testID]
    privilege_mod_1004  #test_scenario (negative test): [--desc;positive;auto_generated_description_data_$testID --rename;negative;STR]
    privilege_mod_1005  #test_scenario (positive test): [--desc;positive;auto_generated_description_data_$testID --rename;positive;re$testID]
    privilege_mod_1006  #test_scenario (negative test): [--rename;negative;STR]
    privilege_mod_1007  #test_scenario (positive test): [--rename;positive;re$testID]
    privilege_mod_1008  #test_scenario (negative test): [--setattr;negative;STR]
    privilege_mod_1009  #test_scenario (positive test): [--setattr;positive;STR]
    privilege_mod_envcleanup
} #privilege-mod

privilege_mod_envsetup()
{
    rlPhaseStartSetup "privilege_mod_envsetup"
        #environment setup starts here
        createTestPrivilege $testPrivilege 
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_mod_envcleanup()
{
    rlPhaseStartCleanup "privilege_mod_envcleanup"
        #environment cleanup starts here
        deleteTestPrivilege $testPrivilege
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_mod_1001()
{ #test_scenario (negative): --addattr;negative;STR
    rlPhaseStartTest "privilege_mod_1001"
        local testID="privilege_mod_1001"
        local tmpout=$TmpDir/privilege_mod_1001.$RANDOM.out
        KinitAsAdmin
        local addattr_TestValue_Negative="STR" #addattr;negative;STR
        local expectedErrMsg="invalid 'addattr': Invalid format. Should be name=value"
        local expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege --addattr=$addattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [addattr]=[$addattr_TestValue_Negative]" 
        # memberof value should not be able to modified here, use can only do permission operation through privilege-add/remove-permission
        addattr_TestValue_Negative="memberof=$testPermission_addgrp" #addattr;negative;STR
        expectedErrMsg="Insufficient access: Insufficient 'write' privilege to the 'memberOf' attribute of entry"
        qaRun "ipa privilege-mod $testPrivilege --addattr=$addattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [addattr]=[$addattr_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1001

privilege_mod_1002()
{ #test_scenario (positive): --addattr;positive;STR
    rlPhaseStartTest "privilege_mod_1002"
        local testID="privilege_mod_1002"
        local tmpout=$TmpDir/privilege_mod_1002.$RANDOM.out
        KinitAsAdmin
        local addattr_TestValue="description=newDescFor$testID" #addattr;positive;STR
        local expectedErrMsg="description: Only one value allowed"
        local expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege --addattr=$addattr_TestValue " $expectedErrCode "$expectedErrMsg" "test options:  [addattr]=[$addattr_TestValue]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1002

privilege_mod_1003()
{ #test_scenario (positive): --desc;positive;auto_generated_description_data_$testID
    rlPhaseStartTest "privilege_mod_1003"
        local testID="privilege_mod_1003"
        local tmpout=$TmpDir/privilege_mod_1003.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        rlRun "ipa privilege-mod $testPrivilege --desc=$desc_TestValue " 0 "test options:  [desc]=[$desc_TestValue]" 
        checkPrivilegeInfo $testPrivilege "description" "$desc_TestValue"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1003

privilege_mod_1004()
{ #test_scenario (negative): --desc;positive;auto_generated_description_data_$testID --rename;negative;STR
    rlPhaseStartTest "privilege_mod_1004"
        local testID="privilege_mod_1004"
        local tmpout=$TmpDir/privilege_mod_1004.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_$testID" #desc;positive;auto_generated_description_data_$testID
        local rename_TestValue_Negative="" #rename;negative;STR
        local expectedErrMsg=replace_me
        local expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege  --desc=$desc_TestValue  --rename=$rename_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [desc]=[$desc_TestValue] [rename]=[$rename_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1004

privilege_mod_1005()
{ #test_scenario (positive): --desc;positive;auto_generated_description_data_$testID --rename;positive;re$testID
    rlPhaseStartTest "privilege_mod_1005"
        local testID="privilege_mod_1005"
        local tmpout=$TmpDir/privilege_mod_1005.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="auto_generated_description_data_re$testID" #desc;positive;auto_generated_description_data_$testID
        local rename_TestValue="re$testID" #rename;positive;re$testID
        rlRun "ipa privilege-mod $testPrivilege  --desc=$desc_TestValue  --rename=$rename_TestValue " 0 "test options:  [desc]=[$desc_TestValue] [rename]=[$rename_TestValue]" 
        rlRun "ipa privilege-mod $rename_TestValue --rename=$testPrivilege" 0 "rename it back to original"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1005

privilege_mod_1006()
{ #test_scenario (negative): --rename;negative;STR
    rlPhaseStartTest "privilege_mod_1006"
        local testID="privilege_mod_1006"
        local tmpout=$TmpDir/privilege_mod_1006.$RANDOM.out
        KinitAsAdmin
        local rename_TestValue_Negative="" #rename;negative;STR
        local expectedErrMsg=replace_me
        local expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege --rename=$rename_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [rename]=[$rename_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1006

privilege_mod_1007()
{ #test_scenario (positive): --rename;positive;re$testID
    rlPhaseStartTest "privilege_mod_1007"
        local testID="privilege_mod_1007"
        local tmpout=$TmpDir/privilege_mod_1007.$RANDOM.out
        KinitAsAdmin
        local rename_TestValue="re$testID" #rename;positive;re$testID
        rlRun "ipa privilege-mod $testPrivilege  --rename=$rename_TestValue " 0 "test options:  [rename]=[$rename_TestValue]" 
        rlRun "ipa privilege-mod $rename_TestValue --rename=$testPrivilege" 0 "rename it back to original"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1007

privilege_mod_1008()
{ #test_scenario (negative): --setattr;negative;STR
    rlPhaseStartTest "privilege_mod_1008"
        local testID="privilege_mod_1008"
        local tmpout=$TmpDir/privilege_mod_1008.$RANDOM.out
        KinitAsAdmin
        local setattr_TestValue_Negative="STR" #setattr;negative;STR
        local expectedErrMsg="invalid 'setattr': Invalid format. Should be name=value"
        local expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege  --setattr=$setattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [setattr]=[$setattr_TestValue_Negative]" 
        setattr_TestValue_Negative="memberof=$testPermission_removegrp" #setattr;negative;STR
        expectedErrMsg="Insufficient access: Insufficient 'write' privilege to the 'memberOf' attribute of entry"
        expectedErrCode=1
        qaRun "ipa privilege-mod $testPrivilege  --setattr=$setattr_TestValue_Negative " "$tmpout" $expectedErrCode "$expectedErrMsg" "test options:  [setattr]=[$setattr_TestValue_Negative]" 
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1008

privilege_mod_1009()
{ #test_scenario (positive): --setattr;positive;STR
    rlPhaseStartTest "privilege_mod_1009"
        local testID="privilege_mod_1009"
        local tmpout=$TmpDir/privilege_mod_1009.$RANDOM.out
        KinitAsAdmin
        local desc_TestValue="new_description_$testID"
        local setattr_TestValue="description=$desc_TestValue" #setattr;positive;STR
        rlRun "ipa privilege-mod $testPrivilege --setattr=$setattr_TestValue " 0 "test options:  [setattr]=[$setattr_TestValue]" 
        checkPrivilegeInfo $testPrivilege "description" "$desc_TestValue"
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_mod_1009

#END OF TEST CASE for [privilege-mod]

#############################################
#  test suite: privilege-remove_permission (2 test cases)
#############################################
privilege_remove_permission()
{
    privilege_remove_permission_envsetup
    privilege_remove_permission_1001  #test_scenario (negative test): [--permissions;negative;nonListValue]
    privilege_remove_permission_1002  #test_scenario (positive test): [--permissions;positive;read,write,delete,add,all]
    privilege_remove_permission_envcleanup
} #privilege-remove_permission

privilege_remove_permission_envsetup()
{
    rlPhaseStartSetup "privilege_remove_permission_envsetup"
        #environment setup starts here
        createTestPrivilege $testPrivilege
        KinitAsAdmin
        rlRun "ipa permission-add priTest_1 --desc=4_removetest_1 --permissions=read --type=user" 0  "test for priTest_1"
        rlRun "ipa permission-add priTest_2 --desc=4_removetest_2 --permissions=write --type=user" 0 "test for priTest_2"
        rlRun "ipa permission-add priTest_3 --desc=4_removetest_3 --permissions=add --type=user"
        rlRun "ipa privilege-add $testPrivilege --permissions=priTest_1,priTest_2,pri_Test3" 0 "add pritest_1 pritest_2 and pritest_3 to $testPrivilege"
        Kcleanup
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_remove_permission_envcleanup()
{
    rlPhaseStartCleanup "privilege_remove_permission_envcleanup"
        #environment cleanup starts here
        deleteTestPrivilege $testPrivilege
        KinitAsAdmin
        rlRun "ipa permission-del priTest_1 " 0 "delete pritest_1"
        rlRun "ipa permission-del priTest_2 " 0 "delete pritest_2"
        rlRun "ipa permission-del priTest_3 " 0 "delete pritest_3"
        Kcleanup
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_remove_permission_1001()
{ #test_scenario (negative): --permissions;negative;nonListValue
    rlPhaseStartTest "privilege_remove_permission_1001"
        local testID="privilege_remove_permission_1001"
        local tmpout=$TmpDir/privilege_remove_permission_1001.$RANDOM.out
        KinitAsAdmin
        local permissions_TestValue_Negative="nonListValue" #permissions;negative;nonListValue
        local expectedErrMsg="permission not found"
        if ipa privilege-remove-permission $testPrivilege  --permissions=$permissions_TestValue_Negative | grep "$expectedErrMsg";then
            rlPass "remove nonexist permission failed as expected"
        else
            rlFail "no expected error msg found"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_remove_permission_1001

privilege_remove_permission_1002()
{ #test_scenario (positive): --permissions;positive;read,write,delete,add,all
    rlPhaseStartTest "privilege_remove_permission_1002"
        local testID="privilege_remove_permission_1002"
        local tmpout=$TmpDir/privilege_remove_permission_1002.$RANDOM.out
        KinitAsAdmin
        local permissions_TestValue="priTest_1 priTest_2 priTest_3" #permissions;positive;read,write,delete,add,all
        for permission in $permissions_TestValue;do
            rlRun "ipa privilege-remove-permission $testPrivilege  --permissions=$permission" \
                  0 "test options:  [permissions]=[$permission]" 
        done
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_remove_permission_1002

#END OF TEST CASE for [privilege-remov_-permission]

#############################################
#  test suite: privilege-show (1 test cases)
#############################################
privilege_show()
{
    privilege_show_envsetup
    privilege_show_1001  #test_scenario (positive test): [--all --raw --rights]
    privilege_show_envcleanup
} #privilege-show

privilege_show_envsetup()
{
    rlPhaseStartSetup "privilege_show_envsetup"
        #environment setup starts here
        createTestPrivilege $testPrivilege
        #environment setup ends   here
    rlPhaseEnd
} #envsetup

privilege_show_envcleanup()
{
    rlPhaseStartCleanup "privilege_show_envcleanup"
        #environment cleanup starts here
        deleteTestPrivilege $testPrivilege
        #environment cleanup ends   here
    rlPhaseEnd
} #envcleanup

privilege_show_1001()
{ #test_scenario (positive): --all --raw --rights
    rlPhaseStartTest "privilege_show_1001"
        local testID="privilege_show_1001"
        local tmpout=$TmpDir/privilege_show_1001.$RANDOM.out
        KinitAsAdmin
        ipa privilege-show $testPrivilege --all --raw --rights > $tmpout
        if grep "objectclass" $tmpout 2>&1;then
            rlPass "get objectclass info"
        else
            rlFail "no objectclass info found"
        fi
        if grep "attributelevelrights" $tmpout 2>&1;then
            rlPass "get rights info"
        else
            rlFail "no rights info found"
        fi
        Kcleanup
        rm $tmpout
    rlPhaseEnd
} #privilege_show_1001

#END OF TEST CASE for [privilege-show]
