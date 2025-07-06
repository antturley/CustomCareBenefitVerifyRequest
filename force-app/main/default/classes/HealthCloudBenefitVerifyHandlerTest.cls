@isTest
public with sharing class HealthCloudBenefitVerifyHandlerTest {
    //static Id memberPlanId;
    //static Id providerId;
    static Id payerId;
    static Id memberId;
    static Id personAccountRTId;
    
    @IsTest
    static void testVerifyBenefits() {
        /**
         * Had issuses with account records in test setup method so I moved
         * test data creation into each test method
         */
        
        // Create Account records
        Account provider = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),
            Name = 'Test Provider',
            NPI__c = 1234567890
        );
        insert provider;

        personAccountRTId = [
        SELECT Id 
        FROM RecordType 
        WHERE SObjectType = 'Account' AND IsPersonType = true 
        LIMIT 1
        ].Id;

        // Create Member records
        Account member = new Account(
            RecordTypeId = personAccountRTId,  
            FirstName = 'Test',
            LastName = 'Member',
            PersonBirthdate = Date.today(),
            PersonGender = 'Male'
        );
        insert member;
        system.debug('Member Id: ' + member.Id);
        memberId = Member.Id;
        system.debug('Member Id Static Var: ' + memberId);
        system.debug('Member Record type id: ' + personAccountRTId);
        

        // Create Payer records
        Account payer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),  
            Name = 'Test Payer',
            Type = 'Payer',
            NPI__c = 1236567890
        );

        insert payer;

        // Create Service_Detail__c records
        Service_Detail__c serviceDetail = new Service_Detail__c(
        Service_Type__c = 'Consultation',
        Service_Date__c = Date.today(),
        Procedure_Code__c = '123',
        Diagnosis_Code__c = '1235'
        );
        insert serviceDetail;

        // Create MemberPlan records
        MemberPlan memPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = member.Id,
            PayerId = payer.Id,
            Policy_Number__c = '1234567890',
            Provider__c = provider.Id,
            GroupNumber = '12345',
            SubscriberId = member.Id
        );
        insert memPlan;

        // Link Service_Detail__c to MemberPlan
        memPlan.Service_Detail__c = serviceDetail.Id;
        update memPlan;

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockBenefitVerificationCallout());

        Test.startTest();
        
        // Create a BenefitsVerificationRequest using test data
        healthcloudext.BenefitsVerificationRequest bvr = new healthcloudext.BenefitsVerificationRequest();
        //bvr.benefitsRequestId = cbvr.Id;
        bvr.encounterDate = String.valueOf(Date.today());
        bvr.groupNumber = 'G123';
        bvr.memberAccountId = string.valueOf(memberId);
        bvr.memberNumber = 'M123';
        bvr.payerId = payerId;
        bvr.providerNpi = '1234567890';
        bvr.providerOrganizationName = 'Test Provider Org';
        bvr.providerType = 'Individual';
        bvr.serviceTypeCodes = new List<String>{ '30' };

        // Call the method to test
        List<healthcloudext.BenefitsVerificationResponse> responses = HealthCloudBenefitVerificationHandler.verifyBenefits(new List<healthcloudext.BenefitsVerificationRequest>{bvr});

        Test.stopTest();

        // Assert the response
        System.debug('Responses: ' + String.valueOf(responses));
        Assert.areEqual(1, responses.size(), 'There is one resonse object returned.');
        Assert.areEqual(null, responses[0].errorResponse, 'No error resonse should be returned.');
    }

    @IsTest
    static void testVerifyBenefits_Error() {
         // Create Account records
        Account provider = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),
            Name = 'Test Provider',
            NPI__c = 1234567890
        );
        insert provider;
        //providerId = provider.Id;

        // Create HealthCareProvider records
        HealthCareProvider healthCareProvider = new HealthCareProvider(
        Name = 'Test HealthCareProvider',
        NPI__c = 0987654321
        );
        insert healthCareProvider;

        personAccountRTId = [
        SELECT Id 
        FROM RecordType 
        WHERE SObjectType = 'Account' AND IsPersonType = true 
        LIMIT 1
        ].Id;

        // Create Member records
        Account member = new Account(
            RecordTypeId = personAccountRTId,  
            FirstName = 'Test',
            LastName = 'Member',
            PersonBirthdate = Date.today(),
            PersonGender = 'Male'
        );
        insert member;
        system.debug('Member Id: ' + member.Id);
        memberId = Member.Id;
        system.debug('Member Id Static Var: ' + memberId);
        system.debug('Member Record type id: ' + personAccountRTId);
        

        // Create Payer records
        Account payer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),  
            Name = 'Test Payer',
            Type = 'Payer',
            NPI__c = 1236567890
        );

        insert payer;
        payerId = payer.Id;

        // Create Service_Detail__c records
        Service_Detail__c serviceDetail = new Service_Detail__c(
        Service_Type__c = 'Consultation',
        Service_Date__c = Date.today(),
        Procedure_Code__c = '123',
        Diagnosis_Code__c = '1235'
        );
        insert serviceDetail;

        // Create MemberPlan records
        MemberPlan memPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = member.Id,
            PayerId = payer.Id,
            Policy_Number__c = '1234567890',
            Provider__c = provider.Id,
            GroupNumber = '12345',
            SubscriberId = member.Id
        );
        insert memPlan;

        // Link Service_Detail__c to MemberPlan
        memPlan.Service_Detail__c = serviceDetail.Id;
        update memPlan;

        // Create a BenefitsVerificationRequest using test data
        healthcloudext.BenefitsVerificationRequest bvr = new healthcloudext.BenefitsVerificationRequest();
        //bvr.benefitsRequestId = 'someRequestId';
        bvr.encounterDate = String.valueOf(Date.today());
        bvr.groupNumber = 'G123';
        bvr.memberAccountId = memberId.toString();
        bvr.memberNumber = 'M123';
        bvr.payerId = payerId.toString();
        bvr.providerNpi = '1234567890';
        bvr.providerOrganizationName = 'Test Provider Org';
        bvr.providerType = 'Individual';
        bvr.serviceTypeCodes = new List<String>{ '30' };

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockBenefitVerificationCallout_Error());

        Test.startTest();

        // Call the method to test
        List<healthcloudext.BenefitsVerificationResponse> responses = HealthCloudBenefitVerificationHandler.verifyBenefits(new List<healthcloudext.BenefitsVerificationRequest>{bvr});

        Test.stopTest();

        // Assert the response
        System.assertEquals(1, responses.size());
        System.assertEquals('HTTP 500: Internal Server Error', responses[0].errorResponse);
        //System.assertEquals('Callout failure: Internal Server Error', responses[0].statusReason);
    }

    @IsTest
    static void testVerifyBenefits_ValidationException() {
        // ... (create test data)
        // Create Account records
        //Removed NPI Number to fail validation
        Account provider = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),
            Name = 'Test Provider'
        );
        insert provider;

        personAccountRTId = [
        SELECT Id 
        FROM RecordType 
        WHERE SObjectType = 'Account' AND IsPersonType = true 
        LIMIT 1
        ].Id;

        // Create Member records
        Account member = new Account(
            RecordTypeId = personAccountRTId,  
            FirstName = 'Test',
            LastName = 'Member',
            PersonBirthdate = Date.today(),
            PersonGender = 'Male'
        );
        insert member;
        system.debug('Member Id: ' + member.Id);
        memberId = Member.Id;
        system.debug('Member Id Static Var: ' + memberId);
        system.debug('Member Record type id: ' + personAccountRTId);
        

        // Create Payer records
        Account payer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),  
            Name = 'Test Payer',
            Type = 'Payer',
            NPI__c = 1236567890
        );

        insert payer;
        payerId = payer.Id;

        // Create Service_Detail__c records
        Service_Detail__c serviceDetail = new Service_Detail__c(
        Service_Type__c = 'Consultation',
        Service_Date__c = Date.today(),
        Procedure_Code__c = '123',
        Diagnosis_Code__c = '1235'
        );
        insert serviceDetail;

        // Create MemberPlan records
        MemberPlan memPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = member.Id,
            PayerId = payer.Id,
            Policy_Number__c = '1234567890',
            Provider__c = provider.Id,
            GroupNumber = '12345',
            SubscriberId = member.Id
        );
        insert memPlan;

        // Link Service_Detail__c to MemberPlan
        memPlan.Service_Detail__c = serviceDetail.Id;
        update memPlan;

        // Create a BenefitsVerificationRequest using test data
        healthcloudext.BenefitsVerificationRequest bvr = new healthcloudext.BenefitsVerificationRequest();
        //bvr.benefitsRequestId = 'someRequestId';
        bvr.encounterDate = String.valueOf(Date.today());
        bvr.groupNumber = 'G123';
        bvr.memberAccountId = memberId.toString();
        bvr.memberNumber = 'M123';
        bvr.payerId = payerId.toString();
        bvr.providerNpi = '1234567890';
        bvr.providerOrganizationName = 'Test Provider Org';
        bvr.providerType = 'Individual';
        bvr.serviceTypeCodes = new List<String>{ '30' };

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockBenefitVerificationCallout_400());

        Test.startTest();
        

        // Call the method to test
        List<healthcloudext.BenefitsVerificationResponse> responses = HealthCloudBenefitVerificationHandler.verifyBenefits(new List<healthcloudext.BenefitsVerificationRequest>{bvr});

        Test.stopTest();

        // Assert the response
        Assert.areEqual(1, responses.size(), 'There is one response object returned.');
        Assert.areNotEqual(null, responses[0].errorResponse, 'Error response should be returned.');
    }

 
    public class MockBenefitVerificationCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'status' => 'Acknowledged',
                'statusReason' => 'Verified successfully'
            }));
            return res;
        }
    }


    public class MockBenefitVerificationCallout_Error implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }


    public class MockBenefitVerificationCallout_400 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('Bad Request: Missing or invalid payload');
            return res;
        }
}
}


