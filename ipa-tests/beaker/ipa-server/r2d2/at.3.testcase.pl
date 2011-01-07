#!/usr/bin/perl
#
#File: at.3.testcase.pl
#Date: Jan. 6, 2011
#By  : Yi Zhang <yzhang@redhat.com>
#       this is a step 3 program for at.pl 
#       this program will translate signuture file into test case file
#

use strict;
use warnings;

$|=1; #flush output
print "test case generator starts...";
our $ipasubcmd;
our $signturefile;
our $testcasefile;
our %tc; # hash table to hold each test case signture and their index;
our $total;
our $indent="\n    ";
our $indent2="\n        ";
# command line argument parse
our $totalArgs=$#ARGV;
if ($totalArgs == 1) {
    $ipasubcmd    = $ARGV[0];
    $signturefile = $ARGV[1];
    $testcasefile = "$signturefile.testcase";
}else{
    usage();
    exit;
}

# open files to read and build initial tc hashtable
if ( -r $signturefile){
    my @signtures = fileToArray($signturefile);
    my @sortedSignture = sortArray(@signtures);
    foreach (0..$#sortedSignture){
        my %testcase;
        my $index = 1001 + $_;
        my $testname = "$ipasubcmd"."_".$index;
        my $value = $sortedSignture[$_];
        $testcase{"index"} = "$index";
        $testcase{"name"}  = $testname;
        $testcase{"signture"} = $value;
        $tc{"$index"} = \%testcase;
        #print "\n[$index]=>[$testname]";
        $total=$_+1;
    }#foreach
} else{
    print "\nsource file not be able to open for read [$signturefile]";
    exit;
}

if (open (DEST,">$testcasefile")){
    print "\ntestcase file is ready to write: [$testcasefile]";
}else{
    print "\ntestcase file is not be able to open for read [$testcasefile]";
    exit;
}

# start to read signture file and create test case file

# test case file part 1: introduction
my $now_string = localtime;
print DEST "#!/bin/bash"; #first line
print DEST "\n# Test case for IPA sub command: $ipasubcmd";
print DEST "\n# By  : Automatic Generated by at.3.testcase.pl";
print DEST "\n# Date: $now_string";
print DEST "\n";

# test case file part 2.1: test cases grouping 
print DEST "\n##############################";
print DEST "\n#  test suite: $ipasubcmd ";
print DEST "\n##############################";
print DEST "\n\n#Total $total test cases";
print DEST "\n";
print DEST "\n$ipasubcmd()";
print DEST "\n{";
foreach my $index (sort keys %tc){
    my $tc_ref = $tc{$index};
    my %testcase = %$tc_ref;
    my $name = $testcase{"name"};
    my $signture = $testcase{"signture"};
    print DEST "$indent"."$name  #signture: [$signture]";
}# parse the tc hash data and generate test case content
print DEST "\n} #$ipasubcmd\n";

foreach my $index (sort keys %tc){
    my $tc_ref = $tc{$index};
    #my %testcase = %$tc_ref;
    #my $name = $testcase{"name"};
    #my $signture = $testcase{"signture"};
    my $testcase = createTestCase($ipasubcmd,$tc_ref);
    #print DEST "\n#[$index] [$name],[$signture]";
    print DEST $testcase;
    print DEST "\n";
}# parse the tc hash data and generate test case content


# test case file part 3: end of test file
print DEST "\n\n#END OF TEST CASE FILE";

# end of program, close files and exit
close DEST;
print "\nEND of test case generator\n";

#####################################
#       subrutine                  #
#####################################

sub usage{
    print "\nUsage: at.3.testcase.pl <ipa sub command> <test signture file>";
    print "\nexample: at.3.testcase.pl permission-find permission.testsignture.permission-find.scenario\n";
    exit;
}#usage

sub fileToArray {
    # lines start with '#' will be ignored
    # empty line will be ignored
    my $file = shift;
    my @array= ();
    if (open (IN, "$file")){
        print "\nopen file to read: [$file]";
    }else{
        print "\nCannot open file : [$file]";
    }
    while (<IN>){
        my $line = $_;
        next if ($line =~/^#/);
        next if ($line =~/^\s*$/);
        chop $line;
        push @array, $line;
    }
    close IN;
    return @array ;
}# fileToArray

sub sortArray {
    my (@a) = @_;
    my %h;
    foreach (@a){
        next if exists $h{$_};
        $h{$_}="1";
    }
    my @sorted = sort keys %h;
    return @sorted;
}#sortArray

sub printArray {
    my (@a) = @_;
    print "\n";
    foreach (0..$#a ) {
        print "\n[$_]". $a[$_];
    }
}#printArray

sub createTestCase{
    my ($subcmd,$tc_ref) = @_;
    my %testcase = %$tc_ref;
    my $name = $testcase{"name"};
    my $signture = $testcase{"signture"};
    my $index = $testcase{"index"};
    my $tc="";
    $tc .= "\n$name()";
    $tc .= "\n{ #signture: $signture";
    $tc .= "$indent"."rlPhaseStartTest \"$name\"";
    $tc .= "$indent2"."KinitAsAdmin";
    my @ipatestcommand = buildTestStatement($subcmd, $signture);
    foreach my $ipatestcommand_parts (@ipatestcommand){
        $tc .="$indent2"."$ipatestcommand_parts";
    }
    $tc .= "$indent2"."Kcleanup";
    $tc .= "$indent"."rlPhaseEnd";
    $tc .= "\n} #$name";
    return $tc;
}#createTestCase

sub buildTestStatement{
    my ($subcmd, $signture) = @_;
    my @returnArray=();

    my @localVariableDeclarition = (); # local veriable declarition block
    my $testExpectedResult=0; #default expection: 0 = pass
    my $testCmdStatement = "ipa $subcmd ";
    my $testCommentStatement = "test options: ";
    my @eachOptions=();

    print "\nbuild test statement [$signture]";
    my @allOptions = split(/--/,$signture);
    foreach my $eachoption (@allOptions){
        next if ($eachoption =~ /^\s*$/);
        push @eachOptions, $eachoption;
    }
    foreach my $option (@eachOptions){
        my @optionParts = split(/;/,$option);
        my $totalOpts = $#optionParts;
        if ($totalOpts == 0 ){ #if only 1 element in option line, 
            my $optionName = $optionParts[0];
            $optionName =~ s/^\s*//g;
            $optionName =~ s/\s$//g;
            $testCmdStatement .= "--$optionName";
        }elsif ($#optionParts == 2){ #if 3 elements in option line,
            my $optionName = $optionParts[0];
            my $optionVariableName = "$optionName"."TestValue";
            my $expectedResult = $optionParts[1];
            if ($expectedResult =~ /negative/){
                $testExpectedResult = 1;
            }
            my $optionData = $optionParts[2];

            my $localVariableStatement = "local $optionVariableName=getTestValue(\"$option\")";
            push @localVariableDeclarition, $localVariableStatement;
            $testCmdStatement .= " --$optionName \$$optionVariableName";
            $testCommentStatement .=" [$optionName]=[\$$optionVariableName]";
        }else{
            print "\nformat error in [$option], expect 3 parts";
            print "\n<option itself><positive/negative><data>";
            print "\nexit program";
            exit;
        } 
    }#walk  through each option 
    my $fullTestStatement = "rlRun \"$testCmdStatement\" $testExpectedResult \"$testCommentStatement\" ";
    push @returnArray, @localVariableDeclarition;
    push @returnArray, $fullTestStatement;
    return @returnArray;
}# buildTestStatement
