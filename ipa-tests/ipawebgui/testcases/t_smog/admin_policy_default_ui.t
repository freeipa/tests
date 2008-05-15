
#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use use Test::More tests => 12;
use Test::Exception;

use lib '/home/yi/workspace/ipawebgui/support';
use IPAutil;
use IPADataStore;

# global veriables
our $host;
our $port;
our $browser;
our $browser_url;
our $configfile="test.conf";
our $testid=1092;
our $testdata;
our @datakeys=();

# read configruation file
our $config=IPAutil::readconfig($configfile);
$host=$config->{'host'};
$port=$config->{'port'};
$browser=$config->{'browser'};
$browser_url=$config->{'browser_url'};

## Test starts here 
IPAutil::env_check($host, $port, $browser, $browser_url);
prepare_data();
run_test($testdata);
cleanup_data($testdata);


#=========== sub =============

sub run_test {
    # test case name (admin_policy_default_ui)
    # source (admin_policy_default_ui.pl)
    # [2008/5/15:11:41:14]

	my ($data, $sel) = @_;  
	if (!defined $sel){
		my $sel = Test::WWW::Selenium->new(host=>$host,port=>$port,browser=>$browser,browser_ur =>$browser_url);
	}
	#$sel->open_ok(https://ipaserver.test.com/ipa); 
	$sel->open_ok(/ipa); 
	$sel->wait_for_page_to_load_ok("30000");
	$sel->click_ok("link=Manage Policy");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->is_text_present_ok("Manage Policy");
	$sel->is_text_present_ok("IPA Policy");
	$sel->click_ok("link=IPA Policy");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->is_text_present_ok("Manage IPA Policy");
	$sel->is_text_present_ok("Search Time Limit (sec.): 	2\nSearch Records Limit: 	0\nUser Search Fields: 	uid,givenName,sn,telephoneNumber,ou,title\nGroup Search Fields: 	cn,description");
	$sel->is_text_present_ok("Password Expiration Notification (days): 	1\nMin. Password Lifetime (hours): 	0\nMax. Password Lifetime (days): 	9\nMin. Number of Character Classes: 	0\nMin. Length of Password: 	6\nPassword History Size: 	1");
	$sel->is_text_present_ok("Max. Username Length: 	8\nRoot for Home Directories: 	/home\nDefault Shell: 	/bin/sh\nDefault User Group: 	ipausers\nDefault E-mail Domain: 	test.com");
} #admin_policy_default_ui


sub prepare_data(){
	$testdata = IPADataStore::construct_testdata($testid, @datakeys); 
}

sub cleanup_data(){
	IPADataStore::cleanup_testdata($testid, $testdata);
}
