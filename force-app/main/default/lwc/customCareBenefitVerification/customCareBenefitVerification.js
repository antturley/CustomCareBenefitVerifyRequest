import { LightningElement, api, track } from 'lwc';



export default class CustomCareBenefitVerification extends LightningElement {
  //get account id from console tab
  recordId;
  
  //Request to be built
  request = [];

  // add call to get all this data from backend - Member/Member Plan - prob from class - HealthCloudBenefitVerificationHandler.cls
  @track memberPlan = [];
  @track cbvr = [];

  connectedCallback() {
    // Simulated fetch of request data
    //this.loadRequests();
    this.loadMemberPlanRequests();
    this.showPlanLevelBenefits();
    this.showCoverageBenefitDetails;

  }

  loadMemberPlanRequests() {
    // get details and handle if it exists or not
    //Also handle multiple

  }

  showPlanLevelBenefits() {
   // get details and handle if it exists or not
  }

  showCoverageBenefitDetails() {
    // get details and handle if it exists or not
  }

  handleSelect(event) {
    const selectedId = event.target.value;
    // display selected request details if needed
    //make call to backend to get request details from 

    /*
    this.request = [{
    "benefitsRequestId": "5008b00001ABC123", 
    "encounterDate": "2024-07-01",
    "groupNumber": "GRP987654",
    "memberAccountId": "0018b00002XYZ789",
    "memberNumber": "MEM123456",
    "payerId": "60054",
    "providerNpi": "1234567890",
    "providerOrganizationName": "Sunrise Medical Group",
    "providerType": "PrimaryCare",
    "serviceTypeCodes": ["30", "98"]
  }]
    */
  }

}