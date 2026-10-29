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
- Automation such as approval creating a loan, or payments updating `Outstanding_Principal__c`, has to be built later. Until then those values are entered by hand.
- With no master-detail, totals on Account need Apex or Flow, not roll-up summary fields.
- Payments, collateral, and guarantor junction objects are deferred to later branches.

---

### D-010: Private sharing for loan applications and loans

- **Status:** Proposed. It is already implemented in source because the plan included it, but it isn't confirmed as a lasting decision.
- **Basis:** Claude recommendation
- **Date:** 2026-10-28

**Context.** Loan applications and loans contain borrower financial information. Who can see a record should be a deliberate choice.

**Proposal.** Set the internal and external organization-wide defaults to **Private** on both objects. Widen access later with roles, sharing rules, or permission sets that grant View All, once roles such as loan officer and underwriter are defined. The `CapitalFlow_User` permission set grants object access but not View All or Modify All.

**Alternatives.** Public Read Only or Public Read/Write. These are simpler for a single-user demo org, but they don't reflect how a lender would protect borrower data. Tightening later is harder than loosening.

**Tradeoffs.** In a multi-user org, users only see records they own until sharing is added. In the Developer Edition org, the System Administrator sees everything through View All Data, so this has no practical effect today. Changing an OWD later triggers a sharing recalculation.

---

## Open questions

These need an owner decision, and some need more information, before a proposal makes sense:

- ~~**Business domain and data model.**~~ Resolved by D-009.
- **Apex layering.** Whether to separate services (business logic) and selectors (queries) from the start, or keep classes flat until complexity justifies more structure.
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
