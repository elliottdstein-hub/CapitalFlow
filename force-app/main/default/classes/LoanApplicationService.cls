/**
 * Business rules for a borrower's loan application: who the applicant is,
 * saving a draft, and submitting it.
 *
 * The applicant is always resolved on the server. A portal user is tied to their
 * own Contact; an internal user (testing the form on a Contact page) acts for the
 * Contact they name. Status and Submitted Date are set here, never by the caller.
 * All queries and DML run in user mode, so object access, field access, and
 * sharing are enforced for the running user.
 */
public with sharing class LoanApplicationService {
  public static final String STATUS_DRAFT = 'Draft';
  public static final String STATUS_SUBMITTED = 'Submitted';

  public class ApplicationException extends Exception {
  }

  /**
   * Returns the applicant Contact, with its business Account fields.
   * @param requestedContactId Contact to act for. Ignored for portal users.
   */
  public static Contact resolveApplicant(Id requestedContactId) {
    Id portalContactId = [
      SELECT ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
    ]
    .ContactId;
    Id contactId = portalContactId != null
      ? portalContactId
      : requestedContactId;
    if (contactId == null) {
      throw new ApplicationException(
        'Open this form from a contact record so we know who is applying.'
      );
    }

    List<Contact> contacts = [
      SELECT
        Id,
        Name,
        AccountId,
        Account.Name,
        toLabel(Account.Business_Structure__c),
        Account.Year_Established__c,
        toLabel(Account.Industry)
      FROM Contact
      WHERE Id = :contactId
      WITH USER_MODE
    ];
    if (contacts.isEmpty()) {
      throw new ApplicationException(
        'We could not find the applicant, or you do not have access to them.'
      );
    }
    if (contacts[0].AccountId == null) {
      throw new ApplicationException(
        'The applicant must belong to a business account before applying.'
      );
    }
    return contacts[0];
  }

  /**
   * Returns the business's most recently changed draft application, or null.
   */
  public static Loan_Application__c findDraft(Contact applicant) {
    List<Loan_Application__c> drafts = [
      SELECT
        Id,
        Name,
        Status__c,
        Loan_Product__c,
        Loan_Purpose__c,
        Requested_Amount__c,
        Requested_Term_Months__c,
        Submitted_Date__c
      FROM Loan_Application__c
      WHERE Borrower__c = :applicant.AccountId AND Status__c = :STATUS_DRAFT
      WITH USER_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 1
    ];
    return drafts.isEmpty() ? null : drafts[0];
  }

  /**
   * Creates or updates a draft. Only the loan request fields are taken from
   * the input; borrower, contact, and status are set here.
   */
  public static Loan_Application__c saveDraft(
    Id requestedContactId,
    Loan_Application__c input
  ) {
    Contact applicant = resolveApplicant(requestedContactId);
    Loan_Application__c application = prepareDraft(applicant, input);
    if (application.Id == null) {
      Database.insert(application, true, AccessLevel.USER_MODE);
    } else {
      Database.update(application, true, AccessLevel.USER_MODE);
    }
    return getApplication(application.Id);
  }

  /**
   * Saves the input and submits the application in one update. Nothing is
   * saved if the request is incomplete.
   */
  public static Loan_Application__c submit(
    Id requestedContactId,
    Loan_Application__c input
  ) {
    Contact applicant = resolveApplicant(requestedContactId);
    Loan_Application__c application = prepareDraft(applicant, input);

    List<String> missing = missingForSubmission(application);
    if (!missing.isEmpty()) {
      throw new ApplicationException(
        'Complete these fields before submitting: ' +
          String.join(missing, ', ') +
          '.'
      );
    }

    application.Status__c = STATUS_SUBMITTED;
    application.Submitted_Date__c = Date.today();
    if (application.Id == null) {
      Database.insert(application, true, AccessLevel.USER_MODE);
    } else {
      Database.update(application, true, AccessLevel.USER_MODE);
    }
    return getApplication(application.Id);
  }

  private static Loan_Application__c prepareDraft(
    Contact applicant,
    Loan_Application__c input
  ) {
    Loan_Application__c application;
    if (input.Id == null) {
      application = new Loan_Application__c(
        Borrower__c = applicant.AccountId,
        Primary_Contact__c = applicant.Id,
        Status__c = STATUS_DRAFT
      );
    } else {
      Loan_Application__c existing = getApplication(input.Id);
      if (existing.Borrower__c != applicant.AccountId) {
        throw new ApplicationException(
          'This application belongs to a different business.'
        );
      }
      if (existing.Status__c != STATUS_DRAFT) {
        throw new ApplicationException(
          'This application has already been submitted and can no longer be changed.'
        );
      }
      application = new Loan_Application__c(Id = existing.Id);
    }
    application.Loan_Product__c = input.Loan_Product__c;
    application.Loan_Purpose__c = input.Loan_Purpose__c;
    application.Requested_Amount__c = input.Requested_Amount__c;
    application.Requested_Term_Months__c = input.Requested_Term_Months__c;
    return application;
  }

  private static List<String> missingForSubmission(
    Loan_Application__c application
  ) {
    List<String> missing = new List<String>();
    if (String.isBlank(application.Loan_Product__c)) {
      missing.add('Loan Product');
    }
    if (String.isBlank(application.Loan_Purpose__c)) {
      missing.add('Loan Purpose');
    }
    if (application.Requested_Amount__c == null) {
      missing.add('Requested Amount');
    }
    if (application.Requested_Term_Months__c == null) {
      missing.add('Requested Term (Months)');
    }
    return missing;
  }

  private static Loan_Application__c getApplication(Id applicationId) {
    List<Loan_Application__c> applications = [
      SELECT
        Id,
        Name,
        Borrower__c,
        Status__c,
        Loan_Product__c,
        Loan_Purpose__c,
        Requested_Amount__c,
        Requested_Term_Months__c,
        Submitted_Date__c
      FROM Loan_Application__c
      WHERE Id = :applicationId
      WITH USER_MODE
    ];
    if (applications.isEmpty()) {
      throw new ApplicationException(
        'We could not find that application, or you do not have access to it.'
      );
    }
    return applications[0];
  }
}
