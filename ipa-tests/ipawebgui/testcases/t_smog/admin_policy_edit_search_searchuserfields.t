
#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use use Test::More tests => 10;
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
our $testid=1037;
our $testdata;
our @datakeys=("form_ipausersearchfields","form_ipausersearchfields");

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
    # test case name (admin_policy_edit_search_searchuserfields)
    # source (admin_policy_edit_search_searchuserfields.pl)
    # [2008/5/15:11:41:14]

	my ($data, $sel) = @_;  
	if (!defined $sel){
		my $sel = Test::WWW::Selenium->new(host=>$host,port=>$port,browser=>$browser,browser_ur =>$browser_url);
	}
	#$sel->open_ok(https://ipaserver.test.com/ipa/ipapolicy/show); 
	$sel->open_ok(/ipa/ipapolicy/show); 
	$sel->wait_for_page_to_load_ok("30000");
	$sel->click_ok("//input[\@value='Edit Policy']");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->type_ok("form_ipausersearchfields", "$testdata->{'form_ipausersearchfields'}");
	$sel->type_ok("form_ipausersearchfields", "$testdata->{'form_ipausersearchfields'}");
	$sel->click_ok("submit");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->is_text_present_ok("IPA Policy updated");
	$sel->is_text_present_ok("User Search Fields: 	uid,givenName,sn,telephoneNumber,ou,title,street");
} #admin_policy_edit_search_searchuserfields


sub prepare_data(){
	$testdata = IPADataStore::construct_testdata($testid, @datakeys); 
}

sub cleanup_data(){
	IPADataStore::cleanup_testdata($testid, $testdata);
}
