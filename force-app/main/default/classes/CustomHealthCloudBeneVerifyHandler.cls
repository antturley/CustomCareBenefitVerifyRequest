public with sharing class CustomHealthCloudBeneVerifyHandler {
    /**
     * @description: Method required for Benefit Verification Component provided by Salesforce.
     * @param: 
     * @return: 
     */

     //Decide if I want it global or public later. 
     //Keep the return type just becuase it has a model built already for the comp.
     @AuraEnabled
     public static List<healthcloudext.BenefitsVerificationResponse> verifyBenefits(List<healthcloudext.BenefitsVerificationRequest> requests) {
        Account providerAcct;
        HealthcareProvider providerHcp;

        //Captures all reasponses 
        List<healthcloudext.BenefitsVerificationResponse> responses = new List<healthcloudext.BenefitsVerificationResponse>();

        // Prepare DML buffers
        List<CoverageBenefit> covInsert   = new List<CoverageBenefit>();
        List<CareBenefitVerifyRequest> toUpdate    = new List<CareBenefitVerifyRequest>();
        List<CareBenefitVerificationTask__c> taskInsert  = new List<CareBenefitVerificationTask__c>();
        List<Id> requestMemberIds = new List<Id>();

        for(healthcloudext.BenefitsVerificationRequest initialRequest : requests){
            requestMemberIds.add(initialRequest.memberAccountId);
        }

        //Fetch the queue that will own the follow-up task
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Care Benefit Records' LIMIT 1].Id;

        //Create Request Model
        BenefitVerificationRequest req = new BenefitVerificationRequest();

        //Assumse only one meember plan
        List<MemberPlan> memPlans = getMemberPlans(requestMemberIds);

        //Process each request
        for (MemberPlan memPlan : memPlans) {

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
    @AuraEnabled
    public static List<MemberPlan> getMemberPlans(List<Id> requestMemberIds){
        return [
            SELECT Member.PersonGender
                ,   Member.FirstName
                ,   Member.LastName
                ,   Member.PersonBirthdate
                ,   MemberNumber
                ,   SubscriberId
                ,   Policy_Number__c
                ,   PayerId
                ,   Payer.Name
                ,   Provider__c
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
        system.debug('Coverage BenefitIds: '+ CoverageBenefitIds);
        system.debug('MemberIds: '+ MemberIds);
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
        system.debug('Coverage Benefit Item Limit Id: '+ CoverageBenefitItemIds );
        
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
        System.debug('Request Ids sent from client: ' + requestMemberIds);
       
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
        system.debug('CBVR Records: ' + cbvRecords.size());
        return cbvRecords;
       
    }
}