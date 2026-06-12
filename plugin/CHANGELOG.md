# Changelog

All notable changes to the `xf-architecture` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0] — 2026-06-13

Foundations & particularities refresh — re-derived from the normative document
(`xfa-es.tex` §5–§9, edition XF-CFAM-001:2026). The rule catalogue, conformance
model, folders and naming were already current as of 0.2.0; this release deepens
the **philosophy** the rules are derived from and corrects conceptual drift in
the prose so skills reason from the model's intent, not surface heuristics.

### Added

- **`_shared/foundations.md`** — a new shared reference capturing the *why* and
  the subtle points: software as automation of formal processes (the isomorphism
  principle), the invariant tripartition and its convergent derivation
  (BPMN · CSP/π-calculus · Actor Model · IPO), the **meta-model / reference-model
  framing** (XF is *over* Clean/Hexagonal/Onion/DDD/MVC, never a rival), the OSI
  orthogonal-extension analogy, the four guiding principles, effective vs
  contextual logic, and the particularities below. Registered in `_shared/spec.md`
  and linked from every skill's `References` footer.
- **Particularities now stated explicitly** across the skills and instruction
  files: dependency direction ≠ data-flow direction (**upward information via
  events/observer** is not a violation); the **cross-layer duplication mandate**
  (one generalization per layer — `StatefulRepository` + `StatefulBusiness` +
  `StatefulView`); the **Access primitive-utils exception** (`StringUtils` &c.
  in `repository/utils/` are cross-layer); the **logical vs generalization
  parametricity test**.

### Changed

- **Corrected the Transfer doctrine** — a Transfer **may carry self-contained
  operations** on its own data (`Temperature.toFahrenheit()`); "data-only / no
  methods" was a DTO oversimplification the model explicitly rejects (§7.3.5).
  Fixed the wrong "logic inside a Transfer" example in `CLAUDE.md`, rule #4 in
  `AGENTS.md`, the `.cursorrules` rule, and the Transfer guidance in
  `xf-implement` and `xf-test`. Rich framework types (collections, dates,
  promises, UI controls) **project** to Transfers.
- **`xf-explain`** — added a "explain the *why*" section (formal processes, the
  three-stage derivation, the meta-model framing, OSI) and four new
  frequently-misunderstood points (upward events, duplication mandate,
  primitive-utils exception, parametricity test).
- **`xf-classify` decision tree** — added the parametricity test and the
  effective/contextual-logic split to the Generalization step; corrected the
  cross-layer-utility guidance to the primitive-types exception.
- **`xf-review`** — added doctrinal notes so a review does not flag upward
  events, cross-layer primitive-utils, or self-contained transfer operations as
  violations.
- **`INSTRUCTIONS.md`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules`** — added the
  foundations/meta-model framing and a "particularities that are NOT violations"
  block to each.
- **Re-synced `_shared/catalogue.md`** from `@xfcfam/tools` (restored byte-parity;
  picked up the new `## Commands` section). Rule catalogue unchanged: 71 rules /
  9 groups (61 structural + 10 semantic), Λ=0..4.
- Bumped plugin, marketplace, and all eight skill versions to **0.3.0**.

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
