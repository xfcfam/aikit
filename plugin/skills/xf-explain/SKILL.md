---
name: xf-explain
description: >
  Use this skill when the user asks to "explain XF", "what is the XF model?",
  "explain CFAM", "how does the injection pattern work?", "what is the difference
  between Business and Interaction?", "why can't Interaction call Access?",
  "what does Λ=2 mean?", "explain the layer system", "what suffix should I use?",
  "how do I use R, B, A?", or any question about understanding the XF
  Architecture Model concepts, principles, or decisions.
metadata:
  version: "0.2.0"
---

# XF Explainer

Answer questions about the **XF Architecture Model — Cross-Framework
Architecture Model (CFAM)** with precision and concrete examples.

## Approach

### Ground answers in the spec

The XF model has a formal specification. Do not improvise classifications or
invent new rules. Every answer must be consistent with the canonical model:

- **3 layers** (low→high abstraction): Access (`§ 7.2.1`) · Business
  (`§ 7.2.2`) · Interaction (`§ 7.2.3`)
- **5 types**: Logical · Generalization · Injection · Utility · Transfer
  (plus the **Exception** sub-type of Transfer, suffix `*Exception`, used as
  vehicle of the exception flow). The **L × T matrix** = 3 layers × 5 types =
  15 cells, total and exhaustive.
- **1 optional XF start-point element**: `XF`, the artefact-level lifecycle
  orchestrator at `/src/XF.<ext>`
- **3 injectors**: `R` (Access) · `B` (Business) · `A` (Interaction)
- **Dependency direction**: Interaction → Business → Access (downward only)
- **Conformance levels**: `Λ=0` · `Λ=1` · `Λ=2` · `Λ=3` · `Λ=4` (function
  `Λ(𝔄) ∈ {0,1,2,3,4}`, `§ 11.2` / `§ 11.4`)

For any answer that requires citing a rule, read the canonical catalogue at
`../_shared/catalogue.md` (rule ids, verifiability, spec ref) and the
detail at `../_shared/rules-detail.md` (per-rule prose and examples).
Treat these files as authoritative; they mirror the normative spec
(`xfa-en.tex § 11.3` — **71 rules across 9 groups**) and the xftools
validator.

### Explain the *why*, not just the *what*

For any "why" question — and for any explanation that benefits from the
model's intent — read [`../_shared/foundations.md`](../_shared/foundations.md)
first. It carries the reasoning the rules are derived from (spec §5, §6.2):

- **Software automates formal processes.** A system does not create processes,
  it *formalizes* them, so the artefact's structure is **isomorphic** to the
  process it models (§5.1). Architecture is a *derived property* of the
  process, not a developer or framework choice. This is why analysis precedes
  design.
- **Three layers, derived not invented.** Every formal process decomposes into
  processing (necessary) + interaction/access (the two exhaustive, mutually
  exclusive directions of communication). Four independent traditions — BPMN,
  CSP/π-calculus, the Actor Model, IPO — converge on it (§5.2). The three
  layers correspond biunivocally to these three stages (§5.5). That is the
  answer to "why exactly three layers?".
- **XF is a META-MODEL, not an architecture.** It is a *reference model*
  (ISO/IEC/IEEE 42010) — an abstraction layer *over* Clean, Hexagonal, Onion,
  DDD, MVC, layered. Those are **instances** that project into the XF
  vocabulary. Never frame it as "XF vs Clean" or "XF is better than X"; frame
  it as the formal target that explains *why* they converge. XF's contribution
  is **vocabulary**, not structure (§5.2): the structure is already present in
  every artefact; XF makes it recognizable across technologies. The
  fragmentation it removes is *terminological* (heterotechnical synonymy,
  interframework homonymy — §5.4), not structural.
- **The OSI analogy** (§5.5): XF does not subdivide OSI's Application Layer; it
  extends OSI's stratification principle to an *orthogonal* dimension — OSI
  stratifies communication *between* artefacts, XF stratifies the *internal*
  structure of each artefact.

### Use concrete examples

Abstract explanations are hard to act on. After every conceptual answer:
1. Give a concrete example in code (pseudo-code or the user's language)
2. Show the correct pattern (✓) and a wrong pattern (❌) when clarifying a rule

### Adapt to the user's context

If the user has a codebase open or has shared code, ground examples in their
actual code. "In your case, the `UserManager` class would be split into…" is
more useful than a generic example.

If the user's question implies a common misconception, address it directly:
- "Service in XF means Interaction Logical, not Business Logical — unlike
  the naming in some frameworks."
- "Transfer objects in XF have no methods; this is stricter than DTO patterns
  that allow computed getters."

### Explain design rationale when useful

The XF model makes specific choices. If the user asks "why", explain:
- **Downward-only dependencies** — prevents circular imports, keeps Business
  testable without framework setup, allows the Access layer to be swapped
  without touching Business.
- **Exactly 3 injectors** — one per layer. More injectors create ambiguity
  about which entry point to use. Fewer breaks the layer isolation.
- **Closed classification** — the 15 L×T categories are exhaustive. Every
  component fits somewhere. This makes architecture reviews mechanical
  (no judgment calls about "what counts as architectural").
- **Technology-agnostic naming** — `UserRepository` not `PostgresUserRepository`
  because the technology is a detail of the Access layer, not a domain concept.

## Common question patterns

### "What layer does X belong to?"
Apply the decision tree:
1. Talks to external system (DB, API, file)? → Access
2. Contains domain rules, business state? → Business
3. Entry point (HTTP, UI, event)? → Interaction
If it mixes concerns, it must be split.

### "What type is X?"
Walk the type detector (full version in `xf-classify`'s decision tree):
- Named `XF` at `/src/XF.<ext>`? → XF start-point element (lifecycle orchestrator)
- Named `R` / `B` / `A`? → Injection
- Only data fields + name ends in `Exception`? → Exception (sub-Transfer)
- Only data fields? → Transfer
- Pure functions, no state? → Utility
- Abstract base for Logicals in same layer? → Generalization
- Everything else → Logical

### "How do I access X from Y?"
Always go through the injector of the target layer:
- From Interaction → Business: `b.userBusiness.doSomething()`
- From Business → Access: `r.userRepository.fetch(id)`
- Never skip a layer or instantiate directly

### "What's the difference between X and Y?"
Common confusions:
- **Business vs Interaction**: Business is framework-free domain logic;
  Interaction is the entry point that receives external calls and delegates
  to Business.
- **Repository vs Service**: Repository is Access/Logical (I/O); Service is
  Interaction/Logical (entry point). They are in different layers with different
  responsibilities.
- **Transfer vs model/entity**: Transfer is a data container with no logic,
  no persistence annotations. It is the data that moves between components.
- **Structural vs semantic rules**: every rule carries
  `verifiability ∈ {structural, semantic}` (`§ 11.1.4`). A **structural**
  violation is decided by static analysis and caps conformance at `Λ=2`.
  A **semantic** rule requires human architectural review; a static tool
  cannot decide it, which is why the static result is capped at `Λ=3`
  rather than `Λ=4`. There are **61 structural** and **10 semantic** rules.
  (Older docs framed this as "Obligatorio vs Recomendado" / "mandatory vs
  optional" — that taxonomy is obsolete.)
- **Native Exception vs custom `*Exception` component**: BOTH are valid
  vehicles of the exception flow. Native runtime exceptions (`Error`,
  `Exception`, `BaseException`) are well-formed Transfers. Custom
  `*Exception` is an opt-in for domain concepts that the language doesn't
  express by itself. The model does NOT mandate wrapping every error.

### "What conformance level are we at?"
Assess against the five levels of `Λ(𝔄) ∈ {0,1,2,3,4}` (see
`_shared/catalogue.md`, `§ 11.2` / `§ 11.4`):
- `Λ=0`: non-conformant — no component is classified in the L × T matrix.
- `Λ=1`: partially conformant — some components are classified (via the
  injection structure) but the **totality** condition fails (≥1 component
  is not classified). The algorithm stops here.
- `Λ=2`: imperfectly conformant — totality holds, but ≥1 **structural**
  violation.
- `Λ=3`: **structurally conformant ("well-formed")** — totality holds, 0
  structural violations, but ≥1 **semantic** rule still pending human
  review. This is the **maximum a static tool can certify**.
- `Λ=4`: perfectly conformant — totality holds and zero violations of any
  kind. Requires human semantic review to confirm.

The XF start-point element is excluded from the totality predicate (it is
not a component). Ask the user to share their code or describe the state of
their project, then give a concrete assessment with the specific gaps to
reach the next level. The xftools validator (`@xfcfam/tools`) computes this
automatically and reports a static ceiling of `Λ=3`; if the user has it
installed, suggest running `xftools validate <path>`.

## Frequently misunderstood points

When the user asks something that touches one of these, address it directly:

- **`main.ts` (entry point) lives outside `/src`** — at the artefact root.
  xftools validates only `/src`; the entry point is the consumer's choice.

- **Library packages declare R/B/A as empty placeholder classes**
  (`private constructor() {}; static async init() {}; static async terminate() {}`),
  NOT `export {}`. The class structure is required; the body can be empty
  for libs that contribute Generalizations only. Rules:
  `structure-injection-missing`, `injection-init-missing`,
  `injection-terminate-missing`.

- **Generalizations ramify by cross-cutting policy, not by functional
  split**. `FileRepository` is ONE Generalization covering the whole
  filesystem protocol (read/write/list/watch/stream/temp). Subclasses like
  `CachedFileRepository` and `AuditedFileRepository` add policy (caching,
  audit) over the same protocol. Splitting into `FileReadRepository` +
  `FileWriteRepository` would be wrong — that's functional division.

- **Logical lifecycle invocation is constrained**: a Logical's `init()`
  and `terminate()` may only be called from `R` / `B` / `A` of its own
  layer (and `XF` only ever invokes the injections, never a Logical
  directly). Rules: `lifecycle-logic-init`, `lifecycle-logic-terminate`,
  `lifecycle-logic-instantiation`.

- **No direct Logical-to-Logical references**: a Business component cannot
  `import { OtherBusiness } from './OtherBusiness.js'` and call it. Access
  goes via `B.otherBusiness`. Rule: `layer-reference` (and `layer-skip`
  for skipping a layer). Type-only imports are exempt.

- **Parsers and similar transformers are Business, not Access**. A
  TypeScript-source parser, a SQL-query builder, a config-file parser:
  all are *logic over data*, not *I/O*. Access encapsulates I/O and
  external systems; pure transformation libraries (the TS compiler, an
  AST library) can be consumed from Business directly.

- **"Downward only" is about dependencies, not data flow.** Information
  *may* travel upward at runtime — a Business component can notify the
  Interaction layer of a state change — as long as no *dependency* points
  upward. The model prescribes event-oriented / observer communication for
  this: the lower layer mutates state and notifies; upper-layer observers
  react without the lower layer ever knowing them (§6.2.2). So never tell a
  developer data can't flow up — tell them the *coupling* stays descending.

- **The cross-layer duplication mandate.** When several layers need the same
  structural pattern (stateful observation, scheduling), each layer **must**
  implement its own Generalization — `StatefulRepository`, `StatefulBusiness`,
  `StatefulView` are three separate classes, by design (§6.2.2, §7.3.2). A
  cross-layer base would create a structural dependency between layers. Do not
  "DRY" a pattern across layers; the duplication is deliberate.

- **Access utilities over primitive types are cross-layer.** Utilities are
  normally layer-local, but Access-layer utilities over *primitive* types
  (`StringUtils`, `DateUtils`, `NumberUtils`, `ArrayUtils`) may be referenced
  from **any** layer without violating isolation — they carry no domain
  semantics and predate the stratification (§7.3.4). A utility over a *domain*
  concept (`TemperatureUtils`) stays layer-local. This is the carve-out in the
  `layer-skip` rule.

- **Logical vs Generalization is the parametricity test.** A component is a
  Generalization if its logic applies to >1 domain concept *without
  modification* (parametric over the domain — `StatefulBusiness<T>`); it is a
  Logical if its logic is *bound* to one concept (`TemperatureBusiness`).
  Effective logic (irreducible to a concept) lives in Logicals; contextual
  logic (shareable/generic) lives in Generalization/Utility/Transfer (§7.3.1,
  §7.3.2). A "generalization" that names a concrete concept has turned
  effective and belongs in a Logical.

- **Transfers may carry self-contained operations.** "Transfer = no methods"
  is a DTO oversimplification the model rejects. A Transfer *is* the data and
  **may** declare operations, provided they are self-contained: they touch
  only its own data and access no other component and model no business
  process (§7.3.5). `Temperature.toFahrenheit()` is fine; deciding to turn on
  the heating is a business process for a Logical. Rich framework types
  (collections, dates, promises, UI controls) **project** to Transfers without
  a rewrite.

## Tone and length

- Answer the specific question directly, then add context if relevant
- Do not over-explain the entire model for a narrow question
- Use short code snippets to illustrate; do not write full files in explanations
- Offer follow-up: "Want me to classify your existing components?" (xf-classify)
- If the user is about to write code, suggest `xf-scaffold` for templates
- If the user wants to audit existing code, suggest `xf-review`
  or "Should I scaffold this?" (xf-scaffold)

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — the *why* (formal-process automation, the tripartition, the meta-model framing, OSI) and the subtle points. Read it for any "why" question.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
