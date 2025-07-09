```markdown
# Care Benefit Verification App

A Salesforce Health Cloud extension that connects to the Benefits Verification Service, enabling streamlined eligibility workflows directly within Salesforce. This managed package includes the full data model, Custom LWC, Apex classes, permission sets, queue-driven task generation, and external credential support.

---


## Setup and Deployment Guide

This development process was pretty stratit forward. I ran into a few issue with the UI but solved those pretty quickly.

My approach was pretty clear and I decided to keep the lwc all together into one component that executed clear logic for displaying data.

I did not have enough time to build the managed packaged but I did setup the project to suport it. 

This project can be deployed by cloning the repo and deploying all metadata together or individually to avoid errors.

---

### 🛠 Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
- [Visual Studio Code](https://code.visualstudio.com/)
- Salesforce Extensions for VS Code
- A [Developer Edition org](https://developer.salesforce.com/signup) with Dev Hub enabled

Code & App Walkthroughs
Take a guided look into the architecture, workflows, and integration design of the Care Benefit Verification App:

Code Walkthrough & Benefit Verification App Walkthrough — Apex logic, LWC, metadata structure, and queue-based task automation

📺 Watch Walkthrough - https://drive.google.com/drive/folders/1CqEd-QyYgie4EljUp7E6tV0AQxIuSDxG?usp=sharing

---

### 🔧 Local Environment Setup

1. **Install Salesforce CLI**  
   > _Note: If CLI isn't added to your system path, manually add: `/Program Files/SF/bin`_

2. **Verify CLI Installation**
   ```bash
   sf -v
   ```

3. **Install Salesforce Extensions Pack** in VS Code from the Extensions Marketplace.

4. **Create a New SFDX Project**
   ```bash
   sf force:project:create -n care-benefit-verification-app
   ```

5. **Initialize Git**
   ```bash
   git init
   ```
   Push to GitHub or Bitbucket after first commit.

---

### Dev Hub & Org Configuration

6. **Enable Dev Hub** in your Developer Edition org (via Setup UI).

7. **Authorize Dev Hub**
   ```bash
   sf org login web --set-default-dev-hub --alias careBenefitOrgDevHub
   ```

8. **Authorize Target Org**
   > _Typically the same as your Dev Hub for development purposes._

---

### Package Setup

9. **Create a Managed Package**
   ```bash
   sf package create --name "Care Benefit Verification App" --path force-app --package-type Managed
   ```

10. **Store your package ID** — e.g.:
    ```
    Package Id │ <Your-PackageId>
    ```

---

### Scratch Org Setup

11. **Create `project-scratch-def.json`** in `config/`, customized to include Health Cloud settings and Person Account.

12. **Generate Scratch Org**
   ```bash
   sf org create scratch -f config/project-scratch-def.json -a HealthCloudDev
   ```

13. **Push Source**
   ```bash
   sf project deploy start --target-org HealthCloudDev
   ```

---

### Data Model & Configuration

14. **Create Business Record Type** on `Account`

15. **Enable Person Account** in scratch org and assign access via permission set

16. **Set Up Standard Benefit Verification Process**

17. **Create & Assign Permission Sets**
   - Custom: `Care_Benefit_Verification`
   - Standard: `HealthCloudFoundation` or `HealthCloudStarter`

18. **Set Up Test User** with Sales Cloud access and Health Cloud Platform license

19. **Follow Salesforce Setup Guide**  
   [Admin Guide](https://help.salesforce.com/s/articleView?id=ind.admin_benefit_verification_data.htm&type=5)

---

### External Credential Configuration

25. **Create External Credential**
   - Authentication Protocol: Custom
   - Add Principal: Username + Password

---

### Development Highlights

- Custom Apex classes:  
  `healthcloudext.BenefitsVerificationRequest`, `CareBenefitVerifyHandler`, etc.

- Custom objects include:
  - `CareBenefitVerifyRequest`
  - Verification Task Object (`CareBenefitVerificationTask__c`)
  
- Custom layouts, record types, and permission sets

- Programmatic metadata fetch:
  ```bash
  sf project retrieve start --metadata "<type>:<name>" --target-org HealthCloudDev
  ```

- Queue-based task routing (queue must be created manually post-deploy)

### External Request Payload Format
The integration with the benefits verification service sends a structured JSON request with the following nested format:

```json
{
  "patient": {
    "firstName": "Jane",
    "lastName": "Doe",
    "dateOfBirth": "1985-03-12",
    "gender": "F"
  },
  "insurance": {
    "insuranceProviderName": "Anthem Blue Cross",
    "policyNumber": "POL123456789",
    "groupNumber": "GRP987654",
    "subscriberId": "SUB0001234"
  },
  "provider": {
    "npi": 1234567890,
    "firstName": "John",
    "lastName": "Smith"
  },
  "service": {
    "serviceType": "30",
    "serviceDate": "2024-06-01",
    "diagnosisCode": "R51",
    "procedureCode": "99385"
  }
}
```

> This payload is generated from the BenefitVerificationRequest class and transmitted via the configured ExternalCredential. Adjust the structure as needed if your remote service expects alternative naming conventions or field mappings.

---

**Benefits Verification Response Model**
After a successful call to the external benefits verification service, The custom LWC receives this response structured response that maps to the CareBenefitVerifyRequest, CoverageBenefit, CoverageBenefit and CoverageBenefitItemLimit records.

Key Response Fields
```careBenefitVerifyRequestId```: ID of the original verification request

```coverageBenefitId```: ID of the created CoverageBenefit__c record

```isSuccess```: Boolean flag indicating if the verification succeeded

```code```: Status or error code returned by the external service

```message```: Human-readable message from the service

Sample JSON Response
```json
{
  "careBenefitVerifyRequestId": "a0B8b00000ABC123",
  "coverageBenefitId": "a0C8b00000XYZ789",
  "isSuccess": true,
  "code": "200",
  "message": "Verification completed successfully"
}
```

> This response is processed by Salesforce's Benefit Verification Component to update the verification request record and create or update related coverage benefit records. If isSuccess is false, the message and code fields help identify the issue.

---

## Project Setup Instructions

Follow the steps below to download the Salesforce DX project from GitHub, authorize your org, and deploy metadata using the Salesforce CLI. This process ensures a smooth and reproducible setup experience across development environments.

Step 1: Clone the GitHub Repo
First, open your terminal and run:

```bash
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>
```
> Replace <your-username> and <your-repo-name> with your GitHub account name and the project repo name.

Step 2: Authorize Your Salesforce Org
Use the Salesforce CLI to log in to the org where you want to deploy the metadata:

```bash
sf org login web --alias MyTargetOrg
This opens a browser window for you to authenticate.
```

After logging in, the alias MyTargetOrg can be used in all future commands.

Step 3: Set Default Org (Optional but helpful)
If you want to make this your default org for the project:

```bash
sf config set target-org MyTargetOrg
```

Step 4: Deploy the Project Metadata
From your project root directory, deploy all source files:

```bash
sf project deploy start --target-org MyTargetOrg
```

You can also preview the changes first with:

```bash
sf project deploy preview --target-org MyTargetOrg
```

Step 5: Verify Deployment
You can now open the org and verify everything deployed correctly:

```bash
sf org open --target-org MyTargetOrg
```

Navigate to App Launcher and check for custom objects, Lightning components, or other deployed metadata.

### Notes

- CoverageBenefit record is created via Apex, no need to create it manually
- Ensure all required fields are visible and marked on the layouts
- The MemberPlan object was extended with provider info for proper routing
- Queues and task routing logic are included in `CareBenefitVerifyReqTriggerHandler`

Navigate to App Launcher and check for custom objects, Lightning components, or other deployed metadata.

---

## Final Setup Checklist

- [x] Dev Hub authorized  
- [x] Scratch org created  
- [x] Metadata pushed  
- [x] External Credentials configured  
- [x] Permission sets assigned  
- [x] Queue manually created  

---

