---
name: xf-library
description: >
  Use this skill when a developer asks which library to use for an
  implementation need — "what library should I use for X?", "is there an XF
  library for caching / Postgres / an HTTP client?", "recommend a package for
  <need> in my stack", "do I build this or is there a library?", "find me a
  reusable component for <need>". It frames the need as an XF capability and L×T
  cell, resolves the concrete package **live** in the developer's ecosystem
  (npm / NuGet / PyPI / Maven), and recommends the best fit — or tells them to
  hand-write it. Advice-only: it recommends and shows the wiring, it does not
  generate the implementation (hand that to `xf-implement`). For conceptual
  questions use `xf-explain`; to actually build, `xf-implement` / `xf-scaffold`.
metadata:
  version: "0.5.0"
---

# XF Library — reuse advisor

Recommend the **best-fit reusable library for an implementation need**, in the
developer's actual stack — or conclude that none fits and it should be
hand-written per the model. This is the front-end of the *reuse-before-you-build*
rule: the build skills (`xf-implement`, `xf-scaffold`, `xf-specify`) delegate the
"is there a library for this?" question here.

**Advice-only.** This skill produces a recommendation and the wiring shape, not
the implementation. When the choice is made, hand off to `xf-implement` (to
build the component) or `xf-scaffold` (to lay down the skeleton).

Read **[`../_shared/libraries.md`](../_shared/libraries.md)** first — it holds
the technology-agnostic **capability map** and the **live resolution protocol**
this skill executes. Do not duplicate it here; apply it.

## Core principle — resolve live, never from memory

The set of packages, their versions and their status change constantly across
ecosystems. **Never recommend a package or a version from memory or from a static
list.** Detect the ecosystem, query its registry, and report what the registry
says *now*. If you cannot reach the registry, say so and give the capability-level
recommendation (which base to extend, which L×T cell) without asserting a package
name or version.

## Procedure

### 1. Frame the need — capability, L×T cell, and "is it even an XF component?"

Restate the need as a **capability** from the map in `libraries.md` (persistence,
HTTP/REST, filesystem, SQL, a server transport, a cross-cutting policy such as
retry / cache / pagination / scheduling / observable state / a state machine) and
the **L×T cell / role** it would occupy. Two distinctions to make up front:

- **XF reference library vs. plain dependency.** Some needs are met by an *XF*
  library (a base Generalization / Utility you extend — e.g. a
  `DatabaseRepository` base). Others are a **low-level dependency** that is *not*
  an XF component at all (a DB driver, a JSON parser, a crypto primitive) — those
  are **encapsulated inside** the relevant Access (or layer-local Utility)
  component, never exposed across layers. Name which kind the need is.
- **Which layer.** The capability fixes the layer: external I/O → Access;
  cross-cutting policy → a Generalization in the layer that needs it; a pure
  helper → a Utility. State it, because a library that would force the wrong cell
  is the wrong library.

### 2. Detect the ecosystem

From the artefact's manifest: `package.json` → npm · `*.csproj` / `*.sln` →
NuGet · `pyproject.toml` / `requirements.txt` → PyPI · `pom.xml` / `build.gradle`
→ Maven / Gradle. If unknown, ask the developer for the target stack.

### 3. Resolve candidates live

Run the registry search from `libraries.md` for the capability — e.g.
`npm search @xfcfam` and `npm view @xfcfam/<pkg> version` for npm; the equivalent
official XF namespace search for NuGet / PyPI / Maven. Read the **current version
and status** from the registry. Also consider any plain (non-XF) dependency the
component would wrap, and check that it is maintained.

### 4. Recommend (or say "hand-write")

- **If an XF library fits:** name it, with the **version the registry reports**,
  the **base Generalization to extend**, and the **canonical folder** for its
  L×T cell. Prefer the most specific fit (a Postgres dialect adapter over a
  generic SQL base when the target is Postgres). If several fit, rank them and say
  why (specificity, maintenance, transitive weight).
- **If no XF library exists for this stack yet:** say so plainly and recommend
  **hand-writing the component per the model** — point to `xf-scaffold` /
  `xf-implement` — and name the plain dependency to encapsulate inside it (with
  its live version). Missing XF library ≠ blocked: hand-written is equally
  conformant.
- **If the need is trivial** (a few lines), recommend writing it directly rather
  than taking a dependency.

### 5. Show the wiring

Sketch how the recommendation slots into XF: the class extending the base, the
canonical folder, and the injection slot to register. Keep the dependency
**confined** to its component — a library detail must never leak across a layer
boundary (the whole point of the Access layer).

## Guardrails

- **Conveniences, not prescriptions.** XF prescribes only the L×T classification
  and the descending-dependency direction; a library is one way to satisfy them,
  never a requirement. Never imply a developer *must* use a given package.
- **Fit the cell, or reject it.** A library that would push domain logic into
  Access, or force an upward dependency, or sit in the wrong layer, is the wrong
  recommendation regardless of popularity.
- **Encapsulate.** A recommended dependency (XF or plain) lives inside one
  component; it is not referenced across layers.
- **Honest about uncertainty.** If the registry is unreachable or the namespace
  has nothing for the need, say "no XF library for this in <ecosystem> today"
  rather than guessing.

## Worked example (compact)

> "I need to read/write Postgres for a TypeScript service."

1. **Capability / cell:** SQL persistence → **Access · Logical** (a
   `*Repository`), extending an SQL **Generalization**; the Postgres driver is a
   plain dependency encapsulated inside the Access component.
2. **Ecosystem:** `package.json` → npm.
3. **Resolve live:** `npm search @xfcfam` → look for the SQL base + a Postgres
   dialect adapter; `npm view <pkg> version` for the current versions. (Report
   what the registry returns — do not assert a version here.)
4. **Recommend:** the SQL `DatabaseRepository` base + the Postgres dialect
   adapter the registry reports (most specific fit), each at its current version;
   or, if absent, hand-write a `DatabaseRepository` over the `pg` driver per the
   model.
5. **Wiring:** `class UserRepository extends DatabaseRepository<…>` in
   `repository/logic/remote/`, registered as a slot in `R`; the driver stays
   inside it.

## References

- **Reuse map & live-resolution protocol:** [`../_shared/libraries.md`](../_shared/libraries.md) — the capability map and the per-ecosystem registry search this skill runs.
- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — why a dependency must be encapsulated in its layer; effective vs contextual logic.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
