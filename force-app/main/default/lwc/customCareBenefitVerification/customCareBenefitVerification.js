import { LightningElement, api, track, wire } from 'lwc';
import verifyBenefits from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.verifyBenefits';
import getMemberPlans from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getMemberPlans';
import getCoverageBenefits from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitDetails';
import getCBVRecord from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCBVR';
import getCoverageBenefitItem from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitItem';
import getCoverageBenefitItemLimit from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitItemLimit';
import { CurrentPageReference } from 'lightning/navigation';



export default class CustomCareBenefitVerification extends LightningElement {
  //get account id from console tab
  @api recordId;

  showMemPlan = false;
  showCovBenefit = false;
  cbvrExist = false;
  displayVerificationSection = false;
  showCovBenefitItem = false;
  showCovBenefitItemLimit = false;

  truncatedDate;
  individualInNetworkOutofPocketApplied;
  individualInNetworkOutofPocketLimit;
  individualInNetworkOutofPocketRemaining;
  individualInNetworkOutofPocketPercentage;
  individualOutofNetworkOutofPocketApplied;
  individualOutofNetworkOutofPocketLimit;
  individualOutofNetworkOutofPocketRemain;
  individualOutofNetworkOutofPocketPercentage;
  
  @track selectedMemberPlan = [];
  @track cbvRecords = []; 
  @track selectedCBVRecord = [];
  @track coverageBenefits = [];
  @track coverageBenefitItems = [];
  @track coverageBenefitItemsLimit = [];
  @track memberPlans = [];
  
  
  //Request to be built
  request = [];

  // add call to get all this data from backend - Member/Member Plan - prob from class - HealthCloudBenefitVerificationHandler.cls

  @wire(CurrentPageReference)
  pageRef(pageRef) {
    const state = pageRef?.state || {};
    // record page
    if (!this.recordId && state.recordId) {
      this.recordId = state.recordId;
      console.log('State object record Id: ' + state.recordId);
    }
    // console or utility bar
    if (!this.recordId && state.inContextOfRef) {
      const pageCtx = JSON.parse(window.atob(state.inContextOfRef));
      this.recordId = pageCtx.recordId;
      console.log('Console: State object record Id: ' + pageCtx.recordId);
    }
  }

  connectedCallback() {
    
    this.showMemberPlans();
    
  }

  showMemberPlans() {
    this.isLoading = true;
    getMemberPlans({ requestMemberIds: this.recordId })
      .then((result) => {
        this.memberPlans = result;
        this.error = undefined;
        this.showMemPlan = true;
        
        console.log('MemberPlans Promise: ' + JSON.stringify(result));
        
      })
      .catch((err) => {
        this.error = err;
        this.memberPlans = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

selectMemberPlan(event){
  try {
    let memberPlanId = event.currentTarget.dataset.id;
    this.selectedMemberPlan = this.memberPlans.find(mp => mp.Id == memberPlanId);
    this.showCBVRecords();
  } catch (error) {
      console.log('Error: ' + error);
  }
}

showCBVRecords(){
  getCBVRecord({ memberPlanIds: this.selectedMemberPlan.Id })
      .then((result) => {
        this.cbvRecords = result;
        this.selectedCBVRecord = this.cbvRecords[0];
        this.error = undefined;
        this.cbvrExist = true;
        
        console.log('getCBVRecord Promise: ' + JSON.stringify(result));
        
      })
      .catch((err) => {
        this.error = err;
        this.cbvRecords = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
  
  
  //this.showCoverageBenefitItemLimit();
}

showCoverageBenefitDetails() {
    console.log('rec id on click:  ' + this.selectedMemberPlan.Id + ' Selected CBV: ' +  this.selectedCBVRecord.Id);
    getCoverageBenefits({ MemberPlanIds: [this.selectedMemberPlan.Id], CareBenefitVerifyRequestIds:  [this.selectedCBVRecord.Id]  })
      .then((result) => {
        this.coverageBenefits = result;
        this.error = undefined;
        this.showCovBenefit = true;
        console.log('getCoverageBenefits Promise: ' + JSON.stringify(result));
        
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefits = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });

      
  }

  showCoverageBenefitItem(){
    getCoverageBenefitItem({ CoverageBenefitIds:  this.coverageBenefits[0].Id}, { MemberIds:   this.selectedMemberPlan.Id })
      .then((result) => {
        this.coverageBenefitItems = result;
        this.error = undefined;
        this.showCovBenefitItem = true;
        console.log('Coverage Benefit Items Promise: ' + JSON.stringify(result));
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefitItems = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  showCoverageBenefitItemLimit(){
    getCoverageBenefitItemLimit({ CoverageBenefitItemIds:  this.coverageBenefits[0].Id})
      .then((result) => {
        this.coverageBenefitItemsLimit = result;
        this.error = undefined;
        this.showCovBenefitItemLimit = true;
        console.log('Coverage Benefit Items Limit Promise: ' + JSON.stringify(result));
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefitItemsLimit = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }


  handleLoad(event) {
    console.log('handleLoad() called.');
    this.selectCbvrRecord(event);
  }

  handleChange(event) {
    console.log('handleChange() called.');
    this.selectCbvrRecord(event);
  }

  selectCbvrRecord(event) {
    console.log('Selected CBVR Option: ' + event.target.value);
    let selectedId = event.target.value;
    if (selectedId) {
      this.selectedCBVRecord = this.cbvRecords.find(record => record.Id === selectedId);
      try {
        this.showCoverageBenefitDetails();
      } catch (error) {
        console.log('Error: ' + error);
      }
      
      //fix later
      //this.truncatedDate = this.truncateDate(this.selectedMemberPlan.RequestDate);
    }
  }

  handleSelect(event) {
    const selectedId = event.target.value;

    try {
      const response = verifyBenefits({ recordId });
      // Process the response as needed
    } catch (error) {
      console.error('Error calling verifyBenefits:', error);
    }
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

  truncateDate(date){
    let dateString = date.toString();
    let trunDate = dateString.split('T')[0];
    console.log('Trunked date: ' + trunDate);
    return trunDate;
  }

  createPercentages(){
    if(this.coverageBenefits.length > 0){
      let currentCovBenefit = this.coverageBenefits[0];
      //Individual In Network
      this.individualInNetworkOutofPocketApplied = currentCovBenefit.IndividualInNetworkOutofPocketApplied;
      this.individualInNetworkOutofPocketLimit = currentCovBenefit.IndividualInNetworkOutofPocketLimit;
      this.individualInNetworkOutofPocketRemaining = currentCovBenefit.IndividualInNetworkOutofPocketRemaining;
      this.individualInNetworkOutofPocketPercentage = Number(currentCovBenefit.IndividualInNetworkOutofPocketApplied) / Number(currentCovBenefit.IndividualInNetworkOutofPocketLimit) * 100;

      //Individiual Out Of Network

      this.individualOutofNetworkOutofPocketApplied = currentCovBenefit.IndividualOutofNetworkOutofPocketApplied;
      this.individualOutofNetworkOutofPocketLimit = currentCovBenefit.IndividualOutofNetworkOutofPocketLimit;
      this.individualOutofNetworkOutofPocketRemain = currentCovBenefit.IndividualOutofNetworkOutofPocketRemaining;
      this.individualOutofNetworkOutofPocketPercentage = Number(currentCovBenefit.IndividualOutofNetworkOutofPocketApplied) / Number(currentCovBenefit.IndividualOutofNetworkOutofPocketLimit) * 100;
      console.log('Percent: ' + this.individualInNetworkOutofPocketPercentage + ' Applied: ' + currentCovBenefit.IndividualInNetworkOutofPocketApplied);
    } else{
      this.individualInNetworkOutofPocketPercentage = 0;
    }
  }

}