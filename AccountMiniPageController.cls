/**
 * Class: AccountMiniPageController
 *
 * Copyright (C) 2016 RevealSoft
 *
 * Purpose: 
 * 
 * Where Referenced:
 *   AccountMiniPage.page
 *
 * Change History:
 *
 * Developer                     Date        Flag    Description
 * -----------------------------------------------------------------------
 * Brian Clift                  03/18/2016   Cayan-4    Initial development
 * 
 * Incendiant
 * Fort Collins, CO
 * +1 970.980.3103 
 *
 */

public with sharing class AccountMiniPageController extends Paging {    
    public String otherMerchantProvider { get; set; }
    public String merchantIndustry { get; set; }
    public String merchantCategoryCode { get; set; }
    public String merchantCategoryMessage { get; private set; }
    public Boolean prohibited { get; set; }
    public Boolean showMerchantCategoryCodeValidationMessage { get; private set; }
    public String selectedQuoteId { get; set; }
    
    public String visaProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product1ImageName'); } }
    public String amexProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product2ImageName'); } }
    public String pinDebitProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product3ImageName'); } }
    public String posProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product4ImageName'); } }
    public String giftCardProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product6ImageName'); } }
    public String reportProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product7ImageName'); } }
    public String dccProductImage { get { return RevealSoftUtils.getGlobalSettingValue('Product8ImageName'); } }    
    
    ApexPages.StandardController theAccountController;
    
    public Account theAccount { get; set; }
    
    public AccountMiniPageController(ApexPages.StandardController theAccountController) {
        this.theAccountController = theAccountController;
        
        if (!Test.isRunningTest()) {
            theAccountController.addFields(new List<String> { 'Merchant_Category__c',
                                                              'Primary_Contact__c', 
                                                              'Merchant_Category__r.Industry__c',
                                                              'Merchant_Category__r.Category_Code__c',
                                                              'Legal_Name__c',
                                                              'Number_of_Locations__c',
                                                              'Merchant_Provider__c',
                                                              'Merchant_Provider__r',
                                                              'Merchant_Provider__r.Name',
                                                              'Merchant_Industry_Segment__c',
                                                              'Merchant_Type__c',
                                                              'Merchant_Channel__c'});
        }
        
        theAccount = (Account) theAccountController.getRecord();
        
        merchantIndustry = theAccount.Merchant_Category__r.Industry__c;
        merchantCategoryCode = theAccount.Merchant_Category__r.Category_Code__c;
    }
    
    public AccountMiniPageController getAccountMiniPageController() { return this; }
    
    public void saveOtherMerchantProvider() {        
        if (String.isBlank(otherMerchantProvider) || otherMerchantProvider.length() < 2) {
            ApexPages.addMessage(new ApexPages.message(Apexpages.severity.ERROR, 'When selecting Other - Not Listed as the Merchant Provider, a Merchant Provider name must be entered in the Other Merchant Provider field.'));
        } else {        
            List<Merchant_Provider__c> theProviders = [ select Name from Merchant_Provider__c where name = :otherMerchantProvider ];
          
            if (!theProviders.isEmpty()) {
                theAccount.Merchant_Provider__c = theProviders[0].Id;
            } else {            
                Merchant_Provider__c theProvider = new Merchant_Provider__c( Name = otherMerchantProvider, IsActive__c = true );
                            
                try {
                    insert theProvider;
                    theAccount.Merchant_Provider__c = theProvider.id;
                    save();  
                    merchantProviders = null;                  
                } catch (Exception ex) {
                    System.debug('*** Exception occurred creating Other Merchant Provider: ' + ex.getMessage());
                }
            }
            
            otherMerchantProvider = null;
        }             
    }
    
    public void save() {  
        merchantCategoryMessage = '';
        showMerchantCategoryCodeValidationMessage = false;
        theAccount.Merchant_Category__c = null;  

        if (String.isBlank(merchantIndustry)) {
        	theAccount.Merchant_Industry_Segment__c = null;
        	merchantCategoryCode = null;
        }
        
        if (!String.isBlank(theAccount.Merchant_Industry_Segment__c)) {
            List<Merchant_Category__c> merchantCategories = [ select Id from Merchant_Category__c where Category_Code__c = :theAccount.Merchant_Industry_Segment__c limit 1];
                
            if (!merchantCategories.isEmpty()) {
                theAccount.Merchant_Category__c = merchantCategories[0].id;
            }
        }       
                        
        try {
            upsert theAccount;
            
            if (theAccount.Merchant_Provider__c != null) {
                List<Merchant_Provider__c> providers = [ select name from Merchant_Provider__c where Id = :theAccount.Merchant_Provider__c ];
                
                if (!providers.isEmpty()) {
                    theAccount.Merchant_Provider__r = providers[0];
                }
            } else {
                if (theAccount.Merchant_Provider__r != null) {
                    theAccount.Merchant_Provider__r.Name = '';
                }
            }
        } catch (DMLException ex) {
            ApexPages.addMessage(new ApexPages.message(Apexpages.severity.ERROR, ex.getDMLMessage(0)));            
        }
    }
    
    public void selectMerchantIndustry() { save(); }   
    
    public List<SelectOption> contactList {        
        get {
            if (contactList == null) {            
                contactList = new List<SelectOption>();
                contactList.add(new SelectOption('', '--None--'));
                              
                for (Contact theContact : [ select Name from Contact where AccountId = :theAccount.id ]) {
                    contactList.add(new SelectOption(theContact.Id, theContact.Name));
                }               
            }
            
            return contactList;
        } 
        
        private set;    
    }    
    
    public List<SelectOption> merchantChannels {        
        get {
            if (merchantChannels == null || RevealSoftUtils.isSystemAdministrator) {            
                merchantChannels = new List<SelectOption>();
                merchantChannels.add(new SelectOption('', '--None--'));
                
                if (RevealSoftUtils.isSystemAdministrator) {
                    List<Sales_Sub_Channel__c> subChannels = [ select Name, Sales_Channel__r.name from Sales_Sub_Channel__c order by Sales_Channel__r.name, Name  limit 500 ];
                    
                    if (subChannels != null) {
                        for (Sales_Sub_Channel__c subChannel : subChannels) {
                            merchantChannels.add(new SelectOption(subChannel.id ,subChannel.Sales_Channel__r.name + ' - ' + subChannel.Name));
                        }                       
                    }
                } else {               
                    List<User_Sub_Channel__c> userSubChannels = [ select Sales_Sub_Channel__c, Sales_Sub_Channel__r.Name from User_Sub_Channel__c where User__c = : UserInfo.getUserId() and Sales_Sub_channel__c != null order by Sales_Sub_Channel__r.Name limit 500 ];
                
                    if (userSubChannels != null) {
                        for (User_Sub_Channel__c userSubChannel : userSubChannels) {
                            merchantChannels.add(new SelectOption(userSubChannel.Sales_Sub_Channel__c,userSubChannel.Sales_Sub_Channel__r.Name));
                        }
                    }
                }               
            }
            
            return merchantChannels;
        } 
        
        private set;    
    }   
    
    public void cloneQuote() {
        RevealSoftUtils.cloneQuote(selectedQuoteId);
        // force quoteList to refresh;
        quoteList = null;         
    }          
    
    public List<SelectOption> merchantIndustries {      
        get {
            if (merchantIndustries == null) {
                merchantIndustries = new List<SelectOption>();
                
                List<Schema.PicklistEntry> merchantIndustriesValues = Merchant_Category__c.Industry__c.getDescribe().getPicklistValues();
                
                merchantIndustries.add(new SelectOption('', '--None--'));
                
                for (Schema.Picklistentry pickListValue : merchantIndustriesValues) {
                    merchantIndustries.add(new SelectOption(pickListValue.getValue(), pickListValue.getValue()));
                }                   
            }
            
            return merchantIndustries;
        } 
        
        set;    
    }    
    
    public List<SelectOption> merchantProviders {       
        get {
            if (merchantProviders == null) {
                merchantProviders = new List<SelectOption>();
                
                List<Merchant_Provider__c> merchantProviderList = [ select Name from Merchant_Provider__c where isActive__c = true order by Name limit 500];               
                Id otherMerchantProviderId;
                merchantProviders.add(new SelectOption('', '--Not Processing Cards--')); 
                
                for (Merchant_Provider__c merchantProvider : merchantProviderList) {
                    if (merchantProvider.Name != 'Other - Not Listed') {
                        merchantProviders.add(new SelectOption(merchantProvider.id, merchantProvider.Name));
                    } else {
                        otherMerchantProviderId = merchantProvider.id;
                    }
                }   
                
                // Other - Not Listed needs to be last
                
                if (otherMerchantProviderId != null ) {
                    merchantProviders.add(new SelectOption(otherMerchantProviderId, 'Other - Not Listed'));
                }               
            }
            
            return merchantProviders;
        } 
        
        private set;    
    }   
    
    public List<SelectOption> merchantSegments {         
        get {
            merchantSegments = new List<SelectOption>();
            merchantSegments.add(new SelectOption('', '--None--'));
                        
            if ( merchantIndustry != null) {             
                List<Merchant_Category__c> theMerchantSegments = [Select Segment__c, Category_Code__c from Merchant_Category__c where Industry__c = :merchantIndustry order by Segment__c limit 500 ];
                                
                if (theMerchantSegments != null) {
                    for (Merchant_Category__c theMerchantSegment : theMerchantSegments) {
                        merchantSegments.add(new SelectOption(theMerchantSegment.Category_Code__c, theMerchantSegment.Segment__c));
                    } 
                }               
            }
            
            return merchantSegments;
        } 
         
        set;    
    } 
    
    public List<SelectOption> merchantTypes {       
        get {
            if (merchantTypes == null) {
                merchantTypes = new List<SelectOption>();
                
                List<Merchant_Type__c> merchantTypeList = [ select Name from Merchant_Type__c order by Sequence__c limit 500 ];
                
                merchantTypes.add(new SelectOption('', '--None--'));
                
                for (Merchant_Type__c merchantType : merchantTypeList) {
                    merchantTypes.add(new SelectOption(merchantType.Id, merchantType.Name));
                }                   
            }
            
            return merchantTypes;
        } 
        
        set;    
    }      
    
    public void validateMerchantCategoryCode() {
        List<Merchant_Category__c> merchantCategories = null;    
        merchantCategoryMessage = '';
        showMerchantCategoryCodeValidationMessage = false;
        prohibited = false;             
        
        if (!String.isBlank(merchantCategoryCode)) {
            merchantCategories = [ select Industry__c, Restriction_Type__c, Comment__c from Merchant_Category__c where Category_Code__c = :merchantCategoryCode limit 1];                   
            Account theAccount = (Account) theAccountController.getRecord();
             
            if (!merchantCategories.isEmpty()) {
                Merchant_Category__c theCategory = merchantCategories[0];
                theAccount.Merchant_Industry_Segment__c = merchantCategoryCode;                
                merchantIndustry = theCategory.Industry__c;
                showMerchantCategoryCodeValidationMessage = false;
                            
                if (theCategory.Restriction_Type__c == 'Prohibited') {              
                    prohibited = true;
                } else if (theCategory.Restriction_Type__c == 'Restricted') {
                    merchantCategoryMessage = theCategory.Comment__c;
                }
                save();
            } else {            
                showMerchantCategoryCodeValidationMessage = true;
                theAccount.Merchant_Industry_Segment__c = '';
                merchantCategoryCode = '';
                merchantIndustry = '';   
            }
        } else {
            theAccount.Merchant_Industry_Segment__c = '';
            merchantCategoryCode = '';
            merchantIndustry = '';            
        }
    }  

    public override Boolean getHasNext () {
        return quoteList.getHasNext();
    }
    
    public override Boolean getHasPrevious() {
        return quoteList.getHasPrevious(); 
    } 
    
    public override Integer getPageNumber() {
        return quoteList.getPageNumber(); 
    } 
    
    public override Integer getPageSize() {
        return quoteList.getPageSize(); 
    }     
    
    public override Integer getResultSize() {
        return quoteList.getResultSize(); 
    }                  
    
    public override void next () {
        quoteList.next();
    }
    
    public override void previous() {
        quoteList.previous();
    }
    
    public override void setItemsToShow() { }       
    
    private ApexPages.StandardSetController quoteList { get {
            if (quoteList == null) {
                
                Id accountId = theAccountController.getId();
                                
                String searchString = 'select Name,' + 
                                             'Merchant__c,' + 
                                             'Merchant__r.Legal_Name__c,' +  
                                             'Merchant__r.Name,' + 
                                             'Merchant__r.Owner.Name,' + 
                                             'Merchant__r.Primary_Contact__c,' +
                                             'Merchant__r.Primary_Contact__r.FirstName,' +
                                             'Merchant__r.Primary_Contact__r.LastName,' +
                                             'Status__c,' + 
                                             'Amercan_Express__c,' + 
                                             'OptBlue_Enabled__c,' + 
                                             'Approval_Status__c,' + 
                                             'Dynamic_Currency_Conversion__c,' + 
                                             'Gift_Card__c,' + 
                                             'MajorCC__c,' + 
                                             'PIN_Debit__c,' + 
                                             'POS__c,' + 
                                             'Reporting__c,' + 
                                             'CreatedDate from ' +   
                                             'Quote__c where Merchant__c = :accountId ' +
                                             'order by createdDate'; 


                List<Quote__c> theQuotes =  Database.query(searchString);

                quoteList = new ApexPages.StandardSetController(theQuotes);
                quoteList.setPageSize(5);                                                       
            }           
            
            return quoteList;
        }  private set;
    }
    
    public List<Quote__c> quoteSet { get {
        List<Quote__c> quotes = quoteList.getRecords();
        RevealSoftUtils.readObjects(quotes);
        return quotes;  }
    }  
    
    public void deleteQuote () {
        if (selectedQuoteId != null && selectedQuoteId instanceof ID) {
            try {
                Database.delete ((ID) selectedQuoteId);
                
                // force quoteList to refresh;
                quoteList = null;
            } catch (DMLException ex) {
                // do nothing
            }                       
        }      
    }                  
}