#ident "%W% %E%"
#
#	File name: run.quickinstall
#
#	This file contains the operations specific to the quickinstall tests.
#	It is targetted to be included by the main script "run" and not be be 
#	used alone.
#
#	Replace the "xyz" by your name (e.g. "schema") and "Xyz" by your
#	name (e.g. "Schema").
#
#	Created by Jean-Luc SCHWING - SUN Microsystems :
#		Thu Jul  1 14:47:28 PDT 1999
#
#	History
# -----------------------------------------------------------------------------
# dd/mm/yy | Author	| Comments
# -----------------------------------------------------------------------------
# 01/07/99 | JL SCHWING	| Creation.
# 05/15/08 | MGregg     | modified for IPA tet framework
# -----------------------------------------------------------------------------

# This function will set the default values for the variables needed.
#
quickinstall_default()
{
	if [ -z "$quickinstallRunIt" ]
	then
		quickinstallRunIt=n
	fi
	if [ -z "$quickinstallRunIt" ]
	then
		SRCROOT=""
	fi
	export SRCROOT
}

# This function will ask the user for more information/choices if needed.
#
quickinstall_ask()
{

	sav_quickinstallRunIt=$quickinstallRunIt
	echo "    Execute quickinstall test suite [$quickinstallRunIt] ? \c"
	read rsp
	case $rsp in
		"")	quickinstallRunIt=$sav_quickinstallRunIt	;;
		y|Y)	
			quickinstallRunIt=y
	#		while true
#			do
#				sav_SRCROOT=$SRCROOT
#				echo "    Enter the repo location [$SRCROOT] ?(a dir containing repo files, or a install tarball) \c"
#				read rsp
#				if [ -f "$rsp" ] || [ -d "$rsp" ]; then
#					SRCROOT=$rsp
#					break
#				else
#					echo "Cannot locate file $SRCROOT"
#				fi
#			done
			;;
		*)	quickinstallRunIt=n		;;
	esac

}

# This function will print the user's choices (aka variables)
#
quickinstall_print()
{
	echo "    Execute quickinstall test suite        : $quickinstallRunIt"
#	if [ $quickinstallRunIt = y ] ; then
#		echo "            quickinstall Source location   : $SRCROOT"
#	fi
}

# This function will echo in shell's format the user's choices
# It is the calling function that will redirect the output to
# the saved config file.
#
quickinstall_save()
{
	echo "quickinstallRunIt=$quickinstallRunIt"
	echo "SRCROOT=$SRCROOT"
}

# This function will check that the test suite may be executed
# It may also perform some kind of pre-configuration of the machine.
# This function should "exit 1" if there is problem.
#
quickinstall_check()
{
	kgb=kgb
}

# This function will startup/initiate the test suite
#
quickinstall_startup()
{
:
}

# This function will run the test suite
#
quickinstall_run()
{
	if [ $quickinstallRunIt = n ]
	then
		return
	fi
	if [ $RunInstall = y ] 
	then
		echo "Sorry, you must turn off install before tests if you would like to run the quickInstall test"
		return
	fi
	echo "quickinstall run..."
	echo "$TET_ROOT/$MainTccName -e -s $TET_ROOT/testcases/IPA/acceptance/quickinstall/tet_scen -x $TET_ROOT/testcases/IPA/tetexecpl.cfg $TET_ROOT/testcases/IPA/acceptance/quickinstall install"

	(
	$TET_ROOT/$MainTccName \
		-e -s $TET_ROOT/testcases/IPA/acceptance/quickinstall/tet_scen \
		-x $TET_ROOT/testcases/IPA/tetexecpl.cfg \
		$TET_ROOT/testcases/IPA/acceptance/quickinstall \
		install > $MainTmpDir/quickinstall.startup.out 2>&1
	)&
	EngageTimer $! 2200 120 # wait 2200 sec before kill, then 1200 until kill -9
	echo ""
	echo "quickinstall startup $MainTmpDir/quickinstall.startup.out"
	echo ""
	cat $MainTmpDir/quickinstall.startup.out
	echo ""
	main_analyze "quickinstall startup" `grep "tcc: journal file is" $MainTmpDir/quickinstall.startup.out | awk '{print $5}'` $MainTmpDir/quickinstall.startup.out
	MainReportFiles="$MainReportFiles $MainTmpDir/quickinstall.startup.out"

	Gfile="$TET_TMP_DIR/global_src_`uname -n`"
	rm -f $Gfile
}

# This function will cleanup after the test suite execution
#
quickinstall_cleanup()
{
:
}


#
# End of file
