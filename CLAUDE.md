# CLAUDE.md — Project Instructions

## 1. Project Overview

This is a Salesforce DX project developed primarily with Claude Code.

The project uses Apex, Lightning Web Components (LWC), Salesforce metadata, Salesforce CLI (`sf`), Git, and Markdown documentation.

Prefer native Salesforce functionality and established platform conventions. Prioritize maintainability, security, testability, and a clean user experience. Avoid unnecessary dependencies and abstractions.

## 2. Critical Safety Rules

These rules take priority over convenience and speed.

### Salesforce Org Protection

- NEVER deploy, push, or apply local changes to any Salesforce org without my explicit authorization in the current conversation.
- NEVER execute anonymous Apex against an org without explicit authorization.
- NEVER create, update, or delete Salesforce records without explicit authorization.
- NEVER modify org configuration, permissions, users, connected apps, or other org settings without explicit authorization.
- NEVER execute destructive metadata operations without explicit authorization.
- Do not retrieve or overwrite org metadata in a way that could replace local work without reviewing the impact.
- Treat every connected org as valuable, including Developer Edition orgs.
- Do not run org-changing commands simply to explore the environment.
- Commands such as `sf project deploy start`, `sf project deploy validate`, `sf project retrieve start`, and commands that execute anonymous Apex or modify org data require authorization. Dry runs and validations that contact an org also require authorization.
- You may inspect local source code and run safe local checks without asking each time.

### Git Protection

- NEVER run `git commit`, `git push`, or publish changes without my explicit authorization.
- NEVER amend commits, rewrite history, rebase, reset, or discard existing work without explicit authorization.
- NEVER overwrite or revert my changes.
- Inspect `git status` and relevant diffs before substantial changes.
- Do not assume uncommitted changes were created by you.
- You may inspect Git history and diffs without permission.

### Terminal and Tool Permissions

- Follow configured Claude Code permissions.
- Request approval for commands that could affect an org, repository, credentials, external services, or user data.
- Do not bypass permission prompts or disable safeguards.
- Understand unfamiliar scripts before running them.
- Explain why a restricted action is necessary and wait for approval.

### Secrets and Sensitive Data

- Never expose or commit passwords, access tokens, private keys, session credentials, or other secrets.
- Never place secrets in source code, documentation, logs, or example configurations.
- Keep authentication files and sensitive configuration out of Git.
- Use placeholders in documentation.
- Do not include real customer or personal data in tests unless explicitly required and authorized.

## 3. Required Development Workflow

For each substantial task:

### Step 1: Inspect

- Read relevant source files and existing tests.
- Review `docs/ARCHITECTURE.md` before architectural changes.
- Review `docs/DEVELOPMENT.md` before changing development or testing workflows.
- Review `docs/DECISIONS.md` when existing technical decisions are relevant.
- Inspect metadata, naming conventions, and related implementations.
- Check Git status before modifying files.
- Do not assume repository or org contents without verifying them.

### Step 2: Plan

For substantial changes:
- Explain the problem and proposed solution.
- Identify files and components likely to change.
- Identify dependencies, security implications, and testing requirements.
- Flag conflicts with documented decisions.
- Ask before proceeding when a significant architectural choice is unclear.

For small changes, avoid unnecessary planning overhead.

### Step 3: Implement

- Make focused changes that solve the requested problem.
- Follow existing conventions and preserve behavior unless instructed otherwise.
- Avoid unrelated refactoring, unnecessary dependencies, and duplicated logic.
- Update relevant tests and documentation alongside implementation.

### Step 4: Validate

- Run appropriate local checks and tests that do not modify a connected org.
- Use available formatters, linters, and static analysis tools.
- Do not run org-dependent commands without authorization.
- If validation requires an org, explain what needs to run and ask permission.
- Never claim tests passed unless they actually ran successfully.
- Identify checks that were skipped, failed, or could not be performed.

### Step 5: Review

- Inspect the final diff.
- Check for unintended changes, security issues, missing tests, and regressions.
- Ensure documentation reflects meaningful architectural or workflow changes.
- Summarize changes, validation, and remaining work.
- Do not commit or deploy without explicit authorization.

## 4. Salesforce Development Standards

### Apex

- Follow bulkification best practices.
- Avoid SOQL and DML inside loops.
- Use bind variables and safe query construction to prevent SOQL injection.
- Respect CRUD, field-level security, and record-level sharing.
- Use appropriate sharing declarations and access controls.
- Handle errors deliberately and return useful, sanitized messages.
- Avoid swallowing exceptions or logging sensitive data.
- Write meaningful unit tests with assertions, including failure cases.
- Avoid relying on existing org records for test setup unless necessary.
- Consider governor limits, transaction boundaries, and asynchronous processing.

### Lightning Web Components

- Follow standard LWC conventions and use Lightning Base Components when suitable.
- Keep components focused and maintainable.
- Separate UI concerns from server-side business logic where practical.
- Use `@api`, reactive state, lifecycle hooks, and events appropriately.
- Handle loading, empty, success, and error states.
- Validate user input and provide accessible feedback.
- Avoid unnecessary Apex calls and redundant data loading.
- Use secure communication patterns and do not expose sensitive information.
- Follow Salesforce security guidance for rendering user-provided content.

### Salesforce Metadata

- Use standard Salesforce DX source format.
- Follow existing naming conventions and directory structure.
- Keep metadata changes focused.
- Do not assume local metadata and deployed org metadata are identical.
- Avoid unrelated changes to profiles, permission sets, sharing, and org-wide configuration.
- Consider dependencies and deployment order.
- Investigate metadata before deleting or replacing it.

### Testing and Quality

- Test observable behavior rather than implementation details.
- Include positive, negative, and boundary cases.
- Avoid brittle tests and execution-order dependencies.
- Keep test data isolated and deterministic.
- Do not weaken assertions or remove tests just to make a suite pass.
- Explain limitations caused by the absence of an authorized org.

## 5. Project Documentation

Maintain these files under `docs/`:

- `docs/ARCHITECTURE.md`
- `docs/DEVELOPMENT.md`
- `docs/DECISIONS.md`

Consult relevant documentation before changes. Create documents when needed. Keep them accurate, concise, and consistent with the implementation.

Never describe proposed functionality as already implemented.

### 5.1 Architecture Documentation

File: `docs/ARCHITECTURE.md`

Purpose: Describe the current architecture and how components work together.

Document where applicable:
- Application purpose and scope.
- Major components and responsibilities.
- Apex classes, services, controllers, and relationships.
- LWC hierarchy and responsibilities.
- Data flows between UI, Apex, Salesforce objects, and integrations.
- Important objects, relationships, and data ownership.
- External integrations and dependencies.
- Security boundaries and access controls.
- Significant asynchronous processes and automation.
- Architectural constraints and known limitations.

Maintenance:
- Read this document before significant architectural changes.
- Update it when components, data flows, integrations, security boundaries, or responsibilities materially change.
- Update documentation in the same task as implementation.
- Skip trivial UI changes and bug fixes that do not affect architecture.
- Document the current implementation, not speculative plans.
- Avoid duplicating setup instructions or the full decision history.
- Investigate discrepancies between documentation and code; correct documentation when the implementation is authoritative.

### 5.2 Development Documentation

File: `docs/DEVELOPMENT.md`

Purpose: Explain how developers set up, validate, and work on the project.

Document where applicable:
- Prerequisites and required tools.
- Salesforce CLI and project setup.
- Repository structure and important directories.
- Local configuration, using placeholders for secrets.
- Safe local checks and tests.
- Salesforce-specific tests when an authorized org is available.
- How to work with the configured org.
- Deployment procedures, prerequisites, and authorization requirements.
- Troubleshooting.
- Relevant scripts and their purposes.

Maintenance:
- Read this document before changing setup or workflows.
- Update it when prerequisites, commands, project structure, tests, or developer workflows materially change.
- Verify commands against the actual project and installed CLI version.
- Distinguish local-only operations from org-connected operations.
- Mark org-dependent procedures as requiring explicit authorization.
- Never include real credentials.
- Do not invent commands or claim unverified procedures work.

### 5.3 Technical Decision Documentation

File: `docs/DECISIONS.md`

Purpose: Record significant technical decisions and why they were made.

For each meaningful decision, include:
- Title.
- Status: proposed, accepted, superseded, or rejected.
- Date, when known.
- Context and problem.
- Decision and rationale.
- Alternatives considered.
- Tradeoffs and consequences.

Maintenance:
- Record decisions that materially affect architecture, maintainability, security, dependencies, data modeling, or future development.
- Do not create entries for trivial implementation choices.
- Flag conflicts with accepted decisions and explain implications before proceeding.
- Ask when a significant decision requires my input.
- Update decision status and rationale when they change.
- Mark replaced decisions as superseded and preserve history.
- Do not invent dates, approvals, or decisions made by me.
- Distinguish my explicit decisions from Claude's recommendations.
- Never silently change an accepted architectural direction.

### Documentation Update Checklist

At the end of each substantial task:
- Architecture changed? Update `docs/ARCHITECTURE.md`.
- Development or testing workflow changed? Update `docs/DEVELOPMENT.md`.
- Significant technical decision made or changed? Update `docs/DECISIONS.md`.
- No meaningful change to a document's subject? Leave it unchanged.

Documentation updates are part of implementation, not a separate cleanup task.

## 6. Maintainability and Communication

- Favor readable code over unnecessary abstraction.
- Use descriptive names.
- Follow established conventions unless there is a clear reason to change them.
- Avoid speculative features and premature optimization.
- Prefer small, independently testable changes.
- Explain important tradeoffs in plain English.
- Ask before significant, irreversible, or broadly impactful changes.
- Do not silently introduce frameworks, packages, or major architectural patterns.
- Ask focused questions when ambiguity materially affects the result.
- Distinguish verified facts from assumptions and recommendations.

## 7. Final Response Requirements

At the end of each substantial task, summarize:

1. **Implemented:** What changed and why.
2. **Files changed:** Important files created or modified.
3. **Validation:** Commands and tests actually run and their results.
4. **Documentation:** Which documents were updated and why.
5. **Outstanding items:** Unresolved questions, limitations, or steps requiring org access.

Never claim a deployment, commit, or external change succeeded unless it was authorized and actually succeeded.

## 8. Default Operating Principle

Work independently on safe local development tasks. Ask for approval before actions that could affect a Salesforce org, destroy or overwrite data, change repository history, expose sensitive information, or commit or publish code.

When in doubt, inspect first, explain the risk, and ask before taking the consequential action.

