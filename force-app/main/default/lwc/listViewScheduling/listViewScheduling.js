import { LightningElement, api, track, wire } from 'lwc';
import getUserTimezone from '@salesforce/apex/SchedulingMap.getUserTimezone';
import updateProjectAccounts from '@salesforce/apex/SchedulingMap.updateProjectAccounts';
import getProject from '@salesforce/apex/SchedulingMap.getProject';
import getProjectAcc from '@salesforce/apex/SchedulingMap.getProjectAcc';
import getProjAccforDownload from '@salesforce/apex/SchedulingMap.getProjAccforDownload';

const cols = [
    {label: 'Name',fieldName: 'Name'}, 
    {label: 'VISIT 1',fieldName: 'Visit_1__c'},
    {label: 'VISIT 2',fieldName: 'Visit_2__c'}, 
    {label: 'VISIT 3',fieldName: 'Visit_3__c'}, 
    {label: 'METRO AREA',fieldName: 'Account__r.Metro_Area__c'}, 
    {label: 'TIME ZONE',fieldName: 'Account__r.Timezone__c'}, 
];

export default class ListViewScheduling extends LightningElement {
    @api recordId;
    @api selectedDate;
    @api selectedProjAccountList = [];
    @api weekNum;
    @track projectAccountExists = false;
    @track projectAccounts = [];
    @track Edit = false;
    @track userTimezone;
    @track showSpinner = false;
    @track applicableDays;
    @track databaseRecords = [];
    @track downlodProjAcc = [];
    @track time;
    @track sortDirection = 'ASC';
    @track sortIconName1;
    @track sortIconStrore  = false;
    @track sortIconMetroArea  = false;
    @track sortIconName2;
    @track filter = 'ORDER BY Account__r.Name';
    @track columns = cols;

    connectedCallback(){
        console.log('ListViewScheduling connectedCallback-->');
        console.log('visit-->'+this.visit);
        console.log('this.weekNum-->'+this.weekNum);
        console.log('selectedProjAccountList-->'+this.selectedProjAccountList);
        console.log('selectedDate-> ' + this.selectedDate);
        this.projectAccounts = JSON.parse(this.selectedProjAccountList);
        console.log('projectAccounts-->'+this.projectAccounts);
        this.getProjectRecord();
        this.getProjectAccounts();
    }

    handleButtonClick() {
        console.log('selectedDate-> ' + this.selectedDate);
        console.log('this.weekNum-->'+this.weekNum);
        if((this.selectedDate != '' && this.selectedDate != null) || (this.weekNum != null && this.weekNum != 0 && (!isNaN(this.weekNum)))){
            console.log('entered-->');
            console.log('this.weekNum-->'+this.weekNum);
            this.dispatchEvent(new CustomEvent(
                'getdata', {
                    detail: { selectedDate: this.selectedDate, showForSelectedDate: true, weekNum: this.weekNum},
                    bubbles: true,
                    composed: true,
                }
            ));
        } else {
            this.showErrorToastSelectedDate();
        }
    }

    getProjectRecord() {
        this.showSpinner = true;
        getProject({recordId: this.recordId})
        .then((result) => {
            console.log('projects-->'+ JSON.stringify(result));
            this.time = result.Start_Time__c;
            this.projName = result.Name.toUpperCase();
            console.log('this.projName-->'+this.projName);
            console.log('this.time-->'+this.time);
            if(this.time){
                this.massTime = this.formateTime(this.time);
            }
            console.log('this.massTime-->'+ this.massTime);
            console.log('this.projName--->'+this.projName);

        })
    }

    formateTime(data) {
        const milliseconds = data;
        const totalSeconds = milliseconds / 1000;
        const totalMinutes = totalSeconds / 60;
        const totalHours = totalMinutes / 60;

        const hours = Math.floor(totalHours);
        const minutes = Math.floor((totalHours % 1) * 60);
        const seconds = Math.floor((totalMinutes % 1) * 60);
        const ms = milliseconds % 1000;

        const formattedHours = hours.toString().padStart(2, '0');
        const formattedMinutes = minutes.toString().padStart(2, '0');
        const formattedSeconds = seconds.toString().padStart(2, '0');
        const formattedMilliseconds = ms.toString().padStart(3, '0');

        const formattedTime = `${formattedHours}:${formattedMinutes}:${formattedSeconds}.${formattedMilliseconds}Z`;
        return formattedTime;
    }

    get hasVisit1Column() {
        return this.projectAccounts.some(pa => pa.Project__r.Number_of_visits__c >= 1 || pa.Project__r.Number_of_visits__c == null);
    }

    get hasVisit2Column() {
        return this.projectAccounts.some(pa => pa.Project__r.Number_of_visits__c >= 2 || pa.Project__r.Number_of_visits__c == null);
    }

    get hasVisit3Column() {
        return this.projectAccounts.some(pa => pa.Project__r.Number_of_visits__c >= 3 || pa.Project__r.Number_of_visits__c == null);
    }

    getProjectAccounts(){
        var index = 0;
        this.showSpinner = true;
        getProjectAcc({ paList : this.selectedProjAccountList, orderBy: this.filter})
        .then((result) => {
            console.log('projectAcc-->'+ JSON.stringify(result));
            var keys = [];
            var values = [];;
            for (let key in result) {
                if (result.hasOwnProperty(key)) {
                    keys= JSON.parse(key);
                    values = JSON.parse(result[key]);
                }
            }
            console.log('Keys: ' + JSON.stringify(keys));
            console.log('Values: ' + JSON.stringify(values));
            this.databaseRecords = keys;
            this.projectAccounts =  values;
            if (this.projectAccounts.length > 0){
                this.projectAccountExists = true;
            }
            for(var res of this.databaseRecords){
                for (var account of this.projectAccounts) { 
                    if(res.Id != account.Id) continue;
                    account.schedule1 = true;
                    account.schedule2 = true;
                    account.schedule3 = true; 
                    if (res.Visit_1__c) {
                        account.hasVisit1 = true;
                        account.schedule1 = false;
                        account.visit1 = res.Visit_1__c;
                    } else {
                        account.hasVisit1 = false;
                        account.visitDate1 = null;
                        if(account.Start_Time__c != null) {
                            account.visitTime1 = account.Start_Time__c;
                        } else {
                            account.visitTime1 = this.massTime;
                        }
                        console.log('strat time2-->'+account.Start_Time__c);
                    }
                    if (res.Visit_2__c) {
                        account.hasVisit2 = true;
                        account.schedule2 = false;
                        account.visit2 = res.Visit_2__c;
                    } else {
                        account.hasVisit2 = false;
                        account.visitDate2 = null;
                        if(account.Start_Time__c != null) {
                            account.visitTime2 = account.Start_Time__c
                        } else {
                            account.visitTime2 = this.massTime;
                        }
                    }
                    if (res.Visit_3__c) {
                        account.hasVisit3 = true;
                        account.schedule3 = false;
                        account.visit3 = res.Visit_3__c;
                    } else {
                        account.hasVisit3 = false;
                        account.visitDate3 = null;
                        if(account.Start_Time__c != null) {
                            account.visitTime3 = account.Start_Time__c;
                        } else {
                            account.visitTime3 = this.massTime;
                        }
                    }
                account.serialNo = index + 1;
                index++;
                }
            }

            this.showSpinner = false;
        });

    }

    downloadCSVFile() {
        let rowEnd = '\n';
        let csvString = '';
        let headers = [
            { key: 'Id', label: 'Id' },
            { key: 'Account__r.Name', label: 'Name' },
            { key: 'Account__c', label: 'Account' },
            { key: 'Project__c', label: 'Project' },
            { key: 'Visit_1__c', label: 'Visit 1' },
            { key: 'Visit_2__c', label: 'Visit 2' },
            { key: 'Visit_3__c', label: 'Visit 3' },
            { key: 'Quantity_of_Devices__c', label: 'Quantity of Devices' },
            { key: 'Comments__c', label: 'Comments' },
            { key: 'Account__r.Metro_Area__c', label: 'Metro Area' },
            { key: 'ADDRESS', label: 'ADDRESS' },
            { key: 'Account__r.Timezone__c', label: 'Time Zone' },
            { key: 'Qty_Old_Devices__c', label: 'Qty Old Devices' },
            { key: 'Site_Status__c', label: 'Site Status' },
            { key: 'Dispatcher__c', label: 'Dispatcher' },
            { key: 'Start_Time__c', label: 'Start Time' },
            { key: 'Precall_Complete__c', label: 'Precall Complete' },
            { key: 'Precall_Contact_Name__c', label: 'Precall Contact Name' },
            { key: 'Precall_Notes__c', label: 'Precall Notes' }
        ];
    
        function flattenObject(obj, parent = '', res = {}) {
            for (let key in obj) {
                let propName = parent ? `${parent}.${key}` : key;
                if (typeof obj[key] === 'object' && obj[key] !== null) {
                    flattenObject(obj[key], propName, res);
                } else {
                    res[propName] = obj[key];
                }
            }
            return res;
        }
    
        let headerLabels = headers.map(header => header.label);
        csvString += headerLabels.join(',');
        csvString += rowEnd;
    
        getProjAccforDownload({ recordId: this.recordId })
        .then((result) => {
            console.log('result-->' + JSON.stringify(result));
            this.downlodProjAcc = result;

            this.downlodProjAcc.forEach(record => {
                let flattenedRecord = flattenObject(record);

                headers.forEach((header, index) => {
                    if (index > 0) {
                        csvString += ',';
                    }
                    let value;
                    if (header.key === 'ADDRESS') {
                        value = `${flattenedRecord['Account__r.ShippingStreet'] || ''} ${flattenedRecord['Account__r.ShippingCity'] || ''} ${flattenedRecord['Account__r.ShippingState'] || ''} ${flattenedRecord['Account__r.ShippingCountry'] || ''} ${flattenedRecord['Account__r.ShippingPostalCode'] || ''}`.trim();
                    } else {
                        value = flattenedRecord[header.key] === undefined ? '' : flattenedRecord[header.key];
                    }
                    if (header.key === 'Start_Time__c' && flattenedRecord[header.key]) {
                        let timeValue = flattenedRecord[header.key];
                        if (typeof timeValue !== 'string') {
                            timeValue = new Date(timeValue).toISOString().split('T')[1]; 
                        }
                        let [hours, minutes, seconds] = timeValue.split(':');
                        let hourInt = parseInt(hours);
                        let period = hourInt >= 12 ? 'PM' : 'AM';
                        hourInt = hourInt % 12 || 12;
                        value = `${hourInt}:${minutes} ${period}`;
                    }
                    csvString += '"' + value + '"';
                });
                csvString += rowEnd;
            });

            var name = 'Project_Accounts.csv';
            var downloadElement = document.createElement('a');
            downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvString);
            downloadElement.target = '_self';
            downloadElement.download = name;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement);
        })
        .catch(error => {
            console.error('Error fetching data for CSV download:', error);
        });
    }          
     

    @wire(getUserTimezone)
    wiredTimezone({ error, data }) {
        if (data) {
            this.userTimezone = data;
            console.log('this.userTimezone-->'+this.userTimezone);
        } else if (error) {
            console.error('Error fetching user timezone: ', error);
        }
    }

    handleMetroAreaSort(event) {
        var title =  event.currentTarget.title;
        var field = '';
        if(title == 'STORE') {
            field = 'ORDER BY Account__r.Name';
        } else  if(title == 'METRO AREA') {
            field = 'ORDER BY Account__r.Metro_Area__c';
        }
        if(this.sortDirection == 'ASC'){
            this.sortDirection = 'DESC';
        } else {
            this.sortDirection = 'ASC';
        }  
        this.filter = field + ' '+ this.sortDirection;
        if(title == 'STORE') {
            this.sortIconName1 = this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
            this.sortIconStrore = true;
            this.sortIconMetroArea = false;
        } else if(title == 'METRO AREA') {
            this.sortIconName2 = this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
            this.sortIconMetroArea = true;
            this.sortIconStrore = false;
        }
        this.getProjectAccounts();
    }
    

    handleEditVisit(event) {       
        var pjId = event.target.dataset.id;
        var title = event.currentTarget.title;
        console.log('title->'+title);
        console.log('time-->'+JSON.stringify(this.projectAccounts));
        for(let pa of this.projectAccounts){
            if(pjId != pa.Id) continue;
            if(title == 'Edit Visit 1'){
                this.Edit = true;
                pa.hasVisit1 = false;
                pa.schedule1 = false;
                pa.hasEditVisit1 = true;
                pa.visit1 = pa.Visit_1__c;
                console.log('pa.visit1 --'+pa.visit1 );
            }
            if(title == 'Edit Visit 2'){
                this.Edit = true;
                pa.hasVisit2 = false;
                pa.schedule2 = false;
                pa.hasEditVisit2 = true;
                pa.visit2 = pa.Visit_2__c;
            }
            if(title == 'Edit Visit 3'){
                this.Edit = true;
                pa.hasVisit3 = false;
                pa.schedule3 = false;
                pa.hasEditVisit3 = true;
                pa.visit3 = pa.Visit_3__c;
            }
            console.log('visit 1---'+pa.hasEditVisit1);
            console.log('visit 2---'+pa.hasEditVisit2);
            console.log('visit 3---'+pa.hasEditVisit3);
        }
    }

    populateDateTime(event) {
        const value = event.target.value;
        console.log('date time value-> ' + value);
        const paIndex = event.currentTarget.dataset.index;
        this.projectAccounts[paIndex].visit = value;
    }

    populateDate(event) {
        const projAccId = event.target.dataset.id;
        const title = event.currentTarget.title;
        const newValue = event.target.value;
        this.projectAccounts.forEach(projAcc => {
            if (projAcc.Id === projAccId && title == 'Edited Visit 1') {
                projAcc.visitDate1 = newValue;
                console.log('projAcc.visitDate1-> ' + projAcc.visitDate1);
            } else if(projAcc.Id === projAccId && title == 'Edited Visit 2'){
                projAcc.visitDate2 = newValue;
                console.log('projAcc.visitDate2-> ' + projAcc.visitDate2);
            } else if(projAcc.Id === projAccId && title == 'Edited Visit 3'){
                projAcc.visitDate3 = newValue;
                console.log('projAcc.visitDate3-> ' + projAcc.visitDate3);
            }
            return projAcc;
        });
    }

    populateTime(event) {
        debugger;
        const projAccId = event.target.dataset.id;
        const title = event.currentTarget.title;
        const newValue = event.target.value;
        this.projectAccounts.forEach(projAcc => {
            if (projAcc.Id === projAccId && title == 'Edited Visit 1') {
                projAcc.visitTime1 = newValue;
                console.log('projAcc.visitTime1-> ' + projAcc.visitTime1);
            } else if(projAcc.Id === projAccId && title == 'Edited Visit 2') {
                projAcc.visitTime2 = newValue;
                console.log('projAcc.visitTime1-> ' + projAcc.visitTime2);
            } else if(projAcc.Id === projAccId && title == 'Edited Visit 3') {
                projAcc.visitTime3 = newValue;
                console.log('projAcc.visitTime3-> ' + projAcc.visitTime3);
            }
            return projAcc;
        });
    }

    handleDateTimeChange(event){
        var pjId = event.target.dataset.id;
        var value = event.target.value;
        var title = event.currentTarget.title;
        console.log('value-->'+ value);
        console.log('pjId-->'+ pjId);
        for(let pa of this.projectAccounts){
            if(pjId != pa.Id) continue;
            if(title == 'Edited Visit 1'){
                pa.visit1 = value;
                console.log('pa.visit1-->'+pa.visit1);
            }
            if(title == 'Edited Visit 2'){
                pa.visit2 = value;
            }
            if(title == 'Edited Visit 3'){
                pa.visit3 = value;
            }
        }
    }

    combineDateTime(date, time) {
        if (!date && !time) return null;   
        const [year, month, day] = date.split('-');
        const [hours, minutes] = time.split(' ')[0].split(':');
        const formattedHours = hours.padStart(2, '0'); 
        const formattedMinutes = minutes.padStart(2, '0');     
        const dateTime = `${year}-${month}-${day}T${formattedHours}:${formattedMinutes}:00.000+0000`;
        return dateTime;
    }
    
    handleSave() {
        // this.showSpinner = true;
        var newDateTimeList = [];
        var updateDateTimeList = [];
        const data = new Map();
    
        for(var db of this.databaseRecords){
            var newVisit = false;
            var updateVist = false;
            var valueList = [];
            for (let pa of this.projectAccounts) {
                if(db.Id != pa.Id || (pa.hasEditVisit1 == false && pa.hasEditVisit2 == false && pa.hasEditVisit3 == false)) continue;
                if(pa.visitDate1 && pa.visitTime1){
                    pa.Visit_1__c = this.combineDateTime(pa.visitDate1, pa.visitTime1);
                    db.Visit_1__c = pa.Visit_1__c;
                    db.hasEditVisit1 = true;
                    newVisit = true;
                    valueList.push('Visit_1__c');
                } else if(pa.visit1 !=null){
                    db.Visit_1__c = pa.visit1;
                    db.hasEditVisit1 = true;
                    updateVist = true;
                } else {
                    db.Visit_1__c = null;
                }
                if(pa.visitDate2 && pa.visitTime2){
                    pa.Visit_2__c = this.combineDateTime(pa.visitDate2, pa.visitTime2);
                    db.Visit_2__c = pa.Visit_2__c;
                    db.hasEditVisit2 = true;
                    newVisit = true;
                    valueList.push('Visit_2__c');
                } else if (pa.visit2 !=null){
                    db.Visit_2__c = pa.visit2;
                    db.hasEditVisit2 = true;
                    updateVist = true;
                } else {
                    db.Visit_2__c = null;
                }
                if(pa.visitDate3 && pa.visitTime3){
                    pa.Visit_3__c = this.combineDateTime(pa.visitDate3, pa.visitTime3);
                    db.Visit_3__c = pa.Visit_3__c;
                    db.hasEditVisit3 = true;
                    newVisit = true;
                    valueList.push('Visit_3__c');
                } else if(pa.visit3 !=null){
                    db.Visit_3__c = pa.visit3;
                    db.hasEditVisit3 = true;
                    updateVist = true;
                } else {
                    db.Visit_3__c = null;
                }
            }
            if(newVisit){
                data.set(db.Id, valueList);
                newDateTimeList.push(db);
            }
            if(updateVist){
                data.set(db.Id, valueList);
                updateDateTimeList.push(db);
            }
        }
        const objData = {};
        data.forEach((value, key) => {
            objData[key] = value;
        });
        console.log('objData:', JSON.stringify(objData));

        if (this.databaseRecords.length > 0) {

            console.log('Sending to Apex:', JSON.stringify(this.databaseRecords));
            const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            let valid = true;
    
            for (let projAcc of this.databaseRecords) {
                if (projAcc.hasEditVisit1 || projAcc.hasEditVisit2 || projAcc.hasEditVisit3) {
                    console.log('entered---->');

                    if (projAcc.hasEditVisit2 && !projAcc.Visit_1__c) {
                        console.log('Visit 1 is required before adding Visit 2');
                        // this.showSpinner = false;
                        this.showErrorToastVisit2();
                        valid = false;
                        return;
                    }
    
                    if (projAcc.hasEditVisit3 && (!projAcc.Visit_1__c || !projAcc.Visit_2__c)) {
                        console.log('Visit 1 is required before adding Visit 3');
                        // this.showSpinner = false;
                        this.showErrorToastVisit3();
                        valid = false;
                        return;
                    }

                    if(projAcc.hasEditVisit1){
                        const visitDateParts = projAcc.Visit_1__c.split('-');
                        const year = parseInt(visitDateParts[0], 10);
                        const month = parseInt(visitDateParts[1], 10) - 1;
                        const day = parseInt(visitDateParts[2], 10);
        
                        const selectedDateObj = new Date(year, month, day);
                        console.log('selectedDateObj -->', selectedDateObj);
        
                        if (isNaN(selectedDateObj.getTime())) {
                            continue;
                        }
        
                        const selectedDayIndex = selectedDateObj.getDay();
                        const adjustedDayIndex = (selectedDayIndex + 6) % 7;
                        const selectedDay = daysOfWeek[adjustedDayIndex];
                        console.log('selectedDay1 -->', selectedDay);
        
                        this.applicableDays = projAcc.Project__r.Applicable_on_Days__c?.split(';') || [];
        
                        if (this.applicableDays.length > 0 && !this.applicableDays.includes(selectedDay)) {
                            console.log('Invalid day selected');
                            // this.showSpinner = false;
                            this.showErrorToast();
                            valid = false;
                            return;
                        }
                    }
                    if(projAcc.hasEditVisit2){
                        console.log('entered2');
                        const visitDateParts = projAcc.Visit_2__c.split('-');
                        const year = parseInt(visitDateParts[0], 10);
                        const month = parseInt(visitDateParts[1], 10) - 1;
                        const day = parseInt(visitDateParts[2], 10);
        
                        const selectedDateObj = new Date(year, month, day);
                        console.log('selectedDateObj -->', selectedDateObj);
        
                        if (isNaN(selectedDateObj.getTime())) {
                            continue;
                        }
        
                        const selectedDayIndex = selectedDateObj.getDay();
                        const adjustedDayIndex = (selectedDayIndex + 6) % 7;
                        const selectedDay = daysOfWeek[adjustedDayIndex];
                        console.log('selectedDay2 -->', selectedDay);
        
                        this.applicableDays = projAcc.Project__r.Applicable_on_Days__c?.split(';') || [];
        
                        if (this.applicableDays.length > 0 && !this.applicableDays.includes(selectedDay)) {
                            console.log('Invalid day selected');
                            // this.showSpinner = false;
                            this.showErrorToast();
                            valid = false;
                            return;
                        }
                    }
                    if(projAcc.hasEditVisit3){
                        const visitDateParts = projAcc.Visit_3__c.split('-');
                        const year = parseInt(visitDateParts[0], 10);
                        const month = parseInt(visitDateParts[1], 10) - 1;
                        const day = parseInt(visitDateParts[2], 10);
        
                        const selectedDateObj = new Date(year, month, day);
                        console.log('selectedDateObj -->', selectedDateObj);
        
                        if (isNaN(selectedDateObj.getTime())) {
                            continue;
                        }
        
                        const selectedDayIndex = selectedDateObj.getDay();
                        const adjustedDayIndex = (selectedDayIndex + 6) % 7;
                        const selectedDay = daysOfWeek[adjustedDayIndex];
                        console.log('selectedDay3 -->', selectedDay);
        
                        this.applicableDays = projAcc.Project__r.Applicable_on_Days__c?.split(';') || [];
        
                        if (this.applicableDays.length > 0 && !this.applicableDays.includes(selectedDay)) {
                            console.log('Invalid day selected');
                            // this.showSpinner = false;
                            this.showErrorToast();
                            valid = false;
                            return;
                        }
                    }
                    console.log('Project Account:', JSON.stringify(projAcc));
                }
                projAcc.hasEditVisit1 = false;
                projAcc.hasEditVisit2 = false;
                projAcc.hasEditVisit3 = false;
            }
            console.log('updateDateTimeList-->'+JSON.stringify(updateDateTimeList));
            if (valid) {
                updateProjectAccounts({ newDateTimeListStr: JSON.stringify(newDateTimeList), updateDateTimeListStr: JSON.stringify(updateDateTimeList), data: objData })
                    .then(result => {
                        console.log('Save successful 1');
                        this.Edit = false;
                        this.getProjectAccounts();
                        // this.showSpinner = false;
                        this.dispatchEvent(new CustomEvent('savecompleted', {
                            bubbles: true,
                            composed: true,
                        }));
                    })
                    .catch(error => {
                        console.error('Error saving modified accounts:', error);
                        // this.showSpinner = false;
                    });
            } else {
                this.showErrorToast();
            }
        } else {
            console.log('No modifications to save');
            // this.showSpinner = false;
        }
    }   

    handleCancel(){
        for(let pa of this.projectAccounts){
            pa.hasEditVisit1 = false;
            pa.hasEditVisit2 = false;
            pa.hasEditVisit3 = false;
        }
        this.Edit = false; 
        this.getProjectAccounts();
    }

    showErrorToast() {
        const toast = this.template.querySelector('.error-toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
        }, 3000);
    }

    get hasProjectAccounts() {
        return this.projectAccounts && this.projectAccounts.length > 0;
    }

    showErrorToastVisit2(){
        const toast = this.template.querySelector('.error-toast-message-Visit2');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
        }, 3000);
    }   
    
    showErrorToastVisit3(){
        const toast = this.template.querySelector('.error-toast-message-Visit3');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
        }, 3000);   
    }
    showErrorToastSelectedDate(){
        const toast = this.template.querySelector('.selected-date');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
        }, 2000);   
    }
}