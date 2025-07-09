trigger CoverageBenefitTrigger on CoverageBenefit (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CoverageBenefitTriggerHandler.handleAfterInsert(Trigger.new);
    }
}