@IsTest
public class productListControllerTest { 
    
    @testSetup static void dataSetup(){
        Product2 testProd= TestDataFactory.createProduct('testProduct', 'MSSP-NVA-DEV-1YR-SUB', true);
        testProd.SBCF_GSAPriceCPQ__c=32;
        testProd.SBCF_ListPriceCPQ__c=90;
        testProd.Family='Layer 2';
        testProd.Price_Tier__c='Layer 2';
        Insert testProd;
        Product2 testProd1= TestDataFactory.createProduct('testProduct1', 'MSSP-NVA-DEV-1YR-SUB', true);
        testProd1.SBCF_GSAPriceCPQ__c=32;
        testProd1.SBCF_ListPriceCPQ__c=90;
        testProd1.Family='Layer 2';
        testProd1.Price_Tier__c='Layer 2';
        Insert testProd1;
       
        
        Price_Tier__c testPriceTier = new Price_Tier__c(Product__c = testProd.Id, Price__c = 1, Min_Qty__c = 1, Max_Qty__c = 10000);
        testPriceTier.Discount_Category__c='Software';
        testPriceTier.External_ID__c='NVA-DEV-1YR-SUB-PR-100';
        insert testPriceTier;
        
         Pricebook2 teststandardPricebook = new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
        );
        Update teststandardPricebook;
        
        PricebookEntry testPricebookEntry=TestDataFactory.createPricebookEntry(string.valueOf(teststandardPricebook.id),string.valueOf(testProd.id),32);
        Insert testPricebookEntry;
        
        Product_Utility_SavePoint__c testSavePoint= new Product_Utility_SavePoint__c(Status__c='In Progress',Failed_Record_Ids__c=testProd.id+',');
        Insert testSavePoint;
        
        Blob b = Blob.valueOf('[{"attributes":{"type":"Product2","url":"/services/data/v57.0/sobjects/Product2/'+testProd.id+'"},"SBCF_ListPriceCPQ__c":687.50,"SBCF_GSAPriceCPQ__c":552.77,"Id":"'+testProd.id+'"}]}');
        Attachment testattachment = new Attachment(ParentId=testSavePoint.id,Name='Test Attachment for Products',Body=b);
        insert testattachment;
         
        SBQQ__LookupData__c	testLookupData= new SBQQ__LookupData__c();
        testLookupData.SBQQ__Product__c=testProd.id;
        testLookupData.SBCF_OpportunityArea__c='Commercial';
        testLookupData.SBCF_QuoteType__c='Direct';
        testLookupData.SBCF_MinQuantity__c=11;
        testLookupData.SBCF_MaxQuantity__c=78;
        testLookupData.SBCF_SSPPrice__c=900;
        Insert testLookupData;
        
        SBQQ__DiscountSchedule__c testDiscountSc= new SBQQ__DiscountSchedule__c();
        testDiscountSc.SBQQ__Product__c=testProd.id;
        testDiscountSc.SBQQ__Pricebook__c=teststandardPricebook.id;
        testDiscountSc.SBQQ__Type__c='Range';
        testDiscountSc.SBQQ__DiscountUnit__c='Amount';
        testDiscountSc.Name='Test';
        Insert testDiscountSc;
        SBQQ__DiscountSchedule__c testDiscountSc1= new SBQQ__DiscountSchedule__c();
        testDiscountSc1.SBQQ__Product__c=testProd.id;
        testDiscountSc1.SBQQ__Pricebook__c=teststandardPricebook.id;
        testDiscountSc1.SBQQ__Type__c='Range';
        testDiscountSc1.SBQQ__DiscountUnit__c='Amount';
        testDiscountSc1.Name='Test1';
        Insert testDiscountSc1;
        
       SBQQ__DiscountTier__c testDiscountTier= new SBQQ__DiscountTier__c();
        testDiscountTier.SBQQ__Schedule__c=testDiscountSc.id;
        testDiscountTier.SBQQ__DiscountAmount__c=200;
        testDiscountTier.SBQQ__LowerBound__c=2;
        testDiscountTier.SBQQ__UpperBound__c=200;
        insert testDiscountTier;
         SBQQ__DiscountTier__c testDiscountTier1= new SBQQ__DiscountTier__c();
        testDiscountTier1.SBQQ__Schedule__c=testDiscountSc.id;
        testDiscountTier1.SBQQ__DiscountAmount__c=2000;
        testDiscountTier1.SBQQ__LowerBound__c=200;
        testDiscountTier1.SBQQ__UpperBound__c=300;
        insert testDiscountTier1;
         SBQQ__DiscountTier__c testDiscountTier2= new SBQQ__DiscountTier__c();
        testDiscountTier2.SBQQ__Schedule__c=testDiscountSc1.id;
        testDiscountTier2.SBQQ__DiscountAmount__c=1000;
        testDiscountTier2.SBQQ__LowerBound__c=300;
        testDiscountTier2.SBQQ__UpperBound__c=500;
        insert testDiscountTier2;
        
        Blob b1 = Blob.valueOf('[{"attributes":{"type":"SBQQ__DiscountTier__c","url":"/services/data/v57.0/sobjects/SBQQ__DiscountTier__c/'+testDiscountTier.Id+'"},"Id":"'+testDiscountTier.Id+'","SBQQ__DiscountAmount__c":291.52,"SBQQ__LowerBound__c":3000,"SBCF_VolumePrice__c":261.25,"SBCF_ListPrice__c":552.77,"SBQQ__Schedule__c":"'+testDiscountSc.Id+'","SBQQ__Schedule__r":{"attributes":{"type":"SBQQ__DiscountSchedule__c","url":"/services/data/v57.0/sobjects/SBQQ__DiscountSchedule__c/'+testDiscountSc.Id+'"},"SBQQ__Pricebook__c":"'+teststandardPricebook.Id+'","SBQQ__Product__c":"'+testProd.id+'","Id":"'+testDiscountSc.Id+'","SBQQ__Pricebook__r":{"attributes":{"type":"Pricebook2","url":"/services/data/v57.0/sobjects/Pricebook2/'+teststandardPricebook.Id+'"},"Name":"CPQ GSA Sales","Id":"'+teststandardPricebook.Id+'"},"SBQQ__Product__r":{"attributes":{"type":"Product2","url":"/services/data/v57.0/sobjects/Product2/'+testProd.id+'"},"Id":"'+testProd.id+'"}}}]');
        
        Attachment testattachment1 = new Attachment(ParentId=testSavePoint.id,Name='Test Attachment for Discount Tiers',Body=b1);
        insert testattachment1;
        
    }
    
    @isTest
    static void testBatch(){
        Product_Utility_SavePoint__c testSavePoint =[Select id from Product_Utility_SavePoint__c Limit 1];
        List<sObject>testList=[Select id from Product2];
        test.startTest();
          Database.executeBatch(new productUpdateBatch(testList,testSavePoint.id,'abc'), 25);
           Database.executeBatch(new productUpdateBatch(testList,testSavePoint.id,'xyz'), 25);


        test.stopTest();
    }
    
	@isTest
    static void testGetFieldsAndRecords(){
        productListController.productWrapper wrp= new productListController.productWrapper();
        productListController.productWrapper wrp1= new productListController.productWrapper();

        Test.startTest();
        wrp=productListController.getFieldsAndRecords();
        Test.stopTest();
    }
    
    @isTest
    static void testgetpriceBookProducts(){
         Pricebook2 testPricebook= [Select Id from Pricebook2 Limit 1];
        List<id>testList=new List<Id>();
        Test.startTest();
        List<Id> PricebookList= productListController.getpriceBookProducts(testPricebook.Id);
        Test.stopTest();

    }
    
    @isTest
    static void testGetpriceBook(){
        Test.startTest();
        List<Pricebook2> testList= productListController.getpriceBook();
        Map<String,List<String>> testMap=   productListController.getPickListValues();
        Test.stopTest();
    }
    
    @isTest
    static void testupdateProducts(){
        List <Product2> testProd= [Select Id from Product2 Limit 2];
        string Prodid=testProd[0].id;
        String Prodid1=testProd[1].id;
         string query = '(\'' + Prodid + '\')';
        string query1 = '(\'' + Prodid + '\',\'' + Prodid1 + '\')';
        
        List<string> fieldDependency= new List<string>();
        fieldDependency.add('Block Price');
        fieldDependency.add('Pricebook Entry');
        List<string> fieldDependency1= new List<string>();
        fieldDependency1.add('Discount Tier');
        fieldDependency1.add('List Price');
        List<string> fieldDependency2= new List<string>();
        fieldDependency2.add('Discount Tier');
        fieldDependency2.add('Block Price');
        fieldDependency2.add('Pricebook Entry');
        
        
        Test.startTest();
        string testtt= productListController.updateProducts(query,'10',true,fieldDependency1,'CPQ GSA Sales');
        string testt= productListController.updateProducts(query,'10',true,fieldDependency,'CPQ GSA Sales');
        string testt1= productListController.updateProducts(query,'10',false,fieldDependency,'CPQ GSA Sales');
        string testttt= productListController.updateProducts(query,'10',false,fieldDependency,'all');
        string testtttt= productListController.updateProducts(query,'10',false,fieldDependency1,'all');
        string testtttt1= productListController.updateProducts(query,'10',true,fieldDependency,'all');
        string testtttt2= productListController.updateProducts(query,'10',false,fieldDependency2,'all');
        string testtttt3= productListController.updateProducts(query,'10',true,fieldDependency2,'all');
        string testtttt4= productListController.updateProducts(query1,'10',true,fieldDependency2,'all');        
        
        Test.stopTest();
    }
    
    @isTest
    static void testrevertChanges(){
        List<string>testList=new List<string>();
        Product2 testProd= [Select Id from Product2 Limit 1];
        string prodId=string.valueOf(testProd.id);    
        testList.add(prodId);
        
        Test.startTest();
        string testt= productListController.revertChanges(testList);
        Test.stopTest();
    }
    
     @isTest
    static void testeditProducts(){
       Product2 testProd= [Select Id from Product2 Limit 1];
        string prodId=testProd.id;
        string data1='[{"SBCF_GSAPriceCPQ__c":"72",'+'"Id":"'+prodId+'"}]';
        object data=json.deserializeUntyped(data1);
        
        Test.startTest();
        string status=productListController.editProducts(data);
        Test.stopTest();
    }
    
    @IsTest
    static void testeditRelatedRecords(){
        Product2 testProd= [Select Id from Product2 Limit 1];
        Price_Tier__c testPriceTier =[Select Id from Price_Tier__c Limit 1];
        PricebookEntry testPricebookEntry=[Select Id from  PricebookEntry Limit 1];
        SBQQ__LookupData__c testLookupData=[Select Id from  SBQQ__LookupData__c Limit 1];
        SBQQ__DiscountSchedule__c testDiscountSc=[Select Id from  SBQQ__DiscountSchedule__c Limit 1];
        
        string Pricetierid=testPriceTier.id;

        string PTdata1='[{"Price__c":"72","Id":"'+Pricetierid+'"}]';
        object PTdata=json.deserializeUntyped(PTdata1);
        
        string PricebookEntryid=testPricebookEntry.id;
        string PEdata1='[{"UnitPrice":"72","Id":"'+PricebookEntryid+'"}]';
        object PEdata=json.deserializeUntyped(PEdata1);
        
        string LookupDataid=testLookupData.id;
        string LDdata1='[{"SBCF_SSPPrice__c":"1000","Id":"'+LookupDataid+'"}]';
        object LDdata=json.deserializeUntyped(LDdata1);
        
        string testDiscountScid=testDiscountSc.id;
        string DSdata1='[{"SBQQ__Type__c":"Slab","Id":"'+testDiscountScid+'"}]';
        object Dsdata=json.deserializeUntyped(DSdata1);
        
        
        Test.startTest();
        string j=productListController.editRelatedRecords('Pricebook Entry',PEdata,PricebookEntryid);
        string k=productListController.editRelatedRecords('Lookup Data',LDdata,LookupDataid);
        string l=productListController.editRelatedRecords('Discount Schedule',Dsdata,testDiscountScid);

        Test.stopTest();
      
    }
    
   
}