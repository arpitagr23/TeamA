public with sharing class ClientDataloaderServerSide {

    public class CommonException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static String doCallout(String username, String password, String sectoken, String endpoint){
        System.debug(username);
        System.debug(password);
        System.debug(sectoken);
        System.debug(endpoint);
        String clientId = '3MVG9n_HvETGhr3BaZc_TRK3XLOHPFpBL9SbFFI0CmCIv2N4eBC0ab5JUCVWI_JyAfUKT1bRMtnyGCg.Rmc0R';
        String clientSecret = '08F83F4F5B169A0F794FC270F7E66D6C6A3786FCBE2BF1E1B09BFD067893A882';
        String responseString;
        String acc;
        HttpRequest request = new HttpRequest();
        request.setMethod('POST'); 
        request.setBody(
            'grant_type=password'+
            '&client_id='+clientId+
            '&client_secret='+clientSecret+
            '&username='+username+
            '&password='+password+sectoken+
            '&Content-Type=application/json'
        );
        request.setEndpoint(endpoint+'services/oauth2/token');
        Http http = new Http();
        HttpResponse response = http.send(request);
        responseString = response.getBody();
        System.debug(response.getStatusCode());
        System.debug(responseString);
        if(response.getStatusCode()==200){
            Map<String, Object> authResult = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            acc = (String)authResult.get('access_token');
            String instanceUrl = (String)authResult.get('instance_url');
            instanceUrl = instanceUrl + '/';
            if(!instanceUrl.equalsIgnoreCase(endpoint)){
                throw new CommonException('Endpoint does not match with the credentials');
            }
        }
        else{
            throw new CommonException('Authentication Failure, Please Check Your Login Details');
        }
        return acc;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getObjectList(String accessToken, String endpoint){
        String endpointUrl = endpoint+'services/data/v56.0/sobjects/';
        HttpRequest getRequest = new HttpRequest();
        getRequest.setHeader('Content-Type', 'application/json');
        getRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        getRequest.setMethod('GET');
        getRequest.setEndpoint(endpointUrl);

        Http Send = new Http();
        HttpResponse initialResponse = new HttpResponse();
        initialResponse = Send.send(getRequest);
        Map<String,Object> getInfo = (Map<String,Object>)Json.deserializeUntyped(initialResponse.getBody());
        List<Object> objInfo = (List<Object>)getInfo.get('sobjects');
        List<String> objNames = new List<String>();
        for(integer i = 0; i < objInfo.size() ; i++) {
            Map<String,Object> objName = (Map<String,Object>)objInfo.get(i);
            if(objName.get('createable') == true && objName.get('deletable') == true && objName.get('updateable') == true && objName.get('queryable') == true && objName.get('searchable') == true && objName.get('undeletable') == true)
                objNames.add(String.valueOf(objName.get('name')));
        }        
        return objNames;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> fieldsList(String accessToken, String endpoint, String objName)
    {
        List<String>  fieldList = new List<String>();
        String endpointUrl = endpoint+'services/data/v56.0/sobjects/' + objName + '/describe/';
        HttpRequest getRequest = new HttpRequest();
        getRequest.setHeader('Content-Type', 'application/json');
        getRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        getRequest.setMethod('GET');
        getRequest.setEndpoint(endpointUrl);

        Http Send = new Http();
        HttpResponse initialResponse = new HttpResponse();
        initialResponse = Send.send(getRequest);
        Map<String,Object> getInfo = (Map<String,Object>)Json.deserializeUntyped(initialResponse.getBody());
        List<Object> fieldInfo = (List<Object>)getInfo.get('fields');
        for(integer i = 0;i<fieldInfo.size(); i++)
        {
            Map<String,Object> fieldNames = (Map<String,Object>)fieldInfo.get(i);
            String fieldName = String.valueOf(fieldNames.get('name'));
            fieldList.add(fieldName);

        }
        return fieldList;
    }

    @AuraEnabled(cacheable=true)
    public static String performDmlOperationsFromCSV(String accessToken, String endPoint, String objName, List<Object> fileDetails, Boolean isInsert, Boolean isUpdate){
        System.debug(isInsert);
        System.debug(isUpdate);
        String endpointUrl = endpoint+'services/data/v56.0/sobjects/' + objName + '/describe/';
        HttpRequest getRequest = new HttpRequest();
        getRequest.setHeader('Content-Type', 'application/json');
        getRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        getRequest.setMethod('GET');
        getRequest.setEndpoint(endpointUrl);

        Http Send = new Http();
        HttpResponse initialResponse = new HttpResponse();
        initialResponse = Send.send(getRequest);
        Map<String,Object> getInfo = (Map<String,Object>)Json.deserializeUntyped(initialResponse.getBody());
        List<Object> fieldInfo = (List<Object>)getInfo.get('fields');
        List<Map<String, String>> valueOfRecords = new List<Map<String, String>>();
        List<Map<String, String>> detailsOfFile = new List<Map<String, String>>();
        for(integer i=0;i<fileDetails.size();i++){ 
            Map<Object, Object> recordValues = (Map<Object, Object>)fileDetails.get(i);
            Map<String, String> autoMatchedFields = new Map<String, String>();
            for(Object recordKey : recordValues.keySet()){
                String fname = String.valueOf(recordKey).toUpperCase();
                String value = String.valueOf(recordValues.get(recordKey));
                autoMatchedFields.put(fname,value);
            }
            detailsOfFile.add(autoMatchedFields);
        }

        for(integer i=0;i<detailsOfFile.size();i++){ 
            Map<String, String> recordValues = (Map<String, String>)detailsOfFile.get(i);
            Map<String, String> autoMatchedFields = new Map<String, String>();
            for(integer j = 0;j<fieldInfo.size(); j++)
            {
                Map<String,Object> fieldNames = (Map<String,Object>)fieldInfo.get(j);
                String fieldName = String.valueOf(fieldNames.get('name')).toUpperCase();
                String labelName = String.valueOf(fieldNames.get('label')).toUpperCase();

                if(recordValues.containsKey(fieldName)){
                    String valueOfRecord = String.valueOf(recordValues.get(fieldName));
                    autoMatchedFields.put(fieldName, valueOfRecord);
                }
                else if(recordValues.containsKey(labelName)){
                    String valueOfRecord = String.valueOf(recordValues.get(labelName));
                    autoMatchedFields.put(fieldName, valueOfRecord);
                }
            }
            System.debug(autoMatchedFields);
            valueOfRecords.add(autoMatchedFields);
        }

        List<Map<String, Object>> newList = new List<Map<String, Object>>();
        for (Integer i = 0; i < valueOfRecords.size(); i++) {
            Map<String, String> mapValueInList = valueOfRecords[i];
            Map<String, Object> newMap = new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => objName, 'referenceId' => objName + i}
            };

            for (String key : mapValueInList.keySet()) {
                newMap.put(key, mapValueInList.get(key));
            }            
            newList.add(newMap);
        }

        Map<String, Object> jsonMap = new Map<String, Object>{
            'allOrNone' => false,
            'records' => newList
        };

        String jsonString = JSON.serialize(jsonMap);
        String newEndpointUrl = endpoint+'services/data/v56.0/composite/sobjects';
        HttpRequest postRequest = new HttpRequest();
        postRequest.setHeader('Content-Type', 'application/json');
        postRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        if(isInsert)
            postRequest.setMethod('POST');
        else if(isUpdate)
            postRequest.setMethod('PATCH');
        postRequest.setBody(jsonString);
        postRequest.setEndpoint(newEndpointUrl);

        Http sendReq = new Http();
        HttpResponse response = new HttpResponse();
        response = sendReq.send(postRequest);
        List<Object> getStatusReport = (List<Object>)Json.deserializeUntyped(response.getBody());
        List<String> statusMessageList = new List<String>();
        for(integer i = 0 ; i<getStatusReport.size(); i++){
            Map<String, Object> statusMessages = (Map<String, Object>)getStatusReport.get(i);
            String successOrFailure = String.valueOf(statusMessages.get('success'));
            if(successOrFailure.equalsIgnoreCase('true')){
                String Id = String.valueOf(statusMessages.get('id'));
                statusMessageList.add(Id);
            }
            else{
                List<Object> errorList = (List<Object>)statusMessages.get('errors');
                Map<String, Object> errorMap = (Map<String, Object>)errorList.get(0);
                statusMessageList.add(String.valueOf(errorMap.get('message')));
            }
        }    
        
        List<String> columnNamesForStatusFile = new List<String>();
        Map<String, String> recordValues = valueOfRecords.get(0);
        for(Object recordKey : recordValues.keySet()){
            columnNamesForStatusFile.add(String.valueOf(recordKey));
        }
        columnNamesForStatusFile.add('Message');

        List<String> csvRows = new List<String>{String.join(columnNamesForStatusFile, ',')};
        for(Integer i = 0; i < valueOfRecords.size(); i++) {
            Map<String, String> row = valueOfRecords[i];
            List<String> csvRow = new List<String>();
            for(String columnName : columnNamesForStatusFile) {
                if(columnName == 'Message') {
                    csvRow.add(statusMessageList[i]); // add message value to Messages column
                } else {
                    csvRow.add(row.get(columnName));
                }
            }
            csvRows.add(String.join(csvRow, ','));
        }
        String csvString = String.join(csvRows, '\n');
        return csvString;
    }


    @AuraEnabled(cacheable=true)
    public static String performDeleteFromCSV(String accessToken, String endPoint, String objName, List<Object> fileDetails){
        String endpointUrl = endpoint+'services/data/v56.0/sobjects/' + objName + '/describe/';
        HttpRequest getRequest = new HttpRequest();
        getRequest.setHeader('Content-Type', 'application/json');
        getRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        getRequest.setMethod('GET');
        getRequest.setEndpoint(endpointUrl);

        Http Send = new Http();
        HttpResponse initialResponse = new HttpResponse();
        initialResponse = Send.send(getRequest);
        Map<String,Object> getInfo = (Map<String,Object>)Json.deserializeUntyped(initialResponse.getBody());
        List<Object> fieldInfo = (List<Object>)getInfo.get('fields');
        List<String> recordIds = new List<String>();
        List<Map<String, String>> detailsOfFile = new List<Map<String, String>>();
        for(integer i=0;i<fileDetails.size();i++){ 
            Map<Object, Object> recordValues = (Map<Object, Object>)fileDetails.get(i);
            Map<String, String> autoMatchedFields = new Map<String, String>();
            for(Object recordKey : recordValues.keySet()){
                String fname = String.valueOf(recordKey).toUpperCase();
                String value = String.valueOf(recordValues.get(recordKey));
                autoMatchedFields.put(fname,value);
            }
            detailsOfFile.add(autoMatchedFields);
        }

        for(integer i=0;i<detailsOfFile.size();i++){ 
            Map<String, String> recordValues = (Map<String, String>)detailsOfFile.get(i);
            String valueOfRecord;
            for(integer j = 0;j<fieldInfo.size(); j++)
            {
                Map<String,Object> fieldNames = (Map<String,Object>)fieldInfo.get(j);
                String fieldName = String.valueOf(fieldNames.get('name')).toUpperCase();
                String labelName = String.valueOf(fieldNames.get('label')).toUpperCase();

                if(recordValues.containsKey(fieldName) && fieldName.equalsIgnoreCase('Id')){
                    valueOfRecord = String.valueOf(recordValues.get(fieldName));
                }
                else if(recordValues.containsKey(labelName) && labelName.equalsIgnoreCase('Id')){
                    valueOfRecord = String.valueOf(recordValues.get(labelName));
                }
            }
            recordIds.add(valueOfRecord);
        }


        String newEndpointUrl = endpoint+'services/data/v56.0/composite/sobjects?ids=';
        for(integer i = 0; i<recordIds.size();i++){
            newEndpointUrl += recordIds.get(i) + ',';
        }

        newEndpointUrl = newEndpointUrl.removeEnd(',');
        newEndpointUrl += '&allOrNone=false';
        HttpRequest postRequest = new HttpRequest();
        postRequest.setHeader('Content-Type', 'application/json');
        postRequest.setHeader('Authorization', 'Bearer '+ accessToken);
        postRequest.setMethod('DELETE');
        postRequest.setEndpoint(newEndpointUrl);

        Http sendReq = new Http();
        HttpResponse response = new HttpResponse();
        response = sendReq.send(postRequest);
        List<Object> getStatusReport = (List<Object>)Json.deserializeUntyped(response.getBody());
        List<String> statusMessageList = new List<String>();
        for(integer i = 0 ; i<getStatusReport.size(); i++){
            Map<String, Object> statusMessages = (Map<String, Object>)getStatusReport.get(i);
            String successOrFailure = String.valueOf(statusMessages.get('success'));
            if(successOrFailure.equalsIgnoreCase('true')){
                String Id = String.valueOf(statusMessages.get('id'));
                statusMessageList.add(Id);
            }
            else{
                List<Object> errorList = (List<Object>)statusMessages.get('errors');
                Map<String, Object> errorMap = (Map<String, Object>)errorList.get(0);
                statusMessageList.add(String.valueOf(errorMap.get('message')));
            }
        }    
        
        List<String> columnNamesForStatusFile = new List<String>();
        columnNamesForStatusFile.add('Id');
        columnNamesForStatusFile.add('Message');

        List<String> csvRows = new List<String>{String.join(columnNamesForStatusFile, ',')};
        for(Integer i = 0; i < recordIds.size(); i++) {
            String row = recordIds[i];
            List<String> csvRow = new List<String>();
            for(String columnName : columnNamesForStatusFile) {
                if(columnName == 'Message') {
                    csvRow.add(statusMessageList[i]); // add message value to Messages column
                } else {
                    csvRow.add(row);
                }
            }
            csvRows.add(String.join(csvRow, ','));
        }
        String csvString = String.join(csvRows, '\n');
        System.debug(csvString);
        return csvString;
    }
}