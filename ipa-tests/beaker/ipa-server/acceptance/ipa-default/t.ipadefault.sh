
######################
# test suite         #
######################
ipadefault()
{
    ipadefault_envsetup
    ipadefault_pwpolicy
    ipadefault_config
    ipadefault_envcleanup
} # ipadefault

######################
# test set           #
######################
ipadefault_pwpolicy()
{
    ipadefault_pwpolicy_envsetup
    ipadefault_pwpolicy_all
    ipadefault_pwpolicy_envcleanup
} #ipadefault_pwpolicy

######################
# test set           #
######################
ipadefault_config()
{
    ipadefault_config_envsetup
    ipadefault_config_all
    ipadefault_config_envcleanup
} #ipadefault_config


######################
# test cases         #
######################
ipadefault_envsetup()
{
    rlPhaseStartSetup "ipadefault_envsetup"
        #environment setup starts here
        rlPass "tmpdir=[$TmpDir] no other special environment setup required, use all default setting"
        #environment setup ends   here
    rlPhaseEnd
} #ipadefault_envsetup

ipadefault_envcleanup()
{
    rlPhaseStartCleanup "ipadefault_envcleanup"
        #environment cleanup starts here
        rlPass "no special environment cleanup required, use all default setting"
        #environment cleanup ends   here
    rlPhaseEnd
} #ipadefault_envcleanup

ipadefault_pwpolicy_envsetup()
{
    rlPhaseStartSetup "ipadefault_pwpolicy_envsetup"
        #environment setup starts here
        rlPass "no special environment setup required, use all default setting"
        #environment setup ends   here
    rlPhaseEnd
} #ipadefault_pwpolicy_envsetup

ipadefault_pwpolicy_envcleanup()
{
    rlPhaseStartCleanup "ipadefault_pwpolicy_envcleanup"
        #environment cleanup starts here
        rlPass "no special environment cleanup required, use all default setting"
        #environment cleanup ends   here
    rlPhaseEnd
} #ipadefault_pwpolicy_envcleanup

ipadefault_pwpolicy_all()
{
# looped data   : 
# non-loop data : 
    rlPhaseStartTest "ipadefault_pwpolicy_all"
        rlLog "check the default settings for global password policy"
        ipadefault_pwpolicy_all_logic
    rlPhaseEnd
} #ipadefault_pwpolicy_all

ipadefault_pwpolicy_all_logic()
{
    # accept parameters: NONE
    # test logic starts
        local out=$TmpDir/defaultvalues.$RANDOM.txt
        kinitAs $admin $adminpassword
        rlRun "ipa pwpolicy-show > $out" 0 "read global password policy"
        maxlife=`grep "Max lifetime" $out | cut -d":" -f2 | xargs echo` # unit is in day
        minlife=`grep "Min lifetime" $out | cut -d":" -f2 | xargs echo` # unit is in hour
        history=`grep "History size" $out | cut -d":" -f2 | xargs echo`
        classes=`grep "Character classes" $out | cut -d":" -f2 | xargs echo`
        length=`grep "Min length" $out | cut -d":" -f2 | xargs echo`
        if [ $maxlife = $default_pw_maxlife ];then
            rlPass "password policy maxlife maches [$maxlife]"
        else
            rlFail "password policy maxlife does not match, expect [$default_pw_maxlife], actual [$maxlife]"
        fi

        if [ $minlife = $default_pw_minlife ];then
            rlPass "password policy minlife maches [$minlife]"
        else
            rlFail "password policy minlife does not match, expect [$default_pw_minlife], actual [$minlife]"
        fi

        if [ $history = $default_pw_history ];then
            rlPass "password policy history maches [$history]"
        else
            rlFail "password policy history does not match, expect [$default_pw_history], actual [$history]"
        fi

        if [ $classes = $default_pw_classes ];then
            rlPass "password policy min classes maches [$classes]"
        else
            rlFail "password policy min classes does not match, expect [$default_pw_classes], actual [$classes]"
        fi

        if [ $length = $default_pw_length ];then
            rlPass "password policy min length maches [$length]"
        else
            rlFail "password policy min length does not match, expect [$default_pw_length], actual [$length]"
        fi

        rm $out
    # test logic ends
} # ipadefault_pwpolicy_all_logic 

ipadefault_config_envsetup()
{
    rlPhaseStartSetup "ipadefault_config_envsetup"
        #environment setup starts here
        rlPass "no special environment setup required, use all default setting"
        #environment setup ends   here
    rlPhaseEnd
} #ipadefault_config_envsetup

ipadefault_config_envcleanup()
{
    rlPhaseStartCleanup "ipadefault_config_envcleanup"
        #environment cleanup starts here
        rlPass "no special environment cleanup required, use all default setting"
        #environment cleanup ends   here
    rlPhaseEnd
} #ipadefault_config_envcleanup

ipadefault_config_all()
{
# looped data   : 
# non-loop data : 
    rlPhaseStartTest "ipadefault_config_all"
        rlLog "check the default settings for general ipa server configuration"
        ipadefault_config_all_logic
    rlPhaseEnd
} #ipadefault_config_all

ipadefault_config_all_logic()
{
    # accept parameters: NONE
    # test logic starts
        local out=$TmpDir/defaultvalues.$RANDOM.txt
        kinitAs $admin $adminpassword
        rlRun "ipa config-show > $out" 0 "store config-show in [$out]"
        usernamelength=`grep "Max username length" $out | cut -d":" -f2| xargs echo`
        ipacompare "default user name length" "$default_config_usernamelength" "$usernamelength"

        homebase=`grep "Home directory base" $out | cut -d":" -f2| xargs echo`
        ipacompare "default home base" "$default_config_homebase" "$homebase"
       
        defaultshell=`grep "Default shell" $out | cut -d":" -f2| xargs echo`
        ipacompare "default shell" "$default_config_shell" "$defaultshell"

        usersgroup=`grep "Default users group" $out | cut -d":" -f2| xargs echo`
        ipacompare "Default users group" "$default_config_usergroup" "$usersgroup"

        searchtimelimit=`grep "Search time limit" $out | cut -d":" -f2| xargs echo`
        ipacompare "search time limit" "$default_config_timelimit" "$searchtimelimit"

        searchsizelimit=`grep "Search size limit" $out | cut -d":" -f2| xargs echo`
        ipacompare "search size limit" "$default_config_sizelimit" "$searchsizelimit"

        usersearchfields=`grep "User search fields" $out | cut -d":" -f2| xargs echo`
        ipacompare "user search fields" "$default_config_usersearchfields" "$usersearchfields"

        groupsearchfields=`grep "Group search fields" $out | cut -d":" -f2| xargs echo`
        ipacompare "group search fields" "$default_config_groupsearchfields" "$groupsearchfields"

        migrationmode=`grep "Migration mode"  $out | cut -d":" -f2| xargs echo`
        ipacompare "migration mode" "$default_config_migrationmode" "$migrationmode"

        certsubjectbase=`grep "Certificate Subject base" $out | cut -d":" -f2| xargs echo`
        ipacompare "cert subject base" "$default_config_certsubjectbase" "$certsubjectbase"

        rm $out
    # test logic ends
} # ipadefault_config_all_logic 
