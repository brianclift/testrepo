<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Account_Name_to_Legal_Name</fullName>
        <field>Legal_Name__c</field>
        <formula>Name</formula>
        <name>Copy Account Name to Legal Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Copy Account Name to Legal Name</fullName>
        <actions>
            <name>Copy_Account_Name_to_Legal_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISBlank( Legal_Name__c )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
