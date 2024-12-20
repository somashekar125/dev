import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import HIGHSTOCK from '@salesforce/resourceUrl/Highstock';
import getVisitData from '@salesforce/apex/SchedulingMap.getVisitData';
import getAccountData from '@salesforce/apex/SchedulingMap.getAccountData';

export default class ScheduledVisitsReport extends LightningElement {
    chart;
    highchartsInitialized = false;
    @api recordId;
    @track chartData = [];
    selectedDate = new Date().toISOString().slice(0,10);
    @track isLoading = true;

    connectedCallback() {
        this.loadHighcharts()
        .then(() => {
            this.setVisitData();
            this.setAccountData();
        })
        .catch(error => {
            console.error('Error loading Highcharts:', error);
            this.isLoading = false;
        });
    }

    handleChange(event) {
        this.selectedDate = event.target.value;
        this.setVisitData();
        this.setAccountData();
    }

    showAllRecords() {
        this.selectedDate = null;
        this.setVisitData();
        this.setAccountData();
    }

    loadHighcharts() {
        return loadScript(this, HIGHSTOCK)
            .then(() => {
                this.highchartsInitialized = true;
            })
            .catch(error => {
                console.error('Error loading Highcharts:', error);
                throw error;
            });
    }

    setVisitData() {
        this.isLoading = true;
        getVisitData({ selectedDate: this.selectedDate, recordId: this.recordId })
        .then(result => {
            this.initializeBarChart(result);
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching visit data:', error);
            this.isLoading = false;
        });
    }

    setAccountData() {
        this.isLoading = true;
        getAccountData({ selectedDate: this.selectedDate, recordId: this.recordId })
        .then(result => {
            this.chartData = Object.keys(result).map(key => ({
                name: key,
                y: result[key]
            }));
            this.createPieChart();
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching account data:', error);
            this.isLoading = false;
        });
    }

    initializeBarChart(data) {
        const categories = Object.keys(data);
        const visit1Data = [];
        const visit2Data = [];
        const visit3Data = [];
        const colors = ['#7cb5ec', '#434348', '#90ed7d'];

        categories.forEach(metroArea => {
            visit1Data.push(data[metroArea].Visit_1__c || 0);
            visit2Data.push(data[metroArea].Visit_2__c || 0);
            visit3Data.push(data[metroArea].Visit_3__c || 0);
        });

        const container = this.template.querySelector('.chart-container');
        this.chart = Highcharts.chart(container, {
            chart: {
                type: 'bar'
            },
            title: {
                text: 'VISITS PER METROPOLITAN AREA',
                align: 'left'
            },
            xAxis: {
                categories: categories,
                title: {
                    text: 'Metropolitan Areas'
                },
                min: 0,
                max: 4,
                scrollbar: {
                    enabled: true
                },
                gridLineWidth: 1,
                lineWidth: 0
            },
            yAxis: {
                min: 0,
                max: 5,
                title: {
                    text: 'Store Visits'
                },
                labels: {
                    overflow: 'justify'
                },
                gridLineWidth: 0
            },
            tooltip: {
                valueSuffix: ' visits'
            },
            plotOptions: {
                bar: {
                    borderRadius: 5,
                    dataLabels: {
                        enabled: true,
                        inside: false
                    },
                    groupPadding: 0.05,
                    pointPadding: 0.1
                },
                series: {
                    stacking: null
                }
            },
            legend: {
                layout: 'vertical',
                align: 'right',
                verticalAlign: 'top',
                x: -40,
                y: 80,
                floating: true,
                borderWidth: 1,
                backgroundColor: Highcharts.defaultOptions.legend.backgroundColor || '#FFFFFF',
                shadow: true
            },
            credits: {
                enabled: false
            },
            series: [
                {
                    name: 'Visit 1',
                    data: visit1Data,
                    color: colors[0]
                },
                {
                    name: 'Visit 2',
                    data: visit2Data,
                    color: colors[1]
                },
                {
                    name: 'Visit 3',
                    data: visit3Data,
                    color: colors[2]
                }
            ]
        });
    }

    createPieChart() {
        const container = this.template.querySelector('.pie-chart-container');
        if (!container) {
            console.error('Pie chart container not found');
            return;
        }

        Highcharts.chart(container, {
            chart: {
                type: 'pie'
            },
            title: {
                text: 'PROJECT ACCOUNTS PER TIMEZONE'
            },
            tooltip: {
                valueSuffix: '.'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        format: '{point.name}: {point.y}',
                        distance: -30,
                        style: {
                            color: 'white',
                            textOutline: 'none'
                        }
                    },
                    showInLegend: true
                }
            },
            series: [
                {
                    name: 'Number of Accounts',
                    colorByPoint: true,
                    data: this.chartData
                }
            ]
        });
    }
}