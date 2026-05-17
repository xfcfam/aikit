# xfarch/aikit

Claude plugin for working with the **XF Architecture Model** (CFAM) from
AI assistants. Bundles skills, instructions and helpers so Claude can
classify components, scaffold artefacts, review compliance, and answer
questions about the XF spec.

## Status

This repository is in early scaffolding. The initial commit contains only
governance and tooling files (license, code of conduct, security policy,
CI, contribution guidelines). The plugin manifest and skills will land in
follow-up commits.

## What's in scope

- A Claude plugin (`plugin.json`) declaring skills, prompts and MCP wiring.
- A library of **skills** that teach Claude how to apply XF rules in
  conversation: `xf-classify`, `xf-explain`, `xf-review`, `xf-scaffold`.
- Reusable **instructions** (`AGENTS.md`, `CLAUDE.md`, `INSTRUCTIONS.md`)
  consumable by any agent that wants XF-aware behaviour.

## What's NOT in scope

- The normative XF specification — see **[xfarch/docs](https://github.com/xfarch/docs)**.
- TypeScript reference implementation — see **[xfarch/lib-npm](https://github.com/xfarch/lib-npm)**.
- CLI validator / linter — see **[xfarch/tools](https://github.com/xfarch/tools)**.

## License

MIT — see [LICENSE](./LICENSE).

## Security

Please report vulnerabilities privately. See [SECURITY.md](./SECURITY.md).

## Code of conduct

This project follows the [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md).
