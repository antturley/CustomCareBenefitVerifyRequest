public class CareBenefitVerifyRequestTriggerHandler {
    public static void handleAfterInsertOrUpdate(List<CareBenefitVerifyRequest> newRecords, Map<Id, CareBenefitVerifyRequest> oldMap) {
        List<CoverageBenefit> benefitsToInsert = new List<CoverageBenefit>();
        List<CareBenefitVerificationTask__c> tasksToInsert = new List<CareBenefitVerificationTask__c>();

        Id queueId;
        try {
            queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Care Benefit Records' LIMIT 1].Id;
        } catch (Exception e) {
            System.debug('Queue not found: ' + e.getMessage());
            return;
        }

        for (CareBenefitVerifyRequest cbvr : newRecords) {
            CareBenefitVerifyRequest oldCbvr = oldMap != null ? oldMap.get(cbvr.Id) : null;
            
            Boolean isNewlyCompleted = cbvr.Status == 'Completed' &&
                (oldCbvr == null || oldCbvr.Status != 'Completed');
           
            if (isNewlyCompleted) {
                // create a follow-up task in the queue
                tasksToInsert.add(new CareBenefitVerificationTask__c(
                    Status__c = 'New',
                    Care_Benefit_Verify_Request__c  = cbvr.Id,
                    OwnerId = queueId
                ));
            }
        }
        try {
            if (!tasksToInsert.isEmpty()) insert tasksToInsert;
        } catch (Exception e) {
            throw e;
        }
        
    }
}