package com.redhat.qe.ipa.sahi.tests.rbac;

import java.util.logging.Logger;

import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import com.redhat.qe.auto.testng.Assert;
import com.redhat.qe.ipa.sahi.base.SahiTestScript;
import com.redhat.qe.ipa.sahi.tasks.CommonTasks;
import com.redhat.qe.ipa.sahi.tasks.DNSTasks;
import com.redhat.qe.ipa.sahi.tasks.GroupTasks;
import com.redhat.qe.ipa.sahi.tasks.HostTasks;
import com.redhat.qe.ipa.sahi.tasks.PermissionTasks;
import com.redhat.qe.ipa.sahi.tasks.PrivilegeTasks;
import com.redhat.qe.ipa.sahi.tasks.RoleTasks;
import com.redhat.qe.ipa.sahi.tasks.UserTasks;

public class RBACFunctional extends SahiTestScript {
	private static Logger log = Logger.getLogger(RoleTasks.class.getName());
	private String currentPage = "";
	private String alternateCurrentPage = "";

	
	@BeforeClass (groups={"init"}, description="Initialize app for this test suite run", alwaysRun=true, dependsOnGroups="setup")
	public void initialize() throws CloneNotSupportedException {
		sahiTasks.setStrictVisibilityCheck(true);
		sahiTasks.navigateTo(commonTasks.rolePage, true);
		currentPage = sahiTasks.fetch("top.location.href");
		alternateCurrentPage = sahiTasks.fetch("top.location.href") + "&privilege-facet=search" ;		
	}
	
	@BeforeMethod (alwaysRun=true)
	public void checkCurrentPage() {
	    String currentPageNow = sahiTasks.fetch("top.location.href");
	    CommonTasks.checkError(sahiTasks);
		if (!currentPageNow.equals(currentPage) && !currentPageNow.equals(alternateCurrentPage)) {
			System.out.println("Not on expected Page....navigating back from : " + currentPageNow);
			sahiTasks.navigateTo(commonTasks.rolePage, true);
		}		
	}
	
	/*
	 * Scenario 1: Add a Host
	 *  get its keytab. 
	 *  kinit as this host
	 *  add a user - fails
	 *  kinit back as admin
	 *  assign a role to thi shost that allows it to add users
	 *  add a user - passes
	 */		
	@Test (groups={"hostAddsUser"}, description="Host has a role to add user", 
			dataProvider="hostAddsUserTestObjects")	
	public void testHostAddsUser(String testName, String roleName, String roleDescription, String privilege, String hostName) throws Exception {		
		//add host		
		log.info("Adding new host");
		sahiTasks.navigateTo(commonTasks.hostPage, true);
		String domain = System.getProperty("ipa.server.domain");
		String fqdn = hostName + "." + domain;
		String ipadr = "";		
		if (!sahiTasks.link(fqdn.toLowerCase()).exists())
			HostTasks.addHost(sahiTasks, hostName, commonTasks.getIpadomain(), ipadr);
		
		log.info("Exceute ipa-getkeytab");
		//ipa-getkeytab -s rhel63-server.testrelm.com -p host/rolehost.testrelm.com@TESTRELM.COM -k /tmp/testrole.keytab 
		String keytabFile="/tmp/testrole.keytab";
		String ipaGetkeytabCommand=" ipa-getkeytab -s " + System.getProperty("ipa.server.fqdn") + " -p host/" + fqdn.toLowerCase() 
		+ "@" + System.getProperty("ipa.server.realm") + " -k " + keytabFile;
		CommonTasks.executeIPACommand(ipaGetkeytabCommand);
		
		log.info("kinit as host using keytab");
		//kinit -k -t /tmp/testrole.keytab  host/rolehost.testrelm.com@TESTRELM.COM
		String ipaKinitCommand="kinit -k -t " + keytabFile + " host/" + fqdn.toLowerCase() + "@" + System.getProperty("ipa.server.realm");
		CommonTasks.executeIPACommand(ipaKinitCommand);
		
		log.info("logout, and return to main page");
		sahiTasks.link("Logout").click();
	    sahiTasks.link("Return to main page.").click();
	    
	    //As a host logged in, no UI is displayed...so the below is not valid..will run this test in CLI...but keeping it here for now
		sahiTasks.navigateTo(commonTasks.userPage, true);
		
		//verify role doesn't exist
		Assert.assertFalse(sahiTasks.link(roleName).exists(), "Verify role " + roleName + " doesn't already exist");
		
		//new role can be added now
		sahiTasks.navigateTo(commonTasks.rolePage, true);
		RoleTasks.addRole(sahiTasks, roleName, roleDescription, "Add");
		
		//verify 
		
	}
	
	
	/*
	 * Bug 785152
	 */
	@Test (groups={"dnsUpdateAdmin"}, description="Bug 785152 - User with permission to update dnsrecord, cannot open it", 
			dataProvider="dnsUpdateAdminTestObjects")
			//, dependsOnGroups="permissionAddSubtreeTests")	
	public void testDNSUpdateAdmin(String testName, String permissionName1, String permissionName2, String privilegeName, String privilegeDescription,
			String roleName, String roleDescription, String userName) throws Exception {
		
		//Add privilege with permission
		sahiTasks.navigateTo(commonTasks.privilegePage, true);
		log.info("Add Privilege");
		String permissions[] = {permissionName1, permissionName2};
		PrivilegeTasks.addPrivilegeAddMembers(sahiTasks, privilegeName, privilegeDescription, "Permissions", "dns", permissions, "Add");
		
		//Add Role with privilege
		sahiTasks.navigateTo(commonTasks.rolePage, true);
		log.info("Add Role");
		String privileges[] = {privilegeName};
		RoleTasks.addRoleAddPrivileges(sahiTasks, roleName, roleDescription, privilegeName, privileges, "Add");	
		 
		//Add user
		sahiTasks.navigateTo(commonTasks.userPage, true);
		log.info("Add User");
		String password=userName;
		UserTasks.createUser(sahiTasks, userName, userName, userName, password, password, "Add");	
		
		//Add user to Role
		sahiTasks.navigateTo(commonTasks.rolePage, true);
		log.info("Add User to Role");
	    RoleTasks.addMemberToRole(sahiTasks, roleName, "User", userName);

	    String newPassword="Secret123";
	    CommonTasks.formauthNewUser(sahiTasks, userName, password,newPassword);
	    /*log.info("Kinit as " + userName );
	    CommonTasks.kinitAsNewUserFirstTime(userName, password, newPassword);
	    
	    sahiTasks.link("Logout").click();
	    sahiTasks.link("Return to main page.").click();
	    Assert.assertEquals("Logged In As: " + userName + " " + userName,sahiTasks.link("Logged In As: " + userName +  " " + userName).text(), 
	    		"User logged in as expected: " + userName);*/
	    
	
		//Verify bug
		sahiTasks.navigateTo(commonTasks.dnsPage, true);
		 sahiTasks.link(System.getProperty("ipa.server.domain")).click();
         sahiTasks.link("servicehost1").click();
         sahiTasks.link("Edit").near(sahiTasks.link("10.16.96.199")).click();
         sahiTasks.textbox("a_part_ip_address").setValue("10.16.96.202");
         sahiTasks.button("Update").click();
         DNSTasks.verifyRecord(sahiTasks, System.getProperty("ipa.server.domain"), "servicehost1", "A", "10.16.96.202", "YES");
         //Revert changes made
         sahiTasks.link(System.getProperty("ipa.server.domain")).click();
         sahiTasks.link("servicehost1").click();
         sahiTasks.link("Edit").near(sahiTasks.link("10.16.96.202")).click();
         sahiTasks.textbox("a_part_ip_address").setValue("10.16.96.199");
         sahiTasks.button("Update").click();

         sahiTasks.link("DNS Zones").in(sahiTasks.div("content")).click();
         
		CommonTasks.formauth(sahiTasks, "admin", System.getProperty("ipa.server.password"));
	
		/*CommonTasks.kinitAsAdmin();
		sahiTasks.link("Logout").click();
	    sahiTasks.link("Return to main page.").click();*/
	}
	
	
	/*
	 * Bug 807361
	 */
	@Test (groups={"dnsListZone"}, description="Bug 807361 - DNS records in LDAP are publicly accessible", 
			dataProvider="dnsListZoneTestObjects", dependsOnGroups="dnsUpdateAdmin")	
	public void testDNSListZone(String testName, String permissionName, String privilegeName,
			String roleName, String userName) throws Exception {
	
	    
		/*log.info("Add Permission - read dns entries");	
		sahiTasks.navigateTo(commonTasks.privilegePage, true);
		String permissions[] = {permissionName};
		PrivilegeTasks.addMembersToPrivilege(sahiTasks, privilegeName, "Permissions", permissionName, permissions, "Add");
		PrivilegeTasks.verifyPrivilegeMembership(sahiTasks, privilegeName, "Permissions", permissions, true);*/
		
		String password="Secret123";
		CommonTasks.formauthNewUser(sahiTasks, userName, password, password);
		/*CommonTasks.kinitAsUser(userName, password);
		sahiTasks.link("Logout").click();
	    sahiTasks.link("Return to main page.").click();
	    Assert.assertEquals("Logged In As: " + userName + " " + userName,sahiTasks.link("Logged In As: " + userName + " " + userName).text(),
	    		"User logged in as expected: " + userName);*/
	  //Verify bug
		sahiTasks.navigateTo(commonTasks.dnsPage, true);
		Assert.assertTrue(sahiTasks.link(System.getProperty("ipa.server.domain")).exists(), "Expected zone listed for " 
				+ System.getProperty("ipa.server.domain"));
		Assert.assertTrue(sahiTasks.link(System.getProperty("ipa.server.reversezone")).exists(), "Expected zone listed for " 
				+ System.getProperty("ipa.server.reversezone"));
		
		CommonTasks.formauth(sahiTasks, "admin", System.getProperty("ipa.server.password"));
		
	}
	
	/*
	 * Bug 784621
	 */
	@Test (groups={"ResetPassword_Bug784621"}, description="Bug 784621 - Reset Password", 
			dataProvider="ResetPasswordBug784621TestObjects")	
	
	public void testResetPassword_Bug784621(String testName, String permissionName, String right, String filter, String attribute, String privilegeName, String privilegedesc,
			String roleName,  String roleDesc, String uidloginuser, String givennameloginuser, String snloginuser, String userpassword, String userpassword2, String uid, String givenname, String sn) throws Exception {
	
	    
		log.info("Add Permission - " + permissionName);	
		sahiTasks.navigateTo(commonTasks.permissionPage, true);
		String rights[]={right};
		String[] attributes={attribute};
		PermissionTasks.createPermissionWithFilter(sahiTasks, permissionName, rights, filter, attributes, "Add");
		PermissionTasks.verifyPermissionFilter(sahiTasks, permissionName, rights, filter, attributes);
		
		log.info("Add Privilege - " + privilegeName);	
		sahiTasks.navigateTo(commonTasks.privilegePage, true);
		String permissions[] = {permissionName};
		PrivilegeTasks.addPrivilege(sahiTasks, privilegeName, privilegedesc, "Add");
		PrivilegeTasks.verifyPrivilege(sahiTasks, privilegeName, privilegedesc);
		PrivilegeTasks.addMembersToPrivilege(sahiTasks, privilegeName, "Permissions", permissionName, permissions, "Add");
		PrivilegeTasks.verifyPrivilegeMembership(sahiTasks, privilegeName, "Permissions", permissions, true);
		
		log.info("Add User to Login - " + uidloginuser);	
		sahiTasks.navigateTo(commonTasks.userPage);
		UserTasks.createUser(sahiTasks, uidloginuser, givennameloginuser, snloginuser, userpassword, userpassword2, "Add");
		Assert.assertTrue(sahiTasks.link(uidloginuser).exists(), "Main User added successfully");
		UserTasks.createUser(sahiTasks, uid, givenname, sn, "Add");
		Assert.assertTrue(sahiTasks.link(uid).exists(), "User to be checked added successfully");
		
		log.info("Add Role - " + roleName);	
		sahiTasks.navigateTo(commonTasks.rolePage);
		String privileges[]={privilegeName};
		RoleTasks.addRoleAddPrivileges(sahiTasks, roleName, roleDesc, privilegeName, privileges, "Add");
		RoleTasks.verifyRoleMemberOfPrivilege(sahiTasks, roleName, "Privileges", privileges, true);
		RoleTasks.addMemberToRole(sahiTasks, roleName, "Users", uidloginuser);
		RoleTasks.verifyMembership(sahiTasks, roleName, "Users", uidloginuser);
		
		CommonTasks.formauthNewUser(sahiTasks, uidloginuser, userpassword,userpassword);
		
		CommonTasks.search(sahiTasks, uid);
		sahiTasks.link(uid).click();
		Assert.assertTrue(sahiTasks.textbox("carlicense").exists(), "Attribute is editable");
		Assert.assertTrue(sahiTasks.link("action disabled").exists(), "Password cannot be reset for this user");
		sahiTasks.link("Users").in(sahiTasks.div("content")).click();
		CommonTasks.clearSearch(sahiTasks);
		
		CommonTasks.formauth(sahiTasks, "admin", System.getProperty("ipa.server.password"));
		
		
		
	}
	
	/*
	 * Bug 811211
	 */
	@Test (groups={"ReaddingPrivilege_Bug811211"}, description="Bug 811211 - Readding privilege", 
			dataProvider="ReaddingPrivilegeBug811211TestObjects")	
	
	public void testReaddingPrivilege_Bug811211(String testName, String permissionName, String right, String filter, String attribute, String privilegeName, String privilegedesc) throws Exception {
	
	    
		log.info("Add Permission - " + permissionName);	
		sahiTasks.navigateTo(commonTasks.permissionPage, true);
		String rights[]={right};
		String[] attributes={attribute};
		PermissionTasks.createPermissionWithFilter(sahiTasks, permissionName, rights, filter, attributes, "Add");
		PermissionTasks.verifyPermissionFilter(sahiTasks, permissionName, rights, filter, attributes);
		
		log.info("Add Privilege - " + privilegeName);	
		sahiTasks.navigateTo(commonTasks.privilegePage, true);
		String permissions[] = {permissionName};
		PrivilegeTasks.addPrivilege(sahiTasks, privilegeName, privilegedesc, "Add");
		PrivilegeTasks.verifyPrivilege(sahiTasks, privilegeName, privilegedesc);
		PrivilegeTasks.addMembersToPrivilege(sahiTasks, privilegeName, "Permissions", permissionName, permissions, "Add");
		PrivilegeTasks.verifyPrivilegeMembership(sahiTasks, privilegeName, "Permissions", permissions, true);
		
		PrivilegeTasks.deletePrivilege(sahiTasks, privilegeName, "Delete");
		
		log.info("Re-add Privilege - " + privilegeName);	
		sahiTasks.navigateTo(commonTasks.privilegePage, true);
		PrivilegeTasks.addPrivilege(sahiTasks, privilegeName, privilegedesc, "Add and Edit");
		
		for(String permission: permissions){
			Assert.assertFalse(sahiTasks.link(permission).exists(), "No permissions added");
		}
		
	}
	
	
	
	//Bug 839008
	 @Test (groups={"IndirectRoles_Bug839008"}, description="Bug 839008 - Indirect Roles",
             dataProvider="IndirectRolesBug839008TestObjects")

	 public void testIndirectRoles_Bug839008(String testName, String permissionName, String privilegeName, String privilegedesc,
             String roleName, String roleDesc, String uid, String givenName, String sn, String password, String groupName, String groupDesc) throws Exception {


     log.info("Add Permission - read dns entries");
     sahiTasks.navigateTo(commonTasks.privilegePage, true);
     String permissions[] = {permissionName};
     PrivilegeTasks.addPrivilege(sahiTasks, privilegeName, privilegedesc, "Add");
     PrivilegeTasks.verifyPrivilege(sahiTasks, privilegeName, privilegedesc);
     PrivilegeTasks.addMembersToPrivilege(sahiTasks, privilegeName, "Permissions", permissionName, permissions, "Add");
     PrivilegeTasks.verifyPrivilegeMembership(sahiTasks, privilegeName, "Permissions", permissions, true);

     log.info("Add Role - " + roleName);
     sahiTasks.navigateTo(commonTasks.rolePage);
     String privileges[]={privilegeName};
     RoleTasks.addRoleAddPrivileges(sahiTasks, roleName, roleDesc, privilegeName, privileges, "Add");
     RoleTasks.verifyRoleMemberOfPrivilege(sahiTasks, roleName, "Privileges", privileges, true);

     log.info("Add User " + uid);
     sahiTasks.navigateTo(commonTasks.userPage);
     UserTasks.createUser(sahiTasks, uid, givenName, sn, password, password, "Add");
     Assert.assertTrue(sahiTasks.link(uid).exists(), "User added successfully");

     log.info("Add User Group " + groupName);
     sahiTasks.navigateTo(commonTasks.groupPage);
     GroupTasks.add_UserGroup(sahiTasks, groupName, groupDesc, "", "nonPosix");
     Assert.assertTrue(sahiTasks.link(groupName).exists(), "User Group added successfully");
     GroupTasks.addMembers(sahiTasks, groupName, "user", uid, "Add");
     GroupTasks.verifyMembers(sahiTasks, groupName, "user", uid, "YES");
     sahiTasks.link(groupName).click();
     GroupTasks.addRole_Single(sahiTasks, roleName);
     String[] grprulenames={roleName};
     sahiTasks.link("User Groups").in(sahiTasks.div("content")).click();
     GroupTasks.verifyMemberOf(sahiTasks, groupName, "roles", grprulenames, "direct", "YES");

     sahiTasks.navigateTo(commonTasks.userPage);
     sahiTasks.link(uid).click();
     sahiTasks.link("memberof_role").click();
     sahiTasks.radio("indirect").click();
     Assert.assertTrue(sahiTasks.link(roleName).exists(), "Indirect membership of role to the user verified");

     commonTasks.formauthNewUser(sahiTasks, uid, password, password);

     sahiTasks.link("DNS").click();
     Assert.assertTrue(sahiTasks.link(System.getProperty("ipa.server.domain")).exists(), "DNS zones listed - verified");

     commonTasks.formauth(sahiTasks, "admin", System.getProperty("ipa.server.password"));

}
	
	/*
	 * Cleanup after tests are run
	 */
	 @AfterClass (groups={"cleanup"}, description="Delete objects created for this test suite", alwaysRun=true)
     public void cleanup() throws CloneNotSupportedException {
             sahiTasks.navigateTo(commonTasks.permissionPage, true);
             String[] permissionTestObjects = {"Manage DNSRecord1", "bug784621_permission", "bug811211_permission"     
             };
             for (String permissionTestObject : permissionTestObjects) {
                     log.fine("Cleaning Permission: " + permissionTestObject);
                     PermissionTasks.deletePermission(sahiTasks, permissionTestObject, "Delete");
             }

             sahiTasks.navigateTo(commonTasks.privilegePage, true);
             String[] privilegeTestObjects = {"TestPrivilegeDNS", "bug784621_privilege", "bug811211_privilege", "bug839008_privilege"
             };
             for (String privilegeTestObject : privilegeTestObjects) {
                     log.fine("Cleaning Privilege: " + privilegeTestObject);
                     PrivilegeTasks.deletePrivilege(sahiTasks, privilegeTestObject, "Delete");
             }


             sahiTasks.navigateTo(commonTasks.rolePage, true);
             String[] roleTestObjects = {"testroledns", "bug784621_role", "bug839008_role"
             };
             for (String roleTestObject : roleTestObjects) {
                     log.fine("Cleaning Role: " + roleTestObject);
                     RoleTasks.deleteRole(sahiTasks, roleTestObject, "Delete");
             }


             sahiTasks.navigateTo(commonTasks.userPage, true);
             String[] userTestObjects = {"testuserdns", "bug784621_user", "xyz", "bug839008_user"                      
             };
             for (String userTestObject : userTestObjects) {
                     log.fine("Cleaning Role: " + userTestObject);
                     UserTasks.deleteUser(sahiTasks, userTestObject);
             }

             sahiTasks.navigateTo(commonTasks.groupPage, true);
             String[] groupTestObjects = {"bug839008_group", "testgroupdns"
             };
             for (String groupTestObject : groupTestObjects) {
                     log.fine("Cleaning Role: " + groupTestObject);
                     GroupTasks.deleteGroup(sahiTasks, groupTestObject);
             }

     }
                                                              
	
	/*******************************************************
	 ************      DATA PROVIDERS     ******************
	 *******************************************************/
	/*
	 * Data to be used when adding roles
	 */		
	@DataProvider(name="hostAddsUserTestObjects")
	public Object[][] gethostAddsUserTestObjects() {
		String[][] roles={
        //	testname			Role Name		Role Description  	Privilege				Host Name 			
		{ "host_add_user",		"TestRole1",	"TestRole1",		"User Administrators",	"testhost"	}
		};
        
		return roles;	
	}
	
	/*
     * Data to be used when testing bug 785152
     */
    @DataProvider(name="dnsUpdateAdminTestObjects")
    public Object[][] getdnsUpdateAdminTestObjects() {
            String[][] roles={
            // testName                     permissionName1                 permissionName2                 privilegeName           privilegeDescription    roleName                roleDescription         userName  
            { "dnsUpdateAdmin",     		"update dns entries",		   "Read DNS Entries",             "TestPrivilegeDNS",     "TestPrivilegeDNS",      "testroledns",		    "testroledns",          "testuserdns"      }
            };

            return roles;
    }

    /*
     * Data to be used when testing bug 807361
     */
    @DataProvider(name="dnsListZoneTestObjects")
    public Object[][] getdnsListZoneTestObjects() {
            String[][] roles={
            // testName                     permissionName                  privilegeName                   roleName                        userName
            { "dnsUpdateAdmin",     "Read DNS Entries",             "TestPrivilegeDNS",             "TestRoleDNS",          "testuserdns"   }
            };

            return roles;
    }

	
    /*
     * Data to be used when testing bug 784621
     */
    @DataProvider(name="ResetPasswordBug784621TestObjects")
    public Object[][] getResetPasswordBug784621TestObjects() {
            String[][] roles={
            // testName                                             permissionName                  permission      filter                          attribute               privilegeName                   privilegedesc                                   roleName                        roledesc                                uidloginuser            givennameloginuser      snloginuser                     userpassword    userpassword2   uid             givenname       sn              
            { "bug784621_ResetPassword",    "bug784621_permission", "write",        "(givenname=xyz)",      "carlicense",   "bug784621_privilege",  "bug784621_privilege desc",     "bug784621_role",       "bug784621_role desc",  "bug784621_user",       "bug784621_user",       "bug784621_test",       "Secret123",    "Secret123",    "xyz",  "xyz",          "test"  }
            };

            return roles;
    }

    /*
     * Data to be used when testing bug 811211
     */
    @DataProvider(name="ReaddingPrivilegeBug811211TestObjects")
    public Object[][] getReaddingPrivilegeBug811211TestObjects() {
            String[][] roles={
            // testName                                             permissionName                  permission      filter                          attribute               privilegeName                   privilegedesc                                           
            { "bug811211_ReaddingPrivilege","bug811211_permission", "write",        "(givenname=abc)",      "carlicense",   "bug811211_privilege",  "bug811211_privilege desc"      }
            };

            return roles;
    }

	
    /*
     * Data to be used when testing bug 839008
     */
    @DataProvider(name="IndirectRolesBug839008TestObjects")
    public Object[][] getIndirectRolesBug839008TestObjects() {
            String[][] roles={
            // testName                                             permissionName          privilegeName                   privilegedesc                           roleName                        roleDesc                                uid                                     givenname                               sn                              "password"                      groupName                       groupDesc
            { "bug839008_IndirectRoles",    "Read DNS Entries",     "bug839008_privilege",  "bug839008_privilege desc", "bug839008_role",   "bug839008_roleDesc",   "bug839008_user",       "bug839008_givenname",  "bug839008_sn", "Secret123",             "bug839008_group",     "bug839008_group desc"}
            };

            return roles;
    }

	
}
