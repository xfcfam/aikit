---
name: xf-analyze
description: >
  Use this skill when the user hands you a client SPECIFICATION, a requirements
  document, an RFP, or a set of features and wants them FORMALIZED into an
  engineering plan — "analyze this spec", "formalize these requirements",
  "produce the SRS and ADRs", "turn this client spec into an XF design", "break
  this whole spec into artefacts/components/operations/tasks", "give me the
  requirements analysis and architecture for this". It runs the full pipeline:
  read specs → SRS + ADRs → decompose into XF artefacts → L×T component matrix
  and data model per artefact → operations → requirement↔operation traceability
  → dependency/call/data graphs → design verification → test plan → ordered task
  list. Design-only — it produces documents and a plan, never implementation
  code. For a SINGLE feature or user story (not a whole spec), use `xf-specify`.
  To analyze EXISTING code, use `xf-classify` / `xf-review`.
metadata:
  version: "0.5.0"
---

# XF Analyze — requirements to a verified XF design

Take a raw client specification and turn it into a **rigorous, traceable,
verified engineering plan** in the XF / CFAM Architecture Model (edition
**XF-CFAM-001:2026**). This is the bridge a developer needs: hand it the specs,
get back a formal **SRS**, the **ADRs** for the decisions that matter, the system
**decomposed into XF artefacts**, each artefact's **L×T component matrix +
operations**, a **bidirectional traceability matrix**, the **dependency / call /
data-flow graphs**, a **design-conformance verification**, a **test plan**, and a
**bottom-up implementation task list** — ready to hand to `xf-implement`.

The pipeline follows **ISO/IEC/IEEE 29148** (requirements engineering) and the
ADR practice, with XF as the concrete design target that makes every requirement
traceable down to a component operation.

## Scope and where this fits

- **Design-only.** This skill writes *documents and a plan*. It never writes
  implementation source. When the plan is agreed, hand the task list to
  **`xf-implement`**.
- **Delegates** to the focused skills — do not reinvent their work:
  - per-artefact component plan + operations → **`xf-specify`**
  - design / conformance verification → **`xf-review`** (and the `@xfcfam/tools`
    validator once anything is scaffolded)
  - test design per L×T cell → **`xf-test`**
  - classifying or auditing *existing* code → **`xf-classify`** / **`xf-review`**
- **Use `xf-specify` instead** when the input is a single feature or user story.
  `xf-analyze` is for a whole specification: multiple requirements, NFRs,
  decisions, and — usually — more than one artefact.

Read **`../_shared/foundations.md`** (the model's intent — especially the
artefact as the canonical scale, §5.2), **`../_shared/catalogue.md`** (the rules
you will verify the design against), and the `xf-classify` decision tree
(`../xf-classify/references/decision-tree.md`). Output formats, the SRS/ADR
templates and a full worked example are in
[`references/templates.md`](references/templates.md).

## Operating principles (the rigor)

1. **Never invent requirements.** If the spec is silent, ambiguous, or
   self-contradictory, record it as an **open question** for the stakeholder —
   do not fill the gap with an assumption. Mark assumptions explicitly when one
   is unavoidable to proceed.
2. **Every requirement is atomic, uniquely identified, and verifiable** (29148):
   one testable statement per ID, with acceptance criteria. If you cannot write
   an acceptance criterion for it, it is not yet a requirement.
3. **XF pre-decides the structure.** The layering, the injection pattern (R/B/A),
   the lifecycle and the nomenclature are *prescribed by the model* — they are
   not architectural decisions. Write **ADRs only for what XF leaves open**
   (artefact boundaries, technology/library per Access component, generalization
   policies, where an ambiguous domain rule lives, NFR trade-offs, data stores,
   cross-artefact composition). Do not spend ADRs on what the model already
   fixes.
4. **Trace everything, both ways.** Every functional requirement maps to ≥1
   operation; every operation maps back to ≥1 requirement. Every NFR has a
   structural home. Uncovered requirements and orphan operations are defects you
   must surface, not hide.
5. **Verify the design before code.** The XF rules apply to the *design*: the
   component graph must be a strictly-descending DAG (layer isolation), the
   classification total, the names canonical. State the conformance of the design
   and block on any structural violation.

## The pipeline

Work the phases in order. Each phase has an explicit **exit criterion** — do not
advance until it holds (or the blocker is logged as an open question).

### Phase 0 — Intake & domain glossary

Read every input the user provided. Establish scope, stakeholders, and the
**ubiquitous language**: a glossary of the domain terms (these become Transfer /
component names later, so name them with the domain, never the technology). Ask
for anything load-bearing that is missing (NFRs, constraints, the target
platform, whether this extends an existing system).
**Exit:** scope stated; glossary drafted; missing inputs requested.

### Phase 1 — Software Requirements Specification (SRS)

Produce a structured SRS (template in `references/templates.md`):

- **Functional requirements** `FR-n`: each atomic, uniquely IDed, with a
  statement, source, priority, and **acceptance criteria** (Given/When/Then).
- **Non-functional requirements** `NFR-n`: performance, security, reliability,
  availability, usability, compliance, constraints — each **measurable**
  (a number or a check, not "fast").

**Exit:** every requirement is atomic, verifiable, and IDed; conflicts/gaps are
in the open-questions list.

### Phase 2 — Architecture Decision Records (ADRs)

For each genuine decision XF leaves open (principle 3), write one ADR (Nygard
format: context · decision · status · consequences · alternatives). Each ADR
**cites the NFR(s) or constraint(s) that forced it** — an ADR with no driving
requirement is either gold-plating or a hidden requirement to lift into the SRS.
**Exit:** every NFR/constraint that shapes the architecture is reflected in an
ADR; no ADR restates a decision XF already prescribes.

### Phase 3 — Decompose into XF artefacts

XF's canonical scale is the **artefact** = one complete formal process / bounded
context (§5.2). Partition the SRS into artefacts: for each, give its name, the
process it automates, its boundary (in/out), and the FRs/NFRs it owns. Record
inter-artefact relationships (composition via the `@xfcfam` ecosystem; direction
of dependency). A small spec may be one artefact; do not invent more than the
process structure justifies.
**Exit:** every FR is owned by exactly one artefact (or explicitly shared, with a
reason); artefact boundaries trace to an ADR when non-obvious.

### Phase 4 — L×T component matrix + data model (per artefact)

For **each** artefact, run the `xf-specify` design (steps 2–4 of that skill):
the components with their layer × type, canonical names and folders, and the
**Transfers** — derive the data model here (domain entities / value objects /
exceptions), naming each by the concept. Keep dependencies strictly descending.
**Exit:** total classification — every piece the artefact needs sits in exactly
one of the 15 L×T cells; no upward or lateral dependency.

### Phase 5 — Operations & traceability

For each Logical, derive its **operations** (`xf-specify` step 5: signature +
downward delegations). Then build the **bidirectional traceability matrix**
(template in `references/templates.md`):

`FR / NFR  ↔  artefact  ↔  component  ↔  operation  ↔  acceptance criterion / test`

Run the coverage checks and **report the results**:

- **Coverage:** every `FR` reaches ≥1 operation. List any uncovered FR.
- **No orphans:** every operation traces back to ≥1 FR. List any orphan
  (candidate gold-plating — remove or justify).
- **NFR homing:** every `NFR` maps to an ADR, a generalization/policy, a library
  choice, or an operation-level constraint. List any unhomed NFR.

**Exit:** coverage, orphan, and NFR-homing lists are produced (ideally empty).

### Phase 6 — Graphs

Produce three graphs (Mermaid templates in `references/templates.md`):

1. **Component dependency graph** — must be a **strictly-descending DAG**
   (Interaction → Business → Access). Any cycle or upward/lateral edge is a
   design defect to fix now.
2. **Operation call graph** — which operation calls which (through the
   injections). It yields the **bottom-up build order** (leaves = Access
   operations with no internal dependency).
3. **Data-flow graph** — which Transfers cross which boundaries.

**Exit:** graphs (1) and (2) are acyclic and descending; the build order is
derived.

### Phase 7 — Verify the design (pre-code conformance)

Check the design against the XF rule catalogue **without writing code**, using
`xf-review`'s catalogue: layer isolation (the DAG of Phase 6), totality of
classification, canonical naming, one injection per layer, injection shape. This
is the *structural conformance of the design*. Produce a short verification
report (template in `references/templates.md`): coverage %, the design
conformance findings, and the consistency checks (no cycles, no dangling
delegation). Once any structure is scaffolded, `xftools validate` confirms it for
real (a clean design targets **Λ=3**; semantic review reaches **Λ=4**).
**Exit:** the design is a clean descending DAG with total classification and
canonical names; every structural finding is either fixed or logged as a blocker.

### Phase 8 — Test plan

Map each FR's acceptance criteria to **tests** via `xf-test` (isolation per L×T
cell: a Business logical mocks `R`, an Interaction logical mocks `B`, Access
gets contract/integration tests, Utilities are pure-function tests). Produce a
test plan: per operation/component, the test kind, what it mocks, and the
acceptance criterion it covers.
**Exit:** every acceptance criterion maps to ≥1 test.

### Phase 9 — Handoff

Assemble the deliverables (below), present the **bottom-up implementation task
list** (from the Phase 6 call graph) ready for `xf-implement`, and surface the
**open-questions list** for the stakeholder. State the conformance level the
design targets and what remains to confirm it.

## Deliverables

Write these as files (offer Markdown by default; adapt paths to the repo):

| File | Content |
|---|---|
| `docs/SRS.md` | The Software Requirements Specification (FRs + NFRs, IDed, acceptance criteria, open questions). |
| `docs/adr/NNNN-<title>.md` | One ADR per decision (Nygard format). |
| `docs/architecture/DESIGN.md` | Artefact map · per-artefact L×T matrix + data model · operations · traceability matrix · the three graphs · verification report · test plan · task list. |

For a small spec these may collapse into a single `docs/ANALYSIS.md` with the
same sections. Keep the SRS and ADRs separately addressable — they are the
artefacts a stakeholder reviews and signs off.

## Quality gate (definition of done)

Before handing off, confirm every box (the full checklist is in
`references/templates.md`):

- [ ] Every requirement is atomic, IDed, and has acceptance criteria.
- [ ] Every architectural decision XF leaves open has an ADR citing its driver.
- [ ] The spec is decomposed into artefacts; every FR is owned.
- [ ] Each artefact's components are totally classified in L×T; deps descend.
- [ ] Every Logical's operations are specified (signature + delegations).
- [ ] Traceability holds both ways: no uncovered FR, no orphan operation, every
      NFR homed.
- [ ] The dependency and call graphs are acyclic and strictly descending.
- [ ] The design verification is clean (or blockers are logged).
- [ ] Every acceptance criterion maps to a test.
- [ ] Open questions are listed for the stakeholder; assumptions are explicit.

## Final note

This skill produces the plan, not the code. Resolve the open questions with the
stakeholder, then hand the task list to **`xf-implement`** (which re-runs the
validator after generating into an XF artefact) and the test plan to
**`xf-test`**. Keep the SRS, ADRs and traceability matrix **maintained**: when a
requirement changes, the traceability matrix is what tells you which operations,
components and tests are affected.

## References

- **Templates & worked example:** [`references/templates.md`](references/templates.md) — SRS & ADR formats, the traceability matrix, the Mermaid graphs, the verification report, the per-phase definition-of-done, and an end-to-end example.
- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — the artefact as canonical scale, effective vs contextual logic, the particularities the design must respect.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before specifying a utility or generalization to build by hand.
