public class productUpdateBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public list<sObject> updateRecs;
    public string prodUtilSavepointId;
    public string transactionType = '';
    Public Product_Utility_SavePoint__c pu = new Product_Utility_SavePoint__c();
    
    public productUpdateBatch(list<sObject> u, string prodUtilSavepointId, String transactionType){
        if(!u.isEmpty()){
            this.updateRecs = u;
        }
        if(prodUtilSavepointId != ''){
            this.prodUtilSavepointId = prodUtilSavepointId;
        }
        this.transactionType = transactionType;
        
    }
    
    
    public List<SObject> start(Database.BatchableContext BC){
        if(this.updateRecs != null){
            return this.updateRecs;
        }
        else{
            return null;
        }
        
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
                if(this.transactionType == 'abc' ||this.transactionType == 'xyz'){
                    if(this.transactionType == 'abc'){
                        this.transactionType = 'Update';
                    }
                    else{
                        this.transactionType = 'Revert';
                    }
                    if(this.prodUtilSavepointId != ''){
                        this.pu.Id = this.prodUtilSavepointId;
                        if(this.transactionType == 'Update'){
                            this.pu.Update_Error__c = 'Testing Error';
                        }
                        else{
                            this.pu.Revert_Error__c = 'Testing Error';
                        }
                        this.pu.Status__c = 'Failed';
                        for(sObject failedRec : scope){
                            if(this.pu.Failed_Record_Ids__c == null){
                                this.pu.Failed_Record_Ids__c = string.valueOf(failedRec.get('Id')) + ',';
                            }
                            else{
                                this.pu.Failed_Record_Ids__c += string.valueOf(failedRec.get('Id')) + ',';
                            }
                        }
                    }
                }
            else{
                if(!scope.isEmpty()){
                    database.update(scope,true); 
                }
            }
        }
        catch(DmlException e){
            if(this.prodUtilSavepointId != ''){
                this.pu.Id = this.prodUtilSavepointId;
                if(this.transactionType == 'Update'){
                    this.pu.Update_Error__c = e.getMessage();
                }
                else{
                    this.pu.Revert_Error__c = e.getMessage();
                }
                this.pu.Status__c = 'Failed';
                for(sObject failedRec : scope){
                    if(this.pu.Failed_Record_Ids__c == null){
                        this.pu.Failed_Record_Ids__c = string.valueOf(failedRec.get('Id')) + ',';
                    }
                    else{
                        this.pu.Failed_Record_Ids__c += string.valueOf(failedRec.get('Id')) + ',';
                    }
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        if(this.pu.Status__c != 'Failed'){
            this.pu.Id = this.prodUtilSavepointId;
            if(this.transactionType == 'Update'){
                this.pu.Status__c = 'Completed';
            }
            else{
                this.pu.Status__c = 'Reverted';
            }
            
            update this.pu;
        }
        else{
            this.pu.Failed_Record_Ids__c = this.pu.Failed_Record_Ids__c.removeEnd(',');
            update this.pu;
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            List<String> address = System.label.ErrorEmailAddress.split(',');
            if(address != null && !(address.isEmpty())){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if(this.transactionType == 'Update'){
                    mail.setSubject('Product Utility - Error While Updating Records');
                    mail.setplaintextbody('There was an error in last transaction - ' + this.pu.Update_Error__c + ' The transaction is reverted and the ids of records which couldn\'t be updated are - ' + this.pu.Failed_Record_Ids__c + '.');
                }
                else{
                    mail.setSubject('Product Utility - Error While Reverting Records');
                    mail.setplaintextbody('There was an error in last transaction - ' + this.pu.Revert_Error__c + ' The ids of records which couldn\'t be reverted are - ' + this.pu.Failed_Record_Ids__c + '.');
                }
                
                 mail.setToAddresses(address);   
                emailList.add(mail);
                if(!emailList.isEmpty()){
                    if(!test.isRunningTest()){
                        Messaging.sendEmail(emailList);
                    }
                }
            }
            if(this.transactionType == 'Update'){
                productListController.revertChanges(new list<string>{});
            }
        }
    }
}