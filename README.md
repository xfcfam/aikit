# xfcfam/aikit

Claude plugin for working with the **XF Architecture Model** (CFAM) from
AI assistants. Bundles skills, instructions and helpers so Claude can
classify components, scaffold artefacts, review compliance, and answer
questions about the XF spec.

## Status

Working plugin, version **0.3.0**, tracking spec edition **XF-CFAM-001:2026**.
See [`plugin/CHANGELOG.md`](./plugin/CHANGELOG.md) for the release history and
[`plugin/README.md`](./plugin/README.md) for install instructions.

## What's in scope

- A Claude plugin (`plugin/.claude-plugin/plugin.json`) bundling eight skills.
- A library of **skills** that teach Claude to apply XF rules in conversation:
  `xf-classify`, `xf-specify`, `xf-implement`, `xf-scaffold`, `xf-review`,
  `xf-test`, `xf-document`, and `xf-explain`.
- **Shared references** under `plugin/skills/_shared/`: the model `foundations`
  (philosophy & particularities), the `spec` clause map, the synced rule
  `catalogue` / `rules-detail`, and the `@xfcfam/*` `libraries` index.
- Reusable **instructions** (`AGENTS.md`, `CLAUDE.md`, `INSTRUCTIONS.md`,
  `.cursorrules`) consumable by any agent that wants XF-aware behaviour.

## Rule catalogue — single source of truth

The skills consume the rule catalogue from a **shared, synced copy** of
the xftools validator's documentation:

```
plugin/skills/_shared/
├── catalogue.md      ← copy of xfcfam/tools/README.md
└── rules-detail.md   ← copy of xfcfam/tools/RULES.md
```

These two files are the canonical reference the LLM walks during
`xf-review`, `xf-scaffold`, `xf-classify` and `xf-explain`. They are
kept in lock-step with the normative spec (`xfa-es.tex § 11.3`) and the
xftools implementation; whenever the upstream catalogue changes, the
copies are resynced.

### Resyncing

To regenerate the shared catalogue from a local checkout of
[`xfcfam/tools`](https://github.com/xfcfam/tools):

```bash
bin/sync-from-spec.sh                       # looks for ../tools/
bin/sync-from-spec.sh /path/to/tools        # explicit path
```

The script copies `README.md` and `RULES.md` byte-for-byte into
`plugin/skills/_shared/`. Commit the resulting diff.

### CI guarantee

The [`catalogue-sync`](./.github/workflows/catalogue-sync.yml) workflow
clones `xfcfam/tools` and runs `diff -u` against the shipped copies on
every PR that touches the shared catalogue. Drift fails the check and
prompts the contributor to resync.

### Why a copy, not a Git submodule

The plugin is consumed via Claude's plugin registry, which fetches the
repository as a flat tree. Submodules add friction without solving the
practical problem (drift detection), which the diff-based CI job covers
directly.

## What's NOT in scope

- The normative XF specification — see **[xfcfam/docs](https://github.com/xfcfam/docs)**.
- TypeScript reference implementation — see **[xfcfam/lib-npm](https://github.com/xfcfam/lib-npm)**.
- CLI validator / linter — see **[xfcfam/tools](https://github.com/xfcfam/tools)**.

## License

MIT — see [LICENSE](./LICENSE).

## Security

Please report vulnerabilities privately. See [SECURITY.md](./SECURITY.md).

## Code of conduct

This project follows the [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md).
