import { LightningElement, api, wire } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import LOAN_APPLICATION_OBJECT from "@salesforce/schema/Loan_Application__c";
import LOAN_PRODUCT_FIELD from "@salesforce/schema/Loan_Application__c.Loan_Product__c";
import LOAN_PURPOSE_FIELD from "@salesforce/schema/Loan_Application__c.Loan_Purpose__c";
import getApplicant from "@salesforce/apex/LoanApplicationController.getApplicant";
import saveDraft from "@salesforce/apex/LoanApplicationController.saveDraft";
import submitApplication from "@salesforce/apex/LoanApplicationController.submitApplication";

const DRAFT = "Draft";

/**
 * Borrower-facing loan request form: shows the applicant's business, lets them
 * save a draft, and submit it. The server decides who the applicant is and sets
 * the status; this component only sends the four loan request fields.
 *
 * Messages are shown inline rather than as toasts, because toasts don't work in
 * Experience Cloud sites.
 */
export default class LoanApplicationForm extends LightningElement {
  /** Contact Id when placed on a Contact record page. Ignored for portal users. */
  @api recordId;

  applicant;
  application = {};
  productOptions = [];
  purposeOptions = [];
  isLoading = true;
  isSaving = false;
  isConfirmingSubmit = false;
  errorMessage;
  successMessage;

  @wire(getObjectInfo, { objectApiName: LOAN_APPLICATION_OBJECT })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: LOAN_PRODUCT_FIELD
  })
  wiredProducts({ data, error }) {
    if (data) {
      this.productOptions = toOptions(data);
    } else if (error) {
      this.errorMessage = reduceError(error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: LOAN_PURPOSE_FIELD
  })
  wiredPurposes({ data, error }) {
    if (data) {
      this.purposeOptions = toOptions(data);
    } else if (error) {
      this.errorMessage = reduceError(error);
    }
  }

  connectedCallback() {
    this.loadApplicant();
  }

  async loadApplicant() {
    this.isLoading = true;
    try {
      this.applicant = await getApplicant({ contactId: this.recordId });
      this.application = this.applicant.draft
        ? { ...this.applicant.draft }
        : {};
    } catch (error) {
      this.errorMessage = reduceError(error);
    } finally {
      this.isLoading = false;
    }
  }

  get isSubmitted() {
    return (
      Boolean(this.application.status) && this.application.status !== DRAFT
    );
  }

  get isEditable() {
    return Boolean(this.applicant) && !this.isSubmitted;
  }

  get formHeading() {
    return this.application.name
      ? `Draft ${this.application.name}`
      : "New loan request";
  }

  get productLabel() {
    return labelFor(this.productOptions, this.application.loanProduct);
  }

  get purposeLabel() {
    return labelFor(this.purposeOptions, this.application.loanPurpose);
  }

  handleChange(event) {
    const field = event.target.dataset.field;
    let value = event.detail.value;
    if (event.target.type === "number") {
      value = value === "" || value === null ? null : Number(value);
    }
    this.application = { ...this.application, [field]: value };
    this.successMessage = undefined;
  }

  async handleSaveDraft() {
    // Requested Amount is required on the object, so even a draft needs it.
    const amountInput = this.template.querySelector(
      '[data-field="requestedAmount"]'
    );
    if (!amountInput.reportValidity()) {
      return;
    }
    await this.save(saveDraft, (saved) => `Draft ${saved.name} saved.`);
  }

  handleSubmit() {
    const inputs = [...this.template.querySelectorAll("[data-field]")];
    const allValid = inputs.reduce(
      (valid, input) => input.reportValidity() && valid,
      true
    );
    if (allValid) {
      this.isConfirmingSubmit = true;
    }
  }

  handleCancelSubmit() {
    this.isConfirmingSubmit = false;
  }

  async handleConfirmSubmit() {
    this.isConfirmingSubmit = false;
    await this.save(
      submitApplication,
      (saved) =>
        `Application ${saved.name} submitted. Your lender will be in touch.`
    );
  }

  async save(apexMethod, successText) {
    this.isSaving = true;
    this.errorMessage = undefined;
    this.successMessage = undefined;
    try {
      const saved = await apexMethod({
        contactId: this.recordId,
        application: {
          id: this.application.id,
          loanProduct: this.application.loanProduct,
          loanPurpose: this.application.loanPurpose,
          requestedAmount: this.application.requestedAmount,
          requestedTermMonths: this.application.requestedTermMonths
        }
      });
      this.application = { ...saved };
      this.successMessage = successText(saved);
    } catch (error) {
      this.errorMessage = reduceError(error);
    } finally {
      this.isSaving = false;
    }
  }
}

function toOptions(picklistData) {
  return picklistData.values.map(({ label, value }) => ({ label, value }));
}

function labelFor(options, value) {
  const match = options.find((option) => option.value === value);
  return match ? match.label : value;
}

/** Turns an Apex, LDS, or JavaScript error into one readable sentence. */
function reduceError(error) {
  if (Array.isArray(error?.body)) {
    return error.body.map((entry) => entry.message).join(", ");
  }
  return (
    error?.body?.message ||
    error?.message ||
    "Something went wrong. Please try again."
  );
}
