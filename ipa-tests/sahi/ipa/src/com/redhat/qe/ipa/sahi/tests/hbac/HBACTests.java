package com.redhat.qe.ipa.sahi.tests.hbac;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.logging.Logger;

import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import com.redhat.qe.auto.testng.Assert;
import com.redhat.qe.auto.testng.TestNGUtils;
import com.redhat.qe.ipa.sahi.base.SahiTestScript;
import com.redhat.qe.ipa.sahi.tasks.CommonTasks;
import com.redhat.qe.ipa.sahi.tasks.GroupTasks;
import com.redhat.qe.ipa.sahi.tasks.HBACTasks;
import com.redhat.qe.ipa.sahi.tasks.HostTasks;
import com.redhat.qe.ipa.sahi.tasks.HostgroupTasks;
import com.redhat.qe.ipa.sahi.tasks.UserTasks;


/* 
 * Review comments
 * 40. In HBACTasks adding/deleting entries (e.g. users, hosts) into/from a
rule is saved immediately, so no need to click Update because the button
will be disabled anyway. //done 

41. In HBACTests.hbacRuleMemberListTests it tests hosts. It should test
users too. It should also test if the host/user is already added
directly it should not appear again in the available list. //done 

42. Ideally all tests that change the data should be validated via CLI
too, but this is probably low priority. // TODO: nkrishnan

43. In HBACTests we could verify that when a category is set to 'all'
the entries in that category are deleted. //done 

  I think there is additional negative testing we can do //added some..but there could be more
  
  One thing that I think we should log a bug on that should not affect our automation at all is the main page for HBAC rules ... 
  There is only "all" category for object type that can be associated with a rule and it is not editable.  I do not think they 
  should be displayed on the main page at all.  I think just the rule name (link), description and whether the rule is enabled or disabled.
  // logged bug 738038

 */

public class HBACTests extends SahiTestScript {
	
	private static Logger log = Logger.getLogger(HBACTests.class.getName());
		
	/*
	 * PreRequisite - 
	 */
	//User used in this testsuite
	private String uid = "hbacusr";
	private String givenName = "HBAC";
	private String sn = "Test";
	
	//Group used in this testsuite
	private String groupName = "hbacgrp";
	private String groupDescription = "Group to be used for HBAC tests";
	
	//Host  used in this testsuite
	private String domain = System.getProperty("ipa.server.domain");
	private String hostname = "hbachost";
	private String fqdn = hostname + "." + domain;
	private String ipadr = "";
	
	//Hostgroup used in this testsuite
	private String hostgroupName = "hbachostgroup";
	private String description = "Hostgroup to be used for HBAC tests";
	
	//Host member in Hostgroup -  used in this testsuite
	private String membertype = "host";
	private String[] names = {fqdn};
	
	private String currentPage = "";
	private String alternateCurrentPage1 = "";
	private String alternateCurrentPage2 = "";
	private String alternateCurrentPage3 = "";
	
	@BeforeClass (groups={"init"}, description="Initialize app for this test suite run", alwaysRun=true, dependsOnGroups="setup")
	public void initialize() throws CloneNotSupportedException {	
		sahiTasks.setStrictVisibilityCheck(true);
		
		//add new user, user group, host, host group
		System.out.println("Check CurrentPage: " + commonTasks.userPage);
		sahiTasks.navigateTo(commonTasks.userPage, true);
		if (!sahiTasks.link(uid).exists())
			UserTasks.createUser(sahiTasks, uid, givenName, sn, "Add");

		System.out.println("Check CurrentPage: " + commonTasks.groupPage);
		sahiTasks.navigateTo(commonTasks.groupPage, true);
		if (!sahiTasks.link(groupName).exists())
			GroupTasks.createGroupService(sahiTasks, groupName, groupDescription, commonTasks.groupPage);
		
		System.out.println("Check CurrentPage: " + commonTasks.hostPage);
		sahiTasks.navigateTo(commonTasks.hostPage, true);
		if (!sahiTasks.link(fqdn.toLowerCase()).exists())
			HostTasks.addHost(sahiTasks, hostname, commonTasks.getIpadomain(), ipadr);
		
		System.out.println("Check CurrentPage: " + commonTasks.hostgroupPage);
		sahiTasks.navigateTo(commonTasks.hostgroupPage, true);
		if (!sahiTasks.link(hostgroupName).exists()) {
			HostgroupTasks.addHostGroup(sahiTasks, hostgroupName, description, "Add");
		}
		
		System.out.println("Check CurrentPage: " + commonTasks.hbacPage);
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
		currentPage = sahiTasks.fetch("top.location.href");
		alternateCurrentPage1 = sahiTasks.fetch("top.location.href") + "&hbacrule-facet=search" ;
		alternateCurrentPage2 = sahiTasks.fetch("top.location.href") + "&hbacsvc-facet=search";
		alternateCurrentPage3 = sahiTasks.fetch("top.location.href") + "&hbacsvcgroup-facet=search";
	}
	
	@BeforeMethod (alwaysRun=true)
	public void checkCurrentPage() {
	    String currentPageNow = sahiTasks.fetch("top.location.href");
	    System.out.println("CurrentPageNow: " + currentPageNow);
		if (!currentPageNow.equals(currentPage) && !currentPageNow.equals(alternateCurrentPage1)
				&& !currentPageNow.equals(alternateCurrentPage2) && !currentPageNow.equals(alternateCurrentPage3)) {
			CommonTasks.checkError(sahiTasks);
			System.out.println("Not on expected Page....navigating back from : " + currentPageNow);
			sahiTasks.navigateTo(commonTasks.hbacPage, true);
		}		
	}
	
	/*****************************************************************************************
	 *********************** 			HBAC Rules						********************** 
	 *****************************************************************************************/
	/*
	 * Add HBACRule
	 */
	@Test (groups={"hbacRuleAddTests"}, dataProvider="getHBACRuleTestObjects")	
	public void testHBACRuleAdd(String testName, String cn) throws Exception {
		//verify rule doesn't exist
		Assert.assertFalse(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + " doesn't already exist");
		
		HBACTasks.addHBACRule(sahiTasks, cn, "Add");
		
		//verify rule were added
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Added HBAC Rule " + cn + "  successfully");
	}
	
	/*
	 * Add, and then add another HBACRule
	 */
	@Test (groups={"hbacRuleAddAndAddAnotherTests"}, dataProvider="getHBACRuleAddAndAddAnotherTestObjects")	
	public void testHBACRuleAddAndAddAnother(String testName, String cn1, String cn2) throws Exception {
		//verify user, user group, host, host group doesn't exist
		Assert.assertFalse(sahiTasks.link(cn1).exists(), "Verify HBAC Rule " + cn1 + " doesn't already exist");
		Assert.assertFalse(sahiTasks.link(cn2).exists(), "Verify HBAC Rule " + cn2 + " doesn't already exist");
		
		HBACTasks.addHBACRuleThenAddAnother(sahiTasks, cn1, cn2);
		
		//verify user, user group, host, host group were added
		Assert.assertTrue(sahiTasks.link(cn1).exists(), "Added HBAC Rule " + cn1 + "  successfully");
		Assert.assertTrue(sahiTasks.link(cn2).exists(), "Added HBAC Rule " + cn2 + "  successfully");
	}
	
	/*
	 * Add, but Cancel adding HBACRule
	 */
	@Test (groups={"hbacRuleCancelAddTests"}, dataProvider="getSingleHBACRuleTestObjects")	
	public void testHBACRuleCancelAdd(String testName, String cn) throws Exception {
		//verify rule doesn't exist
		Assert.assertFalse(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + " doesn't already exist");
		
		//new test rule can be added now
		HBACTasks.addHBACRule(sahiTasks, cn, "Cancel");
		
		//verify rule was added successfully
		Assert.assertFalse(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + "  was not added");
	}
	
	/*
	 * Add, and edit HBACRule
	 */	
	@Test (groups={"hbacRuleAddAndEditTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups="hbacRuleCancelAddTests")	
	public void testHBACRuleAddAndEdit(String testName, String cn) throws Exception {
		
		//verify rule doesn't exist
		Assert.assertFalse(sahiTasks.link(cn).exists(), "Verify rule " + cn + " doesn't already exist");
		
		// Add service category for this rule
		String service = "ftp" ;
		
		//new test rule can be added now
		HBACTasks.addAndEditHBACRule(sahiTasks, cn, uid, hostgroupName, service, fqdn);				
		
		//verify changes	
		HBACTasks.verifyHBACRuleUpdates(sahiTasks, cn, uid, hostgroupName, service, fqdn);
	}
	
	/*
	 * Add Rules - for negative tests
	 */
	@Test (groups={"invalidhbacRuleAddTests"}, dataProvider="getInvalidHBACRuleTestObjects", dependsOnGroups="hbacRuleAddTests")	
	public void testInvalidHBACRuleadd(String testName, String cn, String expectedError) throws Exception {
		//new test user can be added now
		HBACTasks.createInvalidRule(sahiTasks, cn, expectedError);		
	}
	
	/*
	 * Add Rules - check required fields - for negative tests
	 */
	@Test (groups={"hbacRuleRequiredFieldAddTests"}, dataProvider="getHBACRuleRequiredFieldTestObjects")	
	public void testHBACRuleRequiredFieldAdd(String testName, String cn, String expectedError) throws Exception {
		//new test user can be added now
		HBACTasks.createRuleWithRequiredField(sahiTasks, cn, expectedError);		
	}
	
	/*
	 * Delete an HBACRule
	 */
	@Test (groups={"hbacRuleDeleteTests"}, dataProvider="getHBACRuleDeleteTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests",
			"hbacRuleAddAndAddAnotherTests", "hbacRuleSearchTests", "hbacRuleViaServiceSettingsTests", "hbacRuleWhoSettingsTests", 
			"hbacRuleGeneralSettingsTests", "hbacRuleFromSettingsTests" })	
	public void testHBACRuleDelete(String testName, String cn) throws Exception {
		//verify rule to be deleted exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + "  to be deleted exists");
		
		//modify this user
		HBACTasks.deleteHBAC(sahiTasks, cn, "Delete");
		
		//verify user is deleted
		Assert.assertFalse(sahiTasks.link(cn).exists(), "HBAC Rule " + cn + "  deleted successfully");
	}
	
	/*
	 * Delete multiple HBACRule
	 */
	@Test (groups={"hbacRuleMultipleDeleteTests"}, dataProvider="getMultipleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddTests", "hbacRuleSearchTests", "invalidhbacRuleAddTests", "hbacRuleMemberListTests" })
	public void testMultipleHBACRuleDelete(String testName, String cn1, String cn2, String cn3) throws Exception {	
		String cns[] = {cn1, cn2, cn3};
		
		
		//verify rule to be deleted exists
		for (String cn : cns) {
			Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + "  to be deleted exists");
		}			
		//mark this rule for deletion
		HBACTasks.chooseMultiple(sahiTasks, cns);		
		HBACTasks.deleteMultiple(sahiTasks);
	}
		
		
	/*
	 * Delete, but Cancel deleting an HBACRule
	 */
	@Test (groups={"hbacRuleCancelDeleteTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests" })	
	public void testHBACRuleCancelDelete(String testName, String cn) throws Exception {
		//verify rule to be deleted exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify HBAC Rule " + cn + "  to be deleted exists");
		
		//cancel deleting this rule
		HBACTasks.deleteHBAC(sahiTasks, cn, "Cancel");
		
		//verify user is deleted
		Assert.assertTrue(sahiTasks.link(cn).exists(), "HBAC Rule " + cn + "  was not deleted");
	}
	
	/*
	 * Edit, but Reset/Undo an HBACRule
	 */
	@Test (groups={"hbacRuleResetUndoSettingsTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests"})	
	public void testHBACRuleResetSettings(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule, then reset/undo
		HBACTasks.resetUndoHBACRuleSections(sahiTasks, cn);
		
	}
	
	/*
	 * Edit the General Section for the HBACRule
	 */
	@Test (groups={"hbacRuleInvalidGeneralSettingsTests"}, dataProvider="getHBACRuleInvalidGeneralSettingsTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests"})	
	public void testHBACRuleInvalidGeneralSettings(String testName, String cn, String description) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		String expectedError = "invalid 'desc': Gettext('Leading and trailing spaces are not allowed', domain='ipa', localedir=None)";
		
		//modify this rule
		HBACTasks.modifyHBACRuleInvalidGeneralSection(sahiTasks, cn, description, expectedError);
		
	}
	
	/*
	 * Edit the General Section for the HBACRule
	 */
	@Test (groups={"hbacRuleGeneralSettingsTests"}, dataProvider="getHBACRuleGeneralSettingsTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests"})	
	public void testHBACRuleGeneralSettings(String testName, String cn, String description) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule
		HBACTasks.modifyHBACRuleGeneralSection(sahiTasks, cn, description);
		
		//verify changes	
		HBACTasks.verifyHBACRuleGeneralSection(sahiTasks, cn, description);
	}
	
	
	/*
	 * Edit the Who Section for the HBACRule
	 */
	@Test (groups={"hbacRuleWhoSettingsTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests", "hbacRuleMemberListTests"})	
	public void testHBACRuleWhoSettings(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule
		HBACTasks.modifyHBACRuleWhoSection(sahiTasks, cn, uid, groupName);
		
		//verify changes	
		HBACTasks.verifyHBACRuleWhoSection(sahiTasks, cn, uid, groupName);
	}
	
	
	/*
	 * Edit the Accessing Section for the HBACRule
	 */
	@Test (groups={"hbacRuleAccessingSettingsTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests", "hbacRuleMemberListTests"})	
	public void testHBACRuleAccessingSettings(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule
		HBACTasks.modifyHBACRuleAccessingSection(sahiTasks, cn, fqdn, hostgroupName);
		
		//verify changes	
		HBACTasks.verifyHBACRuleAccessingSection(sahiTasks, cn, fqdn, hostgroupName);
	}
	

	/*
	 * Edit the From Section for the HBACRule
	 */
	@Test (groups={"hbacRuleFromSettingsTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests", "hbacRuleMemberListTests"})	
	public void testHBACRuleFromSettings(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule
		HBACTasks.modifyHBACRuleFromSection(sahiTasks, cn, fqdn, hostgroupName);
		
		//verify changes	
		HBACTasks.verifyHBACRuleFromSection(sahiTasks, cn, fqdn, hostgroupName);
	}
	
	/*
	 * Edit the Via Service Section for the HBACRule
	 */
	@Test (groups={"hbacRuleViaServiceSettingsTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests"})	
	public void testHBACRuleViaServiceSettings(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		//modify this rule
		String searchString = "dm";
		String searchResult[] = {"gdm", "gdm-password", "kdm" };
		HBACTasks.modifyHBACRuleViaServiceSection(sahiTasks, cn, searchString, searchResult );
		
		//verify changes	
		HBACTasks.verifyHBACRuleViaServiceSection(sahiTasks, cn, searchResult);
	}
	
	
	/*
	 * Verify member list for the HBACRule
	 * fqdn is added as member of hostgroupName
	 * hostgroupName is added to From list for Rule
	 * When choosing to add Hosts to From list for Rule, verify that fqdn 
	 * is not listed since it already is in the list for this Rule, because
	 * the it is memberof hostgroupName
	 */
	@Test (groups={"hbacRuleMemberListTests"}, dataProvider="getHBACRuleMemberListTestObjects", dependsOnGroups={"hbacRuleAddTests"})	
	public void testHBACRuleMemberList(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		sahiTasks.navigateTo(commonTasks.hostgroupPage, true);
		HostgroupTasks.addMembers(sahiTasks, hostgroupName, membertype, names, "Enroll");
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
		//modify this rule
		HBACTasks.modifyHBACRuleAccessingSectionMemberList(sahiTasks, cn, fqdn, hostgroupName);
		
		sahiTasks.navigateTo(commonTasks.hostgroupPage, true);
		HostgroupTasks.removeMembers(sahiTasks, hostgroupName, membertype, names, "Delete");
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
		
	}
	
	
	
	/*
	 * Verify member list for the HBACRule
	 * uid is added as member of groupName
	 * groupName is added to Who list for Rule
	 * When choosing to add Users to Who list for Rule, verify that uid 
	 * is not listed since it already is in the list for this Rule, because
	 * the it is memberof groupName
	 */
	@Test (groups={"hbacRuleUserMemberListTests"}, dataProvider="getHBACRuleMemberListTestObjects", dependsOnGroups={"hbacRuleAddTests"})	
	public void testHBACRuleUserMemberList(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		
		sahiTasks.navigateTo(commonTasks.groupPage, true);
		GroupTasks.addMembers(sahiTasks, groupName, membertype, uid, "Enroll");
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
		//modify this rule
		HBACTasks.modifyHBACRuleWhoSectionMemberList(sahiTasks, cn, uid, groupName);
		
		sahiTasks.navigateTo(commonTasks.groupPage, true);
		GroupTasks.removeMembers(sahiTasks, groupName, "user", uid, "Delete");
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
		
	}
	
	/*
	 * In HBACTests we could verify that when a category is set to 'all' the entries in that category are deleted.
	 * Add a source host (Done in hbacRuleFromSettingsTests)
	 * Set the sourcehostcategory to 'all'
	 * Update this
	 * Verify error
	 * Delete source host 
	 * Set the sourcehostcategory to 'all'
	 * Update this
	 * Should be successful
	 */
	@Test (groups={"hbacRuleUpdateCategoryTests"}, dataProvider="getSingleHBACRuleTestObjects", dependsOnGroups={"hbacRuleAddAndEditTests", "hbacRuleFromSettingsTests"})	
	public void testHBACRuleUpdateCategory(String testName, String cn) throws Exception {		
		//verify rule to be edited exists
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Verify Rule " + cn + " to be edited exists");
		String expectedError = "sourcehost category cannot be set to 'all' while there are allowed source hosts";
		HBACTasks.updateCategory(sahiTasks, cn, hostgroupName, expectedError, true);		
	}
	
	
	
	/*
	 * Expand/Collapse details of an HBACRule
	 */
	@Test (groups={"hbacRuleExpandCollapseTests"}, dataProvider="getSingleHBACRuleTestObjects",  dependsOnGroups="hbacRuleAddAndEditTests")
	public void testHBACRuleExpandCollapse(String testName, String cn) throws Exception {
		
		HBACTasks.expandCollapseRule(sahiTasks, cn);		
		
	}
	
	/*
	 * Search an HBACRule
	 */
	@Test (groups={"hbacRuleSearchTests"}, dataProvider="getHBACRuleSearchTestObjects",  dependsOnGroups={"hbacRuleAddTests", "hbacRuleAddAndEditTests", "hbacRuleAddAndAddAnotherTests"})
	public void testHBACRuleSearch(String testName, String cn, String multipleResult) throws Exception {		
		CommonTasks.search(sahiTasks, cn);
		
		//verify rules were found
		Assert.assertTrue(sahiTasks.link(cn).exists(), "Searched and found Rule " + cn + "  successfully");
		if (!multipleResult.equals(""))
			Assert.assertTrue(sahiTasks.link(multipleResult).exists(), "Searched and found another Rule " + multipleResult + "  successfully");
		
		CommonTasks.clearSearch(sahiTasks);
	}
	
	@AfterClass (groups={"cleanup"}, description="Delete objects created for this test suite", alwaysRun=true, dependsOnGroups="init")
	public void cleanup() throws CloneNotSupportedException {
		//delete user, user group, host, host group added for this suite
		sahiTasks.navigateTo(commonTasks.userPage, true);
		//Since memberships were checked previously, may not be in the front page for User
		if (sahiTasks.link("Users").in(sahiTasks.div("content")).exists())
			sahiTasks.link("Users").in(sahiTasks.div("content")).click();
		if (sahiTasks.link(uid).exists())
			UserTasks.deleteUser(sahiTasks, uid);

		sahiTasks.navigateTo(commonTasks.groupPage, true);
		//Since memberships were checked previously, may not be in the front page for User Group
		if (sahiTasks.link("User Groups").in(sahiTasks.div("content")).exists())
			sahiTasks.link("User Groups").in(sahiTasks.div("content")).click();
		if (sahiTasks.link(groupName).exists())
			GroupTasks.deleteGroup(sahiTasks, groupName);
		
		sahiTasks.navigateTo(commonTasks.hostPage, true);
		//Since memberships were checked previously, may not be in the front page for Hosts
		if (sahiTasks.link("Hosts").in(sahiTasks.div("content")).exists())
			sahiTasks.link("Hosts").in(sahiTasks.div("content")).click();
		if (sahiTasks.link(fqdn.toLowerCase()).exists())
			HostTasks.deleteHost(sahiTasks, fqdn);
		
		sahiTasks.navigateTo(commonTasks.hostgroupPage, true);
		//Since memberships were checked previously, may not be in the front page for Host Groups
		if (sahiTasks.link("Host Groups").in(sahiTasks.div("content")).exists())
			sahiTasks.link("Host Groups").in(sahiTasks.div("content")).click();
		if (sahiTasks.link(hostgroupName).exists())
			HostgroupTasks.deleteHostgroup(sahiTasks, hostgroupName, "Delete");
		
		
		sahiTasks.navigateTo(commonTasks.hbacPage, true);
	}
	
	
	/*******************************************************
	 ************      DATA PROVIDERS     ******************
	 *******************************************************/
	
	
	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getHBACRuleTestObjects")
	public Object[][] getHBACRuleTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createHBACRuleTestObjects());
	}
	protected List<List<Object>> createHBACRuleTestObjects() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn   
		ll.add(Arrays.asList(new Object[]{ "good_hbacrule",					"dev_hbacRule"      } ));
		ll.add(Arrays.asList(new Object[]{ "hbacrule_long",					"abcdefghijklmnopqrstuvwxyz123456789ANDAGAINabcdefghijklmnopqrstuvwxyz123456789ANDAGAINabcdefghijklmnopqrstuvwxyz123456789"      } ));
		ll.add(Arrays.asList(new Object[]{ "hbacrule_specialchar",			"h@ba*c#Ru?le"      } ));
		
		return ll;	
	}
	
	@DataProvider(name="getMultipleHBACRuleTestObjects")
	public Object[][] getMultipleHBACRuleTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(deleteMultipleHBACRuleTestObjects());
	}
	protected List<List<Object>> deleteMultipleHBACRuleTestObjects() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn1					cn2																																	cn3   
		ll.add(Arrays.asList(new Object[]{ "delete_multiple_hbacrule",		"dev_hbacRule",		"abcdefghijklmnopqrstuvwxyz123456789ANDAGAINabcdefghijklmnopqrstuvwxyz123456789ANDAGAINabcdefghijklmnopqrstuvwxyz123456789",		"h@ba*c#Ru?le"      } ));
		
		return ll;	
	}
	

	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getSingleHBACRuleTestObjects")
	public Object[][] getSingleHBACRuleTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createSingleHBACRuleTestObject());
	}
	protected List<List<Object>> createSingleHBACRuleTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn   
		ll.add(Arrays.asList(new Object[]{ "create_good_hbacrule",			"eng_hbacRule"      } ));
		
		return ll;	
	}
	
	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getHBACRuleMemberListTestObjects")
	public Object[][] getHBACRuleMemberListTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createHBACRuleMemberListTestObject());
	}
	protected List<List<Object>> createHBACRuleMemberListTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn   
		ll.add(Arrays.asList(new Object[]{ "create_good_hbacrule",			"dev_hbacRule"      } ));
		
		return ll;	
	}

	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getInvalidHBACRuleTestObjects")
	public Object[][] getInvalidHBACRuleTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createInvalidHBACRuleTestObject());
	}
	protected List<List<Object>> createInvalidHBACRuleTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname							cn					expected_Error   
		ll.add(Arrays.asList(new Object[]{ "create_duplicate_hbacrule",				"dev_hbacRule",		"HBAC rule with name \"dev_hbacRule\" already exists"      } ));
		ll.add(Arrays.asList(new Object[]{ "hbacrule_with trailing_space_in_name",	"hbacRule ",		"invalid 'name': Leading and trailing spaces are not allowed"	} ));
		ll.add(Arrays.asList(new Object[]{ "hbacrule_with leading_space_in_name",	" hbacRule",		"invalid 'name': Leading and trailing spaces are not allowed"	} ));
		
		return ll;	
	}
	
	/*
	 * Data to be used when adding rules with required fields 
	 */
	@DataProvider(name="getHBACRuleRequiredFieldTestObjects")
	public Object[][] getHBACRuleRequiredFieldTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createHBACRuleRequiredFieldTestObject());
	}
	protected List<List<Object>> createHBACRuleRequiredFieldTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn					expected_Error   
		ll.add(Arrays.asList(new Object[]{ "create_blank_hbacrule",			"",					"Required field"      } ));
		
		return ll;	
	}
	
	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getHBACRuleGeneralSettingsTestObjects")
	public Object[][] getHBACRuleGeneralSettingsTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(editHBACRuleGeneralSettingsTestObject());
	}
	protected List<List<Object>> editHBACRuleGeneralSettingsTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn   				description
		ll.add(Arrays.asList(new Object[]{ "edit_general_hbacrule",			"eng_hbacRule",		"This rule is for eng"      } ));
		
		return ll;	
	}
	
	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getHBACRuleInvalidGeneralSettingsTestObjects")
	public Object[][] getHBACRuleInvalidGeneralSettingsTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(editHBACRuleInvalidGeneralSettingsTestObject());
	}
	protected List<List<Object>> editHBACRuleInvalidGeneralSettingsTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname										cn   				description
		ll.add(Arrays.asList(new Object[]{ "edit_general_hbacrule_trailingspace_in_desc",		"eng_hbacRule",		"This rule is for eng "      } ));
		ll.add(Arrays.asList(new Object[]{ "edit_general_hbacrule_leadingspace_in_desc",		"eng_hbacRule",		" This rule is for eng"      } ));
		
		return ll;	
	}
	
	
	/*
	 * Data to be used when deleting rules 
	 */
	@DataProvider(name="getHBACRuleDeleteTestObjects")
	public Object[][] getHBACRuleDeleteTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(deleteHBACRuleTestObject());
	}
	protected List<List<Object>> deleteHBACRuleTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn   
		ll.add(Arrays.asList(new Object[]{ "delete_hbacrule1",			"eng_hbacRule"      } ));
		ll.add(Arrays.asList(new Object[]{ "delete_hbacrule2",			"doc_hbacRule"      } ));
		ll.add(Arrays.asList(new Object[]{ "delete_hbacrule3",			"doc_hbacRule1"      } ));
		
		return ll;	
	}
	
	
	/*
	 * Data to be used when adding rules 
	 */
	@DataProvider(name="getHBACRuleAddAndAddAnotherTestObjects")
	public Object[][] getHBACRuleAddAndAddAnotherTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createHBACRuleAndAddAnotherTestObject());
	}
	protected List<List<Object>> createHBACRuleAndAddAnotherTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname						cn1						cn2   
		ll.add(Arrays.asList(new Object[]{ "create_two_good_hbacrule",			"doc_hbacRule",		"doc_hbacRule1"  } ));
		
		return ll;	
	}
	
	
	/*
	 * Data to be used when searching for rules 
	 */
	@DataProvider(name="getHBACRuleSearchTestObjects")
	public Object[][] getHBACRuleSearchTestObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createSearchHBACRuleTestObject());
	}
	protected List<List<Object>> createSearchHBACRuleTestObject() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //										testname					cn       				multiple_result1  
		ll.add(Arrays.asList(new Object[]{ "search_good_hbacrule",			"eng_hbacRule",			""  } ));		
		ll.add(Arrays.asList(new Object[]{ "search_specialchar_hbacrule",	"h@ba*c#Ru?le",			""  } ));
		ll.add(Arrays.asList(new Object[]{ "search_multiple_hbacrule",			"doc_hbacRule",			"doc_hbacRule1"  } ));
		
		return ll;	
	}
	
	
	
}
