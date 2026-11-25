@IsTest
private class LoanApplicationControllerTest {
  @TestSetup
  static void createApplicant() {
    Account business = new Account(
      Name = 'Acme Bakery',
      Business_Structure__c = 'LLC',
      Year_Established__c = 2015
    );
    insert business;
    insert new Contact(LastName = 'Applicant', AccountId = business.Id);
  }

  private static Id applicantId() {
    return [SELECT Id FROM Contact WHERE LastName = 'Applicant'].Id;
  }

  private static LoanApplicationController.ApplicationInput completeInput() {
    LoanApplicationController.ApplicationInput input = new LoanApplicationController.ApplicationInput();
    input.loanProduct = 'Line of Credit';
    input.loanPurpose = 'Working Capital';
    input.requestedAmount = 75000;
    input.requestedTermMonths = 12;
    return input;
  }

  @IsTest
  static void getApplicantReturnsBusinessAndNoDraft() {
    Test.startTest();
    LoanApplicationController.ApplicantView view = LoanApplicationController.getApplicant(
      applicantId()
    );
    Test.stopTest();

    Assert.areEqual(applicantId(), view.contactId);
    Assert.areEqual('Acme Bakery', view.businessName);
    Assert.areEqual('LLC', view.businessStructure);
    Assert.areEqual(2015, view.yearEstablished);
    Assert.isNull(view.draft);
  }

  @IsTest
  static void getApplicantReturnsSavedDraft() {
    LoanApplicationController.ApplicationView saved = LoanApplicationController.saveDraft(
      applicantId(),
      completeInput()
    );

    LoanApplicationController.ApplicantView view = LoanApplicationController.getApplicant(
      applicantId()
    );

    Assert.areEqual(saved.id, view.draft.id);
    Assert.areEqual('Line of Credit', view.draft.loanProduct);
    Assert.areEqual(75000, view.draft.requestedAmount);
  }

  @IsTest
  static void saveDraftReturnsDraftView() {
    Test.startTest();
    LoanApplicationController.ApplicationView view = LoanApplicationController.saveDraft(
      applicantId(),
      completeInput()
    );
    Test.stopTest();

    Assert.isNotNull(view.id);
    Assert.isTrue(view.name.startsWith('APP-'), view.name);
    Assert.areEqual(LoanApplicationService.STATUS_DRAFT, view.status);
    Assert.areEqual('Working Capital', view.loanPurpose);
    Assert.areEqual(12, view.requestedTermMonths);
    Assert.isNull(view.submittedDate);
  }

  @IsTest
  static void submitApplicationReturnsSubmittedView() {
    Test.startTest();
    LoanApplicationController.ApplicationView view = LoanApplicationController.submitApplication(
      applicantId(),
      completeInput()
    );
    Test.stopTest();

    Assert.areEqual(LoanApplicationService.STATUS_SUBMITTED, view.status);
    Assert.areEqual(Date.today(), view.submittedDate);
  }

  @IsTest
  static void businessRuleMessageReachesTheBorrower() {
    String message;
    try {
      LoanApplicationController.getApplicant(null);
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.isTrue(message.contains('contact record'), message);
  }

  @IsTest
  static void validationRuleMessageReachesTheBorrower() {
    LoanApplicationController.ApplicationInput input = completeInput();
    input.requestedAmount = -5;

    String message;
    try {
      LoanApplicationController.saveDraft(applicantId(), input);
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.areEqual('Requested amount must be greater than zero.', message);
  }

  @IsTest
  static void unexpectedErrorsUseGenericMessage() {
    AuraHandledException result = LoanApplicationController.toAuraException(
      new MathException('Divide by zero in internal calculation')
    );
    Assert.areEqual(
      LoanApplicationController.GENERIC_ERROR,
      result.getMessage()
    );
  }
}
