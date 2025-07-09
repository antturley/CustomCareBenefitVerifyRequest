public with sharing class CustomHealthCloudBeneVerifyHandler {
    /**
     * @description: Method required for Benefit Verification Component provided by Salesforce.
     * @param: 
     * @return: 
     */

     //Decide if I want it global or public later. 
     //Keep the return type just becuase it has a model built already for the comp.
     @AuraEnabled
     public static List<healthcloudext.BenefitsVerificationResponse> verifyBenefits(List<MemberPlan> MemberPlans) {
        Account providerAcct;
        //Captures all reasponses 
        List<healthcloudext.BenefitsVerificationResponse> responses = new List<healthcloudext.BenefitsVerificationResponse>();

        //Create Request Model
        BenefitVerificationRequest req = new BenefitVerificationRequest();

        //Process each request
        for (MemberPlan memPlan : MemberPlans) {

            healthcloudext.BenefitsVerificationResponse hres = new healthcloudext.BenefitsVerificationResponse();

            try {
                
                if (memPlan.Provider__c != null) {
                    // get provider account
                    providerAcct = [
                        SELECT Id, NPI__c, Name 
                        FROM Account 
                        WHERE Id =: memPlan.Provider__c
                    ];
                    
                }

                //Build the JSON model (will throw on missing data)
                if(providerAcct != null){
                    req = BenefitVerificationRequest.buildRequest(memPlan, providerAcct);
                }
                
                //Perform the callout
                HttpRequest  httpReq = new HttpRequest();
                httpReq.setEndpoint('callout:CareVerificationEndpoint');
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type','application/json');
                httpReq.setBody(req.toJson());
                
                HttpResponse httpRes = new Http().send(httpReq);
            
                //Handle the response
                if (httpRes.getStatusCode() == 200) {
                    //parse JSON
                    Map<String,Object> payload = 
                        (Map<String,Object>) JSON.deserializeUntyped(httpRes.getBody());

                    hres.benefitPeriodEndDate = String.valueOf(Date.today().addYears(2));
                    hres.benefitPeriodStartDate = String.valueOf(Date.today());
                    hres.isCoverageActive = true;
                    hres.jsonResponse = json.serialize(payload);
                    hres.memberNumber = memPlan.MemberNumber;
                    responses.add(hres);
                    try {
                         createRelatedRecords(httpRes.getStatusCode(), memPlan);
                    } catch (Exception ex) {
                        system.debug( 'Error: ' +  ex.getMessage());
                    }
                   
                
                } else {
                    //non-200 HTTP
                    String reason        = 'HTTP ' + httpRes.getStatusCode() + ': ' + httpRes.getBody();
                    hres.isCoverageActive = false;
                    hres.errorResponse = reason;
                    hres.memberNumber = memPlan.MemberNumber;
                    responses.add(hres);
                }
                
            } catch (BenefitVerificationRequest.ValidationException ve) {
                hres.errorResponse = ve.getMessage();
                hres.memberNumber = memPlan.MemberNumber;
                responses.add(hres);

            } catch (Exception e) {
                hres.benefitsRequestId = memPlan.Id;
                hres.errorResponse = e.getMessage();
                hres.memberNumber = memPlan.MemberNumber;
                responses.add(hres);
            }
        }

        return responses;
    }

    private static void createRelatedRecords(Integer StatusCode, MemberPlan memPlan){
        
        //mock data received fromt the api to generate the related records
        //Would normally break this up but out of scope for this demo app
        if(StatusCode == 200){
            CareBenefitVerifyRequest cbvr = new CareBenefitVerifyRequest();
            cbvr.PayerId = memPlan.PayerId;
            cbvr.ProviderId = memPlan.Provider__c;
            cbvr.RequestDate = Datetime.now();
            cbvr.Status = 'Completed';
            cbvr.MemberPlanId = memPlan.Id;
            cbvr.StatusReason = 'Verified Successfully';
            cbvr.AssignedToId = UserInfo.getUserId();
            insert cbvr;

            CoverageBenefit coverageBenefit = new CoverageBenefit();
            coverageBenefit.Name = 'Coverage Benefit - ' + Datetime.now() + ' - ' + memPlan.MemberNumber;
            coverageBenefit.BenefitNotes = 'Test Coverage Notes';
            coverageBenefit.MemberPlanId = memPlan.Id;
            coverageBenefit.BenefitPeriodEndDate = Date.today().addYears(2);
            coverageBenefit.BenefitPeriodStartDate = Date.today();
            coverageBenefit.CareBenefitVerifyRequestId = cbvr.Id;
            coverageBenefit.CoverageType = 'Pharmacy';
            coverageBenefit.EmergencyDepartmentCopay = 350;
            coverageBenefit.FamilyInNetworkDeductibleApplied = 200;
            coverageBenefit.FamilyInNetworkDeductibleLimit = 2000;
            coverageBenefit.FamilyInNetworkDeductibleRemaining = 1800;
            coverageBenefit.FamilyInNetworkOutofPocketApplied = 100;
            coverageBenefit.FamilyInNetworkOutofPocketLimit = 3000;
            coverageBenefit.FamilyInNetworkOutofPocketRemaining = 2900;
            coverageBenefit.FamilyOutofNetworkDeductibleApplied = 300;
            coverageBenefit.FamilyOutofNetworkDeductibleLimit = 5000;
            coverageBenefit.FamilyOutofNetworkDeductibleRemaining = 4700;
            coverageBenefit.FamilyOutofNetworkOutofPocketApplied = 600;
            coverageBenefit.FamilyOutofNetworkOutofPocketLimit = 1000;
            coverageBenefit.FamilyOutofNetworkOutofPocketRemaining = 400;
            coverageBenefit.InNetworkCoinsuranceAmount = 4000;
            coverageBenefit.InNetworkCoinsurancePercentage = 10;
            coverageBenefit.InNetworkLifetimeMaximum = 10000;
            coverageBenefit.IndividualInNetworkDeductibleApplied = 800;
            coverageBenefit.IndividualInNetworkDeductibleLimit = 10000;
            coverageBenefit.IndividualInNetworkDeductibleRemaining = 9200;
            coverageBenefit.IndividualInNetworkOutofPocketApplied = 550;
            coverageBenefit.IndividualInNetworkOutofPocketLimit = 6000;
            coverageBenefit.IndividualInNetworkOutofPocketRemaining = 5450;
            coverageBenefit.IndividualOutofNetworkDeductibleApplied = 700;
            coverageBenefit.IndividualOutofNetworkDeductibleLimit = 15000;
            coverageBenefit.IndividualOutofNetworkDeductibleRemain = 14300;
            coverageBenefit.IndividualOutofNetworkOutofPocketApplied = 250;
            coverageBenefit.IndividualOutofNetworkOutofPocketLimit = 500;
            coverageBenefit.IndividualOutofNetworkOutofPocketRemain = 250;
            coverageBenefit.MemberId = memPlan.MemberId;
            coverageBenefit.MemberPlanId = memPlan.Id;
            coverageBenefit.OutofNetworkCoinsuranceAmount = 4000;
            coverageBenefit.OutofNetworkCoinsurancePercentage = 20;
            coverageBenefit.OutofNetworkLifetimeMaximum = 30000;
            coverageBenefit.PharmaCopayAmount = 600;
            coverageBenefit.PrimaryCareCopay = 4000;
            coverageBenefit.SpecialistCopay = 8000;
            coverageBenefit.UrgentCareCopay	 = 7000;
            coverageBenefit.IsActive = true;
            insert coverageBenefit;

            cbvr.CoverageBenefitId = coverageBenefit.Id;
            update cbvr;

            CoverageBenefitItem cbi = new CoverageBenefitItem();
            cbi.CoverageBenefitId = coverageBenefit.Id;
            cbi.IsActive = true;
            cbi.MemberId = memPlan.MemberId;
            cbi.BenefitCategory = 'General Health';
            cbi.ServiceType = 'General';
            cbi.ServiceTypeCode = 'A22';
            cbi.CoverageLevel = 'Primary';
            cbi.IsInPlanNetwork = true;
            cbi.TimePeriod = '1-Year';
            cbi.Name = 'Test Coverage Benefit Item - ' + Datetime.now();
            cbi.Notes = 'Test Coverage Benefit Item Notes';
            cbi.InNetworkCoverage = '1000';
            cbi.OutofNetworkCoverage = '2000';
            insert cbi;

            CareLimitType careLimitType = [SELECT Id, DeveloperName, LimitType FROM CareLimitType];
            CoverageBenefitItemLimit cbil = new CoverageBenefitItemLimit();
            cbil.CareLimitTypeId = careLimitType.Id;
            cbil.CoverageBenefitItemId = cbi.Id;
            cbil.Name = 'Out of Network Limit';
            cbil.AllowedLimit = '2000';
            cbil.AppliedLimit = '1000';
            cbil.NetworkType = 'Out';
            cbil.CoverageLevel = 'Individual';
            cbil.TermType = 'Years';
            cbil.AppliedQuantity = 1000;
            cbil.AllowedQuantity = 2000;
            insert cbil;

            Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Care Benefit Records' LIMIT 1].Id;
            List<CareBenefitVerificationTask__c> tasksToInsert = new List<CareBenefitVerificationTask__c>();

            // create a follow-up task in the queue
            tasksToInsert.add(new CareBenefitVerificationTask__c(
                Status__c = 'New',
                Care_Benefit_Verify_Request__c  = cbvr.Id,
                OwnerId = queueId
            ));

            if (!tasksToInsert.isEmpty()) insert tasksToInsert;

        }
    }
    @AuraEnabled
    public static List<MemberPlan> getMemberPlans(List<Id> requestMemberIds){
        return [
            SELECT Member.PersonGender
                ,   Member.FirstName
                ,   Member.LastName
                ,   Member.PersonBirthdate
                ,   MemberId
                ,   MemberNumber
                ,   SubscriberId
                ,   Policy_Number__c
                ,   PlanId
                ,   PayerId
                ,   Payer.Name
                ,   Provider__c
                ,   Provider__r.NPI__c
                ,   Provider__r.Name
                ,   Service_Detail__c
                ,   Service_Detail__r.Service_Type__c
                ,   Service_Detail__r.Service_Date__c
                ,   Service_Detail__r.Procedure_Code__c
                ,   Service_Detail__r.Diagnosis_Code__c
                ,   GroupNumber
                ,   RelationshipToSubscriber
                ,   LastVerification
            FROM MemberPlan 
            WHERE MemberId = : requestMemberIds];
    }

    @AuraEnabled
    public static List<CoverageBenefit> getCoverageBenefitDetails(List<Id> MemberPlanIds, List<Id> CareBenefitVerifyRequestIds ){
        List<CoverageBenefit> covBens = [
        SELECT Id
        ,   BenefitNotes
        ,   BenefitPeriodEndDate
        ,   BenefitPeriodStartDate
        ,   CareBenefitVerifyRequestId
        ,   CoverageType
        ,   EmergencyDepartmentCopay
        ,   FamilyInNetworkDeductibleApplied
        ,   FamilyInNetworkDeductibleLimit
        ,   FamilyInNetworkDeductibleRemaining
        ,   FamilyInNetworkOutofPocketApplied
        ,   FamilyInNetworkOutofPocketLimit
        ,   FamilyInNetworkOutofPocketRemaining
        ,   FamilyOutofNetworkDeductibleApplied
        ,   FamilyOutofNetworkDeductibleLimit
        ,   FamilyOutofNetworkDeductibleRemaining
        ,   FamilyOutofNetworkOutofPocketApplied
        ,   FamilyOutofNetworkOutofPocketLimit
        ,   FamilyOutofNetworkOutofPocketRemaining
        ,   InNetworkCoinsuranceAmount
        ,   InNetworkCoinsurancePercentage
        ,   InNetworkLifetimeMaximum
        ,   IndividualInNetworkDeductibleApplied
        ,   IndividualInNetworkDeductibleLimit
        ,   IndividualInNetworkDeductibleRemaining
        ,   IndividualInNetworkOutofPocketApplied
        ,   IndividualInNetworkOutofPocketLimit
        ,   IndividualInNetworkOutofPocketRemaining
        ,   IndividualOutofNetworkDeductibleApplied
        ,   IndividualOutofNetworkDeductibleLimit
        ,   IndividualOutofNetworkDeductibleRemain
        ,   IndividualOutofNetworkOutofPocketApplied
        ,   IndividualOutofNetworkOutofPocketLimit
        ,   IndividualOutofNetworkOutofPocketRemain
        ,   MemberId
        ,   MemberPlanId
        ,   OutofNetworkCoinsuranceAmount
        ,   OutofNetworkCoinsurancePercentage
        ,   OutofNetworkLifetimeMaximum
        ,   PharmaCopayAmount
        ,   PrimaryCareCopay
        ,   SpecialistCopay
        ,   UrgentCareCopay	
         FROM CoverageBenefit 
         WHERE isActive = true
         AND MemberPlanId =: MemberPlanIds
         AND CareBenefitVerifyRequestId =: CareBenefitVerifyRequestIds 
         LIMIT 1];
        return covBens;
    }

    @AuraEnabled
    public static List<CoverageBenefitItem> getCoverageBenefitItem(List<Id> CoverageBenefitIds, List<Id> MemberIds){
        List<CoverageBenefitItem> cbi = [SELECT Id
            ,   IsActive
            ,   BenefitCategory
            ,   ServiceType
            ,   ServiceTypeCode
            ,   CoverageBenefitId
            FROM CoverageBenefitItem
            WHERE CoverageBenefitId =: CoverageBenefitIds
            AND MemberId =: MemberIds
            AND IsActive = true];
        return cbi;
    }



    @AuraEnabled
    public static List<CoverageBenefitItemLimit> getCoverageBenefitItemLimit (List<Id> CoverageBenefitItemIds){
        
        List<CoverageBenefitItemLimit> cbItemLimits = [SELECT 
            Id
        ,   CareLimitTypeId 
        ,   AllowedLimit
        ,   AppliedLimit
        ,   TermType
        ,   NetworkType
        ,   CoverageLevel
        ,   CoverageBenefitItemId
        FROM CoverageBenefitItemLimit
        WHERE CoverageBenefitItemId =: CoverageBenefitItemIds
        ];
        return cbItemLimits;
    }

    @AuraEnabled
    public static List<CoverageBenefitItem> getPlanLevelBenefits(List<Id> requestMemberIds){
       
        return [SELECT 
          Id 
        , IsActive
        , BenefitCategory
        , CodeSetServiceTypeId
        , CoverageBenefitId
        , CoverageLevel
        , InNetworkCoverage
        , DoesDeductibleApply
        , IsInPlanNetwork
        , MemberId
        , Name
        , Notes
        , OutofNetworkCoverage
        , IsPreauthorizationRequired
        , ServiceType
        , ServiceTypeCode
        , TimePeriod
        FROM CoverageBenefitItem
        WHERE IsActive = true
         AND MemberId =: requestMemberIds
        ];
    }

    @AuraEnabled
    public static List<CareBenefitVerifyRequest> getCBVR(List<Id> memberPlanIds){
         List<CareBenefitVerifyRequest> cbvRecords = [
            SELECT Id
            , Name
            , CoverageBenefitId
            , PayerId
            , PlanId
            , ProviderId
            , RequestDate
            , Status
            , MemberPlanId
            , StatusReason 
            FROM CareBenefitVerifyRequest 
            WHERE MemberPlanId =: memberPlanIds 
            ORDER BY CreatedDate DESC
        ];

        return cbvRecords;
       
    }
}