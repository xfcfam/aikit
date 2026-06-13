---
name: xf-document
description: >
  Use this skill when the user asks to "document this XF artifact", "generate
  architecture docs for my XF project", "create a component catalog for my XF
  project", "create a README for my XF artifact", "explain the structure of
  this XF codebase", "produce an injection map", or "document the layers of my
  XF code". Also trigger when the user wants Markdown documentation,
  architecture docs, or a component inventory derived from an XF / CFAM
  codebase.
metadata:
  version: "0.4.0"
---

# XF Documentation Generator

Generate documentation for an **XF Architecture Model (CFAM)** artefact by
reading its canonical structure and projecting it into a component catalog,
an injection map, a layer-dependency view, and model-aligned doc stubs.

XF documentation is **descriptive, not prescriptive**: it narrates a
structure that the canonical folders already make self-evident
(`/business/logic/UserBusiness.ts` *is* `(Business, Logical)`). The value is
in collecting that structure into one navigable view and keeping it in sync
with conformance — never in inventing structure that the code does not show.

For the canonical layout and the rule catalog, read
`../_shared/catalogue.md` and `../_shared/rules-detail.md`. Treat them as
authoritative; they mirror the normative spec (`xfa-es.tex`, edition
`XF-CFAM-001:2026`).

## Procedure

### 1. Detect the artefact root(s)

An **artefact root** is any directory that holds the L×T matrix — a `src/`
(or equivalent) containing the canonical layer folders `repository/`,
`business/`, `api/`. The matrix may hang from any path, and **multiple roots
can coexist** in one repository (e.g. a monorepo). Documentation scope is
**per root**, exactly like verification.

1. Glob for `repository/`, `business/`, `api/` sibling folders to locate each
   root. Confirm the set with the user if more than one is plausible.
2. For each root, note whether an optional `XF` start-point element is
   present (`src/XF.<ext>`).
3. Remember that the **entry point (`main`) and tests live OUTSIDE the
   artefact root** — they are not L×T components and do not appear in the
   catalog.

### 2. Build the component catalog (by L×T cell)

Walk each root and classify every file by its path into the L×T matrix —
3 layers × 5 types = 15 cells. The path gives the classification directly
(`api/logic/service/UserService.ts` → `(Interaction, Logical / Service)`);
use `xf-classify`'s decision tree only for anything that resists path
classification.

Emit **one table per layer**, listing every component in that layer:

#### Access layer (`/repository`) — descends to nothing inside the artefact

| Component | Type | Canonical name | Path | Responsibility |
| --- | --- | --- | --- | --- |
| User repository | Logical | `UserRepository` | `repository/logic/remote/UserRepository.ts` | Fetch/persist users over HTTP |
| Config repository | Logical | `ConfigRepository` | `repository/logic/local/ConfigRepository.ts` | Read local configuration |
| R | Injection | `R` | `repository/R.ts` | Exposes & wires Access logicals |

Repeat for **Business** (`/business`) and **Interaction** (`/api`). Within a
layer, group rows by type in this order: Injection, Logical, Generalization,
Utility, Transfer (Exceptions listed under Transfer as a subtype). Derive the
"Responsibility" column from docstrings/comments if present, otherwise from
the component's public operations — keep it to one line.

The canonical folders for every cell (`§ 7.4`):

```
/src/<repository|business|api>/{general, logic, transfers, utils}  +  {R|B|A}
```

Recommended `/logic` subdivisions: `api → gui/service`,
`business → instance/device`, `repository → local/remote`. The file name
(without extension) equals the canonical class name.

### 3. Produce the injection map

The injection components `R`, `B`, `A` (one per layer) are the only
sanctioned access conduit. Document, per layer:

- **What the injection exposes** — each static logical slot and the
  operations that slot offers, written as the canonical access path
  `<injection>.<component>.<operation>()`, e.g. `B.session.refresh()` or
  `R.userRepository.fetch(id)`.
- **The init/terminate wiring** — which slots `init()` constructs and in
  what order, and the symmetric `terminate()`.

Present it as a table plus the lifecycle order:

| Injection | Layer | Exposes (slots) | Canonical access |
| --- | --- | --- | --- |
| `R` | Access | `userRepository`, `configRepository` | `R.userRepository.fetch(id)` |
| `B` | Business | `userBusiness`, `sessionBusiness` | `B.session.refresh()` |
| `A` | Interaction | `userService`, `mainView` | `A.userService.handle(req)` |

```
init:       R.init()  →  B.init()  →  A.init()
terminate:  A.terminate()  →  B.terminate()  →  R.terminate()
```

If an `XF` start-point element exists, document it as the wrapper:
`XF.init() = R.init(); B.init(); A.init()` and `XF.terminate()` in reverse.
Note that logicals are reached **only** via their layer injection and are
never `new`-ed elsewhere.

### 4. Produce the layer-dependency view

Dependencies run strictly **descending**: Interaction → Business → Access —
never upward, never lateral. Document this as a directed view and name the
**Transfers that flow** across each boundary (the data carried between
layers).

```
┌──────────────┐      Transfers (User, Session, …)
│ Interaction  │  ───────────────────────────────►  Business
│   (/api)     │
└──────────────┘
        Business  ───────────────────────────────►  Access
                                                     (/repository)
```

State the rule plainly: a higher layer reaches a lower one only through that
lower layer's injection; Access depends on nothing inside the artefact.
Optionally render the same view as a Mermaid graph (see
`references/templates.md`).

### 5. Generate per-component doc stubs and a README section

For each component, produce a model-aligned doc stub / docstring that records
its L×T cell, its canonical access path, and its responsibility — in the
target language's docstring idiom (TSDoc, Javadoc, docstrings, …). Keep them
factual and aligned to the model; do not restate language obvious from the
signature. See `references/templates.md` for the docstring shapes and a
ready-to-paste **README architecture section** (overview, the per-layer
catalog tables, the injection map, the dependency view, and a conformance
line).

### 6. Output and sync note

- Offer the catalog as **Markdown** by default (a single `ARCHITECTURE.md` or
  a README section). Mention that the dependency view and injection map can
  additionally be rendered as **Mermaid diagrams** if the user wants visuals.
- Close with the **sync caveat**: this documentation describes structure that
  is already self-evident from the canonical folders, so it must be
  regenerated whenever the structure changes and **kept in step with
  conformance** (`xftools validate <root>` / the `xf-review` skill). Stale
  architecture docs are worse than none — point the reader at the validator
  as the source of truth for the current `Λ` level.

## Notes

- **Document per artefact root.** Never merge two roots into one catalog;
  each root is an independent matrix with its own injection map and `Λ`.
- **Tests and `main` are out of scope** for the catalog — they live outside
  the root and are not L×T components. The README may *link* to them, but
  they get no L×T row.
- **Do not invent responsibilities.** If a component has no docstring and an
  opaque body, say so rather than guessing; offer to run `xf-classify` or to
  read the implementation to fill the gap.
- Suggest `xf-review` to attach a live conformance level to the docs, and
  `xf-scaffold` if the user wants to fill in missing canonical pieces before
  documenting.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — the model's intent (artefact scale, the injection conduit, dependency vs data-flow direction) to frame an architecture narrative correctly.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
