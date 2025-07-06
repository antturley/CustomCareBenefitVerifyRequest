@isTest
private class BenefitVerificationRequestTest {

  @TestSetup
  static void makeData(){
    // Create Account records
    Account provider = new Account(
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId(),
        Name = 'Test Provider',
        NPI__c = 1234567890
    );
    insert provider;

    Id personAccountRTId = [
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
        GroupNumber = '12345',
        SubscriberId = member.Id
    );
    insert memPlan;

    // Link Service_Detail__c to MemberPlan
    memPlan.Service_Detail__c = serviceDetail.Id;
    update memPlan;
  }

@IsTest
    static void testBuildRequest() {
        MemberPlan memPlan = [SELECT Id, Member.FirstName, Member.LastName, Member.PersonBirthdate, Member.PersonGender, Payer.Name, Policy_Number__c, GroupNumber, SubscriberId,
                              Service_Detail__r.Service_Type__c, Service_Detail__r.Service_Date__c, Service_Detail__r.Procedure_Code__c, Service_Detail__r.Diagnosis_Code__c
                              FROM MemberPlan LIMIT 1];
        Account provider = [SELECT Id, NPI__c, Name FROM Account LIMIT 1];

        BenefitVerificationRequest req = BenefitVerificationRequest.buildRequest(memPlan, provider);

        Assert.areEqual(memPlan.Member.FirstName, req.patient.firstName);
        Assert.areEqual(memPlan.Member.LastName, req.patient.lastName);
        Assert.areEqual(memPlan.Member.PersonBirthdate, req.patient.dateOfBirth);
        Assert.areEqual(memPlan.Member.PersonGender, req.patient.gender);
        Assert.areEqual(memPlan.Payer.Name, req.insurance.insuranceProviderName);
        Assert.areEqual(memPlan.Policy_Number__c, req.insurance.policyNumber);
        Assert.areEqual(memPlan.GroupNumber, req.insurance.groupNumber);
        Assert.areEqual(memPlan.SubscriberId, req.insurance.subscriberId);
        Assert.areEqual(provider.NPI__c, req.provider.npi);
        Assert.areEqual(provider.Name, req.provider.firstName);
        Assert.areEqual('N/A', req.provider.lastName);
        Assert.areEqual(memPlan.Service_Detail__r.Service_Type__c, req.service.serviceType);
        Assert.areEqual(memPlan.Service_Detail__r.Service_Date__c, req.service.serviceDate);
        Assert.areEqual(memPlan.Service_Detail__r.Procedure_Code__c, req.service.diagnosisCode);
        Assert.areEqual(memPlan.Service_Detail__r.Diagnosis_Code__c, req.service.procedureCode);
    }
}