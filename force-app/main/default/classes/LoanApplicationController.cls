/**
 * Entry point for the loanApplicationForm LWC. Translates between the
 * component's plain objects and Loan_Application__c, delegates to
 * LoanApplicationService, and turns failures into messages safe to show a
 * borrower.
 */
public with sharing class LoanApplicationController {
  @TestVisible
  private static final String GENERIC_ERROR = 'Something went wrong while processing your application. Please try again, or contact your lender if the problem continues.';

  /**
   * Returns the applicant, their business, and their current draft (if any).
   * @param contactId Contact to act for when an internal user tests the form
   *                  on a Contact page. Ignored for portal users.
   */
  @AuraEnabled
  public static ApplicantView getApplicant(Id contactId) {
    try {
      Contact applicant = LoanApplicationService.resolveApplicant(contactId);
      return new ApplicantView(
        applicant,
        LoanApplicationService.findDraft(applicant)
      );
    } catch (Exception e) {
      throw toAuraException(e);
    }
  }

  @AuraEnabled
  public static ApplicationView saveDraft(
    Id contactId,
    ApplicationInput application
  ) {
    try {
      return new ApplicationView(
        LoanApplicationService.saveDraft(contactId, application.toRecord())
      );
    } catch (Exception e) {
      throw toAuraException(e);
    }
  }

  @AuraEnabled
  public static ApplicationView submitApplication(
    Id contactId,
    ApplicationInput application
  ) {
    try {
      return new ApplicationView(
        LoanApplicationService.submit(contactId, application.toRecord())
      );
    } catch (Exception e) {
      throw toAuraException(e);
    }
  }

  /**
   * Business-rule and validation-rule messages are written for users, so
   * they are passed through. Anything else gets a generic message so no
   * internal detail reaches the browser.
   */
  @TestVisible
  private static AuraHandledException toAuraException(Exception e) {
    String message = GENERIC_ERROR;
    if (e instanceof LoanApplicationService.ApplicationException) {
      message = e.getMessage();
    } else if (e instanceof DmlException) {
      message = ((DmlException) e).getDmlMessage(0);
    }
    AuraHandledException auraException = new AuraHandledException(message);
    auraException.setMessage(message);
    return auraException;
  }

  /** Fields the borrower can edit. Anything else sent by the browser is ignored. */
  public class ApplicationInput {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String loanProduct { get; set; }
    @AuraEnabled
    public String loanPurpose { get; set; }
    @AuraEnabled
    public Decimal requestedAmount { get; set; }
    @AuraEnabled
    public Decimal requestedTermMonths { get; set; }

    public Loan_Application__c toRecord() {
      return new Loan_Application__c(
        Id = id,
        Loan_Product__c = loanProduct,
        Loan_Purpose__c = loanPurpose,
        Requested_Amount__c = requestedAmount,
        Requested_Term_Months__c = requestedTermMonths
      );
    }
  }

  public class ApplicationView {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String loanProduct;
    @AuraEnabled
    public String loanPurpose;
    @AuraEnabled
    public Decimal requestedAmount;
    @AuraEnabled
    public Decimal requestedTermMonths;
    @AuraEnabled
    public Date submittedDate;

    public ApplicationView(Loan_Application__c application) {
      id = application.Id;
      name = application.Name;
      status = application.Status__c;
      loanProduct = application.Loan_Product__c;
      loanPurpose = application.Loan_Purpose__c;
      requestedAmount = application.Requested_Amount__c;
      requestedTermMonths = application.Requested_Term_Months__c;
      submittedDate = application.Submitted_Date__c;
    }
  }

  public class ApplicantView {
    @AuraEnabled
    public Id contactId;
    @AuraEnabled
    public String contactName;
    @AuraEnabled
    public String businessName;
    @AuraEnabled
    public String businessStructure;
    @AuraEnabled
    public Decimal yearEstablished;
    @AuraEnabled
    public String industry;
    @AuraEnabled
    public ApplicationView draft;

    public ApplicantView(Contact applicant, Loan_Application__c draft) {
      contactId = applicant.Id;
      contactName = applicant.Name;
      businessName = applicant.Account.Name;
      businessStructure = applicant.Account.Business_Structure__c;
      yearEstablished = applicant.Account.Year_Established__c;
      industry = applicant.Account.Industry;
      this.draft = draft == null ? null : new ApplicationView(draft);
    }
  }
}
