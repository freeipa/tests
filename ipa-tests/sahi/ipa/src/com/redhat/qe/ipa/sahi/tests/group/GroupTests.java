package com.redhat.qe.ipa.sahi.tests.group;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;

import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import com.redhat.qe.auto.testng.TestNGUtils;
import com.redhat.qe.ipa.sahi.base.SahiTestScript;
import com.redhat.qe.ipa.sahi.tasks.CommonTasks;
import com.redhat.qe.ipa.sahi.tasks.SahiTasks;
import com.redhat.qe.ipa.sahi.tasks.GroupTasks;

public class GroupTests extends SahiTestScript{
	private static Logger log = Logger.getLogger(GroupTests.class.getName());
	public static SahiTasks sahiTasks = null;	
	private String userPage = "/ipa/ui/";
	
	@BeforeClass (groups={"init"}, description="Initialize app for this test suite run", alwaysRun=true, dependsOnGroups="firefoxSetup")
	public void initialize() throws CloneNotSupportedException {	
		sahiTasks = SahiTestScript.getSahiTasks();	
		sahiTasks.navigateTo(System.getProperty("ipa.server.url")+userPage, true);
	}
	
	/*
	 * Add groups - positive tests
	 */
	@Test (groups={"addGroup"}, dataProvider="getGroupObjects")	
	public void testAddGroup(String testName, String groupName, String groupDescription) throws Exception {

		//add new host
		GroupTasks.createGroup(sahiTasks, groupName, groupDescription);
		 
	}//testAddGroup
	
	/*
	 * Add groups - positive tests
	 */
	@Test (groups={"addExtensiveGroup"}, dataProvider="getGroupObjects")	
	public void testAddExtensiveGroup(String testName, String groupName, String groupDescription) throws Exception {

		//add new host
		GroupTasks.smokeTest(sahiTasks, groupName, groupDescription);
		 
	}//testAddExtensiveGroup
	
	/*******************************************************
	 ************      DATA PROVIDERS     ***********
	 *******************************************************/

	/*
	 * Data to be used when adding hosts - for positive cases
	 */
	@DataProvider(name="getGroupObjects")
	public Object[][] getGroupObjects() {
		return TestNGUtils.convertListOfListsTo2dArray(createGroupObjects());
	}
	protected List<List<Object>> createGroupObjects() {		
		List<List<Object>> ll = new ArrayList<List<Object>>();
		
        //	test name, groupName, groupDescription				
		ll.add(Arrays.asList(new Object[]{ "addgroup","sahi_auto_001","auto generated by sahi, group 001"} )); 
		        
		return ll;	
	}//createGroupObject
	
}//class GroupTest
