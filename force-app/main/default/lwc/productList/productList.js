import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import editProducts from '@salesforce/apex/productListController.editProducts';
import editRelatedRecords from '@salesforce/apex/productListController.editRelatedRecords';
import getFieldsAndRecords from '@salesforce/apex/productListController.getFieldsAndRecords';
import getProductFromPriceBookId from '@salesforce/apex/productListController.getpriceBookProducts';
import getPriceBook from '@salesforce/apex/productListController.getpriceBook';
import LightningConfirm from 'lightning/confirm';
import Product_Utility from '@salesforce/resourceUrl/ProductUtility';
import revertChanges from '@salesforce/apex/productListController.revertChanges';
import updateProducts from '@salesforce/apex/productListController.updateProducts';
import getProductUtilitySavePoint from '@salesforce/apex/productListController.getProductUtilitySavePoint';


let pricebookSelected;
let priceBookLabelSelected;
let firstFieldAPI;
let searchKey;
let fliterRecords = [];
let firstTimeEntry = false;


export default class ProductList extends NavigationMixin(LightningElement) {

    @api firstColumnAsRecordHyperLink = 'Yes';
    @track closeCheck = false;
    @track isShowSpinner = true;
    @track detailPage = false;
    @track firstSearch = true;
    @track listViewFilter = false;
    @track togglePriceBook = false;
    @track checkbool = false;
    @track datatable = true;
    @track positive = true;
    @track revertTransactionCheck = true;
    @track priceBookValue = 'all';
    @track dynamicLpColor = "slds-cell-edit";
    @track dynamicGsColor = "slds-cell-edit";
    @track priceBookLabel = 'all';
    @track fieldName = 'Name';
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 10;
    @track recordStart = 1;
    @track SelectedChecklist;
    @track childData;
    @track childDataFull;
    @track columns;
    @track tableData;
    @track fieldMap;
    @track selectedIds;
    @track cpqGsaId;
    @track searchRecords;
    @track relatedRecordId;
    @track value;
    @track subTableTop;
    @track subTableStyle;
    @track tabname;
    @track recordToUpdateValue = '';
    @track listOfRecords = [];
    @track fieldCheckBox = [];
    @track filterList = [];
    @track selectedCheckBoxList = [];
    @track toggleList = [];
    @track listPriceCPQ = [];
    @track searchData = [];
    @track pricebookProductList = [];
    @track pageList = [];
    @track checkList = [];
    @track finalList = [];
    @track draftValues = [];
    @track TransactionID = '';


    connectedCallback() {
        this.getRecords();
    }

    renderedCallback() {
        Promise.all([loadStyle(this, Product_Utility)]);
    }

    get options() {
        return [
            { label: '10', value: '10' },
            { label: '30', value: '30' },
            { label: '60', value: '60' },
            { label: '100', value: '100' }
        ];
    }

    get positiveOptions() {
        return [
            { label: '+', value: '+' },
            { label: '-', value: '-' }
        ];
    }

    get bDisableFirst() {
        return this.recordStart === 1;
    }
    get bDisableLast() {
        return this.recordEnd === this.totalRecords;
    }

    get revertDisabled() {
        return this.revertTransactionCheck;
    }



    async handleUpdateRecords() {
        var bool = false;

        if (this.checkList !== null || this.checkList !== '') {
            var j = false;
            var k = false;
            for (var i in this.checkList) {
                if (this.checkList[i] === 'Volume Price') {
                    j = true;
                }
                if (this.checkList[i] === 'List Price') {
                    k = true;
                }
            }
            if (j === true && k === true) {
                bool = true;
            }
        }
        if (this.checkList == null || this.checkList == '') {
            const event = new ShowToastEvent({
                message: 'Please select atleast one field dependency',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        else if (bool === true) {
            const event = new ShowToastEvent({
                message: 'You can not select List Price and Volume Price simultaneously',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        else if (this.recordToUpdateValue == null || this.recordToUpdateValue == '' || this.recordToUpdateValue == 0) {
            const event = new ShowToastEvent({
                message: 'Percentage can\'t be null',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        else if (this.positive === false && this.recordToUpdateValue >= 100) {
            const event = new ShowToastEvent({
                message: 'Decrement percentage can\'t be ' + this.recordToUpdateValue,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        else if (!(Number(this.recordToUpdateValue) || parseFloat(this.recordToUpdateValue, 2))) {
            const event = new ShowToastEvent({
                message: 'Only numbers are allowed',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        else {
            if (this.togglePriceBook === true && k === true) {
                const result = await LightningConfirm.open({
                    message: 'Please make sure you have permission of federal government before updating list prices of GSA products?',
                    label: 'Update Products',
                    theme: 'shade'
                });
                if (result === true) {
                    this.updateRecords();
                }
            }
            else {
                const result = await LightningConfirm.open({
                    message: 'Are you sure you want to update all the selected records?',
                    label: 'Update Products',
                    theme: 'shade'
                });
                if (result === true) {
                    this.updateRecords();
                }
            }
        }





    }

    updateRecords(event) {

        this.SelectedChecklist = this.checkList;
        for (var i in this.SelectedChecklist) {
            if (this.SelectedChecklist[i] == 'Volume Price') {
                this.SelectedChecklist[i] = 'Discount Tier';
            }
            if (this.SelectedChecklist[i] == 'List Price') {
                this.SelectedChecklist[i] = 'Pricebook Entry';
            }
        }

        this.isShowSpinner = true;
        let query = '(';
        if (this.selectedIds && this.selectedIds.length != 0) {
            for (var key in this.selectedIds) {
                query += '\'' + this.selectedIds[key] + '\',';
            }
        }

        else if (this.searchRecords && this.searchRecords.length != 0) {
            for (var key in this.searchRecords) {
                query += '\'' + JSON.parse(JSON.stringify(this.searchRecords[key])).Id + '\',';
            }
        }
        else {
            for (var key in this.childDataFull.recordList) {
                query += '\'' + key + '\',';
            }
        }
        query = query.slice(0, -1) + ')';
        updateProducts({ query: query, percentage: this.recordToUpdateValue, positive: this.positive, updateObjsList: this.SelectedChecklist, priceBook: this.priceBookLabel })
            .then(data => {
                const event = new ShowToastEvent({
                    message: ' your changes are in progress',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.selectedIds = null;
                this.searchRecords = null;
                this.dynamicGsColor = "slds-cell-edit";
                this.dynamicLpColor = "slds-cell-edit";
                searchKey = '';
                fliterRecords = [];
                this.togglePriceBook = false;
                this.getRecords();

                this.template.querySelector('lightning-datatable').selectedRows = [];

                eval("$A.get('e.force:refreshView').fire();");
                this.TransactionID = data;

                this.navigateToListView();
                this.handleSearchRecords(searchKey);
            })
            .catch(error => {
                if(typeof error.body== 'string'){
                    const event = new ShowToastEvent({
                        message: error.body,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                else{
                    const event = new ShowToastEvent({
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.isShowSpinner = false;
                this.error = error;
                console.log('error. ', error);
            })

        this.handleback();
    }

    recordToUpdate(event) {
        var val = event.detail.value;
        this.recordToUpdateValue = Number(val);
        this.handleChangePrice(Number(val));

    }

    navigateToListView() {
            let URLField;

        URLField = '/lightning/r/' + 'Product_Utility_SavePoint__c' + '/' + this.TransactionID + '/view';
        window.open(URLField, '_self');

    }


    handleChangePrice(val) {
        this.dynamicGsColor = "slds-cell-edit";
        this.dynamicLpColor = "slds-cell-edit";
        var check = this.positive;
        var listToCheck = this.listPriceCPQ;

        if (this.checkList.includes('List Price')) {
            if (this.togglePriceBook) {
                if (val == null || val == '') {
                    this.dynamicGsColor = "slds-cell-edit";
                    this.handleColumns();
                    this.searchRecords.forEach(function (ds) {
                        ds.SBCF_GSAPriceCPQ__c = listToCheck.find(obj => obj.Id === ds.Id).gsaPrice;
                    })
                }

                else {
                    this.dynamicGsColor = "slds-text-color_error";
                    this.handleColumns();
                    this.searchRecords.forEach(function (ds) {
                        if (check == true) {
                            if (ds.SBCF_GSAPriceCPQ__c != NaN && ds.SBCF_GSAPriceCPQ__c != null && ds.SBCF_GSAPriceCPQ__c != '' && ds.SBCF_GSAPriceCPQ__c) {
                                ds.SBCF_GSAPriceCPQ__c = parseFloat(Number(listToCheck.find(obj => obj.Id === ds.Id).gsaPrice + (listToCheck.find(obj => obj.Id === ds.Id).gsaPrice * Number(val)) / 100).toFixed(2));
                            }
                        }
                        else {
                            if (ds.SBCF_GSAPriceCPQ__c != NaN && ds.SBCF_GSAPriceCPQ__c != null && ds.SBCF_GSAPriceCPQ__c != '' && ds.SBCF_GSAPriceCPQ__c) {
                                ds.SBCF_GSAPriceCPQ__c = parseFloat(Number(listToCheck.find(obj => obj.Id === ds.Id).gsaPrice - (listToCheck.find(obj => obj.Id === ds.Id).gsaPrice * Number(val)) / 100).toFixed(2));
                            }
                        }
                    });
                }
            }

            else {
                if (val == null || val == '') {
                    this.dynamicLpColor = "slds-cell-edit";
                    this.handleColumns();
                    this.searchRecords.forEach(function (ds) {
                        ds.SBCF_ListPriceCPQ__c = listToCheck.find(obj => obj.Id === ds.Id).listPrice;
                    })
                }

                else {
                    this.dynamicLpColor = "slds-text-color_error";
                    this.handleColumns();
                    this.searchRecords.forEach(function (ds) {
                        if (check == true) {
                            if (ds.SBCF_ListPriceCPQ__c != NaN && ds.SBCF_ListPriceCPQ__c != null && ds.SBCF_ListPriceCPQ__c != '' && ds.SBCF_ListPriceCPQ__c) {
                                ds.SBCF_ListPriceCPQ__c = parseFloat(Number(listToCheck.find(obj => obj.Id === ds.Id).listPrice + (listToCheck.find(obj => obj.Id === ds.Id).listPrice * Number(val)) / 100).toFixed(2));
                            }
                        }
                        else {
                            if (ds.SBCF_ListPriceCPQ__c != NaN && ds.SBCF_ListPriceCPQ__c != null && ds.SBCF_ListPriceCPQ__c != '' && ds.SBCF_ListPriceCPQ__c) {
                                ds.SBCF_ListPriceCPQ__c = parseFloat(Number(listToCheck.find(obj => obj.Id === ds.Id).listPrice - (listToCheck.find(obj => obj.Id === ds.Id).listPrice * Number(val)) / 100).toFixed(2));
                            }
                        }
                    });
                }
            }


        }
        else {
            if (this.togglePriceBook) {
                this.dynamicGsColor = "slds-cell-edit";
                this.handleColumns();
                this.searchRecords.forEach(function (ds) {
                    ds.SBCF_GSAPriceCPQ__c = listToCheck.find(obj => obj.Id === ds.Id).gsaPrice;
                })
            }
            else {
                this.dynamicLpColor = "slds-cell-edit";
                this.handleColumns();
                this.searchRecords.forEach(function (ds) {
                    ds.SBCF_ListPriceCPQ__c = listToCheck.find(obj => obj.Id === ds.Id).listPrice;
                })
            }
        }
        this.paginationHelper();
    }

    getRecords() {
        getFieldsAndRecords({ searchValue: this.searchVal, criteriaField: this.fieldName })
            .then(data => {
                this.childDataFull = data;
                this.fieldMap = data.fieldMap;

                this.handleColumns();
                this.handleData();

                this.error = undefined;
                this.isShowSpinner = false;

                getPriceBook()
                    .then((data) => {
                        data.forEach(item => {
                            if (item.Name == 'CPQ GSA Sales') {
                                this.cpqGsaId = item.Id;
                            }
                        })

                    })
                    .catch((error) => {
                        console.log('getPriceBook error====>', error);
                    })

            })
            .catch(error => {
                this.error = error;
                console.log('error-----', error);
                this.tableData = undefined;
                this.isShowSpinner = false;
            })

        this.getTransactionInfo();

    }

    handleColumns() {
        this.fieldCheckBox = [];
        this.SelectedChecklist = [];
        this.finalList = [];
        firstTimeEntry = false;

        for (var key in this.fieldMap) {
            if (key != 'Product' && key != 'Discount Schedule') {
                this.fieldCheckBox.push(key);
            }
        }
        this.Checkbox();
        let items = [];
        items.push({ label: '', fieldName: 'rowNumber', type: 'number', fixedWidth: 40 });
        for (var key in this.fieldMap.Product) {
            if (this.firstColumnAsRecordHyperLink != null && this.firstColumnAsRecordHyperLink == 'Yes'
                && firstTimeEntry == false) {
                firstFieldAPI = key;
                items = [...items,
                {
                    label: this.fieldMap.Product[key].split(',')[0],
                    fieldName: 'URLField',
                    editable: false,
                    showRowNumberColumn: false,
                    type: 'url',
                    typeAttributes: {
                        label: {
                            fieldName: key
                        },
                        tooltip: {
                            fieldName: key
                        },

                        target: '_blank'
                    },
                    sortable: true
                }];
                firstTimeEntry = true;
            }
            else {
                if (key == 'SBCF_ListPriceCPQ__c' || key == 'SBCF_GSAPriceCPQ__c') {
                    items = [...items, {
                        label: this.fieldMap.Product[key].split(',')[0],
                        fieldName: key,
                        editable: true,
                        showRowNumberColumn: false,
                        cellAttributes: {
                            class: (key == 'SBCF_ListPriceCPQ__c') ? this.dynamicLpColor : this.dynamicGsColor,
                        },
                        type: (key == 'IsActive') ? 'checkbox' : 'text'
                    }];
                }
                else {
                    items = [...items, {
                        label: this.fieldMap.Product[key].split(',')[0],
                        fieldName: key,
                        editable: true,
                        showRowNumberColumn: false,
                        type: (key == 'IsActive') ? 'checkbox' : 'text'
                    }];
                }
            }
        }

        items.push({
            label: 'Related', fieldName: 'Related', type: 'button', title: 'abc',
            typeAttributes: {
                label: {
                    fieldName: 'Related'
                },
                variant: 'base',
                target: 'abc'
            },
        });
        this.columns = items;
    
    }

    handleData() {
        var productList = [];
        this.currentPage = 1;
        var i = 1;
        let mapval = [];
        for (var key in this.childDataFull.recordList) {
            this.childDataFull.recordList[key].Product[0].rowNumber = i;
            productList.push(this.childDataFull.recordList[key].Product[0]);
            this.listPriceCPQ.push({
                Id: this.childDataFull.recordList[key].Product[0].Id, listPrice: this.childDataFull.recordList[key].Product[0].SBCF_ListPriceCPQ__c, gsaPrice: this.childDataFull.recordList[key].Product[0].SBCF_GSAPriceCPQ__c
            })
            for (var discountKey in this.childDataFull.recordList[key]['Discount Schedule']) {
                mapval.push({
                    label: this.childDataFull.recordList[key]['Discount Schedule'][discountKey].Id, value: this.childDataFull.recordList[key]['Discount Schedule'][discountKey]
                });
            }
            i++;
        }
        this.searchRecords = [];
        this.totalRecords = i - 1;
        this.totalPages = (Math.ceil(Number(this.totalRecords) / Number(this.pageSize)));
        this.listOfRecords = productList;
        this.searchRecords = this.listOfRecords;
        this.recordEnd = 10;
        this.recordStart = 1;
        this.paginationHelper();
        this.handlePageList();

        this.handleContinuity();

    }
    handleContinuity() {
        if (fliterRecords.length != 0) {
            this.handleFilterValueRecords(fliterRecords);
        }
        else if (this.togglePriceBook) {
            this.handleToggleList();
        }
        else if (searchKey) {
            this.handleSearchRecords(searchKey);
        }
    }

    handleRowSelection(event) {
        var selectedRow = event.detail.selectedRows;
        if (selectedRow) {
            var idToAdd = [];
            selectedRow.forEach(item => {
                idToAdd.push(item.Id);
            })
            this.selectedIds = idToAdd;
        }
    }

    handlePageList() {
        this.pageList = [];
        var j = Math.ceil(Number(this.currentPage) / 7);

        if (7 * j <= Number(this.totalPages)) {
            for (var i = (7 * j) - 6; i <= (7 * j); i++) {
                if (i == this.currentPage) {
                    this.pageList.push({
                        class: 'pageListSelectedClass',
                        value: i
                    });
                }
                else {
                    this.pageList.push({
                        class: 'pageListClass',
                        value: i
                    });
                }
            }
        }

        else {
            for (var i = (7 * j) - 6; i <= (Number(this.totalPages)); i++) {
                if (i == this.currentPage) {
                    this.pageList.push({
                        class: 'pageListSelectedClass',
                        value: i
                    });
                }
                else {
                    this.pageList.push({
                        class: 'pageListClass',
                        value: i
                    });
                }
            }
        }

    }

    handlepositiveOptions(event) {
        if ((event.target.value) == '+') {
            this.positive = true;
        }
        else if ((event.target.value) == '-') {
            this.positive = false;
        }
        this.handleChangePrice(this.recordToUpdateValue);
    }

    handleChangeInRow(event) {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = 1;
        this.recordStart = 1;
        this.pageSize = event.target.value;
        this.totalPages = (Math.ceil(Number(this.totalRecords) / Number(this.pageSize)));
        this.handlePageList();
        if (this.pageSize <= this.totalRecords) {
            this.recordEnd = event.target.value;
        }
        else {
            this.recordEnd = this.totalRecords;
        }
        this.paginationHelper();
    }

    handlePriceBookValue(event) {
        pricebookSelected = event.detail;
        this.priceBookValue = event.detail;
    }

    handlePriceBooklabel(event) {
        priceBookLabelSelected = event.detail;
        this.priceBookLabel = event.detail;
        if (event.detail == 'all') {
            this.pricebookProductList = [];
        }
    }

    handlePriceBookProductList(event) {
        this.pricebookProductList = JSON.parse(JSON.stringify(event.detail));
    }

    handleSavedFilterList(event) {
        this.filterList = JSON.parse(JSON.stringify(event.detail));
    }

    handleFilter() {
        this.listViewFilter = !this.listViewFilter;
        this.firstSearch = true;
        this.closeCheck = true;
        this.handleback();
    }

    handleToggel(event) {
        this.togglePriceBook = !this.togglePriceBook;
        this.firstSearch = true;
        this.handleToggleList();
    }
    handleToggleList() {
        if (this.togglePriceBook) {
            this.isShowSpinner = true;
            this.priceBookLabel = 'CPQ GSA Sales';
            this.priceBookValue = this.cpqGsaId;
            getProductFromPriceBookId({ pricebookId: this.cpqGsaId })
                .then((data) => {
                    this.toggleList = [];
                    var i = 1;
                    data.forEach(item => {
                        for (let record of this.listOfRecords) {
                            if (record.Id == item) {
                                record.rowNumber = i;
                                this.toggleList.push(record);
                                i++;
                            }
                        }
                        this.isShowSpinner = false
                    })

                    this.handleToggleData();


                })
                .catch((error) => {
                    this.isShowSpinner = false;
                    console.log('getPickListValueList error====>', error);
                })
        }

        else if (!this.togglePriceBook) {
            if (pricebookSelected != null) {
                this.priceBookLabel = priceBookLabelSelected;
                this.priceBookValue = pricebookSelected;
            }
            else {
                this.priceBookLabel = 'all';
                this.priceBookValue = 'all';
            }
            this.handleData();

        }
        if (this.recordToUpdateValue != null && this.recordToUpdateValue != '') {
            this.handleChangePrice(this.recordToUpdateValue);
        }
        this.closeCheck = true;
        this.handleback();
    }

    handleToggleData() {
        var testRecords = this.toggleList;
        var i = 1;
        if (fliterRecords != null && fliterRecords.length != 0) {
            testRecords = [];
            for (var dataKey in fliterRecords) {
                for (var toggleKey in this.toggleList) {
                    if (fliterRecords[dataKey].Id == this.toggleList[toggleKey].Id) {
                        fliterRecords[dataKey].rowNumber = i;
                        testRecords.push(fliterRecords[dataKey]);
                        i++;
                    }
                }
            }
        }
        else if (fliterRecords.length == 0 && this.filterList.length != 0) {
            testRecords = [];
        }
        this.searchRecords = [];
        this.searchRecords = testRecords;
        this.currentPage = 1;
        this.totalRecords = this.searchRecords.length;
        this.totalPages = (Math.ceil(Number(this.totalRecords) / Number(this.pageSize)));
        this.recordStart = 1;
        if (this.totalRecords > this.pageSize) {
            this.recordEnd = this.pageSize;
        }
        else {
            this.recordEnd = this.totalRecords;
        }
        this.paginationHelper();
        this.handlePageList();
        if (searchKey) {
            this.handleSearchRecords(searchKey);
        }

    }

    async handleRevert() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to revert your last changes?',
            label: 'Revert Updates',
            theme: 'shade'
        });
        if (result == true) {
            this.isShowSpinner = true;
            this.checkbool = false;
            revertChanges({ selectedRecs: this.selectedIds })
                .then(data => {
                    const event = new ShowToastEvent({
                        message: 'your changes are in progress',
                        variant: 'success'
                    });
                    this.dispatchEvent(event);

                    this.TransactionID = data;
                    this.navigateToListView();

                    eval("$A.get('e.force:refreshView').fire();");
                })
                .catch(error => {
                    console.log('data1 > ', error);
                    this.isShowSpinner = false;
                    const event = new ShowToastEvent({
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                })
        }
        this.closeCheck = true;
        this.handleback();
    }

    handleNext() {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = this.currentPage + 1;

        if ((Number(this.recordEnd) + Number(this.pageSize) <= this.totalRecords)) {
            this.recordStart = Number(this.recordStart) + Number(this.pageSize);
            this.recordEnd = Number(this.recordEnd) + Number(this.pageSize);
        }
        else {
            this.recordStart = Number(this.recordStart) + Number(this.pageSize);
            this.recordEnd = this.totalRecords;
        }

        this.handlePageList();
        this.paginationHelper();
    }

    handlePrev() {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = this.currentPage - 1;
        if ((Number(this.recordStart) - Number(this.pageSize) >= 1)) {
            this.recordEnd = Number(this.recordStart) - 1;
            this.recordStart = Number(this.recordStart) - Number(this.pageSize);
        }
        else {
            this.recordEnd = Number(this.recordEnd) - Number(this.pageSize);
            this.recordStart = 1;
        }
        this.handlePageList();
        this.paginationHelper();
    }

    handleLast() {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = this.totalPages;
        if ((Number(this.totalRecords) % Number(this.pageSize)) == 0) {
            this.recordStart = ((Math.floor(Number(this.totalRecords) / Number(this.pageSize))) - 1) * this.pageSize + 1;
        }
        else {
            this.recordStart = (Math.floor(Number(this.totalRecords) / Number(this.pageSize))) * this.pageSize + 1;
        }
        this.recordEnd = this.totalRecords;
        this.handlePageList();
        this.paginationHelper();
    }

    handleFirst() {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = 1;
        this.recordStart = 1;
        this.recordEnd = this.pageSize;
        this.handlePageList();
        this.paginationHelper();
    }

    processMe(event) {
        this.closeCheck = true;
        this.handleback();
        this.currentPage = event.target.label;
        if (Number(this.currentPage) < Number(this.totalPages)) {
            this.handlePageList();
            this.recordStart = (Number(this.currentPage) - 1) * Number(this.pageSize) + 1;
            this.recordEnd = (Number(this.currentPage)) * Number(this.pageSize);
        }
        else {
            this.handleLast();
        }
        this.paginationHelper();
    }

    paginationHelper() {
        var records = [];

        for (let i = (this.recordStart) - 1; i < this.recordEnd; i++) {
            records.push(this.searchRecords[i]);
        }

        this.tableData = records;


        if (this.firstColumnAsRecordHyperLink != null && this.firstColumnAsRecordHyperLink == 'Yes') {
            let URLField;
            let Related;
            this.tableData = records.map(item => {
                URLField = '/lightning/r/' + 'Product2' + '/' + item.Id + '/view';
                Related = 'Related';
                item = { ...item, URLField };
                return { ...item, Related };
            });

            this.tableData = this.tableData.filter(item => item.fieldPath != firstFieldAPI);
        }
    }


    mouseLocationDiv(evt) {
        this.subTableTop = evt.pageY;
        this.subTableTop -= 116;
    }
    handleSearch(event) {
        this.closeCheck = true;
        this.handleback();
        searchKey = event.target.value.toLowerCase();
        this.handleSearchRecords(searchKey);

    }


    handleSearchRecords(searchKey) {
        if (searchKey) {
            if (this.searchRecords) {
                var searchList = [];
                if (this.firstSearch) {
                    this.searchData = this.searchRecords;
                    this.firstSearch = false;
                }
                var i = 1;
                for (let record of this.searchData) {
                    if (record.ProductCode != null && record.ProductCode != '') {
                        if ((record.ProductCode).toLowerCase().includes(searchKey)) {
                            record.rowNumber = i;
                            searchList.push(record);
                            i++;
                        }
                    }

                }
                this.searchRecords = [];
                this.searchRecords = searchList;
                this.currentPage = 1;
                this.totalRecords = this.searchRecords.length;
                this.totalPages = (Math.ceil(Number(this.totalRecords) / Number(this.pageSize)));
                this.recordStart = 1;
                if (this.totalRecords > this.pageSize) {
                    this.recordEnd = this.pageSize;
                }
                else {
                    this.recordEnd = this.totalRecords;
                }
                this.paginationHelper();
                this.handlePageList();
            }
        }
        else {
            this.firstSearch = true;
            if (this.togglePriceBook) {
                this.handleToggleData();
            }
            else {
                this.handleData();
            }

        }
    }

    handelFilterValue(event) {
        fliterRecords = [];
        fliterRecords = JSON.parse(JSON.stringify(event.detail));
        this.handleFilterValueRecords(fliterRecords);
    }

    handleFilterValueRecords(fliterRecords) {
        var testRecords = fliterRecords;
        if (this.pricebookProductList != null && this.pricebookProductList.length != 0) {
            var i = 1;
            testRecords = [];
            for (var filterKey in fliterRecords) {
                for (var priceBookProductListKey in this.pricebookProductList) {
                    if (fliterRecords[filterKey].Id == this.pricebookProductList[priceBookProductListKey].Id) {
                        fliterRecords[filterKey].rowNumber = i;
                        testRecords.push(fliterRecords[filterKey]);
                        i++;
                    }
                }
            }
        }
        else{
            var i = 1;
            testRecords = [];
            for (var filterKey in fliterRecords) {
                for (var priceBookProductListKey in this.listOfRecords) {
                    if (fliterRecords[filterKey].Id == this.listOfRecords[priceBookProductListKey].Id) {
                        fliterRecords[filterKey].rowNumber = i;
                        testRecords.push(fliterRecords[filterKey]);
                        i++;
                    }
                }
            }
        }
        this.searchRecords = []
        this.searchRecords = testRecords;
        this.currentPage = 1;
        this.totalRecords = this.searchRecords.length;
        this.totalPages = (Math.ceil(Number(this.totalRecords) / Number(this.pageSize)));
        this.recordStart = 1;
        if (this.totalRecords > this.pageSize) {
            this.recordEnd = this.pageSize;
        }
        else {
            this.recordEnd = this.totalRecords;
        }
        this.paginationHelper();
        this.handlePageList();
        if (this.togglePriceBook) {
            this.handleToggleList();
        }
        else if (searchKey) {
            this.handleSearchRecords(searchKey);
        }
    }

    handleCloseFilter() {
        this.listViewFilter = false;
    }

    async onAction(event) {
        this.childData = this.childDataFull.recordList[event.detail.row.Id];

        if (this.relatedRecordId != event.detail.row.Id) {
            this.closeCheck = false;
            this.relatedRecordId = event.detail.row.Id;

            this.subTableStyle = 'position: absolute;right: 0;top:' + this.subTableTop + 'px;z-index:2;';
            this.detailPage = !(this.detailPage);

        }
        else {
            this.detailPage = !(this.detailPage);
            this.closeCheck = true;
        }
    }

    handleback(event) {
        if (this.closeCheck) {
            this.detailPage = false;
        }
        else {
            this.detailPage = !(this.detailPage);
            this.datatable = true;
        }
    }

    checkBoxSelect(event) {
        if (event.target.checked == true) {
            this.checkList.push(event.currentTarget.name);
        }
        else {
            this.checkList = this.checkList.filter(value => value !== event.target.name);
        }

        if (!this.selectedCheckBoxList.includes(event.currentTarget.name)) {
            this.selectedCheckBoxList.push(event.currentTarget.name);
        }
        else if (this.selectedCheckBoxList.includes(event.currentTarget.name)) {
            for (var i = 0; i < this.selectedCheckBoxList.length; i++) {
                if (this.selectedCheckBoxList[i] === event.currentTarget.name) {
                    var spliced = this.selectedCheckBoxList.splice(i, 1);
                }
            }
            if (event.target.checked == true && spliced == 'List Price') {
                if (this.recordToUpdateValue != null && this.recordToUpdateValue != '') {
                    this.handleChangePrice(this.recordToUpdateValue);
                }
            }
            else if (event.target.checked == false && spliced == 'List Price') {
                if (this.recordToUpdateValue != null && this.recordToUpdateValue != '') {
                    this.handleChangePrice(this.recordToUpdateValue);
                }
            }

        }

    }

    Checkbox() {

        var len = this.fieldCheckBox.length;
        var fieldList = [];
        var looplength;
        if (len > 5) {
            looplength = Math.ceil(len / 2);
        }
        else {
            looplength = len;
        }
        for (var i = 0; i < looplength; i++) {
            fieldList.push(this.fieldCheckBox[i]);
        }
        this.finalList.push(fieldList);
        fieldList = [];
        for (var i = looplength; i < len; i++) {
            fieldList.push(this.fieldCheckBox[i]);
        }
        this.finalList.push(fieldList);
        for (var i in this.finalList) {
            for (var j in this.finalList[i]) {
                if (this.finalList[i][j] == 'Discount Tier') {
                    this.finalList[i][j] = 'Volume Price';
                }
                if (this.finalList[i][j] == 'Pricebook Entry') {
                    this.finalList[i][j] = 'List Price';
                }
            }
        }
    }

    handleKeyUp(event) {
        this.closeCheck = true;
        this.handleback();

    }

    async handleSave(event) {
        this.draftValues = event.detail.draftValues;
        var fieldname = [];
        var fieldValue;
        this.mapp = [];

        for (var i in this.draftValues) {
            for (var j in this.draftValues[i]) {
                fieldname = j;
                fieldValue = this.draftValues[i][j];
                this.mapp.push({ key: fieldname, value: fieldValue });
            }
        }
        this.isShowSpinner = true;
        await editProducts({ data: this.draftValues })
            .then(result => {
                const event = new ShowToastEvent({
                    message: result,
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.draftValues = [];
                this.getRecords();
            })
            .catch(error => {
                console.log('error->' + JSON.stringify(error));
                  if(typeof error.body== 'string'){
                    const event = new ShowToastEvent({
                        message: error.body,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                else{
                    const event = new ShowToastEvent({
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.isShowSpinner = false;
            });
    }
    gettabname(event) {
        this.tabname = event.detail;
    }

    saveRecordPage(event) {
        var recordPageFields = event.detail;
        var recordid = recordPageFields.key;
        var draftValues = recordPageFields.value;

        var fieldname = [];
        var fieldValue;
        for (var i in draftValues) {
            for (var j in draftValues[i]) {
                fieldname = j;
                fieldValue = draftValues[i][j];
                break;
            }
        }

        this.isShowSpinner = true;
        editRelatedRecords({ apiname: this.tabname, data: draftValues, Recordid: recordid })
            .then(result => {
                const event = new ShowToastEvent({
                    message: result,
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.draftValues = [];
                eval("$A.get('e.force:refreshView').fire();");
                this.isShowSpinner = false;
            })
            .catch(error => {
                console.log('error->' + JSON.stringify(error.body));
                const event = new ShowToastEvent({
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.isShowSpinner = false;
            });
    }

    getTransactionInfo() {
        getProductUtilitySavePoint()
            .then((data) => {
                data.forEach(item => {
                    if (item.Status__c == 'Completed' || item.Status__c == 'Failed') {
                        this.revertTransactionCheck = false;
                    }
                    else {
                        this.revertTransactionCheck = true;
                    }
                })
            })
            .catch((error) => {
                console.log('getProductUtilitySavePoint error====>', error);
            })
    }



}