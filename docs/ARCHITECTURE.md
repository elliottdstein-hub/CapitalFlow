# CapitalFlow Salesforce Org — Architecture

_Last updated: 2026-10-28_

This document describes the architecture as it is currently implemented. Setup and commands are in [DEVELOPMENT.md](DEVELOPMENT.md). The reasoning behind choices, and choices still open, is in [DECISIONS.md](DECISIONS.md). Coding standards are in `CLAUDE.md` §4.

## Purpose and scope

CapitalFlow is a small business lending application built on Salesforce (D-009). It covers borrowers, loan applications through the credit decision, and booked loans. Payments, approval automation, underwriting calculations, and a borrower portal are planned but **not implemented**.

## Current state

`force-app/main/default/` contains the first data model (from the `Create-Initial-Objects` branch). It's declarative only: custom objects and fields, validation rules, page layouts, tabs, a Lightning app, and one permission set. There is no Apex, no triggers, no LWC, no Flow, and no integrations yet.

This metadata was deployed to the Developer Edition org (`vscodeOrg`) on 2026-10-29 (deploy ID `0Afbm00000le4oDCAQ`), and `CapitalFlow_User` is assigned to the org's admin user. Since there is no source tracking, later changes made in the org won't appear here until they are retrieved.

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
| Data model (objects, fields, relationships) | `Loan_Application__c`, `Loan__c`, two Account fields, `Loan_Product` global value set | See Data model below |
| User interface | `CapitalFlow` Lightning app, for desktop and mobile; tabs and page layouts for both custom objects | Standard Lightning record pages. The app uses the utility bar `CapitalFlow_UtilityBar`, which exists only in the org (see Constraints) |
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
        └── Loan_Application__c → application lookup, delete restricted
```

| Object | Purpose | Key fields |
| --- | --- | --- |
| Account (standard) | The borrowing business. Reuses standard `Industry`, `AnnualRevenue`, `NumberOfEmployees` | `Business_Structure__c` (picklist), `Year_Established__c` |
| Contact (standard) | People at the borrower | — |
| `Loan_Application__c` (`APP-00000`) | A request for financing, from draft to credit decision | `Status__c` (Draft → Submitted → In Underwriting → Approved / Declined / Withdrawn), `Loan_Product__c`, `Loan_Purpose__c`, `Requested_Amount__c`, `Requested_Term_Months__c`, `Submitted_Date__c`, `Decision_Date__c`, `Decision_Notes__c` |
| `Loan__c` (`LN-00000`) | A booked loan | `Status__c` (Pending Funding → Active → Paid Off / Defaulted), `Loan_Product__c`, `Principal_Amount__c`, `Interest_Rate__c`, `Term_Months__c`, `Funding_Date__c`, `Maturity_Date__c` (formula: funding date + term), `Outstanding_Principal__c` |

- `Loan_Product__c` on both objects uses the `Loan_Product` global value set (Term Loan, Line of Credit, Equipment Financing), so the lists can't drift apart.
- Field history is tracked for `Status__c` on both objects.
- Validation rules enforce:
  - positive amounts;
  - terms of 1–360 months;
  - a rate of at least 0% and below 100%;
  - a decision date on approved or declined applications;
  - a funding date once a loan leaves Pending Funding.
- Each record has its own owner. Lookups are used instead of master-detail so applications and loans don't inherit access from the Account.
- Nothing creates a `Loan__c` from an approved application yet. Users create loans by hand. `Outstanding_Principal__c` is a plain field until payment processing exists.

## Data flows

There's no automation yet. Users create and edit records through the standard Lightning UI in the `CapitalFlow` app. Validation rules run on save.

## Security boundaries

- **Organization-wide defaults:** `Loan_Application__c` and `Loan__c` are Private, both internally and externally (D-010). Users see the records they own, plus anything the role hierarchy or org-level permissions such as View All Data grant. Account and Contact sharing is whatever the org has configured. It hasn't been inspected and isn't in source.
- **Permission set `CapitalFlow_User`** (D-007):
  - Grants read on Account and Contact.
  - Grants full create/read/edit/delete on both custom objects, without View All or Modify All.
  - Grants field access on every non-required custom field. `Maturity_Date__c` is read-only.
  - Grants the two tabs and the app.
- **Required fields** aren't listed in the permission set, because their access can't be restricted.
- **New fields have no profile access.** Fields deployed from source aren't visible to any profile, including System Administrator, until the user is assigned `CapitalFlow_User`.
- **No sharing rules, roles, or Apex sharing** exist in source.

## Constraints and known limitations

- **No source tracking.** The Developer Edition org can't detect conflicts between local and org changes, so the repository is the only record of intended state.
- **Manifest covers only code types.** `manifest/package.xml` doesn't describe the full deployable surface (see D-006).
- **No CI.** Nothing automatically verifies that the repository matches the org or that tests pass.
- **Utility bar not in source.** The `CapitalFlow` app was first created in Setup, and its utility bar FlexiPage `CapitalFlow_UtilityBar` hasn't been retrieved. The app in source refers to it by name, so deploying the app to an org without that page fails. Retrieve it (`--metadata "FlexiPage:CapitalFlow_UtilityBar"`, Org change) before it's needed elsewhere.
- **Account layout not in source.** The two Account fields and the Loan Applications / Loans related lists aren't on the Account page layout. Deploying a layout from source would overwrite the org's copy, which hasn't been retrieved, so those additions have to be made in Setup for now.
