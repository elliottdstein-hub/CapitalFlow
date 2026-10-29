# CapitalFlow Salesforce Org — Architecture

_Last updated: 2026-10-28_

This document describes the architecture as it is currently implemented. Setup and commands are in [DEVELOPMENT.md](DEVELOPMENT.md). The reasoning behind choices, and choices still open, is in [DECISIONS.md](DECISIONS.md). Coding standards are in `CLAUDE.md` §4.

## Purpose and scope

_Not yet defined._ The business domain CapitalFlow will model has not been documented (see Open questions in [DECISIONS.md](DECISIONS.md)).

## Current state

The project is a freshly generated Salesforce DX scaffold. `force-app/main/default/` contains **no application metadata**: no custom objects or fields, Apex classes, triggers, Lightning Web Components, Aura components, flows, permission sets, or integrations. Only lint and editor configuration files are present.

Work on the first data model is happening on the `Create-Initial-Objects` branch. This document will describe those components once they exist.

## Project structure

| Aspect | Current implementation | Decision |
| --- | --- | --- |
| Source format | Salesforce DX source format | — |
| Package directories | One: `force-app` (default) | D-004 |
| Namespace | None | D-004 |
| Development model | Org-based: metadata is deployed directly, with no packages | D-004 |
| Target org | Developer Edition org, no source tracking | D-003 |
| Source API version | 59.0 | D-005 (accepted upgrade, not yet applied) |

## Components

| Layer | Components | Notes |
| --- | --- | --- |
| Data model (objects, fields, relationships) | None | |
| Apex (triggers, handlers, services, controllers) | None | Trigger convention: D-008 |
| Lightning Web Components | None | |
| Automation (Flow, scheduled or async Apex) | None | |
| Integrations (named credentials, external services) | None | |

## Data flows

None yet. Once components exist, describe how data moves between the UI (LWC), Apex, Salesforce objects, and any external systems.

## Security boundaries

No access control is defined in source: there are no permission sets, sharing rules, or custom sharing settings in the repository. The org's own sharing configuration has not been inspected. Access to new metadata will be granted through permission sets (D-007).

## Constraints and known limitations

- **No source tracking.** The Developer Edition org can't detect conflicts between local and org changes, so the repository is the only record of intended state.
- **Manifest covers only code types.** `manifest/package.xml` doesn't describe the full deployable surface (see D-006).
- **No CI.** Nothing automatically verifies that the repository matches the org or that tests pass.
