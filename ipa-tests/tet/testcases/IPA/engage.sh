#!/bin/sh
#ident "%W% %E%"
#
#	File name: engage
#
# please use tab stop = 4 when edit this file, ie 
# :set ts=4
#
#	This is the main script of the test automation. It will use the
#	subsidiary scripts (e.g. engage.vlv) to obtain more information and to
#	really engage the test suites.
#
#	All the variables and functions defined here should be prefixed by
#	either main_ (functions) or Main (variables).
#
#	Created by Jean-Luc SCHWING - SUN Microsystems :
#		Tue Jun 29 13:53:00 PDT 1999
#
#	History
# -----------------------------------------------------------------------------
# dd/mm/yy | Author	| Comments
# -----------------------------------------------------------------------------
# 29/06/99 | JL SCHWING	| Creation.
# 21/07/04 | Orla Hegarty | merging bp's 64 bit changes
# 15/06/08 | Michael Gregg | added updates to allow usage in IPA tet system
# -----------------------------------------------------------------------------
# Set this next line to y to see debugging output from engage(not from the tests. This gives a huge ammount of output
export engage_debug=n

grep "Red Hat Enterprise Linux Server release 5" /etc/redhat-release
if [ $? != 0 ]; then
	echo ""
	echo "WARNING!"
	echo "tet has been know to be unreliable when not used on Red Hat Enterprise Linux Server release 5.x"
	echo "fixing engage to make it work well on Fedora is a planned feature for the future"
	echo "This engage will allow you to continue on this machine, but, for now, you are advised"
	echo " to run this engage from RHEL 5.x"
	echo " Hit enter to continue"
	echo ""
	read rsp
fi

if [ "$engage_debug" = "y" ]; then
	set -x;
fi
# Make sure there is no problem with sh users - mandatory for AIX at least
#
unset ENV
# need to run in C locale, 
# TET depends on the output of date command to be in english (dchan 7/02)
LC_ALL=C ; export LC_ALL

export PATH=$PATH:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/sbin:/root/bin
# input script
MainRunScript=$0

# Should be declared first
#
MainOS=`uname -s`
# DisplayOS : more information about the current OS
case $MainOS in
	Windows_NT)
		RelOS=`uname -r`
		if [ "$RelOS" = "4" ]
		then
			DisplayOS="Windows_NT4"
		else
			DisplayOS="Windows_2000"
		fi
	;;
	SunOS)
		RelOS=`uname -r`
		ArchOS=`uname -p`
		DisplayOS=${MainOS}${RelOS}_${ArchOS}
		MainOS=${MainOS}-${ArchOS}
	;;
	Linux)
		# Extract Redhat Release Version for display in email subject
		OS=RHEL # default value
		if [ -f /etc/redhat-release ]
		then

			cat /etc/redhat-release | grep -i "release 4" > /dev/null 2>&1
			if [ $? -eq 0 ];
			then
				OS="RHEL4"
			fi

			cat /etc/redhat-release | grep -i "release 5" > /dev/null 2>&1
			if [ $? -eq 0 ];
			then
				OS="RHEL5"
			fi
		fi

		RelOS=$OS
		ArchOS=`uname -p`
		DisplayOS="${MainOS}_${RelOS}_${ArchOS}"
	;;
	HP-UX)
		# Add the architecture PA_RISC or IA64 to the email subject
		ArchOS=`uname -m`
		DisplayOS=${MainOS}_${ArchOS}
	;;
	*)
		DisplayOS=$MainOS
	;;
esac

# Let's try to figure out *where* are the scripts
case $MainRunScript in
	/*|[a-zA-Z]:*)	mainRunBaseDir=`dirname $MainRunScript`		;;
	*)		mainRunBaseDir=`pwd`/`dirname $MainRunScript`	;;
esac

############### Source Library functions
. $mainRunBaseDir/engagelib

######################################################################
# Site dependent information
# ex : ICNC's sessions will not be on redhat.com
######################################################################
case `engage_domainname` in
	*mtbrook.bozemanpass.com)
	            MailHost="mail"
	            MainMaildomain="bozemanpass.com"
	            ;;
	*)			# if you change WebServer besure to change it in engagelib also
				MailHost="pobox-3.corp.redhat.com"
				MainMaildomain="redhat.com"
				;;
esac

# Silk variables
MainSilkName="c:/Program Files/Segue/SilkTest"
# BackEnd variables
MainQuestions=y
MainConfigFile=./engage.`hostname`.cfg
CP_P="cp -p"
case $MainOS in
	Windows_NT)	MainWhoami="$USERNAME"		;;
	SunOS*)		MainWhoami=`/usr/ucb/whoami`	;;
	*)		MainWhoami=`whoami`		;;
esac


# DRIVE is used for NT, blank for any other platform
# there are no default for DRIVE, this is only use for the automated
# daily acceptance tests.
DRIVE=""
case $MainOS in
	SunOS-sparc)		
		MainTccName=bin/c/sparc-sun-solaris2.6/tcc
		MainPerlName=perl/sparc_sun_solaris2.6/lib/nsPerl5.6.1/bin/nsperl
		MainTmpDir=/tmp
		MainSendmail="/usr/lib/sendmail -t"
		;;
	SunOS-i386)		
		MainTccName=bin/c/i386-sun-solaris2.8/tcc
		MainPerlName=perl/SunOS5.8-i386/lib/nsPerl5.005_03/bin/nsperl
		MainTmpDir=/tmp
		MainSendmail="/usr/lib/sendmail -t"
		;;
	Windows_NT)	
		MainTccName=bin/c/winnt/tcc.exe
		MainPerlName=perl/winnt4.0/lib/nsPerl5.6.1/nsperl
		MainTmpDir=c:/temp
		# a hack for NT, have to have -f somebody
		# most of the time whoami is Administrator, for now force to be robobld
		MainSendmail="smtpmail -f robobld@${MainMaildomain} -h $MailHost"
		#MainWhoami="robobld@${MainMaildomain}"
		MainWhoami=robobld
		# hack the tetexec.cfg so the NT wont make a copy of 
		# test suite before executing (faster)
		echo "TET_EXEC_IN_PLACE=True" > $mainRunBaseDir/../../../tetexec.cfg
		;;
	AIX)
		MainTccName=bin/c/powerpc-ibm-aix4.2.1.0/tcc
		MainPerlName=/perl/aix4.3/lib/nsPerl5.005_03/bin/nsperl
		MainTmpDir=/tmp
		#MainSendmail="/usr/lib/sendmail -t"
		# CR 2001-06-07
		# Use sendmail from $MailHost
		MainSendmail="rsh $MailHost /usr/lib/sendmail -t"
		;;
	Linux)
		MainTccName=bin/tcc
		MainTmpDir=/tmp
		MainPerlName=perl/linux2.2/lib/nsPerl5.6.1/bin/nsperl
		#MainSendmail="/usr/lib/sendmail -t"
		# CR 2001-06-07
		# Use sendmail from $MailHost
		MainSendmail="/usr/lib/sendmail -t"
		CP_P="cp"
		;;
	HP-UX)
		if [ -n "`file /stand/vmunix | grep 'PA-RISC1\.1'`" ]
		then
			MainTccName=bin/c/hppa1.1-hp-hpux10.10/tcc
		else
			# Despite its name, this is a PA-RISC 2.0 binary :-(
			#
			MainTccName=bin/c/hppa1.1-hp-hpux11.00/tcc
		fi
		MainPerlName=perl/hpux11.0/lib/nsPerl5.6.1/bin/nsperl
		MainTmpDir=/tmp
		#MainSendmail="/usr/lib/sendmail -t"
		# CR 2001-06-07
		# Use sendmail from $MailHost
		# MainSendmail="remsh $MailHost /usr/lib/sendmail -t"
		MainSendmail="/usr/lib/sendmail -t"
		CP_P="cp"
		;;
	*)	echo "engage: unknown OS \"`uname -s`\""
		exit 1
		;;
esac

#####################################################
# Non-System dependent variables
#####################################################
# Report Variables 
logTimeStamp=`date '+%Y%m%d-%H%M%S'`

# engage will abort if install failed due to missing global_src_`uanem -n` file
AbortInstallFailed=1
# to store the H:M:S of the elapse time
ElapseStr=""

###### Export variables ########################################
export MainRunScript mainRunBaseDir MainOS
export MainQuestions MainConfigFile MainTccName MainPerlName  MainSendmail MainSilkName

#####################################################
#
#	engage's shared library (analyser, etc...)
#
#####################################################

# This function initiates the final report
# Should be called *before* any test occurs.
#
main_init_report()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	rm -f $MainReport
	touch $MainReport
	if [ ! -f $MainReport ]
	then
		echo "engage: cannot create report file $MainReport"
		exit 1
	fi

	# show the user's choices
	#
	main_print_choices > $MainReport
}

main_fixpath()
# arg : file
# remove the /tmp_mnt fro OSF and IRIX(dchan)
# remove drive letter for NT
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
# web server can't get file contain /../ in it's path
# strip the /../ from path,
n=$1
d=`dirname $n`
rd=`(cd $d; pwd)`
f=`basename $n`
echo $rd/$f | sed 's:/tmp_mnt::g
                   s/[A-Za-z]://g'
}

ENGAGE_MV()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
# mv to a different file system does not work on NT (lgopal 3/00)
in=$1
out=$2
if [ "$MainOS" = "Windows_NT" ]; then
	cp $in $out
	#rm -rf $f	
else
	cp -r $in $out
fi
}

# Analyse a tet journal file and add report to the report file
#
totpass=0
tottestnum=0

main_analyze()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	# Generates the report
	#
	maTestSuite=$1
	maJournal=$2
	maTmpOut=$3
	maType=$4

	if [ $# -lt 3 ]; then
		echo "Warning:main_analyze is called with only $# arguments($*)"
	fi
	######################################################
	# figure out the output directory and log directory
	######################################################
	# move results directory to a new location
	# OutputRoot is the directory to store the jounral and output file
	OutputRoot=${MainReportRoot}/output/${MainOS}
	if [ ! -d $OutputRoot ]; then mkdir -p $OutputRoot; fi
	# all the output file will reside in it's only data directory
	# pick up the testsuite path (ex acceptance/basic ) 
	testsuite=`echo $maJournal | sed -e 's:/result.*::g' -e 's:^.*'$VER'/::g'`
	# logdir ex : $OutputRoot/20000127-144024/acceptance/basic/journal
	logdir=$OutputRoot/$logTimeStamp/$testsuite
	if [ ! -d $logdir ]; then mkdir -p $logdir; fi
	# move the result file there
	newJournalName=$logdir/journal.`basename $maTmpOut`
	ENGAGE_MV $maJournal $newJournalName

	# clean up output directory
	# JLS 05-10-00	DON'T remove this directory !!!
	# JLS 05-10-00	rm -rf `dirname $maJournal`
	# point to the new journal file
	maJournal=$newJournalName

	if [ "$maType" != "" ] && [ $maType -eq 1 ]
	then
		echo "main_silkreport $maTestSuite $maJournal $maTmpOut would go here"
		main_silkreport "$maTestSuite" "$maJournal" $maTmpOut
		return 0
	fi
	# var to determine if replay script needs to be generated
	maFoundNotPassed=n
	echo							>> $MainReport
	echo "############## Result  for  backend test :  $maTestSuite"	>> $MainReport
	echo
	#########################################
	# calculate elapse time
	#########################################
	stime=`grep 'TCC Start' $maJournal | awk '{print $2}' | awk -F: '{print $1*3600+$2*60+$3}'`
	etime=`grep 'TCC End' $maJournal | cut -d\| -f2 | awk -F: '{print $1*3600+$2*60+$3}'`
	elapsetime=`expr $etime - $stime | awk '{printf "%2.2d:%2.2d:%2.2d\n", $1/3600, $1%3600/60, $1%3600%60 }'`
	echo "    $maTestSuite elapse time : $elapsetime" >> $MainReport

	#########################################
	# calculate number of current tests
	#########################################
	# use grep instead of egrep (OSF)
	# OSF egrep will error : *?+ not preceded by valid expression
	# add awk to strip out white spaces
	maNbResTot=`grep '^220|' $maJournal | wc -l | awk '{print $1}'`
	# calculate the total number of tests
	tottestnum=`expr $tottestnum + $maNbResTot`

	# get for test result from journal file
	# add awk to print only the first field
	# some time the line looks like :
	# 220|0 3 7 10:46:17|NORESULT (auto-generated by TCC)
	s=`awk -F'|' '$1 == "220" {print $3}' $maJournal|awk '{print $1}'|sort -u`
	if [ "$s" = "" ]; then # no status, assume FAIL
		s="FAIL"
	fi
	for i in `echo $s`
	do
		maNbRes=`awk -F'|' '$1 == "220" {print $3}' $maJournal | grep $i | wc -l | awk '{print $1}'`
		if [ $maNbRes -eq 0 ]; then
			pcent=0
		else
			pcent=`echo ${maNbRes}00 ${maNbResTot} / p q | dc`
		fi
		echo "    $maTestSuite Tests $i      : ${pcent}% ($maNbRes/$maNbResTot)"      >> $MainReport
		if [ $i != PASS ]
		then
			maFoundNotPassed=y # generate replay script
		else
			totpass=`expr $totpass + $maNbRes` # calculate total % pass
		fi
	done
	echo								>> $MainReport
	echo "    Files are located on `hostname` (`date '+%Y%m%d-%H%M%S'`)" >> $MainReport
	maFixedPath="${WebServer}`main_fixpath $maJournal`"
	maFixedPath_rloc="<a href=$maFixedPath>$maFixedPath</a>"
	echo "    Journal    file: $maFixedPath_rloc"			 >> $MainReport
	for f in $maTmpOut
	do
		maFile=`dirname $maJournal`/`basename $f`.$$
		ENGAGE_MV $f $maFile
		maFixedPath="${WebServer}`main_fixpath $maFile`"
		maFixedPath_rloc="<a href=$maFixedPath>$maFixedPath</a>"
		echo "    Associated file: $maFixedPath_rloc"		 >> $MainReport
	done

	# Generates the scripts to reproduce the problems 
	#
	if [ $maFoundNotPassed = y ]
	then
		# Initiates the tet_scen file
		#
		maTetScen=`dirname $maJournal`/tet_scen.sh
		rm -f $maTetScen
		echo "all"					>> $maTetScen
		echo "\t\"Starting replay of $maTestSuite\""	>> $maTetScen

		cat $maJournal | awk '
			BEGIN { Binary=""
				First=1
				List="0"
			}
			/^10\|/	{ 	if (length(Binary) != 0)
					{
						if (length(List) != 0)
							printf ("\t%s{%s}\n", Binary, List)
					}
					if (First == 1)
					{
						List="0"
						First=0
					}
					else
						List=""
					Binary=$2
				}
			/^400\|/ { 	IcNum=$2
				}
			/^220\|/ {	if (index ($4, "PASS") == 0)
					{
						if (length (List) == 0)
							List=IcNum;
						else
						{
							# This test is to avoid {0,0}
							#
							if (List == IcNum)
								List=IcNum;
							else
								List=List "," IcNum
						}
					}
				}
			END {
				if (length(List) != 0)
				{
					printf ("\t%s{%s}\n", Binary, List);
				}
			}
		' >> $maTetScen

		echo "\t\"Ending replay of $maTestSuite\""	>> $maTetScen
		chmod a+r $maTetScen

		# Create the replay script
		#
		case $MainOS in
			Windows_NT)	maStartFieldNum=9	;;
			*)		maStartFieldNum=10	;;
		esac
		maTetCommandLine=`grep "TCC Start, Command line:" $maJournal | awk '{for (i='$maStartFieldNum' ; i<NF ; i++) printf ("%s ", $i);}'`
		maTetCommandLine=`echo $maTetCommandLine | sed 's,-s [^ ]* ,-s '$maTetScen' ,'`
		# Remplacer le scen dans la commande !
		maReplay=`dirname $maJournal`/replay.sh
		rm -f $maReplay
		echo "#!/bin/sh"		>> $maReplay
		echo 				>> $maReplay
		cat $MainConfigFile		>> $maReplay
		echo				>> $maReplay
		cat $MainConfigFile | grep = | awk -F= '{printf ("export %s\n", $1);}'	>> $maReplay
		echo				>> $maReplay
		echo "$maTetCommandLine all"	>> $maReplay
		chmod a+rx $maReplay

		# Add all these information in the report
		#
		echo "    To replay on `hostname` use the following script:"	>> $MainReport
		echo "        $maReplay"					>> $MainReport
	fi


}

#### Add Silk test result file to the Report
main_silkreport()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	# Generates the report
	#
	maTestSuite=$1
	maJournalFile=$2
    maTmpOut=$3

	maResultFile=`grep "silk: result file is" $maTmpOut | awk '{print $5}'`
	maPassTest=`grep "Tests PASSED :" $maTmpOut | awk '{print $0}'`
	maFailTest=`grep "Tests FAILED :" $maTmpOut | awk '{print $0}'`

	maFoundNotPassed=n

 # Modified by Lakshmi Gopal 08/16/2000 to print the silk report properly

	echo							>> $MainReport
	echo "############## Result for SilkTest :  $maTestSuite " >> $MainReport

	echo								>> $MainReport
    echo " $maTestSuite $maPassTest " >> $MainReport
    echo " $maTestSuite $maFailTest " >> $MainReport
    	
	echo "    Files are located on `hostname`"			>> $MainReport

# Result File

	for f in $maTmpOut
	do
		maFile=`dirname $maJournal`/`basename $maResultFile`
		ENGAGE_MV $maResultFile $maFile
		maFixedPath="${WebServer}`main_fixpath $maFile`"
		echo "    Silk Result file: $maFixedPath"		 >> $MainReport
	done



	
# Journal File

	maFixedPath="${WebServer}`main_fixpath $maJournal`"
 
	echo "    Journal    file: $maFixedPath"			 >> $MainReport

 # move the associated file
	for f in $maTmpOut
	do
		maFile=`dirname $maJournal`/`basename $f`.$$
		ENGAGE_MV $f $maFile
		maFixedPath="${WebServer}`main_fixpath $maFile`"
		echo "    Associated file: $maFixedPath"		 >> $MainReport
	done

}

calnew()
{
# new method of calculating total percent pass
# used to be based on number of testcases, this new function
# will calculate based on number of testsuite
report=$1
# pick out the test pass/total line from the report
# output format : TestName:Percent:Pass:Total  
#  ex:
#	Schema:0%:0:1
#	Schema:100%:19:19

# egrep to pick out the line that contain the the percentage
# sed to replace all "FAIL : 100%" and "NORESULT : 100%" with "PASS : 0%"
# grep to only want to view PASS line
# sometime there are no test run, replace (0/0) with (0/1)
# then remove all lines with NORESULT and FAIL
# last sed to convert to the final format
egrep ' startup.*Tests.*: |run.*Tests.*: | cleanup.*Tests.*: ' $report |\
sed 's/(0\/0)/(0\/1)/g
	 s/FAIL.*: 0% ([0-9]*\//PASS : 0% (0\//g
	 s/FAIL.*: 100% ([0-9]*\//PASS : 0% (0\//g
	 s/NORESULT.*: 100% ([0-9]*\//PASS : 0% (0\//g' | grep PASS |\
sed 's/ startup.*Tests.*PASS.*: /:/g
		s/ run.*Tests.*PASS.*: /:/g
		s/ cleanup.*Tests.*PASS.*: /:/g
		s/^[ ]*//g
		s/ (/:/g
		s/)//g
		s/\//:/g' > $MainTmpDir/a$$

# calculate the total percentage per test suite , Ex:
# Schema startup, Schema run, and Schema cleanup is consider to be one testsuite
# output should look like  : Schema:95
awk -F: 'BEGIN {last=""; tpass=0; ttest=0}
	$1 != last { if (last != "" ) 
					{
					if ( ttest <= 0 ) # no test ran, assume 0% pass
						printf "%s:0\n", last;
					else # TestName:TotalPercentPass
						printf "%s:%d\n", last, tpass/ttest*100;
					}
				tpass=$3 ; ttest=$4 ; # first line of test
				last = $1; next }
	{ tpass=tpass+$3 ; ttest=ttest+$4 }
	END { 
	if (ttest <=0 ) 
		printf "%s:0\n", last 
	else
		printf "%s:%d\n", last, tpass/ttest*100 }' $MainTmpDir/a$$ > $MainTmpDir/b$$

# now calculate the total result based on number of testsuite 
awk -F: '{n=n+1; t=t+$2}
	END{ printf "%d\n", t/n }' $MainTmpDir/b$$
rm $MainTmpDir/a$$ $MainTmpDir/b$$ > /dev/null 2>&1
}

#is function send the final report by mail
main_send_report()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo >> $MainReport

	case $MainOS in
		Windows_NT)
			# NT require the use of smtpmail with users as argument
			# strip out "@ something", only want the name
			#ml=`echo $MainMailTo | sed 's/@[+-~]*//g'`
			# CR 2001-06-07 : does not seem to work
			# -> keep the whole address
			ml=$MainMailTo
			echo NT mail list $ml 
			;;
		*)
			ml=""
			;;
	esac
	# create report dir if not there
    ReportRoot=$MainReportRoot/$MainOS
    if [ ! -d $ReportRoot ]; then mkdir -p $ReportRoot; fi

    # report file
    reportfile=$ReportRoot/${logTimeStamp}.html
	# save the original report file
	plain_reportfile=$ReportRoot/${logTimeStamp}.txt
	cp $MainReport $plain_reportfile

	# calculate the total 
	#totpass=`expr $totpass \* 100`
	#n=0
	#if [ $tottestnum -gt 0 ]; then
	#	n=`expr $totpass / $tottestnum`  # calculate % pass
	#fi
	# new cal method based on number of testsuite not number of testcases
	n=`calnew $MainReport`

	# create mail header file
	if [ "$DSTET_64" = "y" ]; then
		DSBITS="-64"
	fi

	case `engage_domainname` in
	*mtbrook.bozemanpass.com)
		if [ $AbortInstallFailed -eq 2 ]; then
			Subject="ABORTED - ${DisplayOS}${DSBITS} IPA $IPAVERSION ${TEST_CAT} test - $n% pass on `hostname | cut -d'.' -f1`"
		else
		    Subject="${DisplayOS}${DSBITS} IPA $IPAVERSION ${TEST_CAT} test - $n% pass on `hostname  | cut -d'.' -f1`"
		fi
		;;
	*)
		if [ $AbortInstallFailed -eq 2 ]; then
			Subject="ABORTED - IPA $IPAVERSION ${DisplayOS}${DSBITS} ${TEST_CAT} test report - $n% passed on `hostname` using $SRCROOT"
		else
			Subject="IPA $IPAVERSION ${DisplayOS}${DSBITS} ${TEST_CAT} test report - $n% passed on `hostname` using $SRCROOT"
		fi
		;;
	esac

	(
	echo "MIME-Version: 1.0"
	echo "Subject: $Subject"
	if [ "$MainOS" != "SunOS" ]; then
		# sun don't like the from line
		echo "From: ${MainWhoami}@${MainMaildomain}"
	fi
	echo "To: ${MainMailTo}"
	echo "Content-Type: multipart/mixed;"
	echo " boundary=\"------------mailboundary\""
	echo						# blank line needed for sendmail
	) > $MainReportHead

	# create mail content
	if [ -f $TET_ROOT/../CVS/Tag ]; then
	    TESTTAG=`cat $TET_ROOT/../CVS/Tag | sed 's/^N//g'`
	else
	    TESTTAG="none"
	fi
	(
	echo "Subject: $Subject"
	echo "Test framework tag: $TESTTAG"
    rloc="<a href=${WebServer}`main_fixpath ${reportfile}`>${WebServer}`main_fixpath ${reportfile}`</a>"
	echo "Report location : $rloc"
	echo

	cat $MainReport
	if [ -s ${TET_TMP_DIR}/isTimeBombset ]; then
		TIMEBOMB=`cat ${TET_TMP_DIR}/isTimeBombset | awk -F= '{print $2}'`	
	fi
	echo "  Is the Time Bomb set (yes/no)  : $TIMEBOMB"
	echo "	Total Test Elapse time         : $ElapseStr"
	if [ $RunInstall = y ] ; then
		echo "Install log as follows:"
		cat ${TET_TMP_DIR}/install_log.txt
	fi
	if [ $RunUnInstall = y ] ; then
		echo 
		echo 
		echo
		echo
		echo "-----------------------------------------------------------------------"
		echo 

		echo " This is the Uninstall log"
		cat ${TET_TMP_DIR}/uninstall_log.txt
	fi

	) > $MainReport.tmp 

	# create the html version of the report
	(
	htmlheader
	# create table of summary
	mksummary $MainReport
	# convert to html
	conv2html $MainReport.tmp 
	htmltrailer
	) > $reportfile

	# send out email
	ENGAGEMAILFILE=$TET_TMP_DIR/engagemail-`date '+%d-%b-%y'`-pid-$$
	(
    cat $MainReportHead 
	cat <<-EOF
	This is a multi-part message in MIME format.
	--------------mailboundary
	Content-Type: text/html; charset=us-ascii
	Content-Transfer-Encoding: 7bit

	EOF
	cat $reportfile 
	echo "--------------mailboundary--"
	) > $ENGAGEMAILFILE
	echo "cat $ENGAGEMAILFILE | $MainSendmail $ml"
	cat "$ENGAGEMAILFILE" | $MainSendmail $ml

	# cleanup
	rm -f $MainReport.tmp $MainReportHead $MainReport
}


#####################################################
#
#	engage's common functions
#
#####################################################

# This function will set the default values for the variables needed
#
main_default()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	# Variables for A2k
	#

	if [ -z "$PkgName"               ] ; then PkgName=dirsrv ; fi
#	if [ -z "$TET_ROOT" ] ;	then TET_ROOT=`(cd $mainRunBaseDir/../../../tet ; pwd)`	; fi
	if [ -z "$CHARSET" ] ;    then CHARSET=en						 ; fi
#	if [ -z "$IROOT" ] ;      then IROOT=/usr/lib/$PkgName/slapd-`hostname` ; fi
	if [ -z "$PREFIX" ] ;     then
      tmp_PREFIX0=`dirname $IROOT`
      tmp_PREFIX1=`dirname $tmp_PREFIX0`
      tmp_PREFIX2=`dirname $tmp_PREFIX1`
      PREFIX=$tmp_PREFIX2
    fi
	if [ -z "$RELM_NAME" ] ;  then RELM_NAME=SJCTEST.REDHAT.COM ; fi
	if [ -z "$DNS_DOMAIN" ] ;  then DNS_DOMAIN=sjctest.redhat.com ; fi
	if [ -z "$KERB_MASTER_PASS" ] ; then KERB_MASTER_PASS=Secret123 ; fi 
	if [ -z "$DM_ADMIN_PASS" ] ; then DM_ADMIN_PASS=Secret123 ; fi
  	if [ -z "$ROOTDN" ] ;     then ROOTDN="cn=directory manager"   ; fi
	if [ -z "$WebServer" ] ;  then WebServer="http://apoc.dsdev.sjc.redhat.com" ; fi
	if [ -z "$ROOTDNPW" ] ;   then ROOTDNPW=Secret123              ; fi
	if [ -z "$TETADMINPW" ] ; then TETADMINPW=Secret123             ; fi
	if [ -z "$DS_USER" ] ; then DS_USER=admin                      ; fi
	if [ -z "$NUMSERVERS" ] ; then NUMSERVERS=1                    ; fi
	if [ -z "$NUMCLIENTS" ] ; then NUMCLIENTS=0                    ; fi
	if [ -z "$DNSMASTER" ] ; then DNSMASTER="10.14.63.2"           ; fi
	if [ -z "$NTPSERVER" ] ; then NTPSERVER="clock.redhat.com"; fi
	if [ -z "$SetupSSHKeys" ]; then SetupSSHKeys="n"                   ; fi
	if [ -z "$RunInstall" ]; then RunInstall="n"                   ; fi
	if [ -z "$RunInstallShow" ]; then RunInstallShow="n"           ; fi
	if [ -z "$RunUnInstall" ]; then RunUnInstall="n"               ; fi
	if [ -z "$RunUnInstallShow" ]; then RunUnInstallShow="n"       ; fi
	if [ -z "$ITTERATIONS" ]; then ITTERATIONS=10                  ; fi
	if [ -z "$IPAVERSION" ]; then IPAVERSION='1.0'                 ; fi
	if [ -z "$VER" ]
	then
		VER=`(cd $mainRunBaseDir ; pwd)`
		VER=`basename $VER`
	fi
	if [ -z "$TESTING_SHARED" ] ;	then TESTING_SHARED=`(cd $TET_ROOT/Shared ; pwd)`	; fi

	# Default log and other temp directories...
	# The basic idea is to stored all data in $REALTMP that will be elsewhere than
	# in the test framework, whenever possible.
	#
	HOSTNAME=`hostname`
	case `engage_domainname` in
		*France.Sun.COM)
			case $MainOS in
				Windows_NT)	REALTMP=y:/$LOGNAME/testsDS51		;;
				*)		REALTMP=/qa/realtmp/$LOGNAME/testsDS51	;;
			esac
			;;
		*)	REALTMP=`(cd $TET_ROOT/testcases/IPA/${VER} ; pwd)`
			;;
	esac

	HOSTNAME=`hostname`
	case `engage_domainname` in
	    *mtbrook.bozemanpass.com)
	        if [ -z "$TET_REPORT_DIR" ] ; then \
	            if [ "$DisplayOS" = "Windows_2000" ]
	            then 
	                TET_REPORT_DIR=//fileserver/shared/projects/aol/docs/other_tests/oneoff/$HOSTNAME
	            else
	                TET_REPORT_DIR=/h/shared/projects/aol/docs/other_tests/oneoff/$HOSTNAME
	            fi
	        fi
	    ;;
	    *)
	        if [ -z "$TET_REPORT_DIR" ] ; then TET_REPORT_DIR=$REALTMP/results/$HOSTNAME    ; fi
	    ;;
	esac

	if [ -z "$TET_TMP_DIR"	  ] ; then TET_TMP_DIR=$REALTMP/tet_tmp_dir/$HOSTNAME	; fi
#	if [ -z "$DS_LOG_DIR"     ] ; then DS_LOG_DIR=$REALTMP/ds_log_dir/$HOSTNAME	; fi

	# Don't forget to create them...
	#
	if [ ! -d $TET_REPORT_DIR ] ; then mkdir -p $TET_REPORT_DIR	; fi
	if [ ! -d $TET_TMP_DIR	  ] ; then mkdir -p $TET_TMP_DIR	; fi
#	if [ ! -d $DS_LOG_DIR	  ] ; then mkdir -p $DS_LOG_DIR		; fi

	#
	# create the needed directory if not already there
	# JLS 10082001 : Don't know what $TET_RUN is used for ?!?!?
	#
#	if [ -z "$TET_RUN" ]; 		then TET_RUN="$TET_ROOT/../testcases/DS/${VER}_run/`hostname`"; fi
	if [ "$TET_RUN" != "" ] && [ ! -d "$TET_RUN" ]; then mkdir -p $TET_RUN; fi

    # This variable is used to turn on/off the report of known bugs
    #
    if [ -z "$IGNORE_KNOWN_BUGS" ] ; then IGNORE_KNOWN_BUGS=n       ; fi

    # This tells TET to use the associated 64 bit files
    #
	if [ -z "$DSTET_64" ] ; then DSTET_64=n ; fi

	# This is a new test debugging variable. Hopefully making debugging easier in future.
	if [ -z "$DSTET_DEBUG" ]; then DSTET_DEBUG=n ; fi

	# Variables for the script engage
	#
	if [ -z "$MainAcceptanceTests"   ] ; then MainAcceptanceTests=y	 ; fi
    if [ -z "$MainReliabTests"       ] ; then MainReliabTests=n      ; fi
	if [ -z "$MainStressTests"       ] ; then MainStressTests=n      ; fi
	if [ -z "$MainGuiTests"          ] ; then MainGuiTests=n         ; fi
	if [ -z "$MainLongDurationTests" ] ; then MainLongDurationTests=n; fi
	if [ -z "$MainPerformanceTests"  ] ; then MainPerformanceTests=n ; fi
	if [ -z "$MainFunctionalTestNIS"  ] ; then MainFunctionalTestNIS=n ; fi

	if [ -z "$MainRunStartup"        ] ; then MainRunStartup=y       ; fi
	if [ -z "$MainRunTests"          ] ; then MainRunTests=y         ; fi
	if [ -z "$MainRunCleanup"        ] ; then MainRunCleanup=y       ; fi

    if [ -z "$MainMailTo"            ] ; then MainMailTo=$LOGNAME@$MainMaildomain	; fi

# export all these variables 

	export TET_ROOT VER CHARSET TESTING_SHARED PREFIX TET_TMP_DIR TET_REPORT_DIR RELM_NAME KERB_MASTER_PASS DM_ADMIN_PASS DS_USER NUMSERVERS SERVERS CLIENTS NUMCLIENTS DNSMASTER DNS_DOMAIN ITTERATIONS NTPSERVER
	export ROOTDN ROOTDNPW TETADMINPW DRIVE IPAVERSION
	export IGNORE_KNOWN_BUGS DSTET_64 DSTET_DEBUG PkgName

	export MainLongDurationTests MainRunStartup MainRunTests MainRunCleanup MainGuiTests MainMailTo MainAcceptanceTests MainReliabTests MainStressTests MainPerformanceTests MainFunctionalTestNIS RunInstall RunInstallShow RunInstall RunInstallShow SetupSSHKeys WebServer
}

# This function will ask the user for more information/choices if needed
#
main_backendask()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi

	# A2K variables
	#
	echo
	echo "Let's check the Automation 2000 framework variables..."
	echo
	sav_TET_ROOT=$TET_ROOT
	echo "    TET_ROOT [$TET_ROOT] ? \c"
	read TET_ROOT
	if [ -z "$TET_ROOT" ] ; then TET_ROOT=$sav_TET_ROOT ; fi

	sav_TET_RUN=$TET_RUN
	echo "    TET_RUN [$TET_RUN] ? \c"
	read TET_RUN
	if [ -z "$TET_RUN" ] ; then TET_RUN=$sav_TET_RUN ; fi

	sav_TESTING_SHARED=$TESTING_SHARED
	echo "    TESTING_SHARED [$TESTING_SHARED] ? \c"
	read TESTING_SHARED
	if [ -z "$TESTING_SHARED" ] ; then TESTING_SHARED=$sav_TESTING_SHARED ; fi

	#sav_VER=$VER
	#echo "    VER [$VER] ? \c"
	#read VER
	#if [ -z "$VER" ] ; then VER=$sav_VER ; fi

	sav_CHARSET=$CHARSET
	echo "    CHARSET [$CHARSET] ? \c"
	read CHARSET
	if [ -z "$CHARSET" ] ; then CHARSET=$sav_CHARSET ; fi

	sav_TET_REPORT_DIR=$TET_REPORT_DIR
	echo "    TET_REPORT_DIR [$TET_REPORT_DIR] ? \c"
	read TET_REPORT_DIR
	if [ -z "$TET_REPORT_DIR" ] ; then 
		TET_REPORT_DIR=$sav_TET_REPORT_DIR
	fi
#LR 10052000
	if [ ! -d $TET_REPORT_DIR ] ; then
		mkdir -p $TET_REPORT_DIR
	fi
#LR

	sav_TET_TMP_DIR=$TET_TMP_DIR
	echo "    TET_TMP_DIR [$TET_TMP_DIR] ? \c"
	read TET_TMP_DIR
	if [ -z "$TET_TMP_DIR" ] ; then TET_TMP_DIR=$sav_TET_TMP_DIR ; fi
#LR 10052000
	if [ ! -d $TET_TMP_DIR ] ; then
		mkdir -p $TET_TMP_DIR
	fi
#LR

	#sav_DS_LOG_DIR=$DS_LOG_DIR
	#echo "    Log/core/backup directory [$DS_LOG_DIR] ? \c"
	#read DS_LOG_DIR
	#if [ -z "$DS_LOG_DIR" ] ; then DS_LOG_DIR=$sav_DS_LOG_DIR ; fi
	#if [ ! -d $DS_LOG_DIR ] ; then
	#	mkdir -p $DS_LOG_DIR
	#fi

	#sav_PERLPATH=$PERLPATH
	#echo "    PATH to perl to use for tests [$PERLPATH] ? \c"
	#read PERLPATH
	#if [ -z "$PERLPATH" ] ; then PERLPATH=$sav_PERLPATH ; fi
	#if [ ! -f "$PERLPATH/perl" ] ; then
	#	echo "$PERLPATH/perl not found!"
	#	exit 1
	#fi

	#sav_IROOT=$IROOT
	#echo "    IROOT [$IROOT] ? \c"
	#read IROOT
	#if [ -z "$IROOT" ] ; then IROOT=$sav_IROOT ; fi

    if [ -z $PREFIX ]; then
      tmp_PREFIX0=`dirname $IROOT`
      tmp_PREFIX1=`dirname $tmp_PREFIX0`
      tmp_PREFIX2=`dirname $tmp_PREFIX1`
      PREFIX=$tmp_PREFIX2
    fi
	sav_PREFIX=$PREFIX
	echo "    PREFIX [$PREFIX] ? \c"
	read PREFIX
	if [ -z "$PREFIX" ] ; then PREFIX=$sav_PREFIX ; fi

	sav_ROOTDN="$ROOTDN"
	echo "    ROOTDN [$ROOTDN] ? \c"
	read ROOTDN
	if [ -z "$ROOTDN" ] ; then ROOTDN="$sav_ROOTDN" ; fi

	sav_ROOTDNPW="$ROOTDNPW"
	echo "    ROOTDNPW [$ROOTDNPW] ? \c"
	read ROOTDNPW
	if [ -z "$ROOTDNPW" ] ; then ROOTDNPW="$sav_ROOTDNPW" ; fi

	sav_TETADMINPW="$TETADMINPW"
	echo "    TETADMINPW [$TETADMINPW] ? \c"
	read TETADMINPW
	if [ -z "$TETADMINPW" ] ; then TETADMINPW="$sav_TETADMINPW" ; fi

        sav_IGNORE_KNOWN_BUGS="$IGNORE_KNOWN_BUGS"
        echo
        echo "    You may configure the tests to ignore (not report) the known bugs:"
        echo "    IGNORE_KNOWN_BUGS [$IGNORE_KNOWN_BUGS] ? \c"
        read IGNORE_KNOWN_BUGS
        if [ -z "$IGNORE_KNOWN_BUGS" ] ; then IGNORE_KNOWN_BUGS="$sav_IGNORE_KNOWN_BUGS" ; fi

	#	sav_DSTET_64="$DSTET_64"
	#	echo
	#	echo "	You may configure these tests to use 64 bit associcated files (For 64bit servers): "
	#	echo "	DSTET_64 [$DSTET_64] ? \c"
	#	read DSTET_64
	#	if [ -z "$DSTET_64" ] ; then DSTET_64="$sav_DSTET_64" ; fi

		sav_DSTET_DEBUG="$DSTET_DEBUG"
		echo
		echo " You may turn on the debugging flag (DSTET_DEBUG) for more verbose output: "
		echo " DSTET_DEBUG [$DSTET_DEBUG] ? \c"
		read DSTET_DEBUG
		if [ -s "$DSTET_DEBUG" ] ; then DSTET_DEBUG="$sav_DSTET_DEBUG" ; fi


}

ask_m1()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of server 1?($HOSTNAME_M1)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "hostname unchanged"; else HOSTNAME_M1="$rsp"; fi
	echo "OS of server 1?"
	echo "   1. RHEL"
	echo "   2. FC(Fedora Core)"
	echo "   Default = $OS_M1"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_M1="RHEL"
			;;
		2) OS_M1="FC"
			;;
		d) echo "OS_M1 unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "Repo for server 1? This is a url to the .repo file, or a tarball on hpux ($REPO_M1)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Server repo unchanged"; else REPO_M1="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_M1?"
		echo " Default - $PASSWORD_M1"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_M1="$rsp"; fi
		export PASSWORD_M1
	fi

	export HOSTNAME_M1 OS_M1 REPO_M1 

}

ask_m2()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of server 2?($HOSTNAME_M2)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "hostname unchanged"; else HOSTNAME_M2="$rsp"; fi
	echo "OS of server 2?"
	echo "   1. RHEL"
	echo "   2. FC(Fedora Core)"
	echo "   Default = $OS_M2"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_M2="RHEL"
			;;
		2) OS_M2="FC"
			;;
		d) echo "OS_M2 unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "Repo for server 2? This is a url to the .repo file, or a tarball on hpux ($REPO_M2)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Server repo unchanged"; else REPO_M2="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_M2?"
		echo " Default - $PASSWORD_M2"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_M2="$rsp"; fi
		export PASSWORD_M2
	fi

	export HOSTNAME_M2 OS_M2 REPO_M2 

}

ask_m3()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of server 3?($HOSTNAME_M3)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Server needs a hostname"; else HOSTNAME_M3="$rsp"; fi
	echo "OS of server 3?"
	echo "   1. RHEL"
	echo "   2. FC(Fedora Core)"
	echo "   Default = $OS_M3"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_M3="RHEL"
			;;
		2) OS_M3="FC"
			;;
		d) echo "OS_M3 unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "Repo for server 3? This is a url to the .repo file, or a tarball on hpux ($REPO_M3)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Server repo unchanged"; else REPO_M3="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_M3?"
		echo " Default - $PASSWORD_M3"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_M3="$rsp"; fi
		export PASSWORD_M3
	fi

	export HOSTNAME_M3 OS_M3 REPO_M3 

}

ask_m4()
{
	echo "hostname of server 4?($HOSTNAME_M4)->"
	if [ "$engage_debug" = "y" ]; then set -x; fi
	read rsp
	if [ -z "$rsp" ] ; then echo "Server needs a hostname"; exit; else HOSTNAME_M4="$rsp"; fi
	echo "OS of server 4?"
	echo "   1. RHEL"
	echo "   2. FC(Fedora Core)"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_M4="RHEL"
			;;
		2) OS_M4="FC"
			;;
		d) echo "OS_M4 unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "Repo for server 4? This is a url to the .repo file, or a tarball on hpux ($REPO_M4)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Server repo unchanged"; else REPO_M1="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_M4?"
		echo " Default - $PASSWORD_M4"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_M4="$rsp"; fi
		export PASSWORD_M4
	fi

	export HOSTNAME_M4 OS_M4 REPO_M4 

}

ask_c1()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 1?($HOSTNAME_C1)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C1="$rsp"; fi
	echo "OS of Client 1?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C1>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C1="RHEL"
			;;
		2) OS_C1="HPUX"
			;;
		3) OS_C1="FC"
			;;
		4) OS_C1="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C1>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C1"; else OS_VER_C1="$rsp"; fi
	echo "Repo for client 1? This is a url to the .repo file, or a tarball on hpux ($REPO_C1)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C1="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C1?"
		echo " Default - $PASSWORD_C1"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C1="$rsp"; fi
		export PASSWORD_C1
	fi

	export OS_C1 HOSTNAME_C1 OS_VER_C1 REPO_C1

}

ask_c2()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 2?($HOSTNAME_C2)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C2="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C2>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C2="RHEL"
			;;
		2) OS_C2="HPUX"
			;;
		3) OS_C2="FC"
			;;
		4) OS_C2="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C2>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C2"; else OS_VER_C2="$rsp"; fi
	echo "Repo for client 2? This is a url to the .repo file, or a tarball on hpux ($REPO_C2)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C2="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C2?"
		echo " Default - $PASSWORD_C2"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C2="$rsp"; fi
		export PASSWORD_C2
	fi

	export OS_C2 HOSTNAME_C2 OS_VER_C2 REPO_C2

}

ask_c3()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 3?($HOSTNAME_C3)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C3="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C3>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C3="RHEL"
			;;
		2) OS_C3="HPUX"
			;;
		3) OS_C3="FC"
			;;
		4) OS_C3="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C3>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C3"; else OS_VER_C3="$rsp"; fi
	echo "Repo for client 3? This is a url to the .repo file, or a tarball on hpux ($REPO_C3)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C3="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C3?"
		echo " Default - $PASSWORD_C3"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C3="$rsp"; fi
		export PASSWORD_C3
	fi

	export OS_C3 HOSTNAME_C3 OS_VER_C3 REPO_C3

}

ask_c4()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 4?($HOSTNAME_C4)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C4="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C4>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C4="RHEL"
			;;
		2) OS_C4="HPUX"
			;;
		3) OS_C4="FC"
			;;
		4) OS_C4="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C4>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C4"; else OS_VER_C4="$rsp"; fi
	echo "Repo for client 4? This is a url to the .repo file, or a tarball on hpux ($REPO_C4)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C4="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C4?"
		echo " Default - $PASSWORD_C4"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C4="$rsp"; fi
		export PASSWORD_C4
	fi

	export OS_C4 HOSTNAME_C4 OS_VER_C4 REPO_C4

}

ask_c5()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 5?($HOSTNAME_C5)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C5="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C5>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C5="RHEL"
			;;
		2) OS_C5="HPUX"
			;;
		3) OS_C5="FC"
			;;
		4) OS_C5="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C5>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C5"; else OS_VER_C5="$rsp"; fi
	echo "Repo for client 5? This is a url to the .repo file, or a tarball on hpux ($REPO_C5)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C5="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C5?"
		echo " Default - $PASSWORD_C5"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C5="$rsp"; fi
		export PASSWORD_C5
	fi

	export OS_C5 HOSTNAME_C5 OS_VER_C5 REPO_C5

}


ask_c6()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 6?($HOSTNAME_C6)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C6="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C6>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C6="RHEL"
			;;
		2) OS_C6="HPUX"
			;;
		3) OS_C6="FC"
			;;
		4) OS_C6="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C6>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C6"; else OS_VER_C6="$rsp"; fi
	echo "Repo for client 6? This is a url to the .repo file, or a tarball on hpux ($REPO_C6)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C6="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C6?"
		echo " Default - $PASSWORD_C6"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C6="$rsp"; fi
		export PASSWORD_C6
	fi

	export OS_C6 HOSTNAME_C6 OS_VER_C6 REPO_C6

}


ask_c7()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 7?($HOSTNAME_C7)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C7="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C7>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C7="RHEL"
			;;
		2) OS_C7="HPUX"
			;;
		3) OS_C7="FC"
			;;
		4) OS_C7="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C7>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C7"; else OS_VER_C7="$rsp"; fi
	echo "Repo for client 7? This is a url to the .repo file, or a tarball on hpux ($REPO_C7)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C7="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C7?"
		echo " Default - $PASSWORD_C7"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C7="$rsp"; fi
		export PASSWORD_C7
	fi

	export OS_C7 HOSTNAME_C7 OS_VER_C7 REPO_C7

}

ask_c8()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "hostname of client 8?($HOSTNAME_C8)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Hostname unchanged"; else HOSTNAME_C8="$rsp"; fi
	echo "OS of Client 2?"
	echo "   1. RHEL"
	echo "   2. HPUX"
	echo "   3. FC(Fedora Core)"
	echo "   4. solaris"
	echo "Default <$OS_C8>:"
	read rsp
	if [ -z "$rsp" ] ; then os_tmp=d; else os_tmp="$rsp"; fi
	case $os_tmp in
		1) OS_C8="RHEL"
			;;
		2) OS_C8="HPUX"
			;;
		3) OS_C8="FC"
			;;
		4) OS_C8="solaris"
			;;
		d) echo "OS unchanged"
			;;
		*) echo "You have chosen a invalid choice($os_tmp), exiting"
			exit
			;;
		esac
	echo "OS version?"
	echo "for RHEL - 3,4,5"
	echo "for FC - 7,8,9"
	echo "for solaris - 6.7.8.9.10"
	echo "for HPUX - <insert crazy uname version here>"
	echo "default <$OS_VER_C8>"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Using $OS_VER_C8"; else OS_VER_C8="$rsp"; fi
	echo "Repo for client 8? This is a url to the .repo file, or a tarball on hpux ($REPO_C8)->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Client repo unchanged"; else  REPO_C8="$rsp"; fi
	if [ "$SetupSSHKeys" = "y" ]; then 
		echo "Root password of $HOSTNAME_C8?"
		echo " Default - $PASSWORD_C8"
		echo "->"
		read rsp
		if [ -z "$rsp" ] ; then echo "Root password unchanged"; else PASSWORD_C8="$rsp"; fi
		export PASSWORD_C8
	fi

	export OS_C8 HOSTNAME_C8 OS_VER_C8 REPO_C8

}

main_ask()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi

	echo ""
	echo "Run setup of SSH keys on all of the Servers and Clients?"
	echo "NOTE - Choosing Y will require the root passwords of all of the machines."
	echo "default $SetupSSHKeys"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Setup of SSH Keys still $SetupSSHKeys"; else SetupSSHKeys="$rsp"; fi
	export SetupSSHKeys

	TestChoice=1
	echo "How many servers are in this test(not clients)? (4 max)"
	echo "default $NUMSERVERS"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "number of servers unchanged"; else NUMSERVERS="$rsp"; fi
	
	echo "How many clients are in this test? (8 max)"
	echo "Hit \"Enter\", without any input for none"
	echo "default $NUMCLIENTS"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Number of Clients unchanged, continuing"; else NUMCLIENTS="$rsp"; fi

	case $NUMSERVERS in 
		0) echo "0 isn't a valid selection."
		   exit
		;;
		1) SERVERS="M1";ask_m1
		;;
		2) SERVERS="M1 M2";ask_m1;ask_m2
		;;
		3) SERVERS="M1 M2 M3";ask_m1;ask_m2;ask_m3
		;;
		4) SERVERS="M1 M2 M3 M4";ask_m1;ask_m2;ask_m3;ask_m4
		;;			
		*) echo "you need to select a number of servers in the valid range"; exit
		;;
	esac
	case $NUMCLIENTS in 
		0) CLIENTS="";echo "Alright, no clients in this test"
		;;
		1) CLIENTS="C1";ask_c1
		;;
		2) CLIENTS="C1 C2";ask_c1;ask_c2
		;;
		3) CLIENTS="C1 C2 C3";ask_c1;ask_c2;ask_c3
		;;
		4) CLIENTS="C1 C2 C3 C4";ask_c1;ask_c2;ask_c3;ask_c4
		;;			
		5) CLIENTS="C1 C2 C3 C4 C5";ask_c1;ask_c2;ask_c3;ask_c4;ask_c5
		;;			
		6) CLIENTS="C1 C2 C3 C4 C5 C6";ask_c1;ask_c2;ask_c3;ask_c4;ask_c5;ask_c6
		;;			
		7) CLIENTS="C1 C2 C3 C4 C5 C6 C7";ask_c1;ask_c2;ask_c3;ask_c4;ask_c5;ask_c6;ask_c7
		;;			
		8) CLIENTS="C1 C2 C3 C4 C5 C6 C7 C8";ask_c1;ask_c2;ask_c3;ask_c4;ask_c5;ask_c6;ask_c7;ask_c8
		;;			
		*) echo "No Clients in this test";
		;;
	esac

	echo "What is a CURRENTLY working DNS server, avaliable to all of the servers to forward unknow DNS requests to?"
	echo "Default $DNSMASTER"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "DNS Master unchanged, continuing"; else DNSMASTER="$rsp"; fi
	echo "What is a CURRENTLY working NTP server, too be used to sync all of the servers to at the begining of this test?"
	echo "Default $NTPSERVER"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "NTP server unchanged, continuing"; else NTPSERVER="$rsp"; fi
	echo "What is the Report server that the results will be viewable on? If unsuer, accept the default."
	echo "Default $WebServer"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "Report server unchanged, continuing"; else WebServer="$rsp"; fi
	echo "What will the IPA RELM name be?(needs to be UPPER case)"
	echo "Default $RELM_NAME:"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "RELM_NAME unchanged, continuing"; else RELM_NAME="$rsp"; fi
	echo "What will the DNS domain be?(needs to be lower case)"
	echo "Default $DNS_DOMAIN:"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "DNS Domain unchanged, continuing"; else DNS_DOMAIN="$rsp"; fi
	echo "Some tests have a configurable number of itterations that will be run during the test. How many itterations would you like?"
	echo "Default $ITTERATIONS:"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "$ITTERATIONS unchanged, continuing"; else ITTERATIONS="$rsp"; fi
	echo "What is the version that you would like to report in the report email subject line?"
	echo "Default $IPAVERSION:"
	echo "->"
	read rsp
	if [ -z "$rsp" ] ; then echo "$IPAVERSION unchanged, continuing"; else IPAVERSION="$rsp"; fi

	# Script engage's variables
	#
	echo
	echo "Choose  any one of Tests categories  to run :"
	echo "	1. ACCEPTANCE tests "
	echo "	2. LONG DURATION  tests "
	echo "	3. RELIABILITY tests "
	echo "	4. STRESS tests "
	echo "	5. GUI Based tests "
	echo "	6. Performance "
	echo "	7. FunctionalTest: NIS plugin"
	echo "	8. Do not want to run any of these tests "
        echo "choose [$TestChoice] : \c"
	read rsp
	if [ -z "$rsp" ] ; then TestChoice=1 ; else TestChoice=$rsp ; fi

	# No category yet.
	#
	MainAcceptanceTests=n
	MainLongDurationTests=n
	MainReliabTests=n
	MainStressTests=n
	MainGuiTests=n
	MainPerformanceTests=n
	MainFunctionalTestNIS=n
	case $TestChoice in
		1)	MainAcceptanceTests=y
			TEST_CAT="Acceptance"
			;;
		2)	MainLongDurationTests=y
			TEST_CAT="Long duration"
			;;
		3)	MainReliabTests=y
			TEST_CAT="Reliability"
			;;
		4)	MainStressTests=y				
			TEST_CAT="Stress"
			;;
		5)	MainGuiTests=y			
			TEST_CAT="Acceptance"
			;;
		6)	MainPerformanceTests=y			
			TEST_CAT="Performance"
			;;
		7)	MainFunctionalTestNIS=y			
			TEST_CAT="FunctionalTestNIS"
			;;
		8)	ExampleTest=y
			TEST_CAT="SAMPLE"
			;;
		*)	echo " You have selected not to run any of the above tests . Exiting program"
			exit 0
			;;
	esac

		sav_MainRunStartup=$MainRunStartup
		echo "        Execute the  startup (aka initialization) tests [$MainRunStartup] ? \c"
		read rsp
		case $rsp in
			"")	MainRunStartup=$sav_MainRunStartup	;;
			y|Y)	MainRunStartup=y			;;
			*)	MainRunStartup=n			;;
		esac

		sav_MainRunTests=$MainRunTests
		echo "        Execute the tests [$MainRunTests] ? \c"
		read rsp
		case $rsp in
			"")	MainRunTests=$sav_MainRunTests	;;
			y|Y)	MainRunTests=y			;;
			*)	MainRunTests=n			;;
		esac

		sav_MainRunCleanup=$MainRunCleanup
		echo "        Execute the cleanup tests [$MainRunCleanup] ? \c"
		read rsp
		case $rsp in
			"")	MainRunCleanup=$sav_MainRunCleanup	;;
			y|Y)	MainRunCleanup=y			;;
			*)	MainRunCleanup=n			;;
		esac

        echo
        echo " Run Install on all Servers and Clients before test run?"

		sav_RunInstall=$RunInstall
		echo "        Install IPA First [$RunInstall] ? \c"
		read rsp
		case $rsp in
			"")	RunInstall=$sav_RunInstall	;;
			y|Y)	RunInstall=y			;;
			*)	RunInstall=n			;;
		esac
		if [ $RunInstall = y ]; then
			sav_RunInstallShow=$RunInstallShow
			echo "            Would you like to watch the install process at the console [$RunInstallShow] ? \c"
			read rsp
			case $rsp in
				"")	RunInstallShow=$sav_RunInstallShow	;;
				y|Y)	RunInstallShow=y			;;
				*)	RunInstallShow=n			;;
			esac
		fi

		sav_RunUnInstall=$RunUnInstall
		echo "        UnInstall IPA after everything is complete [$RunUnInstall] ? \c"
		read rsp
		case $rsp in
			"")	RunUnInstall=$sav_RunUnInstall	;;
			y|Y)	RunUnInstall=y			;;
			*)	RunUnInstall=n			;;
		esac
		if [ $RunUnInstall = y ]; then
			sav_RunUnInstallShow=$RunUnInstallShow
			echo "            Would you like to watch the uninstall process at the console [$RunUnInstallShow] ? \c"
			read rsp
			case $rsp in
				"")	RunUnInstallShow=$sav_RunUnInstallShow	;;
				y|Y)	RunUnInstallShow=y			;;
				*)	RunUnInstallShow=n			;;
			esac
		fi

        echo
        echo "    Mail Reports....."

	sav_MainMailTo=$MainMailTo
	echo "    Mail reports should be sent to [$MainMailTo] ? \c"
	read MainMailTo
	if [ -z "$MainMailTo" ] ; then MainMailTo=$sav_MainMailTo ; fi


        main_backendask

	export MainRunTests MainRunCleanup MainRunStartup SERVERS CLIENTS NUMSERVERS NUMCLIENTS DNSMASTER RunInstall RunInstallShow RunInstall RunInstallShow NTPSERVER IPAVERSION SetupSSHKeys WebServer
}

# This function will print the user's choices (aka variables)
#
main_print()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "    TET_ROOT       : $TET_ROOT"
	echo "    TET_RUN        : $TET_RUN "
	echo "    TET_REPORT_DIR : $TET_REPORT_DIR"
	echo "    TET_TMP_DIR    : $TET_TMP_DIR"
#	echo "    DS_LOG_DIR     : $DS_LOG_DIR"
#	echo "    PERLPATH       : $PERLPATH"
	echo "    VER            : $VER"
	echo "    IPAVERSION     : $IPAVERSION"
	echo "    CHARSET        : $CHARSET"
	echo "    PREFIX         : $PREFIX"
	echo "    SRCROOT        : $SRCROOT"
	if [  "$MainOS" = "Windows_NT" ] && [ "$DRIVE" != "" ]; then
		echo "    DRIVE          : $DRIVE"
	fi
	echo "    ROOTDN         : $ROOTDN"
	echo "    ROOTDNPW       : $ROOTDNPW"
	echo "    TETADMINPW     : $TETADMINPW"
        echo "    RELM_NAME      : $RELM_NAME"
	echo "    DNS_DOMAIN     : $DNS_DOMAIN"
	echo "    NTPSERVER      : $NTPSERVER"
	echo "    Report Server  : $WebServer"
	echo "    KERB_MASTER_PASS: $KERB_MASTER_PASS"
	echo "    DM_ADMIN_PASS  : $DM_ADMIN_PASS"
	echo "    DS_USER        : $DS_USER"
	echo "    SERVERS        : $SERVERS"
	echo "    CLIENTS        : $CLIENTS"
	echo "    DNSMASTER      : $DNSMASTER"
	echo "    ITTERATIONS    : $ITTERATIONS"
	echo " Set up SSH keys?  : $SetupSSHKeys"
	. $TESTING_SHARED/shared.sh
	echo " Host Info"
	for s in $SERVERS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			echo "         Host $s"
			echo "   HOSTNAME_$s     : $HOSTNAME"
			echo "   OS_$s           : $OS"
			echo "   REPO_$s         : $REPO"
			echo "   PASSWORD_$s     : $PASSWORD"
		fi
	done
	for s in $CLIENTS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			echo "         Host $s"
			echo "   HOSTNAME_$s     : $HOSTNAME"
			echo "   OS_$s           : $OS"
			echo "   OS_VER_$s       : $OS_VER"
			echo "   REPO_$s         : $REPO"
			echo "   PASSWORD_$s     : $PASSWORD"
		fi
	done

	echo
	echo
	echo "Other general choices:"
	echo "    Execute the Reliability tests  : $MainReliabTests"
	echo "    Execute the Acceptance tests   : $MainAcceptanceTests"
	echo "    Execute the Stress tests       : $MainStressTests"
	echo "    Execute the Gui Tests          : $MainGuiTests"
	echo "    Execute the Long Duration Tests: $MainLongDurationTests"
	echo "    Execute the performance tests  : $MainPerformanceTests"
	echo "    Execute the NIS plugin tests   : $MainFunctionalTestNIS"
	echo 
	echo "    Execute the tests startup      : $MainRunStartup"
	echo "    Execute the main tests         : $MainRunTests"
	echo "    Execute the tests cleanup      : $MainRunCleanup"
	echo "    Mail reports should be sent to : $MainMailTo"
    echo
    echo "    64bit Directory Server         : $DSTET_64"
    echo "    Ignore known bugs              : $IGNORE_KNOWN_BUGS"
    echo "    Debugging Output (Verbose)     : $DSTET_DEBUG"
	echo ""
	echo " Setup SSH keys on all Servers and Clinets? : $SetupSSHKeys"
	echo " Install all Servers and Clients at startup : $RunInstall"
	echo "                         Watch the install? : $RunInstallShow"
	echo " UnInstall all Servers and Clients after run: $RunUnInstall"
	echo "                       Watch the uninstall? : $RunUnInstallShow"


}

# This function will echo in shell's format the user's choices
# It is the calling function that will redirect the output to
# the saved config file.
#
main_save()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	echo "TET_ROOT=$TET_ROOT"
	echo "TET_RUN=$TET_RUN"
	echo "TESTING_SHARED=$TESTING_SHARED"
#	echo "PERLPATH=$PERLPATH"
	echo "TET_REPORT_DIR=$TET_REPORT_DIR"
	echo "TET_TMP_DIR=$TET_TMP_DIR"
#	echo "DS_LOG_DIR=$DS_LOG_DIR"
	echo "VER=$VER"
	echo "CHARSET=$CHARSET"
#	echo "IROOT=$IROOT"
	echo "PREFIX=$PREFIX"
	echo "DNSMASTER=$DNSMASTER"
	echo "NTPSERVER=$NTPSERVER"
	echo "WebServer=\"$WebServer\""
	echo "IPAVERSION=$IPAVERSION"
	echo "SetupSSHKeys=$SetupSSHKeys"
	echo "RunInstall=$RunInstall"
	echo "RunInstallShow=$RunInstallShow"
	echo "RunUnInstall=$RunUnInstall"
	echo "RunUnInstallShow=$RunUnInstallShow"
	echo "ITTERATIONS=$ITTERATIONS"
	if [ ! -z "$DOMAINNAME" ]; then
	    echo "DOMAINNAME=$DOMAINNAME"
	    export DOMAINNAME
	fi
	if [  "$MainOS" = "Windows_NT" ] && [ "$DRIVE" != "" ]; then
		echo "DRIVE=\"$DRIVE\""
	fi
	echo "ROOTDN=\"$ROOTDN\""
	echo "ROOTDNPW=\"$ROOTDNPW\""
	echo "TETADMINPW=\"$TETADMINPW\""
    echo "IGNORE_KNOWN_BUGS=$IGNORE_KNOWN_BUGS"
	echo "DSTET_64=$DSTET_64"
	if [ "$DSTET_DEBUG" = "" ]; then
		echo "DSTET_DEBUG=y"
	else
		echo "DSTET_DEBUG=$DSTET_DEBUG"
	fi
	echo ""
	echo "RELM_NAME=$RELM_NAME"
	echo "DNS_DOMAIN=$DNS_DOMAIN"
	echo "KERB_MASTER_PASS=$KERB_MASTER_PASS"
	echo "DM_ADMIN_PASS=$DM_MASTER_PASS"
	echo "DS_USER=$DS_USER"
	echo "SERVERS=\"$SERVERS\""
	echo "CLIENTS=\"$CLIENTS\""
	echo "NUMSERVERS=$NUMSERVERS"
	echo "NUMCLIENTS=$NUMCLIENTS"
	
	for s in $SERVERS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			echo "#working on $s"
			echo "HOSTNAME_$s=$HOSTNAME"
			echo "OS_$s=$OS"
			echo "REPO_$s=\"$REPO\""
			echo "PASSWORD_$s=$PASSWORD"
		fi
	done
	for s in $CLIENTS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			echo "#working on client $s"
			echo "HOSTNAME_$s=$HOSTNAME"
			echo "OS_$s=$OS"
			echo "OS_VER_$s=$OS_VER"
			echo "REPO_$s=\"$REPO\""
			echo "PASSWORD_$s=$PASSWORD"
		fi

	done

	echo
	echo "MainReliabTests=$MainReliabTests"
	echo "MainAcceptanceTests=$MainAcceptanceTests"
	echo "MainGuiTests=$MainGuiTests"
	echo "MainStressTests=$MainStressTests"
	echo "MainLongDurationTests=$MainLongDurationTests"
	echo "MainPerformanceTests=$MainPerformanceTests"
	echo "MainFunctionalTestNIS=$MainFunctionalTestNIS"
	echo 
	echo "MainRunStartup=$MainRunStartup"
	echo "MainRunTests=$MainRunTests"
	echo "MainRunCleanup=$MainRunCleanup"
	echo "MainMailTo=$MainMailTo"
	echo
}

#####################################################
#
#	engage's main functions
#
#####################################################

# var to hold the offical name of the test catagory
TEST_CAT=""
# This function will load the initial values
#
main_load_init_values()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
    # If the config file exist, load it.
    #
    if [ -f $MainConfigFile ] ; then
	. $MainConfigFile
    fi

    # Load each test suite default values
    #
    main_default
	
    # set perl env vars
    perl_check $PREFIX

    n=0
    if [ $MainReliabTests = y ] ; then 
	. $mainRunBaseDir/reliability/engage.reliability
	reliability_default 
	n=`expr $n + 1`
	TEST_CAT="Reliability"
    fi

    if [ $MainAcceptanceTests = y ]; then 
	. $mainRunBaseDir/acceptance/engage.acceptance.sh
	acceptance_default 
	n=`expr $n + 1`
	TEST_CAT="Acceptance"
    fi

    if [ $MainStressTests = y ] ; then 
	. $mainRunBaseDir/stress/engage.stress
	stress_default 
	n=`expr $n + 1`
	TEST_CAT="Stress"
    fi

    if [ $MainGuiTests = y ] ; then 
	. $mainRunBaseDir/Gui/engage.gui
	gui_default 
	n=`expr $n + 1`
	TEST_CAT="GUI"
    fi

    if [ $MainLongDurationTests = y ]; then 
	. $mainRunBaseDir/longduration/engage.longduration
	longduration_default
	n=`expr $n + 1`
	TEST_CAT="Long duration"
    fi

    if [ $MainPerformanceTests = y ]; then 
	. $mainRunBaseDir/performance/engage.performance
	performance_default
	n=`expr $n + 1`
	TEST_CAT="Performance"
    fi

    if [ $MainFunctionalTestNIS = y ]; then 
	. $mainRunBaseDir/functional/nis-plugin/engage.nis
	nis_default
	n=`expr $n + 1`
	TEST_CAT="Functional NIS"
    fi

    if [ $n -gt 1 ]; then
	echo "main_load_init_values:more then one test catagory was selected."
	echo "Please only select one of the following main catagory : "
	echo "	ACCEPTANCE, LONG DURATION, RELIABILITY, STRESS, GUI, PERFORMANCE" 
	echo "exiting..."
	exit 1
    fi
}


# This function will print the current choices
#
main_print_choices()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
    echo
    echo "General choices..."
    echo
    main_print
    echo
    echo "Detailed choices..."
    echo

    if [ $MainReliabTests       = y ] ; then reliability_print  ; fi
    if [ $MainAcceptanceTests   = y ] ; then acceptance_print   ; fi
    if [ $MainStressTests       = y ] ; then stress_print       ; fi
    if [ $MainGuiTests          = y ] ; then gui_print          ; fi
    if [ $MainLongDurationTests = y ] ; then longduration_print ; fi
    if [ $MainPerformanceTests  = y ] ; then performance_print  ; fi
    if [ $MainFunctionalTestNIS = y ] ; then nis_print          ; fi
}

# This function will ask for the user choices
#
main_ask_choices()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
    echo
    main_ask
    echo

    if [ $MainReliabTests = y ] ; then 
	. $mainRunBaseDir/reliability/engage.reliability
	reliability_default 
	reliability_ask 
    fi

    if [ $MainAcceptanceTests = y ] ; then 
	. $mainRunBaseDir/acceptance/engage.acceptance
	acceptance_default 
	acceptance_ask 
    fi

    if [ $MainStressTests = y ] ; then 
	. $mainRunBaseDir/stress/engage.stress
	stress_default 
	stress_ask 
    fi

    if [ $MainGuiTests = y ] ; then 
	. $mainRunBaseDir/Gui/engage.gui 
	gui_default 
	gui_ask 
    fi

    if [ $MainLongDurationTests = y ] ; then  
	. $mainRunBaseDir/longduration/engage.longduration
	longduration_default
	longduration_ask
    fi
	
    if [ $MainPerformanceTests = y ] ; then  
	. $mainRunBaseDir/performance/engage.performance
	performance_default
	performance_ask
    fi
	
    if [ $MainFunctionalTestNIS = y ] ; then  
	. $mainRunBaseDir/functional/nis-plugin/engage.nis
	nis_default
	nis_ask
    fi

}

# This function will loop on the user's choices
#
main_loop_on_choices()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	rsp=n
	while [ $rsp != y ]
	do
		echo
		echo "########### Here are the current choices:"
		main_print_choices
		echo
		echo "Do you agree [y] ? \c"
		read rsp
		case $rsp in
			""|y|Y)	rsp=y			;;
			*)	main_ask_choices
				rsp=n
				;;
		esac
	done
	echo
}

# Save the choices
#
main_save_choices()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
    if [ -f $MainConfigFile ] ; then
	mv $MainConfigFile $MainConfigFile.bak
    fi
	
	echo "Running main_save now"
    # Now, the MainConfigFile does not exist.
    # Let's fill it
    #
    (
	main_save	
	if [ $MainReliabTests       = y ] ; then reliability_save  ; fi
	if [ $MainAcceptanceTests   = y ] ; then acceptance_save   ; fi
	if [ $MainStressTests       = y ] ; then stress_save       ; fi
	if [ $MainGuiTests          = y ] ; then gui_save          ; fi
	if [ $MainLongDurationTests = y ] ; then longduration_save ; fi
	if [ $MainPerformanceTests  = y ] ; then performance_save  ; fi
	if [ $MainFunctionalTestNIS = y ] ; then nis_save          ; fi
    ) >> $MainConfigFile
}


# This function will check that all the test suites may be executed
#
main_check()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi

    if [ $MainReliabTests = n ] && [ $MainAcceptanceTests = n ] &&  [ $MainStressTests = n ] &&  [ $MainGuiTests = n ] && [ $MainLongDurationTests = n ] && [ $MainFunctionalTestNIS = n ] && [ $MainPerformanceTests = n ] ; then 
        echo " You have chosen not to run any tests "
        exit 0 
    fi

    echo 
    echo "########## Checking your choices......"

    if [ $MainReliabTests       = y ] ; then reliability_check  ; fi
    if [ $MainAcceptanceTests   = y ] ; then acceptance_check   ; fi
    if [ $MainStressTests       = y ] ; then stress_check       ; fi
    if [ $MainGuiTests          = y ] ; then gui_check          ; fi
    if [ $MainLongDurationTests = y ] ; then longduration_check ; fi
    if [ $MainPerformanceTests  = y ] ; then performance_check  ; fi
    if [ $MainFunctionalTestNIS = y ] ; then nis_check          ; fi

    echo
    echo "   Ok, no problem found."
}

abortfunc()
{
AbortInstallFailed=2 # indicate an email Subject with ABORT message
main_send_report # send out report before going away
exit 1
}

# This function will engage all the test suites
#
main_run()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	# catch signal 16, used by quickinstall to exit program
	trap abortfunc 16 # 16 is USR1
    echo
    echo "########### Running tests in automated mode. You may now"
    echo "########### return to normal life.   A mail will be sent"
    echo "########### when completed."
    echo

    # Now install IPA onto the machines if the option is set
    if [ $RunInstall = y ] || [ $RunInstall = Y ]; then 
       echo "Installing IPA on all servers now";
       rm -f cat ${TET_TMP_DIR}/install_log.txt
       if [ $DSTET_DEBUG = y ] || [ $RunInstallShow = y ] || [ $RunInstallShow = Y ]; then
           sh $TET_ROOT/Shared/Full_Install | tee ${TET_TMP_DIR}/install_log.txt
           ret=$?
           if [ $ret != 0 ]; then
              echo ""
              echo "ERROR - install failed."
              echo ""
              sleep 10
           fi
       else
           sh $TET_ROOT/Shared/Full_Install > ${TET_TMP_DIR}/install_log.txt
           ret=$?
           if [ $ret != 0 ]; then
              echo ""
              echo "ERROR - install failed."
              echo ""
              sleep 10
           fi
       fi
    fi

    if [ $MainReliabTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/reliability; export TET_SUITE_ROOT
	reliability_run
    fi

    if [ $MainAcceptanceTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/acceptance; export TET_SUITE_ROOT
	acceptance_run
    fi

    if [ $MainLongDurationTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/longduration; export TET_SUITE_ROOT
	longduration_run
    fi

    if [ $MainStressTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/stress; export TET_SUITE_ROOT
	stress_run
    fi

    if [ $MainGuiTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/Gui; export TET_SUITE_ROOT
	gui_run
    fi

    if [ $MainPerformanceTests = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/performance; export TET_SUITE_ROOT
	performance_run
    fi

    if [ $MainFunctionalTestNIS = y ] ; then
	TET_SUITE_ROOT=$mainRunBaseDir/functioinal/nis-plugin ; export TET_SUITE_ROOT
	nis_run
    fi

    if [ $RunUnInstall = y ] ; then 
       echo "UnInstalling IPA on all servers now";
       rm -f cat ${TET_TMP_DIR}/uninstall_log.txt
       if [ $DSTET_DEBUG = y ] || [ $RunUnInstallShow = y ]; then
           sh $TET_ROOT/Shared/Full_Uninstall.sh | tee ${TET_TMP_DIR}/uninstall_log.txt
           ret=$?
           if [ $ret != 0 ]; then
              echo ""
              echo "ERROR - uninstall failed."
              echo ""
              sleep 10
           fi
       else
           sh $TET_ROOT/Shared/Full_UnInstall > ${TET_TMP_DIR}/uninstall_log.txt
           ret=$?
           if [ $ret != 0 ]; then
              echo ""
              echo "ERROR - uninstall failed."
              echo ""
              sleep 10
           fi
       fi
    fi

}


# Usage function
#
main_usage()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
    echo "usage: engage [-c <configfile>]"
    echo "    Run the IPA DS automated test suites."
    echo "    -c : config file (no questions)"
    echo ""
    echo "To generate a new config, simply run ./engage as root, and answer \"n\" to the first question \"Do you agree [y] ?\""
    echo ""
}

# Parse the parameters
#
main_get_options()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	# use getopt instead of getopts, problem with osf and irix (dchan)
	set -- `getopt c:h $*`
	if [ $? -ne 0 ]; then
		main_usage
	    exit 1
	fi

	while [ $1 != -- ]
	do
		case $1 in
			-c)	MainConfigFile=$2
				MainQuestions=n
				if [ ! -f $MainConfigFile ]
				then
					echo "engage: cannot access config file $MainConfigFile"
					exit 1
				fi
				shift;;
			-h|-help)	
				main_usage
				exit 0
				;;
			\?)	
				echo "engage: use engage -h to see the arguments."
				exit 1
				;;
		esac
		shift
	done
	shift
	return 0
}

# Runs ntpdate $NTPSERVER on the machine specified in $1
set_date()
{
	echo "setup date sync for host [$1] with ntp server [$NTPSERVER]"
	ssh root@$1 "/etc/init.d/ntpd stop;ntpdate $NTPSERVER"&
	return 0
}


# Main function
#
main_main()
{
	if [ "$engage_debug" = "y" ]; then set -x; fi
	main_get_options $*
	main_load_init_values
	if [ $MainQuestions = n ]
	then
		main_print_choices
		echo
		echo "Using direct values from the config file..."
	else
		main_loop_on_choices
	fi


	if [ "$SERVERS" == "" ]||[ "$RELM_NAME" == "" ]||[ "$DNS_DOMAIN" == "" ]
	then
		echo "ERROR no SERVERS, DNS_DOMAIN or RELM_NAME do not exist, $SERVERS, $DNS_DOMAIN, $RELM_NAME" 
		exit
	fi

	# Syncing clock if we can
	sudo /etc/init.d/ntpd stop
	sudo ntpdate $NTPSERVER &

	export HOSTNAME_M1 OS_M1 REPO_M1 PASSWORD_M1 
	export HOSTNAME_M2 OS_M2 REPO_M2 PASSWORD_M2
	export HOSTNAME_M3 OS_M3 REPO_M3 PASSWORD_M3
	export HOSTNAME_M4 OS_M4 REPO_M4 PASSWORD_M4
	export HOSTNAME_C1 OS_C1 REPO_C1 OS_VER_C1 PASSWORD_C1
	export HOSTNAME_C2 OS_C2 REPO_C2 OS_VER_C2 PASSWORD_C2
	export HOSTNAME_C3 OS_C3 REPO_C3 OS_VER_C3 PASSWORD_C3
	export HOSTNAME_C4 OS_C4 REPO_C4 OS_VER_C4 PASSWORD_C4
	export HOSTNAME_C5 OS_C5 REPO_C5 OS_VER_C5 PASSWORD_C5
	export HOSTNAME_C6 OS_C6 REPO_C6 OS_VER_C6 PASSWORD_C6
	export HOSTNAME_C7 OS_C7 REPO_C7 OS_VER_C7 PASSWORD_C7
	export HOSTNAME_C8 OS_C8 REPO_C8 OS_VER_C8 PASSWORD_C8
	
# Lakshmi Gopal. Storing the test run files in TET_TMP_DIR instead of /tmp dir. 
	# echo "MainOD ? $MainOS"
	MainTmpDir=$TET_TMP_DIR/`hostname`$$ 
	mkdir $MainTmpDir
	MainReport=$MainTmpDir/engage.body$$
	MainReportHead=$MainTmpDir/engage.head$$
	# Lakshmi Gopal . Storing the Report files. 03/13/2000
	MainReportRoot=$TET_REPORT_DIR
	export MainTmpDir MainReport MainReportHead MainReportRoot 
	export MainOS logTimeStamp
	main_save_choices
	
	# If SetupSSHKeys is specified then check to ensure that expect is installed, and set up ssh keys
	if [ "$SetupSSHKeys" = "y" ]; then 
		# Check to ensure that expect is installed
		# If it is, then set up ssh keys
		/bin/rpm -q expect
		if [ $? -eq 0 ]; then
			# Check to make sure that a local public key file exists, if not, create one.
			if [ ! -f ~/.ssh/id_dsa.pub ]; then
				setup_local_ssh_keys;
				if [ $? -ne 0 ]; then
					echo "ERROR - setup of local ssh keypair seems to have failed."
					exit 1
				fi
			fi
			for s in $SERVERS; do
				if [ "$s" != "" ]; then
					setup_ssh_keys_remote $s
				fi
			done
			for s in $CLIENTS; do
				if [ "$s" != "" ]; then
					setup_ssh_keys_remote $s
				fi
			done
		else
			echo "ERROR! WARNING! Expect is not installed. Please install expect to enable"
			echo " the setting up of all of the ssh keys"
		fi
	fi

	# Setting the time and date on all of the servers and clients if we can
	for s in $SERVERS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			set_date $FULLHOSTNAME
		fi
	done
	for s in $CLIENTS; do
		if [ "$s" != "" ]; then
			eval_vars $s
			set_date $FULLHOSTNAME
		fi
	done

	main_check
	main_init_report
	EngageStopwatch start
	main_run
	elapse=`EngageStopwatch stop`
	ElapseStr=`EngageStopwatch $elapse`
	main_send_report
}

# Just call the main function ;-)
#
main_main $*
exit 0

#
# End of file
