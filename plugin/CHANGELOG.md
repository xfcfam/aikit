# Changelog

All notable changes to the `xf-architecture` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] — 2026-06-12

### Changed

- **Migrated the whole plugin to spec edition XF-CFAM-001:2026.**
- **Conformity model: 4 levels (N=0..3) → 5 levels (Λ=0..4).** New semantics:
  Λ=2 = totality with ≥1 **structural** violation; Λ=3 = structurally conformant
  (0 structural, ≥1 semantic — the ceiling a static tool can certify);
  Λ=4 = perfectly conformant (needs human semantic review). Removed the old
  "mandatory / framework-forced violation" framing.
- **Rule catalogue re-synced from `@xfcfam/tools`: 9 thematic groups, 71 rules**
  (61 structural + 10 semantic) with current canonical IDs (`structure-*`,
  `layer-*`, `logic-*`, `general-*`, `injection-*`, `utility-*`, `transfer-*`,
  `xf-*`, `lifecycle-*`). Replaces the former 10-group set and obsolete IDs.
- **Canonical folders renamed to match § 7.4:** `/base` → `/general`,
  `/structs` → `/transfers` (immutable normative contract).
- **Corrected the injection lifecycle pattern** in the instruction files and the
  example skeleton: injections (`R`/`B`/`A`/`XF`) are now shown as **static,
  non-instantiable** with **no-argument** `init()` / `terminate()`, and lower
  layers are reached statically (`R.userRepository…`) rather than by constructor
  injection (`B.init(R)`). The previous example would have tripped
  `injection-instantiable` / `injection-init-mismatch`.
- Updated `INSTRUCTIONS.md`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, the plugin
  `README.md`, and the four existing skills (`xf-classify`, `xf-explain`,
  `xf-review`, `xf-scaffold`) and their references to all of the above.

### Added

- **xf-implement** skill — generates XF-compliant code from a feature or
  requirement (classification → canonical names → injection-wired implementation).
- **xf-specify** skill — translates requirements / user stories into an L×T
  component plan (design only) before coding.
- **xf-document** skill — generates documentation for an XF artifact: component
  catalog by L×T cell, injection map, dependency view, README and docstrings.
- **xf-test** skill — designs tests that respect layer isolation (mock through
  the R/B/A injections), with coverage organized by L×T cell.
- **Reference pointers in every skill** — a `References` footer linking the
  normative specification (<https://xfcfam.org>, edition XF-CFAM-001:2026) and
  two new shared references: `_shared/spec.md` (clause map) and
  `_shared/libraries.md` (the `@xfcfam/*` reference libraries). The build skills
  (`xf-implement`, `xf-scaffold`, `xf-specify`) now tell developers to reuse a
  published library before implementing a utility or generalization by hand.

---

## [0.1.0] — 2026-05-16

### Added

- **xf-review** skill — audits code for XF Architecture Model compliance.
  Reports layer boundary violations, naming issues, folder misplacements,
  injection violations, Transfer/Utility anti-patterns. Assigns conformity
  level N=0..3. Includes detailed violation reference (`references/violations.md`).

- **xf-scaffold** skill — generates canonical XF project structure and component
  boilerplate. Supports TypeScript, Python, Swift, and Kotlin. Produces
  R/B/A injection stubs and component skeletons for any Logical, Utility,
  Transfer, or Generalization. Includes per-language templates
  (`references/structure.md`).

- **xf-classify** skill — classifies existing code components into the XF
  L×T matrix (3 layers × 5 types). Proposes canonical names, target file
  paths, and migration steps. Includes full decision tree
  (`references/decision-tree.md`).

- **xf-explain** skill — answers questions about XF concepts, layer rules,
  naming conventions, injection patterns, conformity levels, and design
  rationale. Adapts examples to the user's language and codebase.

- `plugin.json` manifest with full distribution metadata.
- `marketplace.json` for self-hosted marketplace distribution.
- MIT license.
