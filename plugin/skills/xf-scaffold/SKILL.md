---
name: xf-scaffold
description: >
  Use this skill when the user asks to "scaffold an XF project", "create an XF
  project structure", "generate the XF folder layout", "start a new project
  with XF architecture", "create XF components", "add a new repository/business/
  service to my XF project", or "generate XF-compliant boilerplate". Also
  trigger when the user wants to add a single new XF component (e.g., "add a
  UserBusiness to my project").
metadata:
  version: "0.2.0"
---

# XF Scaffold

Generate XF-compliant project structure and component boilerplate.

> **Reuse before you build.** Before writing a Utility, a Generalization, or a layer adapter, check the `@xfcfam/*` reference libraries ([`../_shared/libraries.md`](../_shared/libraries.md)) — persistence, HTTP, SQL, filesystem, server transports, retry/cache/pagination, scheduling and state machines already exist. Extend them instead of reinventing.

## Determine scope

Identify whether the user wants:
- **Full project scaffold** — new project from scratch (all folders + R/B/A stubs)
- **Single component** — add one new Logical, Utility, Transfer, or Generalization
- **Layer scaffold** — add a full layer to an existing project

Ask for missing information:
- Language / framework (TypeScript, Swift, Python, Kotlin, etc.)
- Project/module name
- Initial components (optional — can scaffold empty structure)

If the user did not specify, produce a TypeScript scaffold by default and note
the assumption.

## Scaffolding rules

Follow the canonical XF folder structure exactly. See `references/structure.md`
for the full layout per language.

### General rules (all languages)

1. Create folders in this order: `repository/`, `business/`, `api/`
2. Within each layer: `general/`, `logic/`, `transfers/`, `utils/`, then the
   injection file (`R`, `B`, `A`)
3. Recommended subfolders inside `logic/`:
   - `repository/logic/local/` and `repository/logic/remote/`
   - `business/logic/instance/` and `business/logic/device/`
   - `api/logic/service/` and `api/logic/gui/`
4. The injection files (`R`, `B`, `A`) go at the root of their layer folder,
   not inside a subfolder
5. Injection files are created before any Logical components

### Injection stub pattern

Every injector (`R` / `B` / `A`) is a **non-instantiable static class**
that must:
- Prevent instantiation (`private constructor()`)
- Expose its layer's Logical components as immutable, public static slots
  (`static readonly`)
- Declare a static `init()` and a static `terminate()` whose bodies do
  nothing but invoke each slot's `init()` / `terminate()`

The optional `XF` start-point element orchestrates the artefact lifecycle.
Bootstrap always runs the injections in this exact order (rule
`xf-init-mismatch`), and termination in reverse (`xf-terminate-mismatch`):
```
XF.init()      →  R.init(); B.init(); A.init()
XF.terminate() →  A.terminate(); B.terminate(); R.terminate()
```
Cross-layer access at runtime goes through the target layer's injection
(`B.userBusiness.getUser(id)`, `R.userRepository.fetch(id)`), never via
`new` or a direct logical-to-logical reference.

### Naming

Derive names from the domain concept, append the canonical suffix. Never name
by technology (use `UserRepository`, not `PostgresUserRepository` — the
technology is an implementation detail of the Access layer).

## Output format

### For a full project scaffold

1. Show the complete folder tree
2. Create each file using the Write tool, inserting appropriate boilerplate
3. After all files are written, list them with a one-line description each

### For a single component

1. State the classification: `Layer: Business | Type: Logical | Name: UserBusiness`
2. Show the target file path
3. Write the file
4. Show the diff needed in the Injection file to register the new component

### For files already present

If the user's project already has some files, read them first and adapt the
scaffold to fit the existing conventions (file extension, import style, class
vs function syntax).

Read `references/structure.md` for per-language boilerplate templates.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — the injection conduit, lifecycle exclusivity, and the cross-layer duplication mandate behind the scaffolding rules.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
