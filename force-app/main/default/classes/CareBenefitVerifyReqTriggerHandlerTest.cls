@isTest
private class CareBenefitVerifyReqTriggerHandlerTest {

    @IsTest
    static void testTaskCreation() {
        //Create a test user
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = prof.Id
        );
        insert u;

        //Create the Queue
        Group queue = [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = 'Queue' AND Name = 'Care Benefit Records' 
            LIMIT 1
        ];

        //In one runAs block, do ALL setup DML to avoid mixed-DML
        System.runAs(new User(Id = Userinfo.getUserId())) {
            //add user to the queue
            insert new GroupMember(UserOrGroupId = u.Id, GroupId = queue.Id);
        }

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
       
        //Create a CareBenefitVerifyRequest in system context
        CareBenefitVerifyRequest cbvr = new CareBenefitVerifyRequest(Status = 'Pending', MemberPlanId = memPlan.Id);
        insert cbvr;

        Test.startTest();
            cbvr = [
                SELECT Id, Status FROM CareBenefitVerifyRequest
                WHERE Id = :cbvr.Id
            ];
            cbvr.Status = 'Completed';
            update cbvr;
        Test.stopTest();
        

        //Assert that the handler created the Task in the queue
        List<CareBenefitVerificationTask__c> tasks = [
            SELECT Id, Status__c, Care_Benefit_Verify_Request__c, OwnerId
            FROM CareBenefitVerificationTask__c
            WHERE Care_Benefit_Verify_Request__c = :cbvr.Id
        ];
        System.assertEquals(1, tasks.size(), 'Exactly one task should be created');
        CareBenefitVerificationTask__c task = tasks[0];
        System.assertEquals('New', task.Status__c, 'Task.Status__c');
        System.assertEquals(queue.Id, task.OwnerId, 'Task should be owned by the Care Benefit Records queue');
    }
}