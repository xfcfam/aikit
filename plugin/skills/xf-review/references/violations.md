# XF Violation Reference

This file used to mirror the rule catalogue. It is now superseded by
the shared canonical sources:

- **`../../_shared/catalogue.md`** — the full rule catalogue, kept in
  sync with the normative spec (`xfa-en.tex § 11.3`) and with the
  xftools validator. **71 rules across 9 groups** (61 structural + 10
  semantic). Every rule lists its `id`, group number (1–9),
  verifiability (`structural` / `semantic`) and spec ref.
- **`../../_shared/rules-detail.md`** — per-group prose with the
  applicability notes for every rule.

## Verifiability — the single axis (read this first)

Every rule carries one attribute, `verifiability ∈ {structural,
semantic}` (`§ 11.1.4`). Older references used a two-axis model
("Mandatory/Optional" criticality × "Verified/Heuristic/Manual"
verifiability) — that taxonomy is **obsolete**. The current model is:

- **`structural`** — decided by static analysis (path, filename, or AST).
  A violation degrades the conformance level to `Λ=2`. **61 rules.**
- **`semantic`** — requires human architectural review (e.g. "this
  Logical actually contains business logic, not data-access logic").
  A static tool cannot decide these, so xftools **declares** them in the
  catalogue but always returns no violation. They are why a static pass
  is capped at `Λ=3` ("structurally conformant / well-formed") rather
  than `Λ=4`. **10 rules.**

So: a single structural violation drops the artefact to `Λ=2`; with zero
structural violations a static tool reports at most `Λ=3` and flags the
outstanding semantic rules; only a human semantic review can certify
`Λ=4`.

## Execution scope

Orthogonal to verifiability, each rule declares an execution `scope`
(how the check runs), used to group violations in the report:

- **structural** — path + filename only; no source parsing.
- **component** — single-file AST (the parsed class shape).
- **artefact** — cross-file (imports / references between components).

## The 9 rule groups (`§ 11.3.1` … `§ 11.3.9`)

| Group | Section | Theme | id prefix |
| :---: | --- | --- | --- |
| 1 | § 11.3.1 | Folder structure | `structure-*` |
| 2 | § 11.3.2 | Layer isolation | `layer-*` |
| 3 | § 11.3.3 | Logical components | `logic-*` |
| 4 | § 11.3.4 | Generalization components | `general-*` |
| 5 | § 11.3.5 | Injection components | `injection-*` |
| 6 | § 11.3.6 | Utility components | `utility-*` |
| 7 | § 11.3.7 | Transfer components | `transfer-*` |
| 8 | § 11.3.8 | XF start-point element | `xf-*` |
| 9 | § 11.3.9 | Exclusivity of lifecycle orchestration | `lifecycle-*` |

The authoritative `id` + description list lives in
`../../_shared/catalogue.md` (summary table) and
`../../_shared/rules-detail.md` (per-group prose). Do **not** invent
ids — copy the real ones. The frequently used ones by group:

- **G1 `structure-*`**: `structure-layer-mismatch`,
  `structure-type-mismatch`, `structure-injection-missing`,
  `structure-injection-multiplicity`, `structure-component-naming`,
  `structure-domain-subdivision` *(semantic)*. Canonical type subfolders
  are `/general`, `/logic`, `/transfers`, `/utils` plus the injection.
- **G2 `layer-*`**: `layer-reference` (upward reference),
  `layer-inheritance` (cross-layer inheritance), `layer-skip` (skips the
  intermediate layer).
- **G3 `logic-*`**: `logic-naming-repository` / `-business` / `-service`
  / `-view`; `logic-mismatch-repository` / `-business` / `-api`
  *(semantic)*; `logic-initialization-missing`,
  `logic-termination-missing`, `logic-constructor-mismatch`,
  `logic-inheritance`.
- **G4 `general-*`**: `general-naming-repository` / `-business` /
  `-service` / `-view`; `general-mismatch-repository` / `-business` /
  `-api` *(semantic)*; `general-injection-reference`,
  `general-domain-state`, `general-instantiable`,
  `general-initialization-missing`, `general-termination-missing`,
  `general-constructor-mismatch`, `general-inheritance`.
- **G5 `injection-*`**: `injection-naming-r` / `-b` / `-a`;
  `injection-non-repository` / `-business` / `-api`;
  `injection-mismatch`, `injection-instantiable`,
  `injection-member-mutable`, `injection-member-public`,
  `injection-init-missing`, `injection-terminate-missing`,
  `injection-init-mismatch`, `injection-terminate-mismatch`,
  `injection-lifecycle-symmetry`, `injection-inheritance`.
- **G6 `utility-*`**: `utility-naming`, `utility-mismatch`
  *(semantic)*, `utility-instantiable`, `utility-member-instance`,
  `utility-mutable-state`, `utility-inheritance`.
- **G7 `transfer-*`**: `transfer-naming` *(semantic)*,
  `transfer-dependency`, `transfer-business-logic` *(semantic)*,
  `transfer-inheritance`. Exceptions are a transfer subtype and are
  covered by these rules.
- **G8 `xf-*`**: `xf-init-missing`, `xf-terminate-missing`,
  `xf-init-mismatch` (body exactly `R.init(); B.init(); A.init()`),
  `xf-terminate-mismatch` (body exactly
  `A.terminate(); B.terminate(); R.terminate()`).
- **G9 `lifecycle-*`**: `lifecycle-logic-instantiation`,
  `lifecycle-logic-init`, `lifecycle-logic-terminate`,
  `lifecycle-injection-init`, `lifecycle-injection-terminate`,
  `lifecycle-xf-init`, `lifecycle-xf-terminate`.

## How to consume these references during a review

1. Start at `_shared/catalogue.md` for the canonical list and the
   `structural` / `semantic` verifiability of each rule.
2. For any rule you suspect is violated, jump to the matching group
   section in `_shared/rules-detail.md` for the applicability notes.
3. Apply the rule's `appliesTo` filter (the artefact's language).
4. Aggregate findings per the report structure in `SKILL.md` and assign
   `Λ ∈ {0,1,2,3,4}` (a static pass tops out at `Λ=3`).

## Common doctrinal clarifications (frequent misreadings)

- **Native exceptions are valid**: `throw new Error(...)`,
  `throw new TypeError(...)`, etc. are well-formed XF transfer
  vehicles. The model does NOT mandate wrapping every error in a
  custom `*Exception`. Custom Exception components (a Transfer subtype
  in `<layer>/transfers/`) are a design choice for domain concepts that
  the language doesn't express by itself (e.g.
  `IllegalTransitionException` for an FSM).
- **Library packages declare empty R/B/A classes** (not `export {}`).
  This is structural completeness, not boilerplate. Rules
  `structure-injection-missing`, `injection-init-missing`,
  `injection-terminate-missing` enforce it.
- **Lifecycle orchestration is exclusive (group 9)**: only a layer's
  injection (`R` / `B` / `A`) may invoke `init()` / `terminate()` on a
  Logical of its layer, and only `XF` may invoke them on an injection.
  Any other receiver triggers `lifecycle-logic-init` /
  `lifecycle-logic-terminate` / `lifecycle-injection-init` /
  `lifecycle-injection-terminate`.
- **No direct Logical references**: a Logical (or any non-R/B/A/XF
  component) may NOT reference another Logical (`*Repository`,
  `*Business`, `*Service`, `*View`) from `/logic/` and call it. Access
  goes via the layer's Injection. Rule: `layer-reference` (and
  `layer-skip`). Type-only imports (`import type { ... }`) are exempt.

## Catalogue parity

Every rule the validator checks is enumerated in the normative spec
(`xfa-en.tex § 11.3`) and surfaced in `_shared/catalogue.md`. There
are no "xftools extensions" — the catalogue is fully mirrored by the
spec, with no prefixed ids or out-of-band guards. If a rule appears
in `_shared/catalogue.md` it is normative.
