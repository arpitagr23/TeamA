import { LightningElement, track, api } from 'lwc';
import img_avatar2 from '@salesforce/resourceUrl/img_avatar2'
import doCallout from '@salesforce/apex/ClientDataloaderServerSide.doCallout'
import getObjectList from '@salesforce/apex/ClientDataloaderServerSide.getObjectList'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fieldsList from '@salesforce/apex/ClientDataloaderServerSide.fieldsList'
import fieldsDML from '@salesforce/apex/ClientDataloaderServerSide.fieldsDML';

export default class ClientSideDataloader extends LightningElement {

    imgavatar2 = img_avatar2;
    accessToken; endpoint; sObject; fileDetails; fieldFromCSV; myMap; 
    finalQuery = '';
    listOfObjects = []; listOfFields = []; selectedFields = []; tableData = []; tableColumns = [];     mapData = []; mapColumns = []; mapTableData = [];
    isLoggedIn = false; isShowForm = true; isQuery = false; isShowFields = false; showQuery = false; isInsert = false;

    authlogin(event) {
        let username = this.template.querySelector('[data-id="uname"]').value;
        let password = this.template.querySelector('[data-id="psw"]').value;
        let sectoken = this.template.querySelector('[data-id="sectoken"]').value;
        this.endpoint = this.template.querySelector('[data-id="endpoint"]').value;

        doCallout({ username: username, password: password, sectoken: sectoken, endpoint: this.endpoint }).then((result) => {
            this.accessToken = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Authentication Success',
                    variant: 'success',
                }),
            );
            this.isLoggedIn = true;
            this.isShowForm = false;
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Authentication failure, Please check your details again',
                    variant: 'error',
                }),
            );
        })
    }

    makeQuery() {
        getObjectList({ accessToken: this.accessToken, endpoint: this.endpoint }).then((result) => {
            this.listOfObjects = result;
            this.isLoggedIn = false;
            this.isShowForm = false;
            this.isQuery = true;
            console.log(this.listOfObjects);
        }).catch(error => {
            console.log(error);
        })
    }

    selectObject(event) {
        this.sObject = event.target.value;
        console.log(this.sObject);
    }

    generateFields() {
        fieldsList({ accessToken: this.accessToken, endpoint: this.endpoint, objName: this.sObject }).then((result) => {
            this.listOfFields = result;
            this.isShowFields = true;
            console.log(result);
        }).catch(error => {
            console.log(error);
        })
    }

    selectFields(event) {
        this.selectedFields = Array.from(event.target.selectedOptions, option => option.value);

        let queryGen = 'SELECT Id, ';
        for (let i = 0; i < this.selectedFields.length; i++) {
            let fieldValue = this.selectedFields[i];
            queryGen += fieldValue + ' ,';
        }
        this.finalQuery = queryGen;
    }

    generateQuery() {
        this.showQuery = true;
        let queryFinal = this.finalQuery;
        queryFinal = queryFinal.slice(0, -1);
        queryFinal += 'FROM ' + this.sObject;
        queryFinal = queryFinal.toUpperCase();
        this.finalQuery = queryFinal;
        console.log(this.finalQuery);
    }


    insertRecords() {
        getObjectList({ accessToken: this.accessToken, endpoint: this.endpoint }).then((result) => {
            this.listOfObjects = result;
            this.isLoggedIn = false;
            this.isShowForm = false;
            this.isQuery = false;
            this.isInsert = true;
            console.log(this.listOfObjects);
        }).catch(error => {
            console.log(error);
        })
    }

    handleFileSelect(event) {
        const file = event.target.files[0];

        if (file) {
            const reader = new FileReader();

            reader.onload = () => {
                const fileContents = reader.result;

                const rows = fileContents.split('\n').map(row => row.trim());
                const headers = rows[0].trim().split(',');
                this.fieldFromCSV = headers;

                let data = rows.slice(1).filter(row => row !== ''); // remove empty rows

                // check if first row is empty and remove it
                if (data.length > 0 && data[0].split(',').every(val => val === '')) {
                    data = data.slice(1);
                }

                // check if last row is empty and remove it
                if (data.length > 0 && data[data.length - 1].split(',').every(val => val === '')) {
                    data = data.slice(0, -1);
                }

                data = data.map(row => {
                    const values = row.split(',');
                    return headers.reduce((obj, header, i) => {
                        obj[header] = values[i];
                        return obj;
                    }, {});
                });

                this.fileContents = data;
                this.fileDetails = this.fileContents;
            };
            reader.readAsText(file);
        }
    }

    parseCSV() {
        fieldsDML({ accessToken: this.accessToken, endpoint: this.endpoint, objName: this.sObject })
            .then((result) => {
                this.myMap = result;
                this.mapColumns = [];
                this.mapData = [];
                let jsMap = {};
                for (let key of Object.keys(this.myMap)) {
                    jsMap[key] = this.myMap[key];
                    this.mapColumns.push(key);
                    this.mapData.push(jsMap[key]);
                }
               
                console.log(JSON.stringify(this.mapColumns));
                console.log(JSON.stringify(this.mapData));
            })
            .catch((error) => {
                console.error(error);
            });
    }

    connectedCallback() {
        this.generateTableData();
    }

    generateTableData() {
        for (let i = 0; i < this.mapData.length; i++) {
            let row = [];
            for (let j = 0; j < this.mapColumns.length; j++) {
                let value = this.mapData[i][j];
                row.push(value);
            }
            this.mapTableData.push(row);
        }
    }
}