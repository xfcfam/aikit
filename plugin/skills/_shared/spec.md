# XF / CFAM — normative specification reference

The single source of truth for everything in this plugin is the **XF
Architecture Model** normative specification (Cross-Framework Architecture
Model, CFAM), edition **XF-CFAM-001:2026**.

- **Specification & documentation:** <https://xfcfam.org>
- **Reference implementation (TypeScript libraries):** the `@xfcfam/*` packages
  on npm — see [`libraries.md`](./libraries.md).
- **Conformance validator:** `@xfcfam/tools` (`xftools`), which computes the
  conformance level Λ. The rule catalog mirrored locally in
  [`catalogue.md`](./catalogue.md) and [`rules-detail.md`](./rules-detail.md) is
  generated from it via `bin/sync-from-spec.sh` — **do not hand-edit those two.**
- **Foundations & particularities:** [`foundations.md`](./foundations.md) — the
  *why* behind the model (software as formal-process automation, the invariant
  tripartition, the meta-model framing, the OSI analogy) and the subtle points
  a faithful skill must get right (dependency vs data-flow direction, the
  cross-layer duplication mandate, the Access primitive-utils exception,
  effective vs contextual logic, transfers-with-operations). Read it whenever a
  task needs the model's intent, not just its rules.

## Where to look in the spec

| Topic | Clause |
|---|---|
| Foundations — software as automation of formal processes; the invariant tripartition (interaction · processing/business · access) | § 5 |
| The XF model + the four guiding principles (technological agnosticism, layer isolation, architecture over tool, closed & exhaustive typing) | § 6 |
| Taxonomy — the L×T matrix, the three layers, the five types | § 7.1–7.3 |
| Canonical folder structure (`/general`, `/logic`, `/transfers`, `/utils` + `R`/`B`/`A`) | § 7.4 |
| Instantiation & lifecycle — start-point element, init/terminate order | § 8 |
| Data flows / transfers | § 9 |
| Compatibility & the `@xfcfam` library ecosystem | § 10 |
| Conformance — model, the five levels Λ=0..4, the 71-rule catalog, the determination algorithm | § 11 |
| Ontology / glossary of coined terms | § 12 |

When a skill needs to justify or deepen a rule, cite the clause above and link
<https://xfcfam.org> rather than restating the specification inline.
