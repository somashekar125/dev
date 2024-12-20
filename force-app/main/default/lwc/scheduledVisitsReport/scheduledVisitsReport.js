import { LightningElement, api, track } from 'lwc';
import getVisitData from '@salesforce/apex/SchedulingMap.getVisitData';
import getAccountData from '@salesforce/apex/SchedulingMap.getAccountData';
import getProjAccVisitsData from '@salesforce/apex/SchedulingMap.getProjAccVisitsData';

export default class ScheduledVisitsReport extends LightningElement {
    @api recordId;
    @track storePerTimezone = [];
    @track visitDateTableData = [];
    @track metroAreaTableData = [];
    @track selectedDate;
    @track weekNum = null;
    @track tableData = [];
    @track projectAccounts = [];
    @track todayCount = null;
    @track metroArea = true;
    @track showForSelectedDate = false;

    connectedCallback() {
        console.log('ScheduledVisitsReport connectedCallback');
        this.setVisitData();
        this.setAccountData();
        this.getProjAccData();
    }

    handleChange(event) {
        this.selectedDate = event.target.value;
        this.weekNum = null;
        this.setVisitData();
        this.setAccountData();
        this.getProjAccData();
        this.handleButtonClick();
    }

    handleWeekChange(event) {
        this.weekNum = event.target.value;
        console.log('this.weekNum-> ' + this.weekNum);
        this.selectedDate = null;
        this.setVisitData();
        this.setAccountData();
        this.getProjAccData();
        this.handleButtonClick();
    }

    handleButtonClick() {
        this.dispatchEvent(new CustomEvent(
            'getdata', {
                detail: { selectedDate: this.selectedDate,showForSelectedDate: this.showForSelectedDate, weekNum: this.weekNum},
                bubbles: true,
                composed: true,
            }
        ));
    } 

    showAllRecords() {
        this.selectedDate = null;
        this.weekNum = null;
        this.setVisitData();
        this.setAccountData();
        this.getProjAccData();
        this.handleButtonClick();
    }

    setVisitData() {
        console.log('this.weekNum--->'+this.weekNum);
        if(this.weekNum == null || this.weekNum == '') this.weekNum = 0;
        getVisitData({ selectedDate: this.selectedDate, recordId: this.recordId, weekNum: this.weekNum})
        .then(result => {
            if(this.weekNum == 0) this.weekNum = null;
            console.log('visit data-> ' + result);
        })
        .catch(error => {
            console.error('Error fetching visit data:', error);
        });
    }

    setAccountData() {
        if(this.weekNum == null || this.weekNum == '') this.weekNum = 0;
        getAccountData({ selectedDate: this.selectedDate, recordId: this.recordId, weekNum: this.weekNum})
        .then(result => {
            console.log('getAccountData-> ' + result);
            if(this.weekNum == 0) this.weekNum = null;
            this.storePerTimezone = Object.keys(result).map(key => ({
                name: key,
                y: result[key]
            }));
        })
        .catch(error => {
            console.error('Error fetching account data:', error);
        });
    }

    getProjAccData() {
        const today = new Date().toISOString().split('T')[0];
        const selectedDate = this.selectedDate || today;
        if(this.weekNum == null || this.weekNum == '') this.weekNum = 0;
        getProjAccVisitsData({ selectedDate: this.selectedDate, recordId: this.recordId, weekNum: this.weekNum})
            .then(result => {
                if(this.weekNum == 0) this.weekNum = null;
                console.log('metroarea-->' + JSON.stringify(result));
                const visitCounts = {};
                let grandTotal = { Visit_1: 0, Visit_2: 0, Visit_3: 0 };
                let metroArea = '';
    
                const visitDateTableData = [];
                const metroAreaTableData = [];
                const metroAreaVisits = {};
    
                result.forEach(pa => {
                    metroArea = pa.Account__r.Metro_Area__c;
    
                    const visitDate1 = this.dateSplit(pa.Visit_1__c);
                    if (visitDate1) {
                        if (!visitCounts[visitDate1]) {
                            visitCounts[visitDate1] = { Visit_1: 0, Visit_2: 0, Visit_3: 0 };
                        }
                        visitCounts[visitDate1].Visit_1 += 1;
                        grandTotal.Visit_1 += visitDate1 === selectedDate ? 1 : 0;
                    }
    
                    const visitDate2 = this.dateSplit(pa.Visit_2__c);
                    if (visitDate2) {
                        if (!visitCounts[visitDate2]) {
                            visitCounts[visitDate2] = { Visit_1: 0, Visit_2: 0, Visit_3: 0 };
                        }
                        visitCounts[visitDate2].Visit_2 += 1;
                        grandTotal.Visit_2 += visitDate2 === selectedDate ? 1 : 0;
                    }
    
                    const visitDate3 = this.dateSplit(pa.Visit_3__c);
                    if (visitDate3) {
                        if (!visitCounts[visitDate3]) {
                            visitCounts[visitDate3] = { Visit_1: 0, Visit_2: 0, Visit_3: 0 };
                        }
                        visitCounts[visitDate3].Visit_3 += 1;
                        grandTotal.Visit_3 += visitDate3 === selectedDate ? 1 : 0;
                    }
    
                    if (!metroAreaVisits[metroArea]) {
                        metroAreaVisits[metroArea] = { Visit_1: 0, Visit_2: 0, Visit_3: 0 };
                    }
                    metroAreaVisits[metroArea].Visit_1 += visitDate1 ? 1 : 0;
                    metroAreaVisits[metroArea].Visit_2 += visitDate2 ? 1 : 0;
                    metroAreaVisits[metroArea].Visit_3 += visitDate3 ? 1 : 0;
                });
    
                console.log('metroAreaVisits1:', JSON.stringify(metroAreaVisits));
                console.log('this.todayCount:'+this.todayCount);
    
                if (typeof this.todayCount === 'undefined' || this.todayCount === null) {
                    let todayCount = 0;
                    Object.keys(visitCounts).forEach(date => {
                        todayCount += date === today ?
                            (visitCounts[date].Visit_1 + visitCounts[date].Visit_2 + visitCounts[date].Visit_3) : 0;
                    });
                    console.log('this.todayCount-->'+this.todayCount);
                    this.todayCount = todayCount;
                }
    
                if (this.selectedDate) {
                    if (grandTotal.Visit_1 > 0 || grandTotal.Visit_2 > 0 || grandTotal.Visit_3 > 0) {
                        visitDateTableData.push({
                            id: 1,
                            column1: selectedDate,
                            column2: grandTotal.Visit_1,
                            column3: grandTotal.Visit_2,
                            column4: grandTotal.Visit_3,
                            column5: grandTotal.Visit_1 + grandTotal.Visit_2 + grandTotal.Visit_3
                        });
                    }
                } else {
                    Object.keys(visitCounts).forEach((date, index) => {
                        const totalVisits = visitCounts[date].Visit_1 + visitCounts[date].Visit_2 + visitCounts[date].Visit_3;
                        visitDateTableData.push({
                            id: index + 1,
                            column1: date,
                            column2: visitCounts[date].Visit_1,
                            column3: visitCounts[date].Visit_2,
                            column4: visitCounts[date].Visit_3,
                            column5: totalVisits
                        });
                    });
                }
    
                Object.keys(metroAreaVisits).forEach((area, index) => {
                    const totalVisits = metroAreaVisits[area].Visit_1 + metroAreaVisits[area].Visit_2 + metroAreaVisits[area].Visit_3;
                    if (totalVisits > 0) {
                        metroAreaTableData.push({
                            id: index + 1,
                            column1: area,
                            column2: metroAreaVisits[area].Visit_1,
                            column3: metroAreaVisits[area].Visit_2,
                            column4: metroAreaVisits[area].Visit_3,
                            column5: totalVisits
                        });
                    }
                });
    
                if (metroAreaTableData.length > 0) {
                    metroAreaTableData.sort((a, b) => {
                        // First, sort by column5 (totals) in descending order
                        const totalComparison = b.column5 - a.column5;
                        if (totalComparison !== 0) {
                            return totalComparison;
                        }
                        // If totals are the same, sort by column1 (metro area) in ascending order
                        return a.column1.localeCompare(b.column1);
                    });
                }

                if (visitDateTableData.length > 0) {
                    visitDateTableData.sort((a, b) => new Date(b.column1) - new Date(a.column1));
                }
                
    
                this.visitDateTableData = visitDateTableData;
                this.metroAreaTableData = metroAreaTableData;


            console.log('Sorted metroAreaTableData:', metroAreaTableData);
            console.log('Sorted visitDateTableData:', visitDateTableData);
            })
            .catch(error => {
                console.error('Error fetching project visits data:', error);
            });
    }  
    
    dateSplit(data) {
        if (data) {
            const dateOnly = data.split('T')[0];
            return dateOnly;
        }
        return null;
    }

}