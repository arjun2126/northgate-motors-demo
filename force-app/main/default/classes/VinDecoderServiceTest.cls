@isTest
private class VinDecoderServiceTest {
    @TestSetup static void actors() { P7Batch1TestData.actor('VIN allowed', true, false, true); P7Batch1TestData.actor('VIN denied', false, false, true); }
    private class Mock implements HttpCalloutMock {
        Integer status; String body; Boolean timeout;
        Mock(Integer status, String body, Boolean timeout) { this.status = status; this.body = body; this.timeout = timeout; }
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('GET', request.getMethod()); System.assertEquals('application/json', request.getHeader('Accept'));
            System.assertEquals('callout:NG_VIN_Mock/decode/4NDM4NJ96V8L0KGCJ', request.getEndpoint());
            if (timeout) throw new CalloutException('Simulated timeout');
            HttpResponse response = new HttpResponse(); response.setStatusCode(status); response.setBody(body); return response;
        }
    }
    @isTest static void simulationResponseIsPreviewOnly() {
        User actor = [SELECT Id FROM User WHERE LastName = 'VIN allowed' LIMIT 1];
        Mock provider = new Mock(200, '{"vin":"4NDM4NJ96V8L0KGCJ","make":"Aurelia","model":"Fictional Sedan","year":2026,"bodyStyle":"Sedan","simulation":true}', false);
        System.runAs(actor) {
            Integer writes = Limits.getDmlStatements();
            // Transport credential activation is separate; verify the actual request/response boundary without configuring it.
            VinDecoderService.DecodedVin result = VinDecoderService.validateResponse(provider.respond(VinDecoderService.requestFor('4NDM4NJ96V8L0KGCJ')), '4NDM4NJ96V8L0KGCJ');
            System.assertEquals('Aurelia', result.make); System.assert(result.simulation); System.assertEquals(writes, Limits.getDmlStatements());
        }
    }
    @isTest static void malformedNonSuccessTimeoutAndWrongIdentityAreRejected() {
        User actor = [SELECT Id FROM User WHERE LastName = 'VIN allowed' LIMIT 1];
        System.runAs(actor) {
            invalidResponse(503, '{}'); invalidResponse(200, 'invalid json'); invalidResponse(200, '{"vin":"wrong","simulation":true}');
            Test.setMock(HttpCalloutMock.class, new Mock(200, '{}', true)); rejected('4NDM4NJ96V8L0KGCJ');
            rejected('4NDM4NJ97V8L0KGCJ'); rejected('bad'); rejected(null);
        }
        User denied = [SELECT Id FROM User WHERE LastName = 'VIN denied' LIMIT 1];
        System.runAs(denied) { rejected('4NDM4NJ96V8L0KGCJ'); }
    }
    private static void invalidResponse(Integer status, String body) {
        HttpResponse response = new HttpResponse(); response.setStatusCode(status); response.setBody(body);
        Boolean rejected = false;
        try { VinDecoderService.validateResponse(response, '4NDM4NJ96V8L0KGCJ'); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
    }
    private static void rejected(String vin) {
        Boolean rejected = false; try { VinDecoderService.decode(vin); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
    }
}
