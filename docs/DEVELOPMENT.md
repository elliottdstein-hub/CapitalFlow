# Development Guide

How to set up, validate, and work on the CapitalFlow Salesforce DX project. For how the system is structured, see [ARCHITECTURE.md](ARCHITECTURE.md). For why things are the way they are, see [DECISIONS.md](DECISIONS.md).

_Commands below were checked against Salesforce CLI `@salesforce/cli/2.156.8` on 2026-10-28 (by reading `--help`, not by running them against an org) unless marked otherwise._

## Command safety levels

Every command in this guide is tagged with one of these:

| Tag | Meaning |
| --- | --- |
| **Local** | Reads or changes only files on your machine. Safe to run any time. |
| **Org read** | Connects to an org but does not change it. Claude asks before running these. |
| **Org change** | Changes the org (metadata, data, or configuration) or overwrites local files with org metadata. Requires explicit authorization in the current conversation. |

## Prerequisites

| Tool | Version on the reference machine | Used for |
| --- | --- | --- |
| Salesforce CLI (`sf`) | 2.156.8 | Org authorization, deploy, retrieve, Apex tests |
| Node.js | 22.23.4 (installed via nvm) | Salesforce CLI, npm tooling |
| npm | 10.9.9 | Installing dev dependencies |
| Git | 2.28.0 | Version control, pre-commit hook |
| Java (JDK) | 11.0.14 | Apex language server in VS Code |
| VS Code | — | Recommended editor |

Recommended VS Code extensions are listed in [`.vscode/extensions.json`](../.vscode/extensions.json): Salesforce Extension Pack, XML (Red Hat), ESLint, Prettier, and Apex Log Analyzer.

## First-time setup

1. **Clone the repository** and open the folder in VS Code.
2. **Install dev dependencies** (Local):

   ```sh
   npm install
   ```

   This installs Prettier, ESLint, Jest, Husky, and lint-staged. Its `postinstall` step runs `husky install`, which sets Git's `core.hooksPath` for this repository so the pre-commit hook in [`.husky/pre-commit`](../.husky/pre-commit) runs on every commit.

   > Not yet done on the reference machine: `node_modules/` and `.husky/_` are absent, so the pre-commit hook is currently inactive and none of the npm scripts below can run.

3. **Authorize the Developer Edition org.** This opens a browser login and stores credentials locally under `.sf/` (gitignored). It does not change the org, but it creates credentials, so Claude does not run it without asking:

   ```sh
   sf org login web --alias <org-alias> --set-default
   ```

   The reference machine already has a default org set (alias `vscodeOrg`, stored in `.sf/config.json`). Because `.sf/` is not committed, every developer authorizes their own org.

4. **Confirm which orgs are authorized** (Local when skipping the connection check):

   ```sh
   sf org list --skip-connection-status
   ```

   Without `--skip-connection-status`, the command contacts each org to check connectivity (Org read).

Never paste access tokens, passwords, or `sf org display --verbose` output into the repository, documentation, or chat.

## Repository structure

```
.
├── config/project-scratch-def.json  Scratch org definition (not currently used)
├── docs/                            Project documentation
├── force-app/main/default/          All deployable source, Salesforce DX format
│   ├── aura/                        Aura components (lint config only)
│   └── lwc/                         Lightning Web Components (lint/jsconfig only)
├── manifest/package.xml             Manifest for code metadata types (see Known gaps)
├── scripts/apex/                    Anonymous Apex snippets
├── scripts/soql/                    Saved SOQL queries
├── sfdx-project.json                Package directory and source API version
├── package.json                     npm scripts and dev dependencies
├── .forceignore                     Paths the CLI ignores on deploy/retrieve
├── .prettierrc / .prettierignore    Formatting rules
└── .husky/pre-commit                Runs lint-staged before each commit
```

New metadata goes in the standard DX folders under `force-app/main/default/` (`objects/`, `classes/`, `triggers/`, `lwc/`, `permissionsets/`, and so on). LWC Jest tests go in a `__tests__/` folder inside each component; `.forceignore` keeps them out of deployments.

## Local checks

All of these are **Local** and require `npm install` first.

| Command | What it does |
| --- | --- |
| `npm run prettier:verify` | Checks formatting of Apex, LWC, XML, JSON, Markdown, and other source files. |
| `npm run prettier` | Rewrites files to match the Prettier config. |
| `npm run lint` | Runs ESLint on Aura and LWC JavaScript. |
| `npm test` | Runs LWC Jest unit tests (`sfdx-lwc-jest`). |
| `npm run test:unit:coverage` | Jest with a coverage report in `coverage/`. |
| `npm run test:unit:watch` | Jest in watch mode while developing. |

The pre-commit hook runs Prettier on staged files and ESLint on staged Aura/LWC JavaScript. If either fails, fix the problem rather than bypassing the hook with `--no-verify`.

Optional static analysis: Salesforce Code Analyzer (`sf code-analyzer run`) is available as a just-in-time CLI plugin and installs on first use. It has not been run on this project yet.

Apex has no local test runner. Apex tests only run in an org (see below).

## Working with the org

Everything in this section connects to an org. **Claude runs none of it without explicit authorization in the current conversation.** Replace `<org-alias>` with your alias, or omit `--target-org` to use the default org.

The Developer Edition org does not support source tracking (only scratch orgs and sandboxes do). That means the CLI cannot detect conflicts between local and org changes, and `sf project retrieve preview` does not work against it. Be deliberate about what you deploy and retrieve.

### Inspect (Org read)

```sh
sf org open --target-org <org-alias>                 # Open Setup in a browser
sf org display --target-org <org-alias>              # Org ID, API version, instance URL
sf project deploy preview --source-dir force-app     # List what a deploy would send
```

`sf org display` shows a short-lived access token in its output. Don't copy that output anywhere.

### Deploy (Org change)

Recommended sequence:

1. **Preview** what will be sent (above).
2. **Validate** without saving. Apex tests run, but nothing is committed to the org. This still counts as an org action and needs authorization:

   ```sh
   sf project deploy validate --source-dir force-app --test-level RunLocalTests --target-org <org-alias>
   ```

3. **Deploy:**

   ```sh
   sf project deploy start --source-dir force-app --target-org <org-alias>
   ```

Prefer the narrowest scope that covers the change: `--source-dir force-app/main/default/objects/<Object__c>`, or `--metadata "CustomObject:<Object__c>"`. Do not use `--ignore-conflicts` (`-c`), `--ignore-errors` (`-r`), or destructive-change flags without a specific, agreed reason.

`deploy validate` does not accept `NoTestRun`. While the project has no Apex, you can do a metadata-only validation with a dry run instead. This still needs authorization:

```sh
sf project deploy start --dry-run --test-level NoTestRun --source-dir force-app --target-org <org-alias>
```

### Assign the permission set (Org change)

Fields deployed from source aren't visible to any profile, including System Administrator, until you have the `CapitalFlow_User` permission set (see ARCHITECTURE.md, Security boundaries). Assigning it creates a record in the org:

```sh
sf org assign permset --name CapitalFlow_User --target-org <org-alias>
```

Without `--on-behalf-of`, it's assigned to the org's default user.

### Retrieve (Org change — overwrites local files)

Retrieving writes org metadata over local source. Check `git status` first so any overwritten work can be reviewed with `git diff`.

```sh
sf project retrieve start --metadata "CustomObject:<Object__c>" --target-org <org-alias>
```

### Run Apex tests (Org change)

Running tests executes code in the org and can create and roll back test data, so it requires authorization:

```sh
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 10 --target-org <org-alias>
sf apex run test --class-names <ClassNameTest> --result-format human --wait 10 --target-org <org-alias>
```

### Scripts

| File | What it does | Level |
| --- | --- | --- |
| [`scripts/apex/hello.apex`](../scripts/apex/hello.apex) | Template anonymous Apex (debug output only). Executing anonymous Apex runs code in the org. | Org change |
| [`scripts/soql/account.soql`](../scripts/soql/account.soql) | Sample query `SELECT Id, Name FROM Account`. | Org read |

Both are scaffold examples. They can be run from VS Code with the "SFDX: Execute Anonymous Apex…" and "SFDX: Execute SOQL Query…" commands.

### Scratch orgs (not set up)

[`config/project-scratch-def.json`](../config/project-scratch-def.json) exists, but no Dev Hub is configured. Enabling Dev Hub changes org configuration (Org change). Once a Dev Hub exists, the command would be the following (not verified in this project):

```sh
sf org create scratch --definition-file config/project-scratch-def.json --alias <scratch-alias> --target-dev-hub <devhub-alias>
```

## Known gaps

- **Manifest excludes declarative metadata.** [`manifest/package.xml`](../manifest/package.xml) lists only code types (Apex, Visualforce, Aura, LWC, static resources). Deploying or retrieving with `--manifest manifest/package.xml` silently skips custom objects, fields, permission sets, flows, and layouts. Use `--source-dir` or `--metadata` instead, or regenerate the manifest from local source (Local):

  ```sh
  sf project generate manifest --source-dir force-app --output-dir manifest
  ```

  This overwrites `manifest/package.xml`. See D-006 in [DECISIONS.md](DECISIONS.md).

- **`npm install` fails** with an ERESOLVE peer-dependency conflict. `@salesforce/eslint-config-lwc@3.7` requires `@lwc/eslint-plugin-lwc@^2`, but `package.json` pins `^1.1.2`. Until `package.json` is fixed, the pre-commit hook and the npm scripts in Local checks can't run.
- **No CI.** All checks are run by hand or by the pre-commit hook.

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| Commits succeed without formatting or linting | Hook not installed. Run `npm install`. |
| `npm run …` fails with "command not found" for prettier, eslint, or sfdx-lwc-jest | Dev dependencies not installed. Run `npm install`. |
| `npm run lint` reports "No files matching the pattern" | No Aura or LWC JavaScript exists yet. ESLint 8 exits with an error when its glob matches nothing. This is expected until the first component is added. |
| `npm test` reports no tests found | No LWC Jest tests exist yet. Expected until the first component is added. |
| An `sf` command says `--target-org` is required | No default org is set. Pass `--target-org <org-alias>`, or run `sf config set target-org <org-alias>` (Local). |
| `sf project retrieve preview` errors | The Developer Edition org has no source tracking. Use explicit `retrieve start --metadata …` instead. |
| Objects or fields missing after a manifest-based deploy | See "Manifest excludes declarative metadata" above. |
| Apex IntelliSense not working in VS Code | Check that a supported JDK is installed and the Salesforce extension can find it (Java 11 is installed on the reference machine). |
