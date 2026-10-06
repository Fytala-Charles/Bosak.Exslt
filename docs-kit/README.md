# FYTALA Documentation Kit

This directory defines the versioned contract for consistent FYTALA documentation rendering. Prime is the canonical source repository for version `1.2.0`; the manifest references authoritative files in their normal repository locations so the live renderer configuration and distributed kit cannot diverge inside Prime.

## Adoption contract

A consumer repository adopts the kit by:

1. Copying every manifest entry from `source` to its declared `destination` and preserving its `sha256` content hash.
2. Merging `workspaceSettings` into its root `.vscode/settings.json` without adding machine-specific browser paths.
3. Adding `.fytala-docs.json` with the adopted `kitVersion` and the location of its copied manifest.
4. Rendering `docs/DOCUMENTATION_RENDERER_TEST.md` in each supported renderer before enabling enforcement.

Repositories may add project-specific Markdown rules after the canonical stylesheet, but must not modify files governed by the manifest. A kit upgrade changes `kitVersion` according to Semantic Versioning: patches preserve appearance and compatibility, minor versions add backward-compatible capabilities, and major versions may change required files or rendering behavior.

`DocumentationStyleChecker` validates this contract as an advisory hygiene rule during rollout. It reports missing adoption metadata, unsupported schema versions, version mismatches, missing or modified governed files, renderer-setting drift, required style-token drift, and machine-specific Markdown PDF browser paths. The rule can be promoted to blocking enforcement after all FYTALA repositories adopt the kit.

## Canonical commands

Install a released tool version and manage the repository without a Prime source checkout:

```bash
dotnet tool install --global Prime.ProjectHygiene.Cli --version <exact-version>
prime-hygiene init --repo-root .
prime-hygiene check --repo-root . --severity-threshold Warning
prime-hygiene sync --repo-root .
```

`init` preserves conflicting consumer files by stopping before it writes. `sync` requires an existing adoption marker and updates only manifest-governed content. Both commands merge portable workspace settings without replacing unrelated editor preferences.

The renderer test is a visual acceptance fixture, not generated documentation. Exported HTML, images, and PDFs are local verification artifacts and should not be committed unless a repository explicitly publishes them.
