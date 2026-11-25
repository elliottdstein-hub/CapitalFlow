# Technical Decisions

Significant technical decisions for the CapitalFlow Salesforce project, and why they were made. Entries are never deleted. When a decision is replaced, its status changes to **Superseded**, with a link to the entry that replaces it.

Each entry records its **basis**, meaning where the decision came from:

- **Owner decision**: stated explicitly by the project owner.
- **Inherited**: the current state of the repository (usually the Salesforce DX scaffold), not a deliberate choice. Confirm or replace it.
- **Claude recommendation**: proposed by Claude. It's only a suggestion while its status is Proposed. Once the owner accepts it, the basis reads "accepted by owner".

## Index

| ID | Title | Status | Basis |
| --- | --- | --- | --- |
| [D-001](#d-001-org-and-repository-changes-require-explicit-authorization) | Org and repository changes require explicit authorization | Accepted | Owner decision |
| [D-002](#d-002-prefer-native-platform-features-no-unapproved-frameworks) | Prefer native platform features; no unapproved frameworks | Accepted | Owner decision |
| [D-003](#d-003-developer-edition-org-as-the-primary-environment) | Developer Edition org as the primary environment | Accepted | Owner decision |
| [D-004](#d-004-org-based-development-with-a-single-package-directory) | Org-based development with a single package directory | Accepted | Inherited |
| [D-005](#d-005-raise-the-source-api-version-before-creating-metadata) | Raise the source API version before creating metadata | Accepted | Claude recommendation, accepted by owner |
| [D-006](#d-006-deploy-by-source-directory-not-by-the-current-manifest) | Deploy by source directory, not by the current manifest | Accepted | Claude recommendation, accepted by owner |
| [D-007](#d-007-grant-access-through-permission-sets-not-profiles) | Grant access through permission sets, not profiles | Accepted | Claude recommendation, accepted by owner |
| [D-008](#d-008-one-logic-less-trigger-per-object-with-a-handler-class) | One logic-less trigger per object, with a handler class | Accepted | Claude recommendation, accepted by owner |
| [D-009](#d-009-small-business-lending-data-model) | Small business lending data model | Accepted | Owner decision (scope); Claude recommendation, accepted by owner (field design) |
| [D-010](#d-010-private-sharing-for-loan-applications-and-loans) | Private sharing for loan applications and loans | Proposed | Claude recommendation |
| [D-011](#d-011-payments-as-a-master-detail-child-of-loan-with-a-calculated-balance) | Payments as a master-detail child of Loan, with a calculated balance | Accepted | Owner decision (scope, balance); Claude recommendation, accepted by owner (structure) |
| [D-012](#d-012-guarantors-as-a-master-detail-child-of-loan-application) | Guarantors as a master-detail child of Loan Application | Proposed | Owner decision (scope); Claude recommendation (structure) |
| [D-013](#d-013-collateral-underwriting-reviews-required-documents-and-covenants) | Collateral, underwriting reviews, required documents, and covenants | Proposed | Owner decision (which objects); Claude recommendation (design) |
| [D-014](#d-014-financial-statements-disbursements-fees-and-payment-transactions) | Financial statements, disbursements, fees, and payment transactions | Proposed | Owner decision (which objects); Claude recommendation (design) |
| [D-015](#d-015-apex-layering-thin-controllers-and-service-classes) | Apex layering: thin controllers and service classes | Accepted | Claude recommendation, accepted by owner |
| [D-016](#d-016-borrower-loan-application-form-with-server-side-applicant-and-status) | Borrower loan application form with server-side applicant and status | Accepted | Owner decision (borrower first, scope, Apex, no Jest yet); Claude recommendation, accepted by owner (design) |

Questions that have no proposal yet are listed under [Open questions](#open-questions).

---

### D-001: Org and repository changes require explicit authorization

- **Status:** Accepted
- **Basis:** Owner decision, documented in `CLAUDE.md` §2
- **Date:** Not recorded. Present in `CLAUDE.md` as of 2026-10-28.

**Context.** The project is developed mostly with Claude Code against an org that is not treated as disposable.

**Decision.** Nothing changes an org or publishes repository history without explicit authorization in the current conversation. This covers deploys, validations and dry runs, retrieves that overwrite local work, anonymous Apex, data changes, org configuration, commits, and pushes. Local inspection and local checks are allowed without asking.

**Alternatives considered.** Not recorded.

**Consequences.** Development is a local-first loop with manual promotion. Any future CI pipeline that deploys automatically would conflict with this decision and needs its own entry. [DEVELOPMENT.md](DEVELOPMENT.md) tags each command by its safety level to make this rule easy to apply.

---

### D-002: Prefer native platform features; no unapproved frameworks

- **Status:** Accepted
- **Basis:** Owner decision, documented in `CLAUDE.md` §1 and §6
- **Date:** Not recorded. Present in `CLAUDE.md` as of 2026-10-28.

**Context.** Third-party frameworks and abstractions add maintenance cost and learning overhead to a small project.

**Decision.** Use native Salesforce functionality and established platform conventions first. Do not introduce frameworks, packages, or major architectural patterns without the owner's approval.

**Alternatives considered.** Not recorded.

**Consequences.** Choices such as a trigger framework (D-008), Apex layering, or new npm dependencies each need explicit approval before they are adopted.

---

### D-003: Developer Edition org as the primary environment

- **Status:** Accepted
- **Basis:** Owner decision
- **Date:** Originally stated in an earlier version of `CLAUDE.md` (date not recorded). Reconfirmed by the owner on 2026-10-28.

**Context.** The project needs one org to develop against.

**Decision.** A Salesforce Developer Edition org is the primary development environment.

**Alternatives considered.** Scratch orgs from a Dev Hub. A scratch definition exists in `config/project-scratch-def.json`, but no Dev Hub is configured.

**Consequences.** Developer Edition orgs do not support source tracking. Conflict detection between local and org changes is therefore unavailable, and every deploy and retrieve must name its scope explicitly (see D-006). Because the org is long-lived, mistakes are not wiped by recreating it.

---

### D-004: Org-based development with a single package directory

- **Status:** Accepted
- **Basis:** Inherited from the Salesforce DX project scaffold; not an explicit decision
- **Date:** Not recorded.

**Context.** Salesforce DX supports org-based development (deploying metadata directly) and package-based development (unlocked or managed packages).

**Current state.** `sfdx-project.json` defines one package directory, `force-app`, with no namespace and no package ID. Metadata is deployed directly to the org.

**Alternatives.** Unlocked packages, which give versioned, installable units with explicit dependencies but need a Dev Hub and extra release steps. A namespace, which can't be removed once metadata is created under it.

**Consequences.** This is the simplest model for a single org. If the project later needs to ship to several orgs, moving to unlocked packages would be a significant change and needs a new decision entry.

---

### D-005: Raise the source API version before creating metadata

- **Status:** Accepted. Applied on 2026-10-29: `sourceApiVersion` and the manifest version are now 68.0, the version `sf org display` reported for the Developer Edition org. The first objects (D-009) were written before the version was checked. Their source files carry no API version of their own, so they needed no changes.
- **Basis:** Claude recommendation, accepted by the owner
- **Date:** Proposed and accepted 2026-10-28

**Context.** `sfdx-project.json` sets `sourceApiVersion` to `59.0` (Winter '24), and `manifest/package.xml` uses the same version. The installed CLI and the org support newer versions. Metadata created at 59.0 can't use newer metadata fields or features.

**Proposal.** Before the first custom objects are created, set `sourceApiVersion` (and the manifest version) to the org's current API version. Find that version with `sf org display`, which is an org read and needs authorization.

**Alternatives.** Keep 59.0 and upgrade later. This works, but it means touching every file's `-meta.xml` version later, or living with mixed versions.

**Tradeoffs.** It's a near-free change while there is no metadata. The cost grows as metadata is added.

---

### D-006: Deploy by source directory, not by the current manifest

- **Status:** Accepted
- **Basis:** Claude recommendation, accepted by the owner
- **Date:** Proposed and accepted 2026-10-28

**Context.** `manifest/package.xml` lists only code types. A manifest-based deploy or retrieve would silently skip custom objects, fields, permission sets, flows, and layouts. That is exactly the metadata the `Create-Initial-Objects` work introduces.

**Proposal.** Deploy with `--source-dir` (or `--metadata` for single components) and retrieve with `--metadata`. Keep `manifest/package.xml` only as a generated artifact (`sf project generate manifest --source-dir force-app`) when a manifest is actually needed.

**Alternatives.** (a) Hand-maintain the manifest to list every type in use. This is error-prone, because a forgotten type fails silently. (b) Use wildcard entries for declarative types. This is still incomplete: a `CustomObject` wildcard doesn't include standard objects, so custom fields on objects like Account must be listed by name.

**Tradeoffs.** Directory-based deploys send everything under the path, so you must scope the path deliberately. The manifest approach gives an explicit list but drifts out of date.

---

### D-007: Grant access through permission sets, not profiles

- **Status:** Accepted
- **Basis:** Claude recommendation, accepted by the owner
- **Date:** Proposed and accepted 2026-10-28

**Context.** New custom objects and fields need object and field-level access. `CLAUDE.md` asks to avoid unnecessary changes to profiles and org-wide configuration.

**Proposal.** Grant access to new objects, fields, Apex classes, and tabs through permission sets (grouped into permission set groups if needed), stored in `force-app/main/default/permissionsets/`. Keep profiles out of source control.

**Alternatives.** Editing profiles directly. Salesforce is steering away from this, profile metadata is large and deploys unpredictably, and it couples access to user licenses.

**Tradeoffs.** Users need permission set assignments, which are record changes in the org and require authorization. In return, access is additive, reviewable, and limited to this project's metadata.

---

### D-008: One logic-less trigger per object, with a handler class

- **Status:** Accepted
- **Basis:** Claude recommendation, accepted by the owner
- **Date:** Proposed and accepted 2026-10-28

**Context.** No triggers exist yet. Without a convention, logic ends up spread across multiple triggers per object, whose execution order is not guaranteed.

**Proposal.** At most one trigger per object, containing no logic. It delegates to an `<Object>TriggerHandler` Apex class that handles each event in bulk. This is a small in-house pattern with no third-party framework, consistent with D-002. Prefer Flow for simple field updates where it fits, and record where Flow is used versus Apex in ARCHITECTURE.md.

**Alternatives.** (a) A third-party trigger framework, which brings features such as bypass switches and recursion control but adds a dependency (needs approval under D-002). (b) Logic directly in triggers, which is hard to test and reuse.

**Tradeoffs.** One extra class per object. Recursion control and bypass switches would have to be added in-house if they're ever needed.

---

### D-009: Small business lending data model

- **Status:** Accepted
- **Basis:** Owner decision for the domain, borrower model, pipeline object, and first-branch scope. Claude recommendation, accepted by the owner through plan approval, for the field-level design.
- **Date:** 2026-10-28

**Context.** CapitalFlow is a Salesforce-first portfolio lending application. Later stages may add an external Python/PostgreSQL service. The first branch needs a data model that later work can build on: approval automation, payments, underwriting calculations, and a borrower portal.

**Decision.**
- **Domain:** small business lending, offering term loans, lines of credit, and equipment financing.
- **Borrowers:** standard **Account** for the business and **Contact** for its people. This keeps native features (activities, reports, duplicate rules) and leaves a path to Experience Cloud portal users.
- **Pipeline:** a custom **`Loan_Application__c`**, from draft through the credit decision, and a separate custom **`Loan__c`** for booked loans. `Loan__c` links back to its application.
- **Relationships:** lookups, not master-detail. Borrower lookups are required and block deletion of an Account that has applications or loans.
- **Product list:** one global value set, `Loan_Product`, shared by both objects.

**Alternatives considered.**
- **Opportunity as the pipeline.** Rejected by the owner. It forces lending semantics onto a sales object.
- **Person Accounts.** Not suitable for business borrowers, and the setting is irreversible.
- **A custom Borrower object.** Loses native Account/Contact features.
- **Master-detail relationships.** Child records would inherit sharing from the Account, which conflicts with D-010. Roll-up summaries would be the main thing lost.

**Consequences.**
- Automation such as approval creating a loan, or payments updating `Outstanding_Principal__c`, has to be built later. Until then those values are entered by hand. (Update 2026-11-24: `Outstanding_Principal__c` was replaced by a calculated balance; see D-011.)
- With no master-detail, totals on Account need Apex or Flow, not roll-up summary fields.
- Payments, collateral, and guarantor junction objects are deferred to later branches. (Update: payments added in D-011, guarantors in D-012, collateral in D-013.)

---

### D-010: Private sharing for loan applications and loans

- **Status:** Proposed. It is already implemented in source because the plan included it, but it isn't confirmed as a lasting decision.
- **Basis:** Claude recommendation
- **Date:** 2026-10-28

**Context.** Loan applications and loans contain borrower financial information. Who can see a record should be a deliberate choice.

**Proposal.** Set the internal and external organization-wide defaults to **Private** on both objects. Widen access later with roles, sharing rules, or permission sets that grant View All, once roles such as loan officer and underwriter are defined. The `CapitalFlow_User` permission set grants object access but not View All or Modify All.

**Alternatives.** Public Read Only or Public Read/Write. These are simpler for a single-user demo org, but they don't reflect how a lender would protect borrower data. Tightening later is harder than loosening.

**Tradeoffs.** In a multi-user org, users only see records they own until sharing is added. Payments (D-011) don't have their own sharing model and inherit their loan's. In the Developer Edition org, the System Administrator sees everything through View All Data, so this has no practical effect today. Changing an OWD later triggers a sharing recalculation.

---

### D-011: Payments as a master-detail child of Loan, with a calculated balance

- **Status:** Accepted
- **Basis:**
  - Owner decision: add payments next, and replace the hand-entered `Outstanding_Principal__c` with a calculated balance.
  - Claude recommendation, accepted by the owner: the object structure.
- **Date:** 2026-11-24

**Context.** Loans need a repayment record. The loan's remaining principal was a plain currency field, `Outstanding_Principal__c`, typed in by hand. Salesforce can't turn an existing field into a formula.

**Decision.**
- **One record per installment.** `Loan_Payment__c` holds the schedule (due date, amount due, principal/interest split) and the receipt (amount paid, paid date, method) together.
- **Master-detail to `Loan__c`.** This is an exception to the lookups-only approach in D-009. A payment has no meaning without its loan and no owner of its own, so it follows the loan's sharing and is deleted with it. Master-detail is also what makes roll-up summary fields possible.
- **Calculated balance.**
  - Two roll-ups on `Loan__c`: `Principal_Paid__c` sums the principal portion of installments with status Paid. `Total_Paid__c` sums every amount paid.
  - `Principal_Balance__c` is a formula: principal minus principal paid.
  - `Outstanding_Principal__c` is removed. In the org that needs a destructive deploy, which needs authorization, and any values entered in that field are lost.

**Alternatives considered.**
- **Keep `Outstanding_Principal__c` beside the new balance.** It preserves data, but two balance fields can disagree.
- **Keep it manual until Apex exists.** No automatic balance in the meantime.
- **Separate schedule and transaction objects.** These would allow several payments against one installment, or a payment covering several installments. That's more realistic, but more than a portfolio stage-1 app needs. Revisit when payment processing is built. (Update: `Payment_Transaction__c` was added alongside the schedule in D-014.)
- **Lookup instead of master-detail.** Keeps payments independently shareable, but loses native roll-ups.

**Consequences.**
- A partial payment counts toward `Total_Paid__c` but not `Principal_Paid__c`, because nothing splits it between principal and interest yet.
- Payment schedules are entered by hand until an amortization generator is built (Apex, per D-008).
- A payment can't be moved to another loan (`reparentableMasterDetail` is false).
- Deleting a loan deletes its payments.

---

### D-012: Guarantors as a master-detail child of Loan Application

- **Status:** Proposed. It's implemented in source but not deployed. The owner chose to add guarantors; the structure below hasn't been confirmed yet.
- **Basis:**
  - Owner decision: add guarantors next.
  - Claude recommendation: the structure.
- **Date:** 2026-11-24

**Context.** Small business lenders usually require personal guarantees from significant owners, typically anyone with 20% or more. Sometimes they also require a corporate guarantee from a parent or affiliate company. Guarantors are agreed during underwriting, so they belong with the application.

**Proposal.**
- **One record per guarantee.** `Guarantor__c` is a master-detail child of `Loan_Application__c`. Like payments (D-011), a guarantee has no meaning without its application. It follows the application's sharing and is deleted with it. Master-detail also allows roll-ups.
- **People or businesses.** A `Guarantee_Type__c` picklist chooses between them, with two lookups: `Guarantor_Contact__c` for personal guarantees and `Guarantor_Account__c` for corporate guarantees. Validation rules require exactly the one that matches the type. The lookups block deleting a Contact or Account that is a guarantor.
- **Coverage.** Coverage is Unlimited or Limited. Limited needs a `Guaranteed_Amount__c` cap. Signing is tracked with Pending, Signed and Released statuses and a signed date.
- **Roll-ups on the application:** `Guarantor_Count__c` counts guarantors that aren't Released. `Guaranteed_Ownership__c` totals the ownership % of signed personal guarantors (corporate guarantees are excluded), so a reviewer can see whether owners have signed.

**Alternatives considered.**
- **Contact only.** Simpler, but it can't represent a corporate guarantee.
- **Master-detail to both the application and the Contact (a classic junction).** That would require a business guarantor to be a Contact. Access to a guarantee would also depend on access to the Contact.
- **Guarantees on `Loan__c` instead of, or as well as, the application.** The loan links back to its application, so its guarantees can be found from there. Copying them onto the loan at booking can come with the approval-to-loan automation if it's needed.
- **Use the standard Contact–Account relationship.** That records who works for a business, not who guaranteed which application.

**Consequences.**
- Nothing prevents adding the same guarantor to one application twice. A unique key kept up to date by automation would be needed.
- The borrower's own Account can't be added as a guarantor (validation rule).
- The Guarantees related lists on Account and Contact aren't on their page layouts, because those layouts aren't in source.
- Nothing enforces a guarantee policy, such as requiring 20% owners to sign before approval. The roll-ups make it visible, and enforcing it would be later automation.

---

### D-013: Collateral, underwriting reviews, required documents, and covenants

- **Status:** Proposed. Built in source but not yet deployed or confirmed by the owner.
- **Basis:**
  - Owner decision: add all four objects (collateral, underwriting review, required document, loan covenant).
  - Claude recommendation: the field-level design and where each object attaches.
- **Date:** 2026-11-25

**Context.** The application had a credit decision (`Status__c`, `Decision_Notes__c`) with nothing behind it: no record of what secured the loan, what analysis supported the decision, which documents were collected, or what the borrower must keep doing after funding.

**Proposal.**
- **Same pattern as D-011 and D-012:** each object is a master-detail child, so it has no owner, follows its parent's sharing, is deleted with the parent, and can't be reparented. Master-detail also enables the roll-ups.
- **`Collateral__c` on the application.** Collateral is identified and valued during underwriting. `Lendable_Value__c` applies an advance rate per asset. The application rolls up `Total_Collateral_Value__c` (excluding Released items) and calculates `Loan_To_Value__c` from the requested amount.
- **`Underwriting_Review__c` on the application,** allowing more than one review (for example, a re-review after the terms change). Metrics are entered by the reviewer. A completed review must have a recommendation, risk rating, and date.
- **`Required_Document__c` on the application,** one record per checklist item. The files themselves aren't stored in custom fields: they would be attached with standard Salesforce Files. The Files related list isn't on the layout yet. The application counts outstanding (Requested or Rejected) items.
- **`Loan_Covenant__c` on the loan,** because covenants apply after funding and are tested for the loan's life. The loan counts covenants In Breach. The record holds only the latest test result.

**Alternatives considered.**
- **Collateral on `Loan__c`, or a junction so one asset can secure several loans** (cross-collateralization). More realistic for a large lender. Deferred: it would need a junction object and per-loan allocation of value.
- **Underwriting metrics as fields on `Loan_Application__c`.** Simpler, but loses the history of multiple reviews and who did each.
- **Calculating DSCR and other metrics from financial-statement records.** Needs a financial spreading model; out of scope for now.
- **A covenant test history object** (one record per test). Gives a full audit trail; deferred until test scheduling exists. Field history on `Compliance_Status__c` keeps a basic trail meanwhile.
- **Lookups instead of master-detail.** Independent sharing, but no native roll-ups, and none of these records needs sharing different from its parent.

**Tradeoffs.**
- `Loan_To_Value__c` uses the requested amount, not the booked principal, and counts Proposed as well as Pledged collateral. It is blank when there is no collateral.
- Nothing enforces policy yet: a maximum LTV, a completed review, or verified documents before approval would need validation rules on the application or automation (D-008).
- Covenant test dates aren't scheduled or advanced automatically, and breaches don't notify anyone.
- `Loan__c` now has two master-detail children, and `Loan_Application__c` has four. That's within platform limits, but each new roll-up counts toward the per-object roll-up limit.

---

### D-014: Financial statements, disbursements, fees, and payment transactions

- **Status:** Proposed. Built in source but not yet deployed or confirmed by the owner.
- **Basis:**
  - Owner decision: add these four objects.
  - Claude recommendation: the field-level design and where each object attaches.
- **Date:** 2026-11-25

**Context.** Underwriting metrics were typed in with nothing behind them. Booked loans had no record of money going out, money actually coming in (as opposed to the installment schedule), or charges other than principal and interest.

**Proposal.**
- **Same pattern as D-011 to D-013:** each object is a master-detail child, so it has no owner, follows its parent's sharing, is deleted with the parent, and enables roll-ups.
- **`Financial_Statement__c` on the application,** one record per period. Formulas calculate EBITDA, DSCR (EBITDA ÷ annual debt service), net worth, and debt-to-worth from the entered figures.
- **`Disbursement__c` on the loan.** The loan rolls up `Total_Disbursed__c` (Completed only) and calculates `Undisbursed_Amount__c`. A validation rule on `Loan__c` stops completed disbursements exceeding the principal, except on lines of credit, where repaid amounts can be drawn again.
- **`Fee__c` on the loan,** with an optional lookup to the installment (required for late and returned payment fees), filtered to installments on the same loan. The loan rolls up fees outstanding and fees paid.
- **`Payment_Transaction__c` on the loan,** one record per receipt, with an optional, same-loan installment lookup and fields showing how the money was split between principal, interest, and fees. The loan rolls up `Total_Received__c` (Cleared only).
- **Installment lookups clear rather than block** (`SetNull`), so deleting an installment doesn't fail because a fee or transaction points to it.
- **`Loan_Payment__c` and its roll-ups are unchanged.** Transactions sit beside the schedule instead of replacing how the balance is calculated.

**Alternatives considered.**
- **Financial statements on Account,** so a returning borrower's history is reused across applications. More realistic, but master-detail to Account would make access follow Account sharing (at odds with D-009 and D-010), and a lookup loses roll-ups. Revisit with a borrower-level view.
- **Calculating the balance from transactions instead of installments.** The right end state, but it needs payment-application logic (Apex, per D-008) to split each receipt across installments and fees. Changing the existing balance roll-ups now would break D-011's behavior without that logic.
- **Fees as installment fields.** Can't represent origination or documentation fees, or more than one fee per installment.
- **One money-movement object for draws and receipts.** Fewer objects, but it mixes outgoing and incoming money, which have different fields and statuses.

**Tradeoffs.**
- Until payment application is automated, users must update both the transaction and the installment, and the two can disagree. `Total_Received__c` and `Total_Paid__c` may differ.
- `Undisbursed_Amount__c` ignores repayments, so on a line of credit it isn't the available credit.
- DSCR on a financial statement and DSCR on an underwriting review are separate, unlinked fields.
- `Loan__c` now has seven roll-up summary fields, within the per-object limit.

---

### D-015: Apex layering: thin controllers and service classes

- **Status:** Accepted
- **Basis:** Claude recommendation, accepted by the owner on 2026-11-25. This resolves the "Apex layering" open question.
- **Date:** 2026-11-25

**Context.** The first Apex is being written for the loan application form. Without a convention, business rules end up inside `@AuraEnabled` methods, where Flows, triggers, or future APIs can't reuse them.

**Decision.**
- **Controllers** (`<Feature>Controller`) are the only `@AuraEnabled` entry points. They convert between component data and records, call a service, and turn exceptions into user-safe `AuraHandledException` messages. They contain no business rules.
- **Services** (`<Feature>Service`, `with sharing`) hold the business rules and run queries and DML in user mode.
- **No separate selector (query) layer yet.** Queries live in the service until the same query is needed in several places.
- **Triggers** still follow D-008: they delegate to a handler, which can call services.

**Alternatives considered.**
- **A single controller class.** Simplest now, but the rules would have to be pulled out later for reuse.
- **Full service, selector, and domain layers** (for example fflib). That's a third-party framework under D-002, and too much structure for the current size.

**Consequences.** Two classes and two test classes per feature. Services can be called from future triggers, Flow actions, or REST endpoints without changes.

---

### D-016: Borrower loan application form with server-side applicant and status

- **Status:** Accepted. Deployed to the Developer Edition org on 2026-11-25.
- **Basis:**
  - Owner decisions: build the borrower-facing form first; v1 covers only the loan request; use an Apex controller rather than Lightning Data Service alone; skip LWC Jest tests for now.
  - Claude recommendation, accepted by the owner through plan approval: the design below.
- **Date:** 2026-11-25

**Context.** Borrowers will eventually apply through an Experience Cloud site. No site, portal licenses, or portal users exist yet. `Loan_Application__c.Status__c` is a required field, so field-level security can't stop a user with edit access from setting it to Approved.

**Decision.**
- **One LWC, `loanApplicationForm`.** It shows the applicant's business read-only, and lets the borrower edit product, purpose, amount, and term, then Save draft or Submit. It targets Contact record pages, so it can be tested internally now, and Experience Cloud pages for later.
- **The server decides who the applicant is.**
  - A portal user's own Contact, from `User.ContactId`. The browser can't override it.
  - Otherwise, the Contact id the component passes, which is its record page's `recordId`.
- **The server owns borrower, primary contact, status, and submitted date.** The browser sends only the four loan request fields. Drafts can be edited only by their own business and only while they're Draft. Submit saves and changes status in one update.
- **Everything runs as the user.** Apex is `with sharing`, with user-mode queries and DML.
- **Messages appear inside the form.** Toasts don't work in Experience Cloud.

**Alternatives considered.**
- **Lightning Data Service only (`lightning-record-edit-form`).** Less code, but the browser would supply borrower and status.
- **A multi-step wizard** covering financials, guarantors, and documents. Rejected for v1, to get one path working end to end first.

**Consequences.**
- Status is protected only on this code path. Before portal users get edit access to `Loan_Application__c`, add a validation rule (or another control) that limits status changes by external users.
- A borrower permission set (object and field access, Apex class access) is still to be created with the portal.
- The portal-user path (`User.ContactId`) isn't covered by Apex tests, because tests can't create portal users without a portal license and site. Only the internal path and permission-set access are tested.
- There are no LWC Jest tests until `npm install` is fixed. The component is tested manually.

---

## Open questions

These need an owner decision, and some need more information, before a proposal makes sense:

- ~~**Business domain and data model.**~~ Resolved by D-009.
- ~~**Apex layering.**~~ Resolved by D-015.
- **Scratch orgs.** Whether to also use scratch orgs for feature work, alongside the Developer Edition org that remains primary (D-003). This would require enabling Dev Hub.
- **Continuous integration.** Whether to add a pipeline for formatting, linting, and LWC tests, and whether it may contact an org (affects D-001).

## Entry template

```markdown
### D-NNN: <Title>

- **Status:** Proposed | Accepted | Superseded by D-NNN | Rejected
- **Basis:** Owner decision | Inherited | Claude recommendation
- **Date:** <YYYY-MM-DD, or "Not recorded">

**Context.** <The problem and constraints.>

**Decision / Proposal.** <What was decided or proposed, and why.>

**Alternatives considered.** <Options and why they weren't chosen.>

**Consequences / Tradeoffs.** <What this makes easier or harder.>
```
