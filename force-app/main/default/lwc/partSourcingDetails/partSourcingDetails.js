import { LightningElement, api, track, wire } from 'lwc';
import getSourceDetails from '@salesforce/apex/PartSourcingDetailController.getPartSourcingDetails';
import VAN_LOGO from "@salesforce/resourceUrl/van";
import LOCKER_LOGO from "@salesforce/resourceUrl/locker";
import WAREHOUSE_LOGO from "@salesforce/resourceUrl/warehouse";

export default class PartSourcingDetails extends LightningElement {
    @api recordId;
    @track woliList;
    @track woLen;
    vanLogoUrl = VAN_LOGO;
    lockerLogoUrl = LOCKER_LOGO;
    whLogoUrl = WAREHOUSE_LOGO;

    @wire(getSourceDetails,{ saId : '$recordId'})
    processPartSourcing({data,error}) {
        if(data){
            var jsonStr = JSON.stringify(data);
            this.woliList = JSON.parse(jsonStr);
            //alert(JSON.stringify(this.woliList));
            for(var woli of this.woliList) {
                woli.vanQty = 0;
                woli.siteQty = 0;
                woli.warehouseQty = 0;
                for(var prli of woli.ProductRequestLineItems) {
                    if(prli.SourceLocation.LocationType == 'Van') {
                        if(prli.QuantityRequested < 10) {
                            woli.vanQty = '0'+prli.QuantityRequested;
                        } else {
                            woli.vanQty = prli.QuantityRequested;
                        }
                    }
                    if(prli.SourceLocation.LocationType == 'Site') {
                        if(prli.QuantityRequested < 10) {
                            woli.siteQty = '0'+prli.QuantityRequested;
                        } else {
                            woli.siteQty = prli.QuantityRequested;
                        }
                        
                    }
                    if(prli.SourceLocation.LocationType == 'Warehouse') {
                        if(prli.QuantityRequested < 10) {
                            woli.warehouseQty = '0'+prli.QuantityRequested;
                        } else {
                            woli.warehouseQty = prli.QuantityRequested;
                        }
                    }
                }
            }
            //alert(JSON.stringify(this.woliList));
            this.woLen = this.woliList.length;
        }if(error){
            alert(JSON.stringify(error));
        }
    }
}