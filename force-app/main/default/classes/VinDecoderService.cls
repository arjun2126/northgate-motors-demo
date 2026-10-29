public with sharing class VinDecoderService {
    public class DecodedVin {
        @AuraEnabled public String vin;
        @AuraEnabled public String make;
        @AuraEnabled public String model;
        @AuraEnabled public Integer year;
        @AuraEnabled public String bodyStyle;
        @AuraEnabled public Boolean simulation;
    }
    @AuraEnabled
    public static DecodedVin decode(String vin) {
        if (!FeatureManagement.checkPermission('Decode_Inventory_VIN')) throw new AuraHandledException('VIN preview permission is required.');
        String normalized = vin == null ? '' : vin.trim().toUpperCase();
        if (!Pattern.matches('[A-HJ-NPR-Z0-9]{17}', normalized) || !VinValidator.isValid(normalized)) {
            throw new AuraHandledException('Enter a valid 17-character VIN with a valid check digit.');
        }
        HttpResponse response;
        try { response = new Http().send(requestFor(normalized)); }
        catch (CalloutException failure) { throw new AuraHandledException('VIN mock service is unavailable or timed out.'); }
        return validateResponse(response, normalized);
    }
    @TestVisible private static HttpRequest requestFor(String normalized) {
        HttpRequest request = new HttpRequest(); request.setMethod('GET'); request.setTimeout(5000);
        request.setEndpoint('callout:NG_VIN_Mock/decode/' + normalized); request.setHeader('Accept', 'application/json');
        return request;
    }
    @TestVisible private static DecodedVin validateResponse(HttpResponse response, String normalized) {
        if (response.getStatusCode() != 200) throw new AuraHandledException('VIN mock service returned HTTP ' + response.getStatusCode() + '.');
        try {
            if (response.getBody() == null || response.getBody().length() > 16000) throw new IllegalArgumentException('Invalid response size.');
            DecodedVin result = (DecodedVin) JSON.deserializeStrict(response.getBody(), DecodedVin.class);
            if (result == null || result.vin != normalized || result.simulation != true || String.isBlank(result.make)
                || result.make.length() > 80 || String.isBlank(result.model) || result.model.length() > 80
                || String.isBlank(result.bodyStyle) || result.bodyStyle.length() > 40 || result.year == null
                || result.year < 1900 || result.year > Date.today().year() + 2) throw new IllegalArgumentException('Invalid mock result.');
            return result;
        } catch (Exception invalid) { throw new AuraHandledException('VIN mock service returned an invalid response.'); }
    }
}
