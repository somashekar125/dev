import { LightningElement, api, track } from 'lwc';
import getSelectedList from '@salesforce/apex/SchedulingVisits.getSelectedList';
import SchedulingVisit from '@salesforce/apex/SchedulingVisits.SchedulingVisit';
import getProjectRecord from '@salesforce/apex/SchedulingVisits.getProjectRecord';

export default class SchedulingVisits extends LightningElement {
    @api selectedProjAccList;
    @track projectRec = {};
    @track projAccList = [];
    @api visit;
    @track projName;
    @api recordId;
    @track showSpinner = false;
    @track applicableDays;
    @track showConfirmationPopUp = false;
    @track showUnschedulePopUp = false;
    @track massDate = null;
    @track massTime = null;
    @track showBelowBottomScheduling = false;
    @track sortDirection = 'ASC';
    @track sortIconName1;
    @track sortIconName2;
    @track sortIconAccount = false;
    @track sortIconMetroArea = false;
    @track filter = 'ORDER BY Account__r.Name';

    connectedCallback() {
        console.log('connectedCallback 1');

        this.getProjects();
        this.getSelectedProjAccs();
    }

    getProjects() {
        this.showSpinner = true;
        const parts = this.visit.split(' ');
        const visitNumber = parts[1]; 
        getProjectRecord({recordId: this.recordId})
        .then((result) => {
            this.projectRec = result;
            console.log('this.projectRec -->' +JSON.stringify(this.projectRec));
            this.projName = this.projectRec.Name;
            this.applicableDays = this.projectRec.Applicable_on_Days__c?.split(';') || [];
            this.projectRec.hasDefaultTime = (this.projectRec.Start_Time__c != null) ? true : false;
            if(this.projectRec.Start_Time__c != null){
                this.massTime = this.formatTime(this.projectRec.Start_Time__c);
            }
            console.log('this.massTime -->' +this.massTime);
            if(visitNumber > this.projectRec.Number_of_visits__c){
                this.showVisitErrorToast();
                setTimeout(() => {
                    window.history.back();
                    this.showSpinner = false;
                }, 1500);
            }
        })
    }

    formatTime(data){
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

    getSelectedProjAccs() {
        this.showSpinner = true;
        const projAccIds = this.selectedProjAccList.map(projAcc => projAcc.Id);
        getSelectedList({ projAccList: projAccIds, recordId: this.recordId, visit: this.visit, orderBy: this.filter})
        .then((result) => {
            if(result == null) {
                this.projectAccountShowErrorToast();
            }
            if(result.length > 50) this.showBelowBottomScheduling = true;
            this.projAccList = result || [];
            console.log('result-->'+JSON.stringify(result));
            if(this.visit == 'VISIT 2') {
                var checkVisit1 = this.projAccList.some(item => item.Visit_1__c);
                if(checkVisit1 == false) {
                    this.showErrorToastVisit2();
                    setTimeout(() => {
                        window.history.back();
                    }, 2000);
                }
            }
            if(this.visit == 'VISIT 3') {
                var checkVisit2 = this.projAccList.some(item => item.Visit_2__c);
                if(checkVisit2 == false) {
                    this.showErrorToastVisit3();
                    setTimeout(() => {
                        window.history.back();
                    }, 2000);
                }
            }

            this.projAccList.forEach((projAcc, index) => {
                if (this.visit === 'VISIT 1') {
                    if (projAcc.Visit_1__c) {
                        projAcc.dateValueAvailable = true;
                        projAcc.visit = projAcc.Visit_1__c;
                    } else if(projAcc.Start_Time__c){
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.formatTime(projAcc.Start_Time__c);
                        projAcc.dateValueAvailable = false;
                    }  else if(projAcc.Project__r.Start_Time__c){
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.massTime;
                        projAcc.dateValueAvailable = false;
                     } else {
                        projAcc.dateValueAvailable = true;
                    }
                } else if (this.visit === 'VISIT 2') {
                    if (projAcc.Visit_2__c) {
                        projAcc.dateValueAvailable = true;
                        projAcc.visit = projAcc.Visit_2__c;
                    }else if (projAcc.Start_Time__c) {
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.formatTime(projAcc.Start_Time__c);
                        projAcc.dateValueAvailable = false;
                    } else if(projAcc.Project__r.Start_Time__c) {
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.massTime;
                        projAcc.dateValueAvailable = false;
                    } else {
                        projAcc.dateValueAvailable = true;
                    }
                } else if (this.visit === 'VISIT 3') {
                    if (projAcc.Visit_3__c) {
                        projAcc.dateValueAvailable = true;
                        projAcc.visit = projAcc.Visit_3__c;
                    }else if (projAcc.Start_Time__c) {
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.formatTime(projAcc.Start_Time__c);
                        projAcc.dateValueAvailable = false;
                    } else if(projAcc.Project__r.Start_Time__c){
                        projAcc.visitDate = null;
                        projAcc.visitTime = this.massTime;
                        projAcc.dateValueAvailable = false;
                    } else {
                        projAcc.dateValueAvailable = true;
                    }
                }
                projAcc.itemSerialNo = index + 1;
            });                                               

            this.showSpinner = false;
        })
        .catch((error) => {
            console.error('Error retrieving project accounts list:', error);
            this.showSpinner = false;
        });
    }

    handleMetroAreaSort(event) {
        var title =  event.currentTarget.title;
        var field = '';
        if(title == 'ACCOUNTS') {
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
        if(title == 'ACCOUNTS') {
            this.sortIconName1 = this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
            this.sortIconAccount = true;
            this.sortIconMetroArea = false;
        } else if (title == 'METRO AREA'){
            this.sortIconName2 = this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
            this.sortIconMetroArea = true;
            this.sortIconAccount = false;
        }
        this.getSelectedProjAccs();
    }

    handleChangeDate(event) {
        const value = event.target.value;
        console.log('date-->'+value);
        this.massDate = value;
        this.projAccList.forEach(projAcc => {
            projAcc.visitDate = value;
            projAcc.dateValueAvailable = false;
            if(projAcc.Start_Time__c != null) {
                projAcc.visitTime = this.formatTime(projAcc.Start_Time__c);
            } else {
                if (this.massTime != null)  projAcc.visitTime = this.massTime;
            }
        });
    }

    handleChangeTime(event) {
        const value = event.target.value;
        this.massTime = value;
        console.log('time-->'+value);
        this.projAccList.forEach(projAcc => {
            projAcc.visitTime = value;
        });
    }

    handleChangeDateTime(event) {
        const value = event.target.value;
        this.projAccList.forEach(projAcc => {
            projAcc.visit = value;
        });
    }

    populateDateTime(event) {
        const value = event.target.value;
        console.log('date time value-> ' + value);
        const paIndex = event.currentTarget.dataset.index;
        this.projAccList[paIndex].visit = value;
    }

    populateDate(event) {
        const projAccId = event.target.dataset.id;
        const newValue = event.target.value;
        console.log('date value-> ' + newValue);
        this.projAccList.forEach(projAcc => {
            if (projAcc.Id === projAccId) {
                projAcc.visitDate = newValue;
            }
            return projAcc;
        });
    }
    
    populateTime(event) {
        const projAccId = event.target.dataset.id;
        const newValue = event.target.value;
        console.log('time value-> ' + newValue);
        this.projAccList.forEach(projAcc => {
            if (projAcc.Id === projAccId) {
                projAcc.visitTime = newValue;
            }
            return projAcc;
        });
    }        

    handleClick(event) {
        this.showSpinner = true;
        let valid = true;
        let missingDateTime = true;
        var newDateTimeList = [];
        var updateDateTimeList = [];
        for (let i = 0; i < this.projAccList.length; i++) {
            let projAcc = this.projAccList[i];
            console.log('projAcc.visitDate-->'+projAcc.visitDate);
            console.log('projAcc.visitTime-->'+projAcc.visitTime);
            console.log('projAcc.visit-->'+projAcc.visit);
            if((projAcc.visitDate && projAcc.visitTime) || projAcc.visit) missingDateTime = false;
            if(missingDateTime) break;
            valid = this.selectedDateValidity(projAcc);
            if(!valid) break;
            if (this.visit === 'VISIT 1' ) {
                if(projAcc.visitDate && projAcc.visitTime){
                    projAcc.Visit_1__c = this.combineDateTime(projAcc.visitDate, projAcc.visitTime);
                    newDateTimeList.push(projAcc);
                } else if(projAcc.visit != null) {
                    projAcc.Visit_1__c = projAcc.visit;
                    updateDateTimeList.push(projAcc);
                }
            } else if (this.visit === 'VISIT 2') {
                if(projAcc.visitDate && projAcc.visitTime){
                    projAcc.Visit_2__c = this.combineDateTime(projAcc.visitDate, projAcc.visitTime);
                    newDateTimeList.push(projAcc);
                } else if(projAcc.visit != null) {
                    projAcc.Visit_2__c = projAcc.visit;
                    updateDateTimeList.push(projAcc);
                }
            } else if (this.visit === 'VISIT 3') {
                if(projAcc.visitDate && projAcc.visitTime){
                    projAcc.Visit_3__c = this.combineDateTime(projAcc.visitDate, projAcc.visitTime);
                    newDateTimeList.push(projAcc);
                } else if(projAcc.visit != null) {
                    projAcc.Visit_3__c = projAcc.visit;
                    updateDateTimeList.push(projAcc);
                }
            }
            console.log('Final Project Account: ' + JSON.stringify(projAcc));
        }
        if (!valid) return;
        if(missingDateTime) {
            this.showConfirmationPopUp = false;
            this.showTimeToast();
            return;
        }

        SchedulingVisit({ newDateTimeListStr: JSON.stringify(newDateTimeList), updateDateTimeListStr: JSON.stringify(updateDateTimeList), visit: this.visit })
        .then(() => {
            this.showToast();
            this.showConfirmationPopUp = false;
            this.showSpinner = false;
            this.getProjects();
            this.getSelectedProjAccs();
        })
        .catch((error) => {
            console.error('Error scheduling visits:', error);
            this.showSpinner = false;
        });
    }

    unscheduleHandleClick(){
        this.showSpinner = true;
        this.projAccList.forEach(projAcc => {
            if (this.visit === 'VISIT 1') {
                projAcc.Visit_1__c = null;
            } else if (this.visit === 'VISIT 2') {
                projAcc.Visit_2__c = null;
            } else if (this.visit === 'VISIT 3') {
                projAcc.Visit_3__c = null;
            }
            projAcc.visit = null; 
        });
        SchedulingVisit({ newDateTimeListStr: null, updateDateTimeListStr: JSON.stringify(this.projAccList), visit: this.visit })
        .then(() => {
            this.showRestToast();
            this.showUnschedulePopUp = false;
            this.getProjects();
            this.getSelectedProjAccs();
        })
        .catch((error) => {
            console.error('SchedulingVisit Error:', error);
            this.showSpinner = false;
            console.error(error);
        });
    }

    selectedDateValidity(projAcc) {
        const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        var selectedDay = null;
        if (projAcc.visitDate != null || projAcc.visit != null) {
            var visitDateParts;
            if(projAcc.visitDate != null) visitDateParts = projAcc.visitDate.split('-');
            if(projAcc.visit != null) {
                const dateTimeParts = projAcc.visit.split('T');
                visitDateParts = dateTimeParts[0].split('-');
            }
            const year = parseInt(visitDateParts[0], 10);
            const month = parseInt(visitDateParts[1], 10) - 1;
            const day = parseInt(visitDateParts[2], 10);
            const selectedDateObj = new Date(year, month, day);
            const selectedDayIndex = selectedDateObj.getDay();
            const adjustedDayIndex = (selectedDayIndex - 1 + 7) % 7; 
            selectedDay = daysOfWeek[adjustedDayIndex];
            console.log('selectedDay-->'+selectedDay);
        }
        if(selectedDay && this.applicableDays.length > 0) {
            console.log('this.applicableDays-->'+this.applicableDays);
            if (!this.applicableDays.includes(selectedDay)) {
                this.showSpinner = false;
                this.showConfirmationPopUp = false;
                this.showErrorToast();
                return false;
            }
        }
        return true;
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
    

    refreshLists(event) {
        this.getProjects();
        this.getSelectedProjAccs();
    }

    onRemovingSelected(event) {
        const recordId = event.currentTarget.dataset.id;
        this.projAccList = this.projAccList.filter(projAcc => projAcc.Id !== recordId);
        this.projAccList.forEach((item, index) => {
            item.itemSerialNo = index + 1;
        });
    }

    closeConfirmationPopup(event){
        this.showConfirmationPopUp = false;
        this.showUnschedulePopUp = false;
    }

    openConfirmationPopUp(event){
        this.showConfirmationPopUp = true;
    }

    openUnscheduleConfirmationPopUp(event){
        this.showUnschedulePopUp = true;
    }

    closeModal(){
        this.showConfirmationPopUp = false;
        this.showUnschedulePopUp = false;
    }

    showToast() {
        const toast = this.template.querySelector('.toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);
    }

    showRestToast() {
        const toast = this.template.querySelector('.toast-message-reset');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);
    }

    showErrorToast() {
        const toast = this.template.querySelector('.error-toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);
    }

    showVisitErrorToast() {
        const toast = this.template.querySelector('.visit-toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);
    }

    showErrorToastVisit2(){
        const toast = this.template.querySelector('.error-toast-message-Visit2');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);
    }   
    
    showErrorToastVisit3(){
        const toast = this.template.querySelector('.error-toast-message-Visit3');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);   
    }  
    
    showTimeToast(){
        const toast = this.template.querySelector('.time-toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
        }, 3000);   
    }

    projectAccountShowErrorToast(){
        const toast = this.template.querySelector('.projectAccount-toast-message');
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            this.showSpinner = false;
            window.history.back();
        }, 2000);   
    }

    handleBackClick() {
        window.history.back();
    }
}