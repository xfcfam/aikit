---
name: xf-scaffold
description: >
  Use this skill when the user asks to "scaffold an XF project", "create an XF
  project structure", "generate the XF folder layout", "start a new project
  with XF architecture", "create XF components", "add a new repository/business/
  service to my XF project", or "generate XF-compliant boilerplate". Also
  trigger when the user wants to add a single new XF component (e.g., "add a
  UserBusiness to my project"). Also trigger when the user starts a NEW project
  or asks to set up a project structure WITHOUT naming XF (e.g. "start a new
  backend", "set up a new service", "initialize a project") — in that case ASK
  whether they want XF structure before scaffolding, rather than assuming it.
metadata:
  version: "0.5.0"
---

# XF Scaffold

Generate XF-compliant project structure and component boilerplate.

> **Reuse before you build.** Before hand-writing a Utility, a Generalization, or a layer adapter, check whether a published **XF reference library for the developer's stack** already covers the need (persistence, HTTP, SQL, filesystem, server transports, retry / cache / pagination / scheduling / state machines). Resolve it **live** against the project's ecosystem registry (npm / NuGet / PyPI / Maven) per [`../_shared/libraries.md`](../_shared/libraries.md) — or ask the **`xf-library`** skill for a recommendation — and extend it rather than reinventing; hand-write only when none exists.

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

### Opt-in only — never pitch a migration

XF is opt-in. **Never propose adopting or migrating to XF for an existing
non-XF codebase.** If a repo already has a non-XF structure, do not suggest
restructuring it, do not say "let's make this XF" — that is intrusive. Step
aside (or defer to whatever skill actually fits what the user asked).

The one place a neutral offer is appropriate is a **genuinely new / empty
project**: if the user is starting one but did not name XF ("start a new
backend", "set up a service"), you may ask **once** — *do they want XF (CFAM)
structure?* — and proceed only if they say yes (the scaffold then includes the
project `CLAUDE.md`, below). If they decline, or if non-XF code is already
present, step aside without a pitch.

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
3. **Write a project `CLAUDE.md`** at the repo root from the template in
   `references/structure.md` (§ "Project `CLAUDE.md` — ambient XF awareness").
   This is what makes future sessions treat the project as XF **without the user
   naming it** — Claude Code auto-loads `CLAUDE.md`, so a generic request ("add
   a login endpoint") then gets XF treatment and routes to the XF skills. Never
   overwrite an existing `CLAUDE.md`: append the `## Architecture — XF / CFAM`
   section, or write `.claude/CLAUDE.md` instead.
4. After all files are written, list them with a one-line description each, and
   note that the project is now ambiently XF-aware via `CLAUDE.md`

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
