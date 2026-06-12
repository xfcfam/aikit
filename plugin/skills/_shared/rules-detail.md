# XF / CFAM Validation Rules — Reference

This document is the **detailed catalog** of every rule `xftools
validate` knows about, mirroring the normative spec `xfa-en.tex § 11.3`
(edition **XF-CFAM-001:2026**): **71 rules across 9 thematic groups**.

For the summary table (id, group, verifiability, spec ref) plus install,
CLI usage, language coverage, and the conformance-level model, see
**[README.md](./README.md)**.

## Verifiability

Every rule carries `verifiability ∈ {structural, semantic}` (§ 11.1.4):

- **structural** — decided by static analysis. A violation degrades the
  conformance level to `Λ=2`. **61 rules.**
- **semantic** — requires human architectural review. A static tool
  cannot decide these, so xftools **declares** them in the catalog but
  always returns no violation. They are why the static result is capped
  at `Λ=3` ("structurally conformant") rather than `Λ=4`. **10 rules.**

## Execution scope

Each rule also declares an execution `scope` (how the check runs):

- **structural** — path + filename only; no source parsing.
- **component** — single-file AST (the parsed class shape).
- **artefact** — cross-file (imports / references between components).

## Conformance level (§ 11.4)

`Λ(𝔄) ∈ {0,1,2,3,4}`, by the four-stage algorithm:

1. **Inventory + classify** every element into the L × T matrix.
2. **Totality**: if any component is unclassified → `Λ=1` (≥1 classified)
   or `Λ=0` (none); stop. The XF start-point element is excluded (it is
   not a component).
3. **Catalog**: evaluate the 71 rules with applicability — a rule with no
   applicable element yields no violation.
4. **Level**: ≥1 structural violation → `Λ=2`; else ≥1 semantic → `Λ=3`;
   else `Λ=4`. Because the tool cannot decide the semantic rules, it caps
   the static result at `Λ=3` and reports the human-review gap.

## Language applicability

Path-based rules apply to every language. Rules that inspect class shape
or call sites declare an `appliesTo` set; the engine skips them on
languages whose construct is not extractable by the current parser. Real
AST coverage today is **TypeScript** (and a Java CST parser when
`java-parser` is installed); other languages run the path-based rules
and degrade gracefully on the rest.

---

## Group 1 — Folder structure (`§ 11.3.1`)

Path-only rules over the canonical layout of `§ 7.4`. No file content is
inspected.

- **`structure-layer-mismatch`** *(structural)* — An element directly
  under `/src` is not canonical: only `/repository`, `/business`, `/api`
  and the `XF` element are allowed at that level. (§ 7.4, § 8.1)
- **`structure-type-mismatch`** *(structural)* — An element directly
  under a layer folder is not canonical: only `/general`, `/logic`,
  `/transfers`, `/utils` and the layer injection (`R`/`B`/`A`). (§ 7.4)
- **`structure-injection-missing`** *(structural)* — A present layer
  folder lacks its canonical injection file at its root. (§ 7.3.3)
- **`structure-injection-multiplicity`** *(structural)* — A layer
  declares more than one file with the canonical injection name. (§ 7.3.3)
- **`structure-component-naming`** *(structural)* — A file declares a
  component whose name does not match the file name (no extension). (§ 7.4)
- **`structure-domain-subdivision`** *(semantic)* — `/repository/logic`
  or `/api/logic` is subdivided by functional domain instead of the
  legitimate layer criterion (transport / interaction-point type).
  (§ 7.2.1, § 7.2.3)

## Group 2 — Layer isolation (`§ 11.3.2`)

Reference relations between components; reported on the importing
component. Injection references are the sanctioned descending-access
conduit and are not "skips".

- **`layer-reference`** *(structural)* — A component references another
  of a **higher** abstraction layer (upward reference). (§ 6.2.2)
- **`layer-inheritance`** *(structural)* — A component inherits from a
  component classified in a **different** layer, either direction. (§ 6.2.2)
- **`layer-skip`** *(structural)* — A component references a **lower**
  layer skipping the intermediate one. Transfers, Access utilities over
  primitives, and injections are excepted. (§ 6.2.2)

## Group 3 — Logical components (`§ 11.3.3`)

Apply to `/src/<layer>/logic/` classes (or those with canonical suffix).

- **`logic-naming-repository`** *(structural)* — Access logical must end
  with `Repository`. (§ 7.3.1, § 7.2.1)
- **`logic-naming-business`** *(structural)* — Business logical must end
  with `Business`. (§ 7.3.1, § 7.2.2)
- **`logic-naming-service`** *(structural)* — Systemic Interaction
  logical must end with `Service`. (§ 7.3.1, § 7.2.3)
- **`logic-naming-view`** *(structural)* — Graphical Interaction logical
  must end with `View`. (§ 7.3.1, § 7.2.3)
- **`logic-mismatch-repository` / `-business` / `-api`** *(semantic)* —
  Logical contains logic outside its layer's responsibility. (§ 7.2.x)
- **`logic-initialization-missing`** *(structural)* — Logical declares
  no superclass and no invocable `init()`. (§ 7.3.1, § 8.2)
- **`logic-termination-missing`** *(structural)* — Logical declares no
  superclass and no invocable `terminate()`. (§ 7.3.1, § 8.2)
- **`logic-constructor-mismatch`** *(structural)* — Logical performs
  non-trivial initialization in its constructor instead of `init()`. (§ 8.2)
- **`logic-inheritance`** *(structural)* — Logical inherits from
  something other than a logical or generalization of its own layer.
  (§ 7.3.1, § 7.3.2)

## Group 4 — Generalization components (`§ 11.3.4`)

Apply to `/src/<layer>/general/` classes.

- **`general-naming-repository` / `-business` / `-service` / `-view`**
  *(structural)* — Generalization must end with its layer's canonical
  suffix. (§ 7.3.2, § 7.2.x)
- **`general-mismatch-repository` / `-business` / `-api`** *(semantic)* —
  Generalization contains logic outside its layer's responsibility.
- **`general-injection-reference`** *(structural)* — Generalization
  invokes logicals through an injection (`R`/`B`/`A`). (§ 7.3.2)
- **`general-domain-state`** *(structural)* — Generalization declares
  mutable instance attributes (domain state). (§ 7.3.1, § 7.3.2)
- **`general-instantiable`** *(structural)* — Generalization does not
  prevent direct instantiation (abstract / private constructor). (§ 7.3.2)
- **`general-initialization-missing` / `general-termination-missing`**
  *(structural)* — Generalization declares no superclass and no
  invocable `init()` / `terminate()`. (§ 7.3.2, § 8.2)
- **`general-constructor-mismatch`** *(structural)* — Non-trivial logic
  in the constructor instead of `init()`. (§ 8.2)
- **`general-inheritance`** *(structural)* — Generalization inherits from
  an **internal** XF component that is not a same-layer generalization.
  (§ 7.3.2)

## Group 5 — Injection components (`§ 11.3.5`)

Apply to the `R` / `B` / `A` files at each layer root.

- **`injection-naming-r` / `-b` / `-a`** *(structural)* — Injection must
  bear the canonical name `R` / `B` / `A`. (§ 7.3.3)
- **`injection-non-repository` / `-business` / `-api`** *(structural)* —
  The injection declares a static slot that is not a logical of its
  layer. (§ 7.3.3)
- **`injection-mismatch`** *(structural)* — The injection declares a
  member other than a static logical reference or static `init()` /
  `terminate()`. (§ 7.3.3)
- **`injection-instantiable`** *(structural)* — Injection does not
  prevent instantiation. (§ 7.3.3)
- **`injection-member-mutable`** *(structural)* — Static logical
  references are not immutable (`readonly` / `final` / `val` / `const`).
  (§ 7.3.3)
- **`injection-member-public`** *(structural)* — Static logical
  references are not public. (§ 7.3.3)
- **`injection-init-missing` / `injection-terminate-missing`**
  *(structural)* — Injection does not declare a static `init()` /
  `terminate()`. (§ 7.3.3, § 8.2)
- **`injection-init-mismatch` / `injection-terminate-mismatch`**
  *(structural)* — The `init()` / `terminate()` body contains statements
  other than slot lifecycle invocations (the canonical
  iterate-over-collection-slot idiom is allowed). (§ 7.3.3)
- **`injection-lifecycle-symmetry`** *(structural)* — A slot initialized
  in `init()` is not terminated in `terminate()`, or vice versa. (§ 8.2)
- **`injection-inheritance`** *(structural)* — Injection inherits from
  any component. (§ 7.3.3)

## Group 6 — Utility components (`§ 11.3.6`)

Apply to `/src/<layer>/utils/` classes (or those with suffix `Utils`).

- **`utility-naming`** *(structural)* — Utility must end with `Utils`.
- **`utility-mismatch`** *(semantic)* — Utility models the domain, calls
  logicals via injections, or causes observable side effects.
- **`utility-instantiable`** *(structural)* — Utility does not prevent
  instantiation.
- **`utility-member-instance`** *(structural)* — Utility declares
  instance members.
- **`utility-mutable-state`** *(structural)* — Utility declares mutable
  attributes.
- **`utility-inheritance`** *(structural)* — Utility inherits from
  something other than a same-layer utility. (all § 7.3.4)

## Group 7 — Transfer components (`§ 11.3.7`)

Apply to `/src/<layer>/transfers/` classes (exceptions are a transfer
subtype and are covered by these rules).

- **`transfer-naming`** *(semantic)* — Transfer bears a suffix added to
  the domain concept it models (`UserDTO`, `UserEntity`, …).
- **`transfer-dependency`** *(structural)* — Transfer references an
  injection, logical, generalization or utility component.
- **`transfer-business-logic`** *(semantic)* — An operation of a transfer
  models a business process of the domain.
- **`transfer-inheritance`** *(structural)* — Transfer inherits from a
  non-transfer component (the language error type used by exception
  transfers is excepted). (all § 7.3.5)

## Group 8 — XF start-point element (`§ 11.3.8`)

Apply to the `XF` element.

- **`xf-init-missing` / `xf-terminate-missing`** *(structural)* — `XF`
  does not declare a static `init()` / `terminate()`.
- **`xf-init-mismatch`** *(structural)* — `XF.init()` body is not exactly
  `R.init(); B.init(); A.init()` in that order.
- **`xf-terminate-mismatch`** *(structural)* — `XF.terminate()` body is
  not exactly `A.terminate(); B.terminate(); R.terminate()` in reverse
  order. (all § 8.3)

## Group 9 — Exclusivity of lifecycle orchestration (`§ 11.3.9`)

Quantify over every component; reported on the **invoking** component.

- **`lifecycle-logic-instantiation`** *(structural)* — A non-injection
  component instantiates a logical via `new`. (§ 7.3.3)
- **`lifecycle-logic-init` / `lifecycle-logic-terminate`** *(structural)*
  — A component other than the logical's layer injection invokes
  `init()` / `terminate()` on a logical. (§ 7.3.3, § 8.2)
- **`lifecycle-injection-init` / `lifecycle-injection-terminate`**
  *(structural)* — A component other than `XF` invokes `init()` /
  `terminate()` on an injection. (§ 7.3.3, § 8.3)
- **`lifecycle-xf-init` / `lifecycle-xf-terminate`** *(structural)* — A
  component other than `XF` itself invokes `init()` / `terminate()` on
  the `XF` element. (§ 8.3)

---

## Adding or changing a rule

1. Implement a class extending `RuleBusiness` (structural) or
   `SemanticRuleBusiness` (semantic) under
   `src/business/logic/rules/<scope>/<ClassName>Business.ts`. Use the
   canonical kebab-case `id` and set `group`, `verifiability`, `scope`
   and `specRef`. Declare `appliesTo` if the check needs a
   language-specific construct.
2. Register it in `src/business/B.ts` (`B.rules`, in its group section).
3. Update the summary table in [README.md](./README.md) and the relevant
   group section here.

## See also

- The normative spec — `xfa-en.tex` § 11.3 (catalog), § 11.4 (algorithm),
  § 11.1.4 (verifiability).
- [README.md](./README.md) — overview, install, CLI, language coverage,
  conformance levels, and the summary table of all 71 rules.
