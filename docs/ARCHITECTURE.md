# CapitalFlow Salesforce Org — Architecture

_Last updated: 2026-11-24_

This document describes the architecture as it is currently implemented. Setup and commands are in [DEVELOPMENT.md](DEVELOPMENT.md). The reasoning behind choices, and choices still open, is in [DECISIONS.md](DECISIONS.md). Coding standards are in `CLAUDE.md` §4.

## Purpose and scope

CapitalFlow is a small business lending application built on Salesforce (D-009). It covers borrowers, loan applications through the credit decision, booked loans, and loan payments. Approval automation, generating payment schedules, underwriting calculations, and a borrower portal are planned but **not implemented**.

## Current state

`force-app/main/default/` contains the first data model (from the `Create-Initial-Objects` branch). It's declarative only: custom objects and fields, validation rules, page layouts, tabs, a Lightning app, and one permission set. There is no Apex, no triggers, no LWC, no Flow, and no integrations yet.

The applications and loans metadata was deployed to the Developer Edition org (`vscodeOrg`) on 2026-10-29 (deploy ID `0Afbm00000le4oDCAQ`), and `CapitalFlow_User` is assigned to the org's admin user.

`Loan_Payment__c` and the Loan repayment fields were deployed on 2026-11-24 (deploy ID `0Afbm00000pevobCAA`). The same deploy deleted `Loan__c.Outstanding_Principal__c` from the org (D-011).

Since there is no source tracking, later changes made in the org won't appear here until they are retrieved.

## Project structure

| Aspect | Current implementation | Decision |
| --- | --- | --- |
| Source format | Salesforce DX source format | — |
| Package directories | One: `force-app` (default) | D-004 |
| Namespace | None | D-004 |
| Development model | Org-based: metadata is deployed directly, with no packages | D-004 |
| Target org | Developer Edition org, no source tracking | D-003 |
| Source API version | 68.0 (the org's version as of 2026-10-29) | D-005 |

## Components

| Layer | Components | Notes |
| --- | --- | --- |
| Data model (objects, fields, relationships) | `Loan_Application__c`, `Loan__c`, `Loan_Payment__c`, two Account fields, `Loan_Product` global value set | See Data model below |
| User interface | `CapitalFlow` Lightning app, for desktop and mobile; tabs and page layouts for the three custom objects | Standard Lightning record pages. The app uses the utility bar `CapitalFlow_UtilityBar`, which exists only in the org (see Constraints) |
| Apex (triggers, handlers, services, controllers) | None | Trigger convention: D-008 |
| Lightning Web Components | None | |
| Automation (Flow, scheduled or async Apex) | None. Validation rules only | |
| Integrations (named credentials, external services) | None | |

## Data model

```
Account (borrower business)
 ├── Contact (principals, guarantors)         standard relationship
 ├── Loan_Application__c.Borrower__c          lookup, required, delete restricted
 │      └── Primary_Contact__c → Contact      lookup, filtered to the borrower's contacts
 └── Loan__c.Borrower__c                      lookup, required, delete restricted
        ├── Loan_Application__c → application lookup, delete restricted
        └── Loan_Payment__c.Loan__c            master-detail (payments are deleted with the loan)
```

| Object | Purpose | Key fields |
| --- | --- | --- |
| Account (standard) | The borrowing business. Reuses standard `Industry`, `AnnualRevenue`, `NumberOfEmployees` | `Business_Structure__c` (picklist), `Year_Established__c` |
| Contact (standard) | People at the borrower | — |
| `Loan_Application__c` (`APP-00000`) | A request for financing, from draft to credit decision | `Status__c` (Draft → Submitted → In Underwriting → Approved / Declined / Withdrawn), `Loan_Product__c`, `Loan_Purpose__c`, `Requested_Amount__c`, `Requested_Term_Months__c`, `Submitted_Date__c`, `Decision_Date__c`, `Decision_Notes__c` |
| `Loan__c` (`LN-00000`) | A booked loan | `Status__c` (Pending Funding → Active → Paid Off / Defaulted), `Loan_Product__c`, `Principal_Amount__c`, `Interest_Rate__c`, `Term_Months__c`, `Funding_Date__c`, `Maturity_Date__c` (formula: funding date + term). Repayment: `Principal_Paid__c` (roll-up: principal portion of Paid installments), `Total_Paid__c` (roll-up: all amounts paid), `Principal_Balance__c` (formula: principal − principal paid) |
| `Loan_Payment__c` (`PMT-000000`) | One scheduled installment on a loan, and what was paid against it | `Status__c` (Scheduled → Paid / Partially Paid / Missed), `Installment_Number__c`, `Due_Date__c`, `Amount_Due__c`, `Principal_Portion__c`, `Interest_Portion__c`, `Amount_Paid__c`, `Paid_Date__c`, `Payment_Method__c` (ACH, Wire, Check) |

- `Loan_Product__c` on both objects uses the `Loan_Product` global value set (Term Loan, Line of Credit, Equipment Financing), so the lists can't drift apart.
- Field history is tracked for `Status__c` on all three custom objects.
- Validation rules enforce:
  - positive amounts;
  - terms of 1–360 months;
  - a rate of at least 0% and below 100%;
  - a decision date on approved or declined applications;
  - a funding date once a loan leaves Pending Funding;
  - on payments: non-negative principal and interest portions that add up to the amount due when both are entered;
  - on payments: an amount paid and a paid date once an installment is Paid or Partially Paid, and a partial payment below the amount due.
- Applications and loans each have their own owner. Lookups are used so they don't inherit access from the Account (D-009). Payments are the exception: they have no owner and follow their loan (D-011).
- Nothing creates a `Loan__c` from an approved application, or generates a loan's payment schedule, yet. Users create both by hand.
- `Principal_Balance__c` only reduces for installments marked **Paid**. Partially paid installments count toward `Total_Paid__c` but not toward principal paid, because splitting a partial payment between principal and interest needs payment-application logic that doesn't exist yet.

## Data flows

There's no automation yet. Users create and edit records through the standard Lightning UI in the `CapitalFlow` app. Validation rules run on save. Saving a payment recalculates the loan's roll-ups, and with them `Principal_Balance__c`, on the platform without any custom code.

## Security boundaries

- **Organization-wide defaults:** `Loan_Application__c` and `Loan__c` are Private, both internally and externally (D-010). Users see the records they own, plus anything the role hierarchy or org-level permissions such as View All Data grant. Account and Contact sharing is whatever the org has configured. It hasn't been inspected and isn't in source.
- **Payments are Controlled by Parent:** anyone who can see a loan can see its payments, and editing a payment requires edit access to the loan.
- **Permission set `CapitalFlow_User`** (D-007):
  - Grants read on Account and Contact.
  - Grants full create/read/edit/delete on the three custom objects, without View All or Modify All.
  - Grants field access on every non-required custom field. Formula and roll-up fields (`Maturity_Date__c`, `Principal_Paid__c`, `Total_Paid__c`, `Principal_Balance__c`) are read-only.
  - Grants the three tabs and the app.
- **Required fields** aren't listed in the permission set, because their access can't be restricted.
- **New fields have no profile access.** Fields deployed from source aren't visible to any profile, including System Administrator, until the user is assigned `CapitalFlow_User`.
- **No sharing rules, roles, or Apex sharing** exist in source.

## Constraints and known limitations

- **No source tracking.** The Developer Edition org can't detect conflicts between local and org changes, so the repository is the only record of intended state.
- **Manifest covers only code types.** `manifest/package.xml` doesn't describe the full deployable surface (see D-006).
- **No CI.** Nothing automatically verifies that the repository matches the org or that tests pass.
- **Utility bar not in source.** The `CapitalFlow` app was first created in Setup, and its utility bar FlexiPage `CapitalFlow_UtilityBar` hasn't been retrieved. The app in source refers to it by name, so deploying the app to an org without that page fails. Retrieve it (`--metadata "FlexiPage:CapitalFlow_UtilityBar"`, Org change) before it's needed elsewhere.
- **Account layout not in source.** The two Account fields and the Loan Applications / Loans related lists aren't on the Account page layout. Deploying a layout from source would overwrite the org's copy, which hasn't been retrieved, so those additions have to be made in Setup for now.
