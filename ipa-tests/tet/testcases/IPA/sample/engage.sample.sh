#/bin/sh
#
# File Name: engage.sample
#
sample_default()
{
	if [ -z "$SampleRunIt" ]
	then
		SampleRunIt=n
	fi

	if [ -z "$SamplePerlRunIt" ]
	then
		SamplePerlRunIt=n
	fi

       if [ -z "$SampleGuiRunIt" ]
        then
                SampleGuiRunIt=n
        fi



        if [ -z "$LdifFile" ] ;        then LdifFile="Airius.ldif"     ; fi
        if [ -z "$SuffixName" ] ;       then SuffixName="o=airius.com"  ; fi
}

# This function will ask the user for more information/choices if needed.
#
sample_ask()
{
	sav_SampleRunIt=$SampleRunIt
        sav_SamplePerlRunIt=$SamplePerlRunIt
	echo "    Execute sample test suite in perl [$SamplePerlRunIt] ? \c"
	read rsp
	case $rsp in
		"")	SamplePerlRunIt=$sav_SamplePerlRunIt	;;
		y|Y)	SamplePerlRunIt=y ;;
		*)	SamplePerlRunIt=n		;;
	esac

        #if [ $SamplePerlRunIt = y ]
        #then
        # return                
        #fi
 
	echo "    Execute sample test suite in korn shell [$SampleRunIt] ? \c"
	read rsp
	case $rsp in
		"")	SampleRunIt=$sav_SampleRunIt	;;
		y|Y)	SampleRunIt=y ;;
		*)	SampleRunIt=n		;;
	esac

        sav_SampleGuiRunIt=$SampleGuiRunIt
        echo "    Execute Sample Gui test suite [$SampleGuiRunIt] ? \c"
        read rsp1
        case $rsp1 in
                "")     SampleGuiRunIt=$sav_SampleGuiRunIt      ;;
                y|Y)    SampleGuiRunIt=y                ;;
                *)      SampleGuiRunIt=n                ;;
        esac


        if [ $SampleGuiRunIt = y ]
        then

		echo "        Name of the ldif file to import [$LdifFile]: \c"
        	sav_ldiffile=$LdifFile
        	read LdifFile
        	if [ -z "$LdifFile" ] ; then LdifFile=$sav_ldiffile ; fi

        	echo "        Suffix name [$SuffixName]: \c"
        	sav_suffixname=$SuffixName
        	read SuffixName
        	if [ -z "$SuffixName" ] ; then SuffixName=$sav_suffixname ; fi
     fi

}

# This function will print the user's choices (aka variables)
#
sample_print()
{
	echo "    Execute sample test suite        : $SampleRunIt"
        echo "    Execute Sample Perl test suite   : $SamplePerlRunIt"
        echo "    Execute Sample Gui Test suite    : $SampleGuiRunIt "
        if [ $SampleGuiRunIt = y ]
        then
		echo "    Ldif File to  import             : $LdifFile "
		echo "    SuffixName                       : $SuffixName "
	fi

}

# This function will echo in shell's format the user's choices
# It is the calling function that will redirect the output to
# the saved config file.
#
sample_save()
{
	echo "SampleRunIt=$SampleRunIt"
        echo "SamplePerlRunIt=$SamplePerlRunIt"
        echo "SampleGuiRunIt=$SampleGuiRunIt"
        echo "LdifFile=$LdifFile"
        echo "SuffixName=$SuffixName"

}

# This function will check that the test suite may be executed
# It may also perform some kind of pre-configuration of the machine.
# This function should "exit 1" if there is problem.
#
sample_check()
{
	kgb=kgb
}

# This function will startup/initiate the test suite
#
sample_startup()
{
	echo "Sample_Startup running"
}

# This function will run the test suite
#
sample_run()
{
	if [ $SampleRunIt = y ]
	then
	echo "Sample run... TET_ROOT is $TET_ROOT MainTccName is $MainTccName"
	echo "$TET_ROOT/$MainTccName -e -s $TET_ROOT/testcases/IPA/sample/tet_scen.sh -x $TET_ROOT/testcases/IPA/tetexecpl.cfg $TET_ROOT/testcases/IPA/sample sample"
	pwd
	$TET_ROOT/$MainTccName -e -s $TET_ROOT/testcases/IPA/sample/tet_scen.sh -x $TET_ROOT/testcases/IPA/tetexecpl.cfg $TET_ROOT/testcases/IPA/sample sample
	$TET_ROOT/$MainTccName \
		-e -s $TET_ROOT/testcases/IPA/sample/tet_scen.sh \
		-x $TET_ROOT/testcases/IPA/tetexecpl.cfg \
		$TET_ROOT/testcases/IPA/sample \
		sample > $MainTmpDir/sample.run.out 2>&1

	echo ""
	echo "journal file is $MainTmpDir/sample.run.out"
	echo ""
	cat $MainTmpDir/sample.run.out
	echo ""
	main_analyze "Sample run" `grep "tcc: journal file is" $MainTmpDir/sample.run.out | awk '{print $5}'` $MainTmpDir/sample.run.out
	MainReportFiles="$MainReportFiles $MainTmpDir/sample.run.out"
       fi
	
	if [ $SamplePerlRunIt = y ]
	then
	echo "Sample run perl..."

	perl_check

	$TET_ROOT/$MainTccName \
		-e -s $TET_ROOT/../testcases/DS/$VER/sample/tet_scen.sh \
		-x $TET_ROOT/../tetexecpl.cfg \
		$TET_ROOT/../testcases/DS/$VER/sample \
		sampleperl > $MainTmpDir/sample.run.out 2>&1
	main_analyze "Sample run" `grep "tcc: journal file is" $MainTmpDir/sample.run.out | awk '{print $5}'` $MainTmpDir/sample.run.out
	MainReportFiles="$MainReportFiles $MainTmpDir/sample.run.out"
       fi
    return 
}


# This function will run the Gui tests suite

sample_gui_run()
{
        if [ $SampleGuiRunIt = n ]
        then
                return
        fi
        echo " Sample Gui run..."
        $TET_ROOT/$MainTccName \
                -e -s $TET_ROOT/../testcases/DS/4.1/sample/tet_scen.sh \
                -x $TET_ROOT/../tetexec.cfg \
                $TET_ROOT/../testcases/DS/4.1/sample \
        runguitest  > $MainTmpDir/sample.gui.out 2>&1

        main_analyze "sample Gui run" `grep "tcc: journal file is" $MainTmpDir/sample.gui.out | awk  '{print $5}'` $MainTmpDir/sample.gui.out 1


        MainReportFiles="$MainReportFiles $MainTmpDir/sample.gui.out"
}

# This function will cleanup after the test suite execution
#
sample_cleanup()
{
:
}

sample_perlrun()
{
	if [ $SampleRunIt = n ]
	then
		return
	fi
	echo "Sample run (in perl)..."
	$TET_ROOT/$MainTccName \
		-e -s $TET_ROOT/../testcases/DS/4.1/sample/tet_scen.sh \
		-x $TET_ROOT/../tetexec.cfg \
		$TET_ROOT/../testcases/DS/4.1/sampleperl \
		sample > $MainTmpDir/sample.run.out 2>&1
	main_analyze "Sample run" `grep "tcc: journal file is" $MainTmpDir/sample.run.out | awk '{print $5}'` $MainTmpDir/sample.run.out
	MainReportFiles="$MainReportFiles $MainTmpDir/sample.run.out"
}


#
# End of file
