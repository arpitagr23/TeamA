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
        try{
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
                    throw new CommonException('Endpoint Incorrect');
                }
            }
            else{
                throw new CommonException('Authentication Failure, Please Check Your Login Details');
            }
        }
        catch(CommonException e){
            Map<String, Object> error = new Map<String, Object>();
            error.put('message', e.getMessage());
            System.debug(error);
            throw new AuraHandledException(JSON.serialize(error));
        }
        catch(Exception e){
            Map<String, Object> error = new Map<String, Object>();
            error.put('message', e.getMessage());
            throw new AuraHandledException(JSON.serialize(error));
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

    /*
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> fieldsDML(String accessToken, String endpoint, String objName)
    {
        Map<String, List<String>>  fieldList = new Map<String, List<String>>();
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
        List<String> fieldNames = new List<String>();
        List<String> fieldLabels = new List<String>();
        List<String> fieldTypes = new List<String>();
        for(integer i = 0;i<fieldInfo.size(); i++)
        {
            
            Map<String,Object> fields = (Map<String,Object>)fieldInfo.get(i);
            String fieldName = String.valueOf(fields.get('name'));
            String fieldLabel = String.valueOf(fields.get('label'));
            String fieldType = String.valueOf(fields.get('type'));
            fieldNames.add(fieldName);
            fieldLabels.add(fieldLabel);
            fieldTypes.add(fieldType);
        }
        fieldList.put('Name', fieldNames);
        fieldList.put('Label',fieldLabels);
        fieldList.put('Type', fieldTypes);
        System.debug(fieldList);
        return fieldList;
    }
    */
    
}