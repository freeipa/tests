use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;

my $sel = Test::WWW::Selenium->new( host => "localhost", 
                                    port => 4444, 
                                    browser => "*firefox", 
                                    browser_url => "http://localhost:4444" ); 

# make sure the dns record has been setup 
$sel->open_ok(https://ipaserver.test.com/ipa/ipapolicy/show); 
$sel->wait_for_page_to_load_ok("30000");

$sel->click_ok("//input[\@value='Edit Policy']");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("form_krbpwdhistorylength", "3");
$sel->click_ok("submit");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Password History Size: 	3");
$sel->is_text_present_ok("IPA Policy updated");

