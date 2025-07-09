/**
 * Model to handle the BenefitVerificationRequest DTO.
 */
public class BenefitVerificationRequest {
   //Patient
    public class Patient{
        public String firstName;
        public String lastName;
        public Date dateOfBirth;
        public String gender;
   }

   //Insurance
   public class Insurance{
     public String insuranceProviderName;
        public String policyNumber;
        public String groupNumber;
        public String subscriberId;
   }

   //Provider
   public class Provider{
        public Decimal npi;
        public String firstName;
        public String lastName;
   }

   //Service
   public class Service{
        public String serviceType;
        public Date serviceDate;
        public String diagnosisCode;
        public String procedureCode;
   }

   public Patient patient;
   public Insurance insurance;
   public Provider provider;
   public Service service;

   public String toJson(){
       return System.JSON.serialize(this);
   }
   
   public static BenefitVerificationRequest buildRequest(MemberPlan memPlan, Account provider) {
        BenefitVerificationRequest req = new BenefitVerificationRequest();

        // --- Patient Details ---
        req.patient = new BenefitVerificationRequest.Patient();
        req.patient.firstName = memPlan.Member.FirstName;
        req.patient.lastName = memPlan.Member.LastName;
        req.patient.dateOfBirth = memPlan.Member.PersonBirthdate;
        req.patient.gender = memPlan.Member.PersonGender;

        // --- Insurance Information ---
        req.insurance = new BenefitVerificationRequest.Insurance();
        req.insurance.insuranceProviderName = memPlan.Payer.Name;
        req.insurance.policyNumber = memPlan.Policy_Number__c;
        req.insurance.groupNumber = memPlan.GroupNumber;
        req.insurance.subscriberId = memPlan.SubscriberId;

        // --- Provider Information ---
        req.provider = new BenefitVerificationRequest.Provider();
        req.provider.npi = provider.NPI__c ;
        req.provider.firstName = provider.Name;
        req.provider.lastName = 'N/A';

        // --- Service Details --- Handle this later
       
        req.service = new BenefitVerificationRequest.Service();
        req.service.serviceType = memPlan.Service_Detail__r.Service_Type__c;
        req.service.serviceDate = memPlan.Service_Detail__r.Service_Date__c;
        req.service.diagnosisCode = memPlan.Service_Detail__r.Procedure_Code__c;
        req.service.procedureCode = memPlan.Service_Detail__r.Diagnosis_Code__c;
        
        validate(req);

        return req;
    }

   //Data Validation
   public static void validate(BenefitVerificationRequest req){
    List<String> errors = new List<String>();

    if(req.patient == null) errors.add('Missing patient info.');
    else {
        if(String.isBlank(req.patient.firstName)) errors.add('Missing patient First Name.');
        if(String.isBlank(req.patient.lastName)) errors.add('Missing patient Last Name.');
        if(req.patient.dateOfBirth == null) errors.add('Missing patient Date Of Birth.');
        if(String.isBlank(req.patient.gender)) errors.add('Missing patient Gender.');
    }

    if(req.insurance == null) errors.add('Missing insurance info.');
        else {
            if(String.isBlank(req.insurance.insuranceProviderName)) errors.add('Missing insurance provider name.');
            if(String.isBlank(req.insurance.policyNumber)) errors.add('Missing policy number.');
            if(String.isBlank(req.insurance.groupNumber)) errors.add('Missing group number.');
            if(String.isBlank(req.insurance.subscriberId)) errors.add('Missing subscriber ID.');
        }

        if(req.provider == null) errors.add('Missing provider info.');
        else {
            if(req.provider.npi == null) errors.add('Missing provider NPI.');
            if(String.isBlank(req.provider.firstName)) errors.add('Missing provider first name.');
            if(String.isBlank(req.provider.lastName)) errors.add('Missing provider last name.');
        }

        if(req.service == null) errors.add('Missing service info.');
        else {
            if(String.isBlank(req.service.serviceType)) errors.add('Missing service type.');
            if(req.service.serviceDate == null) errors.add('Missing service date.');
            if(String.isBlank(req.service.diagnosisCode)) errors.add('Missing diagnosis code.');
            if(String.isBlank(req.service.procedureCode)) errors.add('Missing procedure code.');
        }

         if (!errors.isEmpty()) {
            throw new ValidationException(String.join(errors, '\n'));
        }
   }

   public class ValidationException extends Exception {}

}