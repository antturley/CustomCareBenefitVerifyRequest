public class CoverageBenefitTriggerHandler {
    public static void handleAfterInsert(List<CoverageBenefit> newBenefits) {
        //Collect all MemberPlan IDs from the newly inserted CoverageBenefit records
        Set<Id> memberPlanIds = new Set<Id>();
        for (CoverageBenefit cb : newBenefits) {
            if (cb.MemberPlanId != null) {
                memberPlanIds.add(cb.MemberPlanId);
            }
            //Would normally come from another object but out of scope for this demo app
            cb.OutofNetworkLifetimeMaximum = 1000;
            cb.OutofNetworkCoinsurancePercentage = 10;
            cb.OutofNetworkCoinsuranceAmount = 2000;
            cb.IndividualInNetworkOutofPocketApplied = 200;
            cb.IndividualInNetworkOutofPocketLimit = 2000;
            cb.IndividualInNetworkOutofPocketRemaining = 1800;
            cb.FamilyInNetworkOutofPocketApplied = 100;
            cb.FamilyInNetworkOutofPocketLimit = 3000;
            cb.FamilyInNetworkOutofPocketRemaining =2900;
        }

        //Query all CareBenefitVerifyRequest for those MemberPlans,
        //ordering by RequestDate desc so the first per MemberPlan is the most recent
        List<CareBenefitVerifyRequest> cbvrList = [
            SELECT Id, MemberPlanId, RequestDate
            FROM CareBenefitVerifyRequest
            WHERE MemberPlanId IN :memberPlanIds
            ORDER BY RequestDate DESC
        ];

        //Build a map from MemberPlan to the most recent CBVR Id
        Map<Id, Id> mostRecentCbvrByPlan = new Map<Id, Id>();
        for (CareBenefitVerifyRequest cbvr : cbvrList) {
            // only populate once per MemberPlan, because list is sorted desc
            if (!mostRecentCbvrByPlan.containsKey(cbvr.MemberPlanId)) {
                mostRecentCbvrByPlan.put(cbvr.MemberPlanId, cbvr.Id);
            }
        }

        //Stamp each CoverageBenefit with the corresponding CBVR Id
        for (CoverageBenefit cb : newBenefits) {
            Id cbvrId = mostRecentCbvrByPlan.get(cb.MemberPlanId);
            if (cbvrId != null) {
                cb.CareBenefitVerifyRequestId = cbvrId;
            }
        }
        
    }
}