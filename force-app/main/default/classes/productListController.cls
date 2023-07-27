public class productListController {
    
    @AuraEnabled
    public static productWrapper getFieldsAndRecords(){
        map<string,map<string,list<sObject>>> recordsMap = new map<string,map<string,list<sObject>>>();
        Map<string,Map<String, String>> allObjFieldMap = new Map<string,Map<String, String>>();
        Map<string,List<sObject>> discountTierMap = new Map<string,List<sObject>>();
        String displayQuery = 'SELECT ';
        String discountTierQuery;
        for(Product_Utility_Setting__mdt p_mdt : Product_Utility_Setting__mdt.getAll().values()){
            Map<String, String> fieldMap = new Map<String,String>();
            if(p_mdt.DeveloperName == 'Product2'){
                displayQuery += p_mdt.DisplayFields__c + ',';
            }
            else if(p_mdt.DeveloperName == 'SBQQ_DiscountTier'){ 
                discountTierQuery = '(SELECT Id,' + p_mdt.DisplayFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + ' order by SBQQ__Number__c)';
            }
            else if(p_mdt.MasterLabel == 'Pricebook Entry'){
                displayQuery += '(SELECT Id,' + p_mdt.DisplayFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + ' WHERE isActive = True AND Pricebook2.isActive = TRUE),'; 
            }
            else{
                if(p_mdt.DisplayFields__c != null)
                    displayQuery += '(SELECT Id,' + p_mdt.DisplayFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + '),';
            }
            Map<String, Schema.SObjectField> MapofField = Schema.getGlobalDescribe().get(p_mdt.Object_API_Name__c).getDescribe().fields.getMap();
            for(String fieldName : MapofField.keyset()){
                if(p_mdt.DisplayFields__c.contains(',')){
                    for(string s : p_mdt.DisplayFields__c.split(',')){
                        if(s.trim() == fieldName){
                            if(p_mdt.DeveloperName == 'Product2')
                                fieldMap.put(s.trim(),MapofField.get(fieldName).getDescribe().getLabel() + ',' + MapofField.get(fieldName).getDescribe().getType());
                            else
                                fieldMap.put(s.trim(),MapofField.get(fieldName).getDescribe().getLabel());
                        }
                    }
                }
                else{
                    if(p_mdt.DisplayFields__c.trim() == fieldName){
                        if(p_mdt.DeveloperName == 'Product2')
                            fieldMap.put(p_mdt.DisplayFields__c.trim(),MapofField.get(fieldName).getDescribe().getLabel() + ',' + MapofField.get(fieldName).getDescribe().getType());
                        else
                            fieldMap.put(p_mdt.DisplayFields__c.trim(),MapofField.get(fieldName).getDescribe().getLabel());
                    }
                }
            }
            allObjFieldMap.put(p_mdt.MasterLabel,fieldMap);
        }
        displayQuery += ' Id FROM Product2 WHERE IsActive=true ' ;
        List<sObject> lstRecords = Database.query(displayQuery);
        discountTierQuery = 'SELECT Id, SBQQ__Product__r.Id, ' + discountTierQuery + ' FROM SBQQ__DiscountSchedule__c WHERE SBQQ__Product__r.Id in (';
        for(sObject productRec : lstRecords){
            discountTierQuery += '\'' + productRec.get('Id') + '\',';
        }
        discountTierQuery = discountTierQuery.removeEnd(',') + ')';
        List<sObject> discountTierRecords = Database.query(discountTierQuery);
        for(sObject discountTier : discountTierRecords){
            if(discountTier.getSObjects('SBQQ__DiscountTiers__r') != null && !discountTier.getSObjects('SBQQ__DiscountTiers__r').isEmpty()){
                if(!discountTierMap.containsKey(String.ValueOf(discountTier.getsObject('SBQQ__Product__r').get('Id')))){
                    discountTierMap.put(String.ValueOf(discountTier.getsObject('SBQQ__Product__r').get('Id')),discountTier.getSObjects('SBQQ__DiscountTiers__r'));
                }
                else{
                    if(discountTierMap.get(String.ValueOf(discountTier.getsObject('SBQQ__Product__r').get('Id'))) != null){
                        list<sObject> tempList = discountTierMap.get(String.ValueOf(discountTier.getsObject('SBQQ__Product__r').get('Id')));
                        tempList.addAll(discountTier.getSObjects('SBQQ__DiscountTiers__r'));
                        discountTierMap.put(String.ValueOf(discountTier.getsObject('SBQQ__Product__r').get('Id')),tempList);
                    }
                }
            }
        }
        for(sObject product : lstRecords){
            map<string,list<sObject>> tempMap = new map<string,list<sObject>>();
            for(Product_Utility_Setting__mdt p_mdt : Product_Utility_Setting__mdt.getAll().values()){
                if(p_mdt.DeveloperName == 'Product2'){
                    tempMap.put(p_mdt.MasterLabel,new list<sObject>{product});
                }
                else if(p_mdt.DeveloperName == 'SBQQ_DiscountTier'){
                    tempMap.put(p_mdt.MasterLabel,discountTierMap.get(string.valueOf(product.get('Id'))));
                }
                else{
                    tempMap.put(p_mdt.MasterLabel,product.getSObjects(p_mdt.Child_Relationship_Name__c));
                }
            }
            recordsMap.put(string.valueof(product.get('Id')),tempMap);
        }
        
        productWrapper pw = new productWrapper();
        pw.fieldMap = allObjFieldMap;
        pw.recordList = recordsMap;
        return pw;
    }
    
    @AuraEnabled 
    public static List<Id> getpriceBookProducts(Id pricebookId){
        List<Id> productId = new List<Id>();
        for(PricebookEntry product:[SELECT Id, Product2Id, Product2.Name, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id =: pricebookId AND IsActive = True ]){
            productId.add(product.Product2Id);
        }
        return productId;
    }
    
    @AuraEnabled 
    public static List<Pricebook2> getpriceBook(){
        return [Select Id, Name FROM Pricebook2 WHERE IsActive = True];
    }
    
    @AuraEnabled 
    public static List<Product_Utility_SavePoint__c> getProductUtilitySavePoint(){
        return [SELECT Id, Name, Status__c FROM Product_Utility_SavePoint__c order by CreatedDate desc limit 1];
    }
    
    @AuraEnabled
    public static Map<String,List<String>> getPickListValues(){
        Map<String,List<String>> picklistValueMap = new Map<String,List<String>>();
        List<String> pickListValuesList= new List<String>();
        List<String> pickListField = new List<String>();
        String objectName = 'Product2';
        Map<String, Schema.SObjectField> productMap = Schema.SObjectType.Product2.fields.getMap();
        for(string productFieldVal : (Product_Utility_Setting__mdt.getInstance('Product2').DisplayFields__c).split(',')){
            Schema.SObjectField field = productMap.get(productFieldVal);
            Schema.DisplayType FldType = field.getDescribe().getType();
            string FldLabel = field.getDescribe().getLabel();
            if(FldType == Schema.DisplayType.PICKLIST){
                pickListField.add(FldLabel + ',' +productFieldVal);
            }
        }
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        for(String a: pickListField){
            Schema.DescribeFieldResult fieldResult = fields.get(a.split(',')[1]).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            picklistValueMap.put(a.split(',')[0], pickListValuesList);
        }
        
        return picklistValueMap;
    }
    
    @AuraEnabled 
    public static string updateProducts(string query,string percentage,boolean positive,list<string> updateObjsList,string priceBook){
        Product_Utility_SavePoint__c pu = new Product_Utility_SavePoint__c();
        string recsJSON = '';
        string discountRecsJSON = '';
        string prodUtilSavepointId = '';
        Map<string,List<sObject>> discountTierMap = new Map<string,List<sObject>>();
        map<string,list<sObject>> recordsMap = new map<string,List<sObject>>();
        map<string,sObject> mapToUpdate = new map<string,sObject>();
        list<sObject> listToUpdate = new list<sObject>();
        string discountTierUpdateQuery;
        String updateQuery = 'SELECT ';
        Map<String,List<String>> fieldMap = new Map<String,List<String>>();
        try{        
            for(Product_Utility_Setting__mdt p_mdt : Product_Utility_Setting__mdt.getAll().values()){
                if(p_mdt.DeveloperName == 'Product2'){
                    if(p_mdt.UpdateFields__c != null && p_mdt.UpdateFields__c.contains(',')){
                        fieldMap.put(p_mdt.Object_API_Name__c,p_mdt.UpdateFields__c.split(','));
                        updateQuery += p_mdt.UpdateFields__c + ',';
                    }
                    else if(p_mdt.UpdateFields__c != null){
                        fieldMap.put(p_mdt.Object_API_Name__c,new list<string>{p_mdt.UpdateFields__c});
                        updateQuery += p_mdt.UpdateFields__c + ',';
                    }
                }
                else if(p_mdt.DeveloperName == 'SBQQ_DiscountTier' && (updateObjsList.contains('Discount Tier') || updateObjsList.contains('Pricebook Entry'))){
                    if(priceBook == 'all'){
                        discountTierUpdateQuery = 'SELECT Id, ' + p_mdt.UpdateFields__c + ',SBQQ__Schedule__r.SBQQ__Pricebook__r.Name,SBQQ__Schedule__r.SBQQ__Product__r.Id,SBQQ__Schedule__r.SBQQ__Product__r.Name,SBQQ__Schedule__r.SBQQ__Pricebook__c' + ' FROM ' + p_mdt.Object_API_Name__c + ' WHERE SBQQ__Schedule__r.SBQQ__Pricebook__r.Name != \'CPQ GSA Sales\' AND SBQQ__Schedule__r.SBQQ__Product__r.Id in ('; 
                    }
                    else{
                        discountTierUpdateQuery = 'SELECT Id, ' + p_mdt.UpdateFields__c + ',SBQQ__Schedule__r.SBQQ__Pricebook__r.Name,SBQQ__Schedule__r.SBQQ__Product__r.Id,SBQQ__Schedule__r.SBQQ__Product__r.Name,SBQQ__Schedule__r.SBQQ__Pricebook__c' + ' FROM ' + p_mdt.Object_API_Name__c + ' WHERE SBQQ__Schedule__r.SBQQ__Pricebook__r.Name = \'' + priceBook +'\' AND SBQQ__Schedule__r.SBQQ__Product__r.Id in (';
                    }
                    if(p_mdt.UpdateFields__c != null && p_mdt.UpdateFields__c.contains(',')){
                        fieldMap.put(p_mdt.Child_Relationship_Name__c,p_mdt.UpdateFields__c.split(','));
                    }
                    else if(p_mdt.UpdateFields__c != null){
                        fieldMap.put(p_mdt.Child_Relationship_Name__c,new list<string>{p_mdt.UpdateFields__c});
                    }
                }
                else{
                    if(updateObjsList.contains(p_mdt.MasterLabel)){
                        if(p_mdt.UpdateFields__c != null){
                            if(p_mdt.UpdateFields__c.contains(',')){
                                fieldMap.put(p_mdt.Child_Relationship_Name__c,p_mdt.UpdateFields__c.split(','));
                            }
                            else{
                                fieldMap.put(p_mdt.Child_Relationship_Name__c,new list<string>{p_mdt.UpdateFields__c});
                            }
                            if(p_mdt.MasterLabel != 'Pricebook Entry'){
                                updateQuery += '(SELECT Id,' + p_mdt.UpdateFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + '),';
                            }
                            else if(p_mdt.MasterLabel == 'Pricebook Entry' && priceBook == 'all'){
                                updateQuery += '(SELECT Id,' + p_mdt.UpdateFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + ' WHERE Pricebook2.Name != \'CPQ GSA Sales\' AND UseStandardPrice = FALSE AND isActive = TRUE AND Pricebook2.isActive = TRUE),';
                            }
                            else{
                                updateQuery += '(SELECT Id,' + p_mdt.UpdateFields__c + ' FROM ' + p_mdt.Child_Relationship_Name__c + ' WHERE Pricebook2.Name = \'' + priceBook +'\' AND UseStandardPrice = FALSE AND isActive = TRUE AND Pricebook2.isActive = TRUE),';
                            }
                        }
                    }
                }
            }
            updateQuery += ' Id FROM Product2 WHERE IsActive=true AND Id in '+ query ;
            list<sObject> allObjRecs = Database.query(updateQuery);
            recsJSON = JSON.serialize(allObjRecs);
            if(updateObjsList.contains('Discount Tier') || updateObjsList.contains('Pricebook Entry')){
                for(sObject product : allObjRecs){
                    discountTierUpdateQuery += '\'' + product.get('Id') + '\',';
                }
                discountTierUpdateQuery = discountTierUpdateQuery.removeEnd(',') + ')';
                List<sObject> discountTierRecords = Database.query(discountTierUpdateQuery);
                discountRecsJSON = JSON.serialize(discountTierRecords);
                for(sObject discountTier : discountTierRecords){
                    if(!discountTierMap.containsKey(String.ValueOf(discountTier.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Id')))){
                        discountTierMap.put(String.ValueOf(discountTier.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Id')),new list<sObject>{discountTier});
                    }
                    else{
                        list<sObject> tempList = discountTierMap.get(String.ValueOf(discountTier.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Id')));
                        tempList.add(discountTier);
                        discountTierMap.put(String.ValueOf(discountTier.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Id')),tempList);
                    }
                    
                }
            }
            for(sObject sObj : allObjRecs){
                for(string objName : fieldMap.keyset()){
                    if(objName == 'Product2'){
                        if(updateObjsList.contains('Pricebook Entry')){
                            if(priceBook == 'CPQ GSA Sales'){
                                if(sObj.get('SBCF_GSAPriceCPQ__c') != null){
                                    if(positive){
                                        sObj.put('SBCF_GSAPriceCPQ__c',(decimal.valueof(string.valueOf(sObj.get('SBCF_GSAPriceCPQ__c')))+decimal.valueof(string.valueOf(sObj.get('SBCF_GSAPriceCPQ__c')))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                    else{
                                        sObj.put('SBCF_GSAPriceCPQ__c',(decimal.valueof(string.valueOf(sObj.get('SBCF_GSAPriceCPQ__c')))-decimal.valueof(string.valueOf(sObj.get('SBCF_GSAPriceCPQ__c')))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                }
                            }
                            else if(priceBook == 'CPQ Standard Sales' || priceBook == 'all'){
                                if(sObj.get('SBCF_ListPriceCPQ__c') != null){
                                    if(positive){
                                        sObj.put('SBCF_ListPriceCPQ__c',(decimal.valueof(string.valueOf(sObj.get('SBCF_ListPriceCPQ__c')))+decimal.valueof(string.valueOf(sObj.get('SBCF_ListPriceCPQ__c')))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                    else{
                                        sObj.put('SBCF_ListPriceCPQ__c',(decimal.valueof(string.valueOf(sObj.get('SBCF_ListPriceCPQ__c')))-decimal.valueof(string.valueOf(sObj.get('SBCF_ListPriceCPQ__c')))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                }
                            }
                            if(!recordsMap.containsKey(objName)){
                                recordsMap.put(objName,new list<sObject>{sObj});
                            }
                            else{
                                list<sObject> tempList = recordsMap.get(objName);
                                tempList.add(sObj);
                                recordsMap.put(objName,tempList);
                            }
                        }
                    }
                    else if(objName != 'SBQQ__DiscountTiers__r'){
                        for(sObject rObj : sObj.getSObjects(objName)){
                            for(string fieldName : fieldMap.get(objName)){
                                if(rObj.get(fieldName) != null){
                                    if(positive){
                                        rObj.put(fieldName,(decimal.valueof(string.valueOf(rObj.get(fieldName)))+decimal.valueof(string.valueOf(rObj.get(fieldName)))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                    else{
                                        rObj.put(fieldName,(decimal.valueof(string.valueOf(rObj.get(fieldName)))-decimal.valueof(string.valueOf(rObj.get(fieldName)))*(decimal.valueof(percentage)/100)).setScale(4));
                                    }
                                }
                            }
                            if(!recordsMap.containsKey(objName)){
                                recordsMap.put(objName,new list<sObject>{rObj});
                            }
                            else{
                                list<sObject> tempList = recordsMap.get(objName);
                                tempList.add(rObj);
                                recordsMap.put(objName,tempList);
                            }
                        }
                    }
                    if((objName == 'SBQQ__DiscountTiers__r' && updateObjsList.contains('Discount Tier')) || objName == 'PricebookEntries'){
                        if(discountTierMap.get(String.valueOf(sObj.get('Id'))) != null){
                            for(sObject rObj : discountTierMap.get(String.valueOf(sObj.get('Id')))){
                                if(rObj.get('SBQQ__LowerBound__c') != 1 && rObj.get('SBQQ__LowerBound__c') != 0 && rObj.getsObject('SBQQ__Schedule__r').get('SBQQ__Pricebook__c') != null){
                                    decimal discount;
                                    if(objName == 'PricebookEntries'){
                                        if(priceBook == 'all' || priceBook == string.valueOf(rObj.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Pricebook__r').get('Name'))){
                                            if(positive){
                                                discount = (decimal.valueof(string.valueOf(rObj.get('SBQQ__DiscountAmount__c'))) + decimal.valueof(string.valueOf(rObj.get('SBCF_ListPrice__c')))*(decimal.valueof(percentage)/100)).setScale(4);
                                            }
                                            else{
                                                discount = (decimal.valueof(string.valueOf(rObj.get('SBQQ__DiscountAmount__c'))) - decimal.valueof(string.valueOf(rObj.get('SBCF_ListPrice__c')))*(decimal.valueof(percentage)/100)).setScale(4);
                                            }
                                        }
                                    }
                                    else{
                                        if(positive){
                                            discount = (decimal.valueof(string.valueOf(rObj.get('SBQQ__DiscountAmount__c'))) - decimal.valueof(string.valueOf(rObj.get('SBCF_VolumePrice__c')))*(decimal.valueof(percentage)/100)).setScale(4);
                                        }
                                        else{
                                            discount = (decimal.valueof(string.valueOf(rObj.get('SBQQ__DiscountAmount__c'))) + decimal.valueof(string.valueOf(rObj.get('SBCF_VolumePrice__c')))*(decimal.valueof(percentage)/100)).setScale(4);
                                        }
                                    }
                                    if(discount >= 0){
                                        rObj.put('SBQQ__DiscountAmount__c',discount);
                                    }
                                    else if(discount < 0){
                                        throw new AuraHandledException(rObj.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Name') + ' - Volume Price cannot be greater than list price.');   
                                    }
                                    if(discount != null){
                                        if(!recordsMap.containsKey(objName)){
                                            recordsMap.put(objName,new list<sObject>{rObj});
                                        }
                                        else{
                                            list<sObject> tempList = recordsMap.get(objName);
                                            tempList.add(rObj);
                                            recordsMap.put(objName,tempList);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(recsJSON != '' || discountRecsJSON != ''){
                pu.Status__c = 'In Progress';
                insert pu;
                prodUtilSavepointId = pu.Id;
                Attachment jsonfile = new Attachment();
                jsonfile.ParentId = pu.Id;
                jsonfile.Name = 'Products ' + string.valueOf(system.now());	
                jsonfile.ContentType = 'text/plain';
                jsonfile.Body = Blob.valueOf(recsJSON);
                insert jsonfile;
                Attachment discountjsonfile = new Attachment();
                discountjsonfile.ParentId = pu.Id;
                discountjsonfile.Name = 'Discount Tiers ' + string.valueOf(system.now());	
                discountjsonfile.ContentType = 'text/plain';
                discountjsonfile.Body = Blob.valueOf(discountRecsJSON);
                insert discountjsonfile;
            }
            for(string objName : recordsMap.keyset()){
                listtoupdate.addall(recordsMap.get(objName));	
            }
            for(sObject sObj : listtoupdate){
                mapToUpdate.put(string.valueof(sObj.get('Id')),sObj);
            }
            if(!listtoupdate.isEmpty()){
                Database.executeBatch(new productUpdateBatch(mapToUpdate.values(),prodUtilSavepointId,'Update'), 25);
            }
            else{
                pu.Status__c = 'Completed';
                upsert pu;
            }
        }
        catch(DmlException e){
            system.debug('error - '+e.getMessage());
            pu.Update_Error__c = e.getMessage();
            pu.Status__c = 'Failed';
            upsert pu;
            throw new AuraHandledException('The following exception has occurred: ' + e.getMessage());
        }
        return prodUtilSavepointId;
    }
    
    @AuraEnabled
    public static string revertChanges(list<string> selectedRecs){
        string prodUtilSavepointId = '';
        list<sObject> listToUpdate = new list<sObject>();
        list<string> productIdList = new list<string>();
        map<string,sObject> mapToUpdate = new map<string,sObject>();
        map<string,list<sObject>> recordsMap = new map<string,List<sObject>>();
        try{
            list<Product_Utility_SavePoint__c> puList = new list<Product_Utility_SavePoint__c>([select id,name from Product_Utility_SavePoint__c order by createdDate desc limit 1]);
            if(!puList.isEmpty()){
                prodUtilSavepointId = puList[0].id;
                puList[0].Status__c = 'In Progress';
                update puList;
                list<attachment> attachmentList = [select Id,Name,Body,ContentType from attachment where parentId =: puList[0].id];
                for(attachment spAttach : attachmentList){
                    if(spAttach.Name.contains('Products')){
                        for(sObject product : (list<sObject>)JSON.deserialize(spAttach.Body.tostring(), list<sObject>.class)){
                            productIdList.add(String.valueOf(product.get('Id')));
                        }
                    }
                }
                if(!selectedRecs.isEmpty()){
                    for(string productId : selectedRecs){
                        if(productIdList.contains(productId)){
                            continue;
                        }
                        else{
                            throw new AuraHandledException('One or more selected records weren\'t updated in the last update.');
                        }
                    }
                }
                for(attachment spAttach : attachmentList){
                    if(spAttach.Body.tostring() != null && spAttach.Body.tostring() != ''){
                        if(spAttach.Name.contains('Products')){
                            for(sObject product : (list<sObject>)JSON.deserialize(spAttach.Body.tostring(), list<sObject>.class)){
                                if(!selectedRecs.isEmpty() && selectedRecs.contains(String.valueOf(product.get('Id'))) || selectedRecs.isEmpty()){
                                    if(!recordsMap.containsKey('Product2')){
                                        recordsMap.put('Product2',new list<sObject>{product});
                                    }
                                    else{
                                        list<sObject> tempList = recordsMap.get('Product2');
                                        tempList.add(product);
                                        recordsMap.put('Product2',tempList);
                                    }
                                    for(Product_Utility_Setting__mdt p_Mdt : Product_Utility_Setting__mdt.getAll().values()){
                                        if(p_Mdt.DeveloperName != 'SBQQ_DiscountTier' && p_Mdt.DeveloperName != 'Product2'){
                                            if(product.getsObjects(p_Mdt.Child_Relationship_Name__c) != null ){
                                                if(!recordsMap.containsKey(p_Mdt.Child_Relationship_Name__c)){
                                                    recordsMap.put(p_Mdt.Child_Relationship_Name__c,product.getsObjects(p_Mdt.Child_Relationship_Name__c));
                                                }
                                                else{
                                                    list<sObject> tempList = recordsMap.get(p_Mdt.Child_Relationship_Name__c);
                                                    tempList.addall(product.getsObjects(p_Mdt.Child_Relationship_Name__c));
                                                    recordsMap.put(p_Mdt.Child_Relationship_Name__c,tempList);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            for(string objName : recordsMap.keyset()){
                                listtoupdate.addall(recordsMap.get(objName));
                            }
                        }
                        else if(spAttach.Name.contains('Discount Tiers')){
                            for(sObject discountTiers : (list<sObject>)JSON.deserialize(spAttach.Body.tostring(), list<sObject>.class)){
                                if(!selectedRecs.isEmpty() && selectedRecs.contains(String.ValueOf(discountTiers.getsObject('SBQQ__Schedule__r').getsObject('SBQQ__Product__r').get('Id'))) || selectedRecs.isEmpty()){
                                    listtoupdate.add(discountTiers);
                                }
                            }
                        }
                    }
                }
            }
            for(sObject sObj : listtoupdate){
                mapToUpdate.put(string.valueof(sObj.get('Id')),sObj);
            }
            if(!listtoupdate.isEmpty()){
                Database.executeBatch(new productUpdateBatch(mapToUpdate.values(),prodUtilSavepointId,'Revert'), 10);
            }
        }
        catch(DmlException e){
            system.debug('error - '+e.getMessage());
            if(prodUtilSavepointId != ''){
                Product_Utility_SavePoint__c pu = new Product_Utility_SavePoint__c();
                pu.Id = prodUtilSavepointId;
                pu.Revert_Error__c = e.getMessage();
                pu.Status__c = 'Failed';
                update pu;
            }
            throw new AuraHandledException('The following exception has occurred: ' + e.getMessage());
        }
        return prodUtilSavepointId;
    }
    
    public class productWrapper{
        @AuraEnabled
        public Map<string,Map<String, String>> fieldMap{get;set;}
        @AuraEnabled
        public map<string,map<string,list<sObject>>> recordList{get;set;}
    }
    
    @AuraEnabled 
    public static string editProducts( Object data) {
        try 
        {
            List<sObject>ProdsForUpdate=new List<sObject>();
            string o = 'Product2' ;
            Schema.SObjectType t  = Schema.getGlobalDescribe().get(o);
            
            List<Map<String, String>> DraftValuesMap = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(data),List<Map<string,string>>.class);
            
            
            Map<String, Schema.SObjectField> MapofField = Schema.getGlobalDescribe().get(o).getDescribe().fields.getMap();
            for(Map<string,string> mapp:DraftValuesMap){
                SObject sobj =  t.newSObject();                
                
                
                for(string fieldNamee: mapp.keyset() ){
                    string typ=String.Valueof(MapofField.get(fieldNamee).getDescribe().getType());
                    if(typ=='TEXT' || typ=='ID'){
                        sobj.put(fieldNamee, mapp.get(fieldNamee));                        
                    }
                    else if(typ=='PICKLIST'){
                        List<string> pickListValuesList=new List<string>();
                        List<Schema.PicklistEntry>values=MapofField.get(fieldNamee).getDescribe().getPicklistValues();
                        for( Schema.PicklistEntry pickListVal : values){
                            pickListValuesList.add(pickListVal.getLabel());
                        } 
                        if(pickListValuesList.contains(mapp.get(fieldNamee)) || mapp.get(fieldNamee)=='' || mapp.get(fieldNamee)==null ){
                            sobj.put(fieldNamee, mapp.get(fieldNamee));
                        }
                        else{
                            throw new AuraHandledException( 'Please Enter a Valid Picklist Value');
                        }
                    }
                    
                    else if(typ=='CURRENCY'){
                        boolean intger=true;
                        boolean dec=true;
                        try{
                            Decimal.valueOf(mapp.get(fieldNamee));                            
                        }
                        catch(TypeException e){
                            dec=false;
                        }
                        try{
                            Integer.ValueOf(mapp.get(fieldNamee));
                        }
                        catch(TypeException e){
                            intger=false;
                        }
                        
                        if(intger==true || dec==true){
                            sobj.put(fieldNamee, Decimal.ValueOf(mapp.get(fieldNamee)));
                        }
                        else{
                            throw new AuraHandledException( 'Please Enter a Valid Price');
                        }
                    }
                    else if(typ=='NUMBER'){
                        boolean intger;
                        try{
                            Integer.ValueOf(mapp.get(fieldNamee));
                        }
                        catch(TypeException e){
                            intger=false;
                        }
                        
                        if(intger==true){
                            sobj.put(fieldNamee, Integer.Valueof(mapp.get(fieldNamee)));
                        }
                        else{
                            throw new AuraHandledException( 'Please Enter a Valid Number');
                        }
                    }
                    else{
                        sobj.put(fieldNamee, mapp.get(fieldNamee));                        
                    }
                }
                ProdsForUpdate.add(sobj);
            }
            if (Schema.sObjectType.Product2.isUpdateable()) 
            {
                update ProdsForUpdate;
            }
            return 'Success: Product(s) updated successfully';
        }
        catch (DmlException e) 
        {
            system.debug('error - '+e.getMessage());
            throw new AuraHandledException('The following exception has occurred: ' + e.getMessage());
        }   
    }
    
    @AuraEnabled
    public static string editRelatedRecords(string apiname,object data, string Recordid){
        string idd=recordId.substring(0,3);
        if(idd=='a0g'){
            apiname='Discount Tier';
        }
        try 
        {
            List<sObject>updateList=new List<sObject>();
            string sObjectName;
            string typ;
            
            List<Product_Utility_Setting__mdt> metadataList =[Select label,Object_API_Name__c from Product_Utility_Setting__mdt];
            for(Product_Utility_Setting__mdt p: metadataList){
                if(p.label==apiname){
                    sObjectName=p.Object_API_Name__c;}
            }
            Schema.SObjectType t  = Schema.getGlobalDescribe().get(sObjectName);
            
            List<Map<String, String>> DraftValuesMap = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(data),List<Map<string,string>>.class);            
            Map<String, Schema.SObjectField> MapofField = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
            for(Map<string,string> mapp:DraftValuesMap){
                SObject sobj =  t.newSObject();
                for(string fieldNamee: mapp.keyset() ){
                    typ=String.Valueof(MapofField.get(fieldNamee).getDescribe().getType());
                    if(typ=='CURRENCY'){
                        sobj.put(fieldNamee, Decimal.Valueof(mapp.get(fieldNamee)));
                    }
                    else if(typ=='ID' || typ=='TEXT'){
                        sobj.put(fieldNamee, string.Valueof(mapp.get(fieldNamee)));
                    }
                    else if(typ=='PICKLIST'){
                        List<string> pickListValuesList=new List<string>();
                        List<Schema.PicklistEntry>values=MapofField.get(fieldNamee).getDescribe().getPicklistValues();
                        for( Schema.PicklistEntry pickListVal : values){
                            pickListValuesList.add(pickListVal.getLabel());
                        } 
                        if(pickListValuesList.contains(mapp.get(fieldNamee)) || mapp.get(fieldNamee)=='' || mapp.get(fieldNamee)==null ){
                            sobj.put(fieldNamee, mapp.get(fieldNamee));
                        }
                        else{
                            throw new AuraHandledException( 'Please Enter a Valid Picklist Value');
                        }
                    }
                    else if(typ=='NUMBER'){
                        sobj.put(fieldNamee, Integer.Valueof(mapp.get(fieldNamee)));
                    }
                    else{
                        sobj.put(fieldNamee, mapp.get(fieldNamee));
                    }
                    
                }
                updateList.add(sobj);
            }
            
            if(updateList!=null){
                update updateList;
            }
            return 'Success: Record updated successfully';
        }
        catch (DmlException e) 
        {
            system.debug('error - '+e.getMessage());
            throw new AuraHandledException('The following exception has occurred: ' + e.getMessage());
        }
        
    }
    
}