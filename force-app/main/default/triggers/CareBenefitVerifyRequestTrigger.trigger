trigger CareBenefitVerifyRequestTrigger on CareBenefitVerifyRequest (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        CareBenefitVerifyRequestTriggerHandler.handleAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
    }
}