#ident "%W% %E%"
#
#	File name: run.pwpolicy
#
#	This file contains the operations specific to the pwpolicy tests.
#	It is targetted to be included by the main script "run" and not be be 
#	used alone.
#
#	Replace the "xyz" by your name (e.g. "schema") and "Xyz" by your
#	name (e.g. "Schema").
#
#
#	History
# -----------------------------------------------------------------------------
# dd/mm/yy | Author	| Comments
# -----------------------------------------------------------------------------
# 07/11/08 | MGregg     | Creation from pwpolicy tests
# -----------------------------------------------------------------------------

# This function will set the default values for the variables needed.
#
pwpolicy_default()
{
	if [ -z "$pwpolicyRunIt" ]
	then
		pwpolicyRunIt=n
	fi
}

# This function will ask the user for more information/choices if needed.
#
pwpolicy_ask()
{

	sav_pwpolicyRunIt=$pwpolicyRunIt
	echo "    Execute pwpolicy test suite [$pwpolicyRunIt] ? \c"
	read rsp
	case $rsp in
		"")	pwpolicyRunIt=$sav_pwpolicyRunIt	;;
		y|Y)	
			pwpolicyRunIt=y
			;;
		*)	pwpolicyRunIt=n		;;
	esac

}

# This function will print the user's choices (aka variables)
#
pwpolicy_print()
{
	echo "    Execute pwpolicy test suite        : $pwpolicyRunIt"
}

# This function will echo in shell's format the user's choices
# It is the calling function that will redirect the output to
# the saved config file.
#
pwpolicy_save()
{
	echo "pwpolicyRunIt=$pwpolicyRunIt"
}

# This function will check that the test suite may be executed
# It may also perform some kind of pre-configuration of the machine.
# This function should "exit 1" if there is problem.
#
pwpolicy_check()
{
	kgb=kgb
}

# This function will startup/initiate the test suite
#
pwpolicy_startup()
{
:
}

# This function will run the test suite
#
pwpolicy_run()
{
	if [ $pwpolicyRunIt = n ]
	then
		return
	fi
	echo "pwpolicy run..."
	echo "$TET_ROOT/$MainTccName -e -s $TET_ROOT/testcases/IPA/acceptance/pwpolicy/tet_scen -x $TET_ROOT/testcases/IPA/tetexecpl.cfg $TET_ROOT/testcases/IPA/acceptance/pwpolicy pwpolicy"

	(
	$TET_ROOT/$MainTccName \
		-e -s $TET_ROOT/testcases/IPA/acceptance/pwpolicy/tet_scen \
		-x $TET_ROOT/testcases/IPA/tetexecpl.cfg \
		$TET_ROOT/testcases/IPA/acceptance/pwpolicy \
		pwpolicy > $MainTmpDir/pwpolicy.run.out 2>&1
	)&
	EngageTimer $! 3200 120 # wait 3200 sec before kill, then 1200 until kill -9
	echo ""
	echo "pwpolicy run $MainTmpDir/pwpolicy.run.out"
	echo ""
	cat $MainTmpDir/pwpolicy.run.out
	echo ""
	main_analyze "pwpolicy run" `grep "tcc: journal file is" $MainTmpDir/pwpolicy.run.out | awk '{print $5}'` $MainTmpDir/pwpolicy.run.out
	MainReportFiles="$MainReportFiles $MainTmpDir/pwpolicy.run.out"

	Gfile="$TET_TMP_DIR/global_src_`uname -n`"
	rm -f $Gfile
}

# This function will cleanup after the test suite execution
#
pwpolicy_cleanup()
{
:
}


#
# End of file
