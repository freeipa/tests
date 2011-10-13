#####################
#  GLOBALS	    #
#####################
HTTPCFGDIR="/etc/httpd/conf"
HTTPCERTDIR="$HTTPCFGDIR/alias"
HTTPPRINC="HTTP/$HOSTNAME"
HTTPKEYTAB="$HTTPCFGDIR/$HOSTNAME.keytab"
HTTPKRBCFG="/etc/httpd/conf.d/krb.conf"

FAKEHOSTNAME="managedby-fakehost.testrelm"
FAKEHOSTREALNAME="managedby-fakehost.idm.lab.bos.redhat.com"
FAKEHOSTNAMEIP="10.16.98.239"

echo " HTTP configuration directory:  $HTTPCFGDIR"
echo " HTTP certificate directory:  $HTTPCERTDIR"
echo " HTTP krb configuration file: $HTTPKRBCFG"
echo " HTTP principal:  $HTTPPRINC"
echo " HTTP keytab: $HTTPKEYTAB"

######################
# test suite         #
######################
ipa-managedbyfunctionaltests()
{
    managedby_server_tests
    cleanup_managedby
} 

######################
# SETUP              #
######################

ipa-managedbyfunctionaltestssetup()
{
	kdestroy
	rlRun "kinitAs $ADMINID $ADMINPW" 0 "Get administrator credentials"

	# create a host to be used by the client. 
#	echo "running: ipa dnsrecord-add 98.16.10.in-addr.arpa. 239 --ptr-rec $FAKEHOSTNAME."
#	ipa dnsrecord-add 98.16.10.in-addr.arpa. 239 --ptr-rec $FAKEHOSTNAME.	
	echo "running: ipa host-add --ip-address=$FAKEHOSTNAMEIP $FAKEHOSTNAME"
	ipa host-add --ip-address=$FAKEHOSTNAMEIP $FAKEHOSTNAME
	
}

managedby_server_tests()
{
	rlPhaseStartTest "Add managedby agreement for this host"
		rlRun "kinitAs $ADMINID $ADMINPW" 0 "Get administrator credentials"
		rlRun "ipa host-add-managedby --hosts=$MASTER $CLIENT" 0 "Adding a managedby agreement for the MASTER of the client"
		rlRun "ipa host-find $CLIENT | grep $MASTER" 0 "Making sure that $MASTER seems to exist on the definition of $CLIENT"
	rlPhaseEnd

	rlPhaseStartTest "Add managedby agreement for the client to $FAKEHOSTNAME"
		rlRun "ipa host-add-managedby --hosts=$CLIENT $FAKEHOSTNAME" 0 "Adding a managedby agreement for the MASTER of the client"
		rlRun "ipa host-find $FAKEHOSTNAME | grep $CLIENT" 0 "Making sure that $CLIENT seems to exist on the definition of $FAKEHOSTNAME"
	rlPhaseEnd

	rlPhaseStartTest "Create a service to CLIENT to test with later"
		rlRun "ipa service-add test/$CLIENT" 0 "Added a test service to the CLIENT"
		rlRun "ipa service-find test/$CLIENT" 0 "Ensure that the service got added properly"
	rlPhaseEnd

	rlPhaseStartTest "Create a services to FAKEHOST to test with later"
		rlRun "ipa service-add test/$FAKEHOSTNAME" 0 "Added a test service to the FAKEHOST"
		rlRun "ipa service-find test/$FAKEHOSTNAME" 0 "Ensure that the service got added properly"
	rlPhaseEnd

	rlPhaseStartTest "Negitive test case to try binding as the CLIENTs principal"
		kdestroy
		rlRun "kinit -kt /etc/krb5.keytab host/$CLIENT" 1 "Bind as the host principal for CLIENT, this should return 1"
		rlRun "klist | grep host/$CLIENT" 1 "make sure we are not bound as the CLIENT host principal"
	rlPhaseEnd

	rlPhaseStartTest "bind as the MASTER's principal"
		kdestroy
		rlRun "kinit -kt /etc/krb5.keytab host/$MASTER" 0 "Bind as the host principal for this host"
		rlRun "klist | grep host/$MASTER" 0 "make sure we seem to be bound as the MASTER principal"
	rlPhaseEnd
	
	rlPhaseStartTest "try to create a keytab for a service that we should not be able to"
		file="/dev/shm/fakehostprincipal.keytab"
		rlRun "ipa-getkeytab -s $MASTER -k $file -p test/$FAKEHOSTNAME" 9 "Try to create a keytab for a service that we shouldn't have access to. running ipa-getkeytab -s $MASTER -k $file -p test/$FAKEHOSTNAME"
	rlPhaseEnd

	file="/dev/shm/clientprincipal.keytab"
	rlPhaseStartTest "try to create a keytab for a service that we should be able to"
		rlRun "ipa-getkeytab -s $MASTER -k $file -p test/$CLIENT" 0 "Try to create a keytab for a service that we should have access to by running ipa-getkeytab -s $MASTER -k $file -p test/$CLIENT"
		rlRun "grep $CLIENT $file" 0 "Make sure that the CLIENT hostname appears to be in the new keytab"
	rlPhaseEnd


# Next, I should be replicating these steps
certutil -R -s 'cn=ipaqavma.testrelm, o=testrelm' -d db -a > /tmp/puma.csr
ipa cert-request --principal=host/ipaqavma.testrelm /tmp/puma.csr

}

cleanup_managedby()
{

	rlRun "kinitAs $ADMINID $ADMINPW" 0 "Get administrator credentials"
	file="/dev/shm/fakehostprincipal.keytab"
	rm -f $file
	file="/dev/shm/clientprincipal.keytab"
	rm -f $file
	ipa service-del test/$FAKEHOSTNAME
	ipa service-del test/$CLIENT
	ipa host-remove-managedby --hosts=$MASTER $CLIENT
	ipa host-remove-managedby --hosts=$CLIENT $FAKEHOSTNAME
	ipa host-del $FAKEHOSTNAME
	echo Y | ipa dnsrecord-del 98.16.10.in-addr.arpa. 239
}

cleanup_http()
{
	rlPhaseStartTest "CLEANUP: HTTP Server"
		rlRun "kinitAs $ADMINID $ADMINPW" 0 "Get administrator credentials"
		cd /etc/httpd/alias/
		# remove cert files
		rm -rf $HOSTNAME.csr ca.crt $HOSTNAME.crt

		# remove the certificates from the web server's database
		cd /etc/httpd/alias/
		rlRun "certutil -d . -D -n $HOSTNAME" 0 "Remove $HOSTNAME certificate from web server certificate database."
		rlRun "certutil -d . -D -n \"IPA CA\"" 0 "Remove IPA CA certificate from web server certificate database."	

		# delete the krb config file
		rlRun "rm -rf $HTTPKRBCFG" 0 "Delete the KRB config file"

		# restore nss.conf
		cp -f /etc/httpd/conf.d/nss.conf.orig /etc/httpd/conf.d/nss.conf
		rlRun "service httpd restart" 0 "Restarting apache server"
	rlPhaseEnd
}

cleanup_ipa_http()
{
	rlPhaseStartTest "CLEANUP: IPA Server - HTTP"
		rlRun "kinitAs $ADMINID $ADMINPW" 0 "Get administrator credentials"
		rlRun "ipa user-del httpuser1" 0 "Delete the http test user"
		rlRun "service httpd stop" 0 "stopping apache server"
		rlRun "ipa-rmkeytab -p $HTTPPRINC -k $HTTPKEYTAB" 0 "removing http keytab"
		# delete keytab file
                rlRun "rm -rf $HTTPKEYTAB" 0 "Delete the HTTP keytab file"
		rlRun "ipa service-del $HTTPPRINC" 0 "Remove the HTTP service for this client host"
	rlPhaseEnd
}
	

