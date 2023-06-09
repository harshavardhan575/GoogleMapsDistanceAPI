/*
 Author : Achyutha Harsha Choudavaram
 Created : 06/01/2023
 Description : API class to make a callout to google maps and get the response of search,distace/duration
*/
public class GoogleMapsAPI {
    
    public static String vHash = 'QWNoeXV0aGEgSGFyc2hhIENob3VkYXZhcmFt';
    public static MapsAPIKey__c myCS1 = MapsAPIKey__c.getValues('API_KEY');
	
    @AuraEnabled( cacheable = true )  
    static public String searchPlace(String searchString){
        String address = EncodingUtil.urlEncode(searchString, 'UTF-8');
        Http h = new Http();        
        HttpRequest req = new HttpRequest();
        
    	String yourAPiKey = myCS1.Key__c; // Enter your Api key which you have created in google api console
        String key = '&key=' + yourAPiKey;
        String endPoint = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=' + address + '&inputtype=textquery&fields=formatted_address%2Cname' + key + '&ipbias' ;
      	req.setEndpoint(endPoint + key);
        req.setMethod('GET');
        req.setTimeout(5000);
        HttpResponse res = h.send(req);
        system.debug('res=='+res.getBody());
        return res.getBody();
    } 

    @AuraEnabled
    static public MatrixWrapper getDistanceAndTimeMatrix(String sourceAddress, String destinationAddress) {
        Http h = new Http();        
        HttpRequest req = new HttpRequest();
        
    	String yourAPiKey = myCS1.Key__c; // Enter your Api key which you have created in google api console
        String key = '&key=' + yourAPiKey;
        String endPoint = 'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=' + EncodingUtil.urlEncode(destinationAddress, 'UTF-8') + '&origins='+ EncodingUtil.urlEncode(sourceAddress, 'UTF-8') +'&&departure_time=now&units=imperial&mode=driving' + key + '&ipbias' ;
      	req.setEndpoint(endPoint + key);
        req.setMethod('GET');
        req.setTimeout(5000);
        HttpResponse res = h.send(req);
        String responseString = res.getBody();
        JSONParser parser = JSON.createParser(responseString);
        Decimal distance = null;
        Decimal duration = null;
        system.debug('===>>>' + res.getBody());
        DistanceAndTimeMatrixWrapper matrixResponseWrapper = (DistanceAndTimeMatrixWrapper)JSON.deserialize( res.getBody(), DistanceAndTimeMatrixWrapper.class );
        MatrixWrapper response = new MatrixWrapper();
        if( matrixResponseWrapper.rows[0].elements[0].status != 'ZERO_RESULTS' ) {
            response.distance = matrixResponseWrapper.rows[0].elements[0].distance.text;
            response.duration = matrixResponseWrapper.rows[0].elements[0].duration.text ;
            Map<String, Decimal> mapModeToCost = new Map<String, Decimal>();
            for( Transportation_Master__mdt mode : [Select MasterLabel, Cost_Per_Mile__c FROM Transportation_Master__mdt WHERE Cost_Per_Mile__c != null]) {
                mapModeToCost.put( mode.Masterlabel, (matrixResponseWrapper.rows[0].elements[0].distance.value * mode.Cost_Per_Mile__c).setScale(2) );
            }
            response.mapModeToTravelToCost = mapModeToCost;
        }
        return response;
    }   
    
    @testVisible
    class MatrixWrapper {
        @AuraEnabled public String distance;
        @AuraEnabled public String duration;
        @AuraEnabled public Map<String, Decimal> mapModeToTravelToCost;
    }
}