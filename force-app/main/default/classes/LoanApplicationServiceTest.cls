@IsTest
private class LoanApplicationServiceTest {
  @TestSetup
  static void createBusinesses() {
    Account acme = new Account(
      Name = 'Acme Bakery',
      Business_Structure__c = 'LLC',
      Year_Established__c = 2015
    );
    Account other = new Account(Name = 'Other Business');
    insert new List<Account>{ acme, other };
    insert new List<Contact>{
      new Contact(LastName = 'Applicant', AccountId = acme.Id),
      new Contact(LastName = 'Outsider', AccountId = other.Id)
    };
  }

  private static Contact contactNamed(String lastName) {
    return [
      SELECT Id, AccountId
      FROM Contact
      WHERE LastName = :lastName
      LIMIT 1
    ];
  }

  private static Loan_Application__c completeRequest() {
    return new Loan_Application__c(
      Loan_Product__c = 'Term Loan',
      Loan_Purpose__c = 'Expansion',
      Requested_Amount__c = 50000,
      Requested_Term_Months__c = 36
    );
  }

  private static Loan_Application__c reload(Id applicationId) {
    return [
      SELECT
        Borrower__c,
        Primary_Contact__c,
        Status__c,
        Loan_Product__c,
        Loan_Purpose__c,
        Requested_Amount__c,
        Requested_Term_Months__c,
        Submitted_Date__c
      FROM Loan_Application__c
      WHERE Id = :applicationId
    ];
  }

  @IsTest
  static void resolveApplicantReturnsContactAndBusiness() {
    Contact applicant = contactNamed('Applicant');

    Test.startTest();
    Contact resolved = LoanApplicationService.resolveApplicant(applicant.Id);
    Test.stopTest();

    Assert.areEqual(applicant.Id, resolved.Id);
    Assert.areEqual(applicant.AccountId, resolved.AccountId);
    Assert.areEqual('Acme Bakery', resolved.Account.Name);
    Assert.areEqual('LLC', resolved.Account.Business_Structure__c);
    Assert.areEqual(2015, resolved.Account.Year_Established__c);
  }

  @IsTest
  static void resolveApplicantWithoutContactThrows() {
    String message;
    try {
      LoanApplicationService.resolveApplicant(null);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }
    Assert.isTrue(
      message.contains('contact record'),
      'Internal users must name a contact: ' + message
    );
  }

  @IsTest
  static void resolveApplicantWithoutBusinessThrows() {
    Contact loner = new Contact(LastName = 'No Business');
    insert loner;

    String message;
    try {
      LoanApplicationService.resolveApplicant(loner.Id);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }
    Assert.isTrue(
      message.contains('business account'),
      'A contact with no account cannot apply: ' + message
    );
  }

  @IsTest
  static void resolveApplicantForMissingContactThrows() {
    Contact gone = new Contact(LastName = 'Deleted');
    insert gone;
    delete gone;

    String message;
    try {
      LoanApplicationService.resolveApplicant(gone.Id);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }
    Assert.isTrue(message.contains('could not find the applicant'), message);
  }

  @IsTest
  static void saveDraftCreatesDraftForApplicant() {
    Contact applicant = contactNamed('Applicant');

    Test.startTest();
    Loan_Application__c saved = LoanApplicationService.saveDraft(
      applicant.Id,
      completeRequest()
    );
    Test.stopTest();

    Loan_Application__c stored = reload(saved.Id);
    Assert.areEqual(applicant.AccountId, stored.Borrower__c);
    Assert.areEqual(applicant.Id, stored.Primary_Contact__c);
    Assert.areEqual(LoanApplicationService.STATUS_DRAFT, stored.Status__c);
    Assert.isNull(stored.Submitted_Date__c);
    Assert.areEqual('Term Loan', stored.Loan_Product__c);
    Assert.areEqual('Expansion', stored.Loan_Purpose__c);
    Assert.areEqual(50000, stored.Requested_Amount__c);
    Assert.areEqual(36, stored.Requested_Term_Months__c);
    Assert.isNotNull(saved.Name, 'The application number is returned');
  }

  @IsTest
  static void saveDraftUpdatesExistingDraft() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c first = LoanApplicationService.saveDraft(
      applicant.Id,
      new Loan_Application__c(Requested_Amount__c = 10000)
    );

    Loan_Application__c changes = completeRequest();
    changes.Id = first.Id;
    Test.startTest();
    Loan_Application__c saved = LoanApplicationService.saveDraft(
      applicant.Id,
      changes
    );
    Test.stopTest();

    Assert.areEqual(first.Id, saved.Id);
    Assert.areEqual(50000, reload(saved.Id).Requested_Amount__c);
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Loan_Application__c],
      'Updating a draft must not create another application'
    );
  }

  @IsTest
  static void saveDraftRejectsAnotherBusinessesApplication() {
    Contact outsider = contactNamed('Outsider');
    Loan_Application__c theirs = completeRequest();
    theirs.Borrower__c = outsider.AccountId;
    theirs.Status__c = LoanApplicationService.STATUS_DRAFT;
    insert theirs;

    Loan_Application__c attempt = new Loan_Application__c(
      Id = theirs.Id,
      Requested_Amount__c = 1
    );
    String message;
    try {
      LoanApplicationService.saveDraft(contactNamed('Applicant').Id, attempt);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }

    Assert.isTrue(message.contains('different business'), message);
    Assert.areEqual(50000, reload(theirs.Id).Requested_Amount__c);
  }

  @IsTest
  static void saveDraftRejectsSubmittedApplication() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c submitted = completeRequest();
    submitted.Borrower__c = applicant.AccountId;
    submitted.Status__c = LoanApplicationService.STATUS_SUBMITTED;
    insert submitted;

    Loan_Application__c attempt = completeRequest();
    attempt.Id = submitted.Id;
    attempt.Requested_Amount__c = 99;
    String message;
    try {
      LoanApplicationService.saveDraft(applicant.Id, attempt);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }

    Assert.isTrue(message.contains('already been submitted'), message);
    Assert.areEqual(50000, reload(submitted.Id).Requested_Amount__c);
  }

  @IsTest
  static void saveDraftSurfacesValidationRules() {
    Loan_Application__c invalid = completeRequest();
    invalid.Requested_Amount__c = 0;

    String message;
    try {
      LoanApplicationService.saveDraft(contactNamed('Applicant').Id, invalid);
    } catch (DmlException e) {
      message = e.getDmlMessage(0);
    }

    Assert.areEqual('Requested amount must be greater than zero.', message);
    Assert.areEqual(0, [SELECT COUNT() FROM Loan_Application__c]);
  }

  @IsTest
  static void findDraftReturnsOnlyDrafts() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c submitted = completeRequest();
    submitted.Borrower__c = applicant.AccountId;
    submitted.Status__c = LoanApplicationService.STATUS_SUBMITTED;
    insert submitted;

    Assert.isNull(
      LoanApplicationService.findDraft(applicant),
      'A submitted application is not a draft'
    );

    Loan_Application__c draft = LoanApplicationService.saveDraft(
      applicant.Id,
      completeRequest()
    );
    Assert.areEqual(draft.Id, LoanApplicationService.findDraft(applicant).Id);
  }

  @IsTest
  static void submitCompletesExistingDraft() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c draft = LoanApplicationService.saveDraft(
      applicant.Id,
      new Loan_Application__c(Requested_Amount__c = 10000)
    );

    Loan_Application__c request = completeRequest();
    request.Id = draft.Id;
    Test.startTest();
    Loan_Application__c submitted = LoanApplicationService.submit(
      applicant.Id,
      request
    );
    Test.stopTest();

    Loan_Application__c stored = reload(submitted.Id);
    Assert.areEqual(LoanApplicationService.STATUS_SUBMITTED, stored.Status__c);
    Assert.areEqual(Date.today(), stored.Submitted_Date__c);
    Assert.areEqual(50000, stored.Requested_Amount__c);
  }

  @IsTest
  static void submitCreatesApplicationWhenNoDraftExists() {
    Contact applicant = contactNamed('Applicant');

    Loan_Application__c submitted = LoanApplicationService.submit(
      applicant.Id,
      completeRequest()
    );

    Loan_Application__c stored = reload(submitted.Id);
    Assert.areEqual(LoanApplicationService.STATUS_SUBMITTED, stored.Status__c);
    Assert.areEqual(applicant.AccountId, stored.Borrower__c);
  }

  @IsTest
  static void submitIncompleteRequestThrowsAndSavesNothing() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c draft = LoanApplicationService.saveDraft(
      applicant.Id,
      new Loan_Application__c(Requested_Amount__c = 10000)
    );

    Loan_Application__c incomplete = new Loan_Application__c(
      Id = draft.Id,
      Requested_Amount__c = 20000
    );
    String message;
    try {
      LoanApplicationService.submit(applicant.Id, incomplete);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }

    Assert.isTrue(message.contains('Loan Product'), message);
    Assert.isTrue(message.contains('Loan Purpose'), message);
    Assert.isTrue(message.contains('Requested Term (Months)'), message);
    Assert.isFalse(message.contains('Requested Amount'), message);
    Loan_Application__c stored = reload(draft.Id);
    Assert.areEqual(LoanApplicationService.STATUS_DRAFT, stored.Status__c);
    Assert.areEqual(
      10000,
      stored.Requested_Amount__c,
      'Nothing is saved when submission is refused'
    );
  }

  @IsTest
  static void submitTwiceIsRejected() {
    Contact applicant = contactNamed('Applicant');
    Loan_Application__c submitted = LoanApplicationService.submit(
      applicant.Id,
      completeRequest()
    );

    Loan_Application__c again = completeRequest();
    again.Id = submitted.Id;
    String message;
    try {
      LoanApplicationService.submit(applicant.Id, again);
    } catch (LoanApplicationService.ApplicationException e) {
      message = e.getMessage();
    }

    Assert.isTrue(message.contains('already been submitted'), message);
  }

  @IsTest
  static void standardUserWithPermissionSetCanApply() {
    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
    ];
    User loanOfficer = new User(
      LastName = 'Officer',
      Alias = 'lnoff',
      Email = 'loan.officer@example.com',
      Username = 'loan.officer.' +
        System.currentTimeMillis() +
        '@example.com.capitalflow',
      ProfileId = standardProfile.Id,
      TimeZoneSidKey = 'America/Denver',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert loanOfficer;
    insert new PermissionSetAssignment(
      AssigneeId = loanOfficer.Id,
      PermissionSetId = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'CapitalFlow_User'
      ]
      .Id
    );

    System.runAs(loanOfficer) {
      Account business = new Account(Name = 'Officer Business');
      insert business;
      Contact applicant = new Contact(
        LastName = 'Owner',
        AccountId = business.Id
      );
      insert applicant;

      Loan_Application__c submitted = LoanApplicationService.submit(
        applicant.Id,
        completeRequest()
      );

      Assert.areEqual(
        LoanApplicationService.STATUS_SUBMITTED,
        submitted.Status__c
      );
      Assert.areEqual(business.Id, submitted.Borrower__c);
    }
  }
}
