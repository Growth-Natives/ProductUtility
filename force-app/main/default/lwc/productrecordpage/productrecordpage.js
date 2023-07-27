import { LightningElement, api, track } from 'lwc';

export default class Productrecordpage extends LightningElement {
    @api value;
    @api childData;
    @api fieldData;
    @track childRecordsMap = [];
    @track dsColumn;
    @track dtColumn;
    @track scheduleTireValue = false;
    @track scheduleTireMap = [];
    @track draftValues = [];
    @track activeTab;
    @track closeCheck = false;


    connectedCallback() {

        if (this.childData != undefined) {
            this.childData = JSON.parse(JSON.stringify(this.childData));
        }
        this.fieldData = JSON.parse(JSON.stringify(this.fieldData));
        for (var key in this.childData) {
            if (key == 'Pricebook Entry') {
                this.childData[key].forEach(function (pb) {
                    if (pb.Pricebook2) {
                        pb.PricebookName = pb.Pricebook2.Name;
                    }
                });
            }
            if (key == 'Discount Schedule') {
                this.childData['Discount Schedule'].forEach(function (ds) {
                    if (ds.SBQQ__Pricebook__r && ds.SBQQ__Pricebook__r != null && ds.SBQQ__Pricebook__r != '' && ds.SBQQ__Pricebook__r != undefined) {
                        ds.PricebookName = ds.SBQQ__Pricebook__r.Name;
                    }
                });
            }
        }
        for (var key in this.fieldData) {
            if (key == 'Pricebook Entry' || key == 'Discount Schedule') {
                this.fieldData[key].PricebookName = 'Price Book';
            }
        }
        this.handleData();
    }

    disconnectedCallback() {
        if (!this.closeCheck) {
            const pageevent = new CustomEvent("getbool");
            this.dispatchEvent(pageevent);
        }
    }


    handleData() {
        let data = [];
        if (this.childData != undefined) {
            data = JSON.parse(JSON.stringify(this.childData));
        }
        for (var key in data['Discount Schedule']) {
            var tirelist = [];
            if (data['Discount Schedule'][key].SBQQ__Pricebook__r) {
                if (data['Discount Schedule'][key].SBQQ__Pricebook__r.Id == this.value) {
                    for (var tirekey in data['Discount Tier']) {
                        if (data['Discount Schedule'][key].Id == data['Discount Tier'][tirekey].SBQQ__Schedule__c) {
                            this.scheduleTireValue = true;
                            tirelist.push(data['Discount Tier'][tirekey]);
                        }
                    }
                    var ds = [];
                    ds.push(data['Discount Schedule'][key]);
                    this.scheduleTireMap.push({
                        key: ds, value: tirelist
                    });
                }
                else if(this.value == 'all') {
                    if (data['Discount Schedule'][key].SBQQ__Pricebook__r.Name != 'CPQ GSA Sales') {
                        for (var tirekey in data['Discount Tier']) {
                            if (data['Discount Schedule'][key].Id == data['Discount Tier'][tirekey].SBQQ__Schedule__c) {
                                this.scheduleTireValue = true;
                                tirelist.push(data['Discount Tier'][tirekey]);
                            }
                        }
                        var ds = [];
                        ds.push(data['Discount Schedule'][key]);
                        this.scheduleTireMap.push({
                            key: ds, value: tirelist
                        });
                    }
                }

            }
        }


        for (var key in data) {
            if (key != 'Product') {
                var detailObj = { Name: '', Columns: [], Records: [] };
                detailObj.Name = key;
                for (var key1 in this.fieldData[key]) {
                    if (this.fieldData[key][key1] != 'Price Book') {
                        detailObj.Columns.push({ label: this.fieldData[key][key1], fieldName: key1, editable: true });
                    }
                    else {
                        detailObj.Columns.push({ label: this.fieldData[key][key1], fieldName: key1 });
                    }

                }
                for (var i in data[key]) {
                    if (key == 'Pricebook Entry') {
                        if (data[key][i].Pricebook2) {
                            if (data[key][i].Pricebook2.Id == this.value) {
                                detailObj.Records.push(data[key][i]);
                            }
                            else if (this.value == 'all' && (data[key][i].Pricebook2.Name) != 'CPQ GSA Sales') {
                                detailObj.Records.push(data[key][i]);
                            }

                        }
                    }
                    else {
                        if (data[key][i]) {
                            detailObj.Records.push(data[key][i]);
                        }
                    }

                }
                this.childRecordsMap.push(detailObj);
            }
        }
        if ((this.childRecordsMap.find(obj => obj.Name === 'Discount Schedule')) != null) {
            this.dsColumn = this.childRecordsMap.find(obj => obj.Name === 'Discount Schedule').Columns;
            this.childRecordsMap = this.childRecordsMap.filter((item) => item.Name !== 'Discount Schedule');
        }

        if ((this.childRecordsMap.find(obj => obj.Name === 'Discount Tier')) != null) {
            this.dtColumn = this.childRecordsMap.find(obj => obj.Name === 'Discount Tier').Columns;
            this.childRecordsMap = this.childRecordsMap.filter((item) => item.Name !== 'Discount Tier');
        }
    }

    handleclick() {
        this.closeCheck = true;
        const pageevent = new CustomEvent("getbool");
        this.dispatchEvent(pageevent);
    }

    handleActive(event) {
        this.activeTab = event.target.label;
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;
        var recordId = event.detail.draftValues[0].Id;
        this.Tabname();

        var saveRecords = [];

        saveRecords = {
            key: recordId,
            value: updatedFields
        };

        const recordPageEvent = new CustomEvent("saverecordpageevent", { detail: saveRecords });
        this.dispatchEvent(recordPageEvent);

    }

    Tabname() {
        const tabEvent = new CustomEvent("tabnameevent", { detail: this.activeTab });
        this.dispatchEvent(tabEvent);
    }

}