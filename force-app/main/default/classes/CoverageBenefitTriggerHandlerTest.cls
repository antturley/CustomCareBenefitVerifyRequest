@isTest
private class CoverageBenefitTriggerHandlerTest {
    @IsTest
    static void testCoverageBenefitTriggerHandler() {
        Id personAccountRTId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' AND IsPersonType = true 
            LIMIT 1
        ].Id;

        //Create Member records
        Account member = new Account(
        RecordTypeId = personAccountRTId,  
        FirstName = 'Test',
        LastName = 'Member',
        PersonBirthdate = Date.today(),
        PersonGender = 'Male'
        );
        insert member;

        //Create Payer records
        Account payer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),  
            Name = 'Test Payer',
            Type = 'Payer',
            NPI__c = 1236567890
        );

        insert payer;

        //Create MemberPlan records
        MemberPlan memPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = member.Id,
            PayerId = payer.Id,
            Policy_Number__c = '1234567890',
            GroupNumber = '12345',
            SubscriberId = member.Id
        );
        insert memPlan;

        // Create a CareBenefitVerifyRequest record for testing
        CareBenefitVerifyRequest testCBVR = new CareBenefitVerifyRequest(
            MemberPlanId = memPlan.Id,
            RequestDate = Date.today()
        );
        insert testCBVR;

        // Create a CoverageBenefit record for testing
        CoverageBenefit testCoverageBenefit = new CoverageBenefit(
            MemberPlanId = memPlan.Id,
            Name = 'Test Coverage Benefit '
        );

        Test.startTest();

        // Insert the CoverageBenefit record to trigger the after insert logic
        insert testCoverageBenefit;

        Test.stopTest();

        // Retrieve the inserted CoverageBenefit record
        CoverageBenefit insertedCB = [SELECT Id, CareBenefitVerifyRequestId, OutofNetworkLifetimeMaximum,
                                      OutofNetworkCoinsurancePercentage, OutofNetworkCoinsuranceAmount,
                                      IndividualInNetworkOutofPocketApplied, IndividualInNetworkOutofPocketLimit,
                                      IndividualInNetworkOutofPocketRemaining, FamilyInNetworkOutofPocketApplied,
                                      FamilyInNetworkOutofPocketLimit, FamilyInNetworkOutofPocketRemaining
                                      FROM CoverageBenefit WHERE Id = :testCoverageBenefit.Id];

        // Assert that the CareBenefitVerifyRequestId is populated correctly
        System.assertEquals(testCBVR.Id, insertedCB.CareBenefitVerifyRequestId);

        // Assert that the other fields are populated correctly
        System.assertEquals(1000, insertedCB.OutofNetworkLifetimeMaximum);
        System.assertEquals(10, insertedCB.OutofNetworkCoinsurancePercentage);
        System.assertEquals(2000, insertedCB.OutofNetworkCoinsuranceAmount);
        System.assertEquals(200, insertedCB.IndividualInNetworkOutofPocketApplied);
        System.assertEquals(2000, insertedCB.IndividualInNetworkOutofPocketLimit);
        System.assertEquals(1800, insertedCB.IndividualInNetworkOutofPocketRemaining);
        System.assertEquals(100, insertedCB.FamilyInNetworkOutofPocketApplied);
        System.assertEquals(3000, insertedCB.FamilyInNetworkOutofPocketLimit);
        System.assertEquals(2900, insertedCB.FamilyInNetworkOutofPocketRemaining);
    }

}