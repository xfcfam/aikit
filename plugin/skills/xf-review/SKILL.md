---
name: xf-review
description: >
  Use this skill when the user asks to "review this code for XF compliance",
  "check if this follows the XF model", "audit XF violations", "what conformity
  level is this?", "does this code follow CFAM?", "find XF violations", or
  "review my architecture". Also use when the user pastes code and asks if the
  structure is correct according to XF or CFAM.
metadata:
  version: "0.4.0"
---

# XF Compliance Review

Perform a structured XF Architecture Model (CFAM) compliance review of the
code the user provided or pointed to. **The catalogue of rules and their
verifiability lives in the shared references — read them at the start of
every review:**

- **`../_shared/catalogue.md`** — the canonical summary table of every
  rule grouped by spec section (`§ 11.3.1` … `§ 11.3.9`), with its
  verifiability (`structural` / `semantic`) and spec ref. **71 rules
  across 9 groups** (61 structural + 10 semantic). Also lists supported
  languages and the conformance levels `Λ=0..4`.
- **`../_shared/rules-detail.md`** — the per-rule detail and
  applicability notes for every group.

These two files are kept in sync with the normative spec (`xfa-en.tex
§ 11.3`) and with the xftools validator (`@xfcfam/tools`). Treat them
as authoritative; do not invent rules outside what they enumerate.

## Review procedure

> **Prefer the validator.** If you can run the `@xfcfam/tools` validator
> (step 0), it gives the authoritative structural verdict in one shot — use its
> `Λ` level and structural violations as the source of truth, then add the human
> semantic pass (steps 2–5) that a static tool cannot perform. Fall back to the
> fully manual walk (steps 1–5) when the tool can't run, or for languages whose
> parser is a stub (only TypeScript is fully covered).

### 0. Run the validator (`@xfcfam/tools`) — preferred

The model ships a reference validator that computes `Λ` exactly. Try it first
whenever the target is an **artefact root** (a directory containing `./src/`
plus a language manifest at its root). Run it with the Bash/shell tool:

```bash
# one-off, no install (fetches the published package on demand):
npx @xfcfam/tools validate <path>

# structured output for parsing:
npx @xfcfam/tools validate <path> --json
```

If the user will review repeatedly, **recommend installing it globally** — it is
much faster than re-fetching with `npx` each time:

```bash
npm i -g @xfcfam/tools     # installs the `xftools` command
xftools validate <path>    # then just run this
```

Use the tool's result directly:

- It prints a conformance level `Λ ∈ {0..4}` and lists violations by scope
  (structural / component / artefact) with rule id + `file:line`. Surface those
  in your report. Exit code is `0` when `Λ ≥ 3`, `1` when `Λ < 3`, `2` on a
  usage / runtime error.
- It is **capped at `Λ=3`**: a static tool cannot decide the 10 semantic rules.
  After a clean tool run, still perform the **semantic human pass** (steps 2 and
  5 plus the "Important notes" below) to judge whether the artefact also reaches
  `Λ=4`.

**Fall back to the manual walk (steps 1–5) when:**

- `node` / `npm` / `npx` is unavailable, or you are offline / the npm registry
  is unreachable (say so to the user) — never fail the review, just do it by hand.
- The target is a single snippet or one file, or otherwise not an artefact root.
- The language's parser is a stub (the tool runs path-based rules for every
  language but AST rules only for TypeScript) — its warnings name the skipped
  rules; cover those by reading the code.

### 1. Gather the code

If the user provided files or a directory, read them. If they pasted a
snippet, work with that. If scope is unclear, ask: "Which files or
directory should I review?"

### 2. Inventory the components

For each file / class / module, attempt a preliminary classification
along the XF matrix **L × T**:

- **Layer (L)** — Access (`/repository`), Business (`/business`),
  Interaction (`/api`). The optional `XF` start-point element at the
  `/src` root sits outside the L × T matrix (it is not a component).
- **Type (T)** — Logical, Generalization, Injection, Utility, Transfer,
  or Exception. Use `xf-classify`'s decision tree if uncertain.

If the codebase is XF-shaped already, the path itself (`/business/logic/
UserBusiness.ts`) gives the classification — `(business, logical)`.

### 3. Walk the catalogue

Open `../_shared/catalogue.md`. Iterate over every rule grouped by
`§ 11.3.X` (groups 1–9). For each rule:

- Decide whether it applies to the artefact's language (look at the
  rule's `appliesTo` if mentioned; path-based structural rules apply
  universally).
- If **structural**: evaluate it programmatically over the components
  inventoried in step 2. A violation caps conformance at `Λ=2`.
- If **semantic**: examine the relevant components by reading the code;
  a static tool cannot decide these, so flag findings as "semantic —
  human review". An outstanding semantic rule caps the static result at
  `Λ=3`.

For violation **descriptions and concrete examples**, consult
`../_shared/rules-detail.md` under the matching group heading.

### 4. Determine conformance level

Per the catalogue's "Conformance levels" table, assign `Λ(𝔄) ∈ {0,1,2,3,4}`
via the four-stage algorithm (classify → totality → catalog → level):

| Level | Meaning |
| :---: | --- |
| `Λ=0` | Non-conformant: no component classified in the L × T matrix. |
| `Λ=1` | Partially conformant: some components classified via injection, but **totality** fails (≥1 component unclassified). Stop here. |
| `Λ=2` | Imperfectly conformant: totality holds, but ≥1 **structural** violation. |
| `Λ=3` | Structurally conformant ("well-formed"): 0 structural violations, ≥1 **semantic** rule pending. **Maximum a static tool certifies.** |
| `Λ=4` | Perfectly conformant: zero violations of any kind (needs human semantic review). |

The XF start-point element is excluded from the totality predicate. As a
reviewer you may reach `Λ=4` only after the human semantic review; a purely
static pass tops out at `Λ=3` — state which one you performed.

### 5. Report

Use this structure:

**Summary**
- Conformance level: `Λ=_` (state whether static-only — ceiling `Λ=3` — or
  including human semantic review)
- Components reviewed: _
- Violations found: _ (structural: _, semantic: _)
- Language detected: _ (and coverage caveat if not TypeScript)

**Component inventory** — table: Component | Path | Layer | Type | Status

**Violations** — grouped by scope (structural / component / artefact),
each entry shows:
- Rule id (kebab-case from the catalogue) + its group (1–9)
- Component + file:line
- Verifiability (`structural` / `semantic`)
- Quoted code if available
- Suggested fix referencing `rules-detail.md` if non-trivial

**Recommendations** — ordered list of fixes to reach the next conformance
level, highest-impact first.

## Important notes for accurate review

- **Native runtime exceptions are valid transfer vehicles.** The XF
  doctrine (spec § 6, "Unidad conceptual de ambos flujos") accepts
  `Error` in JS/TS, `Exception` in Java/C#, `BaseException` in Python,
  etc. as well-formed vehicles of the exception flow. Custom
  `*Exception` components are a design choice for domain concepts, not
  an obligation. Do not flag `throw new Error(...)` as a violation per
  se.
- **Library packages (e.g. `@xfcfam/fs`) declare R/B/A as empty
  classes**: `private constructor() {}; static async init(): Promise<void> {}; static async terminate(): Promise<void> {}`.
  This is the structural placeholder pattern, not a violation. The
  underlying requirements are `structure-injection-missing`,
  `injection-init-missing`, `injection-terminate-missing`.
- **`main.ts` (the entry point) lives outside `/src`** (typically at
  the artefact root). xftools validates only `/src`; the entry point
  is the consumer's prerogative.
- **Generalizations may ramify by cross-cutting policy, not by
  functional split.** `RestRepository` is one Generalization for HTTP
  (whole protocol); `RetryRestRepository` adds retry policy.
  `FileRepository` covers the whole filesystem protocol;
  `CachedFileRepository` adds caching, `AuditedFileRepository` adds
  hooks. Multiple Generalizations in a package that divide by
  functionality (e.g. `FileReadRepository` + `FileWriteRepository`)
  are a design smell, not necessarily an XF violation.
- **Logical lifecycle invocation is constrained**: a Logical's
  `init()` / `terminate()` may only be called from `R` / `B` / `A` of
  its own layer; `XF` only ever invokes the injections. See rules
  `lifecycle-logic-init`, `lifecycle-logic-terminate`,
  `lifecycle-logic-instantiation`.
- **Direct Logical-to-Logical references are forbidden**: rule
  `layer-reference` (and `layer-skip` for skipping a layer). Access
  flows through the layer's Injection.
- **Upward *information* flow is not a violation.** Isolation constrains
  *dependencies*, not runtime data flow (§6.2.2). A Business component
  notifying the Interaction layer of a state change via events / the
  observer pattern — the lower layer mutates and notifies, the upper
  layer observes — keeps coupling descending while information ascends.
  Do not flag event emission upward as a `layer-reference` violation; do
  flag a lower layer that *imports or calls* an upper component.
- **Access utilities over primitive types are legitimately cross-layer.**
  `StringUtils` / `DateUtils` / `NumberUtils` / `ArrayUtils` in
  `repository/utils/` may be referenced from Business or Interaction
  without tripping `layer-skip` — this is the explicit primitive-types
  exception (§7.3.4). The carve-out is *only* for primitive-type utils;
  a domain utility (`TemperatureUtils`) referenced cross-layer is a real
  violation.
- **Transfers may carry self-contained operations.** Do not flag a
  Transfer method as `transfer-business-logic` merely for existing —
  `transfer-dependency` / `transfer-business-logic` fire only when the
  operation touches another component or models a business process
  (§7.3.5). `Temperature.toFahrenheit()` is conformant; rich framework
  types (collections, dates, promises) classify as Transfers.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — the intent behind each rule group (dependency vs data-flow direction, the primitive-utils exception, transfers-with-operations) so a review judges intent, not surface.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
