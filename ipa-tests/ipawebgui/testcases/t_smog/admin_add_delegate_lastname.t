
#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use use Test::More tests => 16;
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
our $testid=1098;
our $testdata;
our @datakeys=("form_name","source_criteria","dest_criteria");

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
    # test case name (admin_add_delegate_lastname)
    # source (admin_add_delegate_lastname.pl)
    # [2008/5/15:11:41:14]

	my ($data, $sel) = @_;  
	if (!defined $sel){
		my $sel = Test::WWW::Selenium->new(host=>$host,port=>$port,browser=>$browser,browser_ur =>$browser_url);
	}
	#$sel->open_ok("/ipa/delegate/list");
	$sel->open_ok("/ipa/delegate/list");
	$sel->is_text_present_ok("Logged in as: admin");
	$sel->click_ok("link=add new delegation");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->type_ok("form_name", "$testdata->{'form_name'}");
	$sel->type_ok("source_criteria", "$testdata->{'source_criteria'}");
	$sel->click_ok("//input[\@value='Find']");
	$sel->click_ok("//a[\@onclick=\"selectGroup('source', 'cn=editor-lastname,cn=groups,cn=accounts,dc=test,dc=com', 'editor-lastname');                 return false;\"]");
	$sel->click_ok("form_attrs_sn");
	$sel->type_ok("dest_criteria", "$testdata->{'dest_criteria'}");
	$sel->click_ok("//input[\@value='Find' and \@type='button' and \@onclick=\"return doSearch('dest');\"]");
	$sel->click_ok("//a[\@onclick=\"selectGroup('dest', 'cn=users-lastname,cn=groups,cn=accounts,dc=test,dc=com', 'users-lastname');                 return false;\"]");
	$sel->click_ok("submit");
	$sel->wait_for_page_to_load_ok("30000");
	$sel->is_text_present_ok("delegate created");
	$sel->is_text_present_ok("lastname 	editor-lastname 	Last Name 	users-lastname");
} #admin_add_delegate_lastname


sub prepare_data(){
	$testdata = IPADataStore::construct_testdata($testid, @datakeys); 
}

sub cleanup_data(){
	IPADataStore::cleanup_testdata($testid, $testdata);
}
