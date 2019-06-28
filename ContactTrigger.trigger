/**
 * Trigger: RevealSoftContact
 *
 * Copyright (C) 2013 RevealSoft
 *
 * Purpose: 
 * 
 * Where Referenced:
 *   
 *
 * Change History:
 *
 * Developer                     Date        Flag    Description
 * -----------------------------------------------------------------------
 * Brian Clift                  04/12/2013  <ID>    Initial development
 *
 * IVB Consulting
 * Fort Collins, CO
 * +1 970.980.3103 
 *
 */

trigger ContactTrigger on Contact (before update) {
    Contact newContact;
    Contact oldContact;
    Set<Id> contactIds = new Set<Id>();       
    
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        newContact = Trigger.new[i];
        oldContact = Trigger.old[i];
        // If contact is changing to a new merchant, then disassociate primary contact id of old merchant if was a primary contact
        if (newContact.AccountId != oldContact.AccountId) {
            contactIds.add(newContact.id);
        }
    }
    
    if (contactIds.size() > 0) {
        Set<Id> accountRecordTypeIds = RevealSoftUtils.accountRecordTypeIds;
        
        String qry = 'select id from Account where Primary_Contact__c in :contactIds';
        
        if (!accountRecordTypeIds.isEmpty()) {
          qry += ' AND recordTypeId in :accountRecordTypeIds' ; 
        }
        
        List<Account> primaryContactMerchants = Database.query(qry);
        
        if (!primaryContactMerchants.isEmpty()) {
            for (Account primaryContactMerchant : primaryContactMerchants) {
                primaryContactMerchant.Primary_Contact__c = null;               
            }
            
            update primaryContactMerchants;
        }
    }
}