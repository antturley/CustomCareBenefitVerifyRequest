import { LightningElement, api, track, wire } from 'lwc';
import verifyMemberPlanBenefits from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.verifyBenefits';
import getMemberPlans from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getMemberPlans';
import getCoverageBenefits from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitDetails';
import getCBVRecord from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCBVR';
import getCoverageBenefitItem from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitItem';
import getCoverageBenefitItemLimit from '@salesforce/apex/CustomHealthCloudBeneVerifyHandler.getCoverageBenefitItemLimit';
import { CurrentPageReference } from 'lightning/navigation';

const columns = [
    { label: 'Limit Type', fieldName: 'CareLimitType.Name' },
    {
        label: 'Allowed Limit',
        fieldName: 'AllowedLimit',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Applied Limit',
        fieldName: 'AppliedLimit',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'left' }
    },
    { 
        label: 'Term Type', 
        fieldName: 'TermType', 
        sortable: true,
        cellAttributes: { alignment: 'left' } 
    },
    {
      label: 'Network Type',
      fieldName: 'NetworkType',
      sortable: true,
      cellAttributes: { alignment: 'left' }
    }

];

export default class CustomCareBenefitVerification extends LightningElement {
  //get account id from console tab
  @api recordId;

  columns = columns

  showMemPlan = false;
  showCovBenefit = false;
  cbvrExist = false;
  displayVerificationSection = false;
  showCovBenefitItem = false;
  showCovBenefitItemLimit = false;
  isLoading = false;

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
  @track selectedCoverageBenefitItem = [];
  @track coverageBenefitItemsLimit = [];
  @track memberPlans = [];

  verificationResults = [];

  columns = columns;
  defaultSortDirection = 'asc';
  sortDirection = 'asc';
  sortedBy;

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
      })
      .catch((err) => {
        this.error = err;
        this.cbvRecords = undefined;
      })
      .finally(() => {
        this.showCoverageBenefitDetails()
        this.isLoading = false;
      });
  
}

showCoverageBenefitDetails() {
    getCoverageBenefits({ MemberPlanIds: [this.selectedMemberPlan.Id], CareBenefitVerifyRequestIds:  [this.selectedCBVRecord.Id]  })
      .then((result) => {
        this.coverageBenefits = result;
        this.error = undefined;
        this.showCovBenefit = true;
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefits = undefined;
      })
      .finally(() => {
        this.createPercentages();
        this.showCoverageBenefitItem();
        this.isLoading = false;
      });

  }

  showCoverageBenefitItem(){
   
      getCoverageBenefitItem({ CoverageBenefitIds:  [this.coverageBenefits[0].Id], MemberIds:   [this.selectedMemberPlan.MemberId]})
      .then((result) => {
        this.coverageBenefitItems = result;
        this.error = undefined;
        this.showCovBenefitItem = true;
        this.selectedCoverageBenefitItem = this.coverageBenefitItems[0];
        this.selectedItemName = this.coverageBenefitItems[0].ServiceType + ': ' + this.coverageBenefitItems[0].ServiceTypeCode; 
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefitItems = undefined;
      })
      .finally(() => {
         
        this.showCoverageBenefitItemLimit();
        this.isLoading = false;
      });
    
    
  }

  showCoverageBenefitItemLimit(){
    if(this.selectedCoverageBenefitItem != null){
      this.isLoading = true;
      getCoverageBenefitItemLimit({ CoverageBenefitItemIds:  this.selectedCoverageBenefitItem.Id})
      .then((result) => {
        this.coverageBenefitItemsLimit = result;
        this.error = undefined;
        this.showCovBenefitItemLimit = true;
      })
      .catch((err) => {
        this.error = err;
        this.coverageBenefitItemsLimit = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
    }else{
      this.coverageBenefitItemsLimit = [];
    }
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
        this.createPercentages();
      } catch (error) {
        console.log('Error: ' + error);
      }
    }
  }

  handleItemChange(event){
    let selectedId = event.target.value;
    if (selectedId) {
      this.selectedCoverageBenefitItem = this.coverageBenefitItems.find(record => record.Id === selectedId);
      this.selectedItemName = this.selectedCoverageBenefitItem.ServiceType + ': ' + this.selectedCoverageBenefitItem.ServiceTypeCode;
    }
  }


  handleVerification() {
    this.isLoading = true;
    verifyMemberPlanBenefits({MemberPlans: [this.selectedMemberPlan]})
      .then((result) => {
        this.verificationResults = result;
        this.error = undefined;
        console.log('Result object from Verification:  ' + JSON.stringify(result));
      })
      .catch((err) => {
        this.error = err;
        this.verificationResults = undefined;
      })
      .finally(() => {
        this.showCBVRecords();
        this.isLoading = false;
      });
  }

  truncateDate(date){
    let dateString = date.toString();
    let trunDate = dateString.split('T')[0];
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

   sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
}