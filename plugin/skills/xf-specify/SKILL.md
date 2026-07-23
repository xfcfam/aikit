---
name: xf-specify
description: >
  Use this skill when the user asks to "turn these requirements into an XF
  design", "specify this feature in XF", "what components do I need for...",
  "plan the XF structure for this user story", "design this the XF way before I
  code", "break this requirement into XF layers", or hands you client
  requirements / user stories and wants them broken into a **programmable plan**
  — the components to implement, their L×T type, dependencies, and the
  **operations of each component** — before any code. Also trigger on "break
  these requirements into tasks", "what do I need to build for...", "turn this
  client requirement into an implementation plan / task list". This is
  design-only — no code is written.
metadata:
  version: "0.5.0"
---

# XF Specify

Translate client requirements or user stories into an **L×T component plan with
operations** for the XF / CFAM Architecture Model (edition **XF-CFAM-001:2026**)
— *before* any code exists. The output is a design a developer can hand straight
to implementation: the components the feature needs (each with its layer, type,
canonical name, target folder, and dependencies), the **operations of each
component** (signature + downward delegations), the R/B/A injection wiring and
folder layout, and a **bottom-up task list**. It is the bridge from raw
requirements to a programmable plan.

**This skill is design-only. It does not implement anything.** Once the plan is
agreed, hand it to **`xf-implement`** to generate the code. To classify
*existing* code use **`xf-classify`**; to audit code already written use
**`xf-review`**. For a whole client **specification** (many requirements, NFRs,
decisions, and usually several artefacts) — with a formal SRS, ADRs, traceability
and verification — use **`xf-analyze`**, which runs this skill per artefact.

Read **`../_shared/catalogue.md`** (rule + conformance overview) and the
`xf-classify` decision tree (`../xf-classify/references/decision-tree.md`)
before decomposing.

> **Reuse before you build.** Before hand-writing a Utility, a Generalization, or a layer adapter, check whether a published **XF reference library for the developer's stack** already covers the need (persistence, HTTP, SQL, filesystem, server transports, retry / cache / pagination / scheduling / state machines). Resolve it **live** against the project's ecosystem registry (npm / NuGet / PyPI / Maven) per [`../_shared/libraries.md`](../_shared/libraries.md) — or ask the **`xf-library`** skill for a recommendation — and extend it rather than reinventing; hand-write only when none exists.

## The model in one screen

- **L × T matrix** — 3 layers × 5 types = 15 cells, exhaustive and closed.
- **Layers** (low → high abstraction): **Access** (`/repository`),
  **Business** (`/business`), **Interaction** (`/api`). Dependencies are
  **strictly descending**: Interaction → Business → Access. Never upward,
  never lateral.
- **Types**: Logical, Generalization, Injection, Utility, Transfer.
- **Injection** — exactly one per layer: **R** (Access), **B** (Business),
  **A** (Interaction). It instantiates and exposes that layer's Logicals and
  is the only conduit downward: `<injection>.<component>.<operation>()`, e.g.
  `B.session.refresh()`, `R.database.fetch()`, `A.temperatureService.update()`.
- **Transfers** are the data objects that *flow* between components (they may carry self-contained operations on their own data); they are
  the payload of every operation.
- **Nomenclature**: Access Logical → `*Repository`; Business Logical →
  `*Business`; Interaction Logical → `*Service` (systemic) / `*View`
  (graphical); Utility → `*Utils`; Generalization → its layer's logical
  suffix; Transfer → the domain concept with **no** suffix (exceptions →
  `*Exception`).

## Procedure

### 1. Restate the requirement as the process it automates

Rewrite the user story as the formal process the system must perform and the
data it moves — strip the UI wording and name the inputs, the transformation,
and the outputs. This is the anchor for the decomposition.

> Story: "As a user I want to log in with my email and password so I can access
> my account."
> Process: *Given an email and a password, verify them against the stored user
> record and, if valid, issue a session token; otherwise reject.*

### 2. Decompose into components per layer

Ask, in this order, what the process needs in each layer (top-down from the
actor, but remember dependencies run the other way):

- **Interaction (`/api`)** — where does the actor enter? An HTTP/RPC endpoint
  (`*Service`) or a GUI screen (`*View`). One Logical per entry point.
- **Business (`/business`)** — what domain rules, invariants, or orchestration
  apply? One `*Business` Logical per cohesive domain responsibility. Note any
  cross-cutting policy that several Logicals share (→ a Generalization) and any
  pure domain helper (→ a Utility).
- **Access (`/repository`)** — what external systems must be reached (DB, REST,
  files, device/sensor)? One `*Repository` Logical per external system /
  bounded transport.

Only include the layers the feature actually touches. A pure computation with
no persistence and no entry point may be a single Business component.

### 3. Assign each its type and canonical name

For every component decided in step 2, fix its **type** (Logical /
Generalization / Injection / Utility / Transfer) and its **canonical name** via
the nomenclature. The file name (no extension) will equal the class name. Name
by the **domain**, never by technology (`UserRepository`, not
`MySqlUserRepository` — the technology is an Access implementation detail).

### 4. Define the Transfer objects and the descending dependencies

- **Transfers** — list every data object that flows: raw records out of Access
  (`repository/transfers/`), domain entities/value objects in Business
  (`business/transfers/`), request/response shapes in Interaction
  (`api/transfers/`). Errors that are a domain concept become `*Exception`
  (a Transfer subtype).
- **Dependencies** — draw them strictly **descending** and always through an
  injection: an Interaction Logical depends on Business via `B.<x>`; a Business
  Logical depends on Access via `R.<x>`. Record each edge as "depends-on" in
  the plan. Flag (and forbid) any edge that would point upward or sideways.

### 5. Derive each Logical's operations — the programmable task list

This is the step that turns the component plan into tasks a developer can pick
up. For each **Logical** component, read the restated process (step 1) and
enumerate its **operations** — one per atomic domain action the component owns
(§7.3.1: an operation maps 1:1 to a well-defined action on the concept the
component models). For each operation give:

- **Signature** — `name(input: Transfer | primitive, …) -> output: Transfer`.
  Inputs and outputs are the Transfers from step 4 (or primitives). A domain
  error surfaces as one of the `*Exception` Transfers.
- **Delegations** — the downward calls the operation makes, in the canonical
  access pattern: a Business op reaches Access as `R.<repo>.<op>()`; an
  Interaction op reaches Business as `B.<biz>.<op>()`; pure helpers are
  `*Utils.<op>()`. These are the operation's edges in the call graph — they
  dictate the build order.

Derive top-down from the entry point, but note you will **build bottom-up**: an
Interaction op calls Business ops, which call Access ops, so Access operations
are the leaves with no internal dependencies. Transfers carry only
self-contained operations on their own data (derive/transform) — a Transfer is
never a task that orchestrates other components.

### 6. Output the plan: components, operations, wiring, layout

Produce the artefacts below.

**(a) Component plan**

| Component | Layer | Type | Canonical name | Folder path | Depends-on |
|---|---|---|---|---|---|
| Login endpoint | Interaction | Logical (systemic) | `AuthService` | `src/api/logic/service/AuthService` | `B.authBusiness` |
| Credential check + session mint | Business | Logical | `AuthBusiness` | `src/business/logic/instance/AuthBusiness` | `R.userRepository`, `PasswordUtils` |
| Password hashing helper | Business | Utility | `PasswordUtils` | `src/business/utils/PasswordUtils` | — |
| Issued session | Business | Transfer | `Session` | `src/business/transfers/Session` | — |
| Users table reader | Access | Logical | `UserRepository` | `src/repository/logic/remote/UserRepository` | — |
| Raw user record | Access | Transfer | `User` | `src/repository/transfers/User` | — |
| Invalid-credentials error | Business | Transfer (Exception) | `InvalidCredentialsException` | `src/business/transfers/InvalidCredentialsException` | — |

**(b) Injection wiring (R / B / A)** — which slot each injection exposes and
the lifecycle order:

```
R  (Access)       slots: userRepository
B  (Business)     slots: authBusiness
A  (Interaction)  slots: authService

init    : R.init() → B.init() → A.init()        // ascending
terminate: A.terminate() → B.terminate() → R.terminate()   // descending

XF (optional, executable artefacts only)
  init()      = R.init(); B.init(); A.init()
  terminate() = A.terminate(); B.terminate(); R.terminate()
  // entry point (main) lives OUTSIDE the artefact root; it calls XF.init/terminate
```

**(c) Folder layout** — only the folders this feature populates:

```
src/
├── XF                              ← (optional) lifecycle orchestrator
├── api/
│   ├── A                           ← Injection
│   └── logic/service/AuthService
├── business/
│   ├── B                           ← Injection
│   ├── logic/instance/AuthBusiness
│   ├── utils/PasswordUtils
│   └── transfers/{Session, InvalidCredentialsException}
└── repository/
    ├── R                           ← Injection
    ├── logic/remote/UserRepository
    └── transfers/User
```

**(d) Operations per component** — the actual work to implement:

| Component (cell) | Operation | Signature | Delegates to |
|---|---|---|---|
| `UserRepository` (Access · Logical) | `findByEmail` | `findByEmail(email: string) -> User \| null` | — (DB driver) |
| `PasswordUtils` (Business · Utility) | `verify` | `verify(plain: string, hash: string) -> boolean` | — |
| `AuthBusiness` (Business · Logical) | `login` | `login(email: string, password: string) -> Session` *(throws `InvalidCredentialsException`)* | `R.userRepository.findByEmail`, `PasswordUtils.verify` |
| `AuthService` (Interaction · Logical) | `handleLogin` | `handleLogin(req) -> response` | `B.authBusiness.login` |

Each row is one unit of work. The `init()` / `terminate()` pair of every Logical
is implicit — list it only when it has real setup/teardown.

**(e) Implementation task list (bottom-up)** — ordered so every dependency is
built before its caller (leaves first: Access → Business → Interaction):

1. `User` Transfer (`repository/transfers/`) — the raw record shape.
2. `UserRepository.findByEmail` (Access) — read the users table; register the slot in `R`.
3. `PasswordUtils.verify` (Business) — pure constant-time hash compare.
4. `Session` + `InvalidCredentialsException` Transfers (`business/transfers/`).
5. `AuthBusiness.login` (Business) — orchestrates 2 + 3, mints the `Session`; register in `B`.
6. `AuthService.handleLogin` (Interaction) — HTTP entry; calls 5; register in `A`.
7. Wire lifecycle: `R.init() → B.init() → A.init()` (and the optional `XF`); `main` stays outside the root.

Hand this list to **`xf-implement`** to generate each task, or work it top to
bottom by hand.

Cross-check the plan against the relevant rule groups (catalogue
`../_shared/catalogue.md`): canonical folders & names (group 1), strictly
descending dependencies (group 2), correct suffix per Logical (group 3),
injection shape and symmetric lifecycle (group 5), pure Utilities (group 6),
dumb Transfers (group 7). A clean plan implemented faithfully targets **Λ=3**
(structural ceiling); **Λ=4** also needs human review of the semantic rules.

### 7. Flag open questions and ambiguities

End with an explicit list of what the requirement left undecided, so the user
can resolve it before code is written. Common ones:

- Is an entry point in scope, or is this a library (no `*Service`/`*View`, no
  `XF`)?
- Does any external system exist yet, or is the Repository a stub for now?
- Which `*Business` owns a rule that could plausibly sit in two places?
- Is an error a domain concept (→ `*Exception`) or just a runtime failure
  (no wrapper needed)?
- Is there shared behaviour that justifies a Generalization, or is it premature?
- Where does the artefact root hang in the repo (multiple roots may coexist)?

## Final note

The deliverable is a plan, not code — never write implementation files from
this skill. Keep every dependency descending and routed through an injection,
name by the domain, and surface the cells the feature genuinely needs (do not
invent empty layers). When the user is happy with the plan, point them at
**`xf-implement`** to generate the components, or at **`xf-scaffold`** to lay
down the empty folder + R/B/A skeleton first.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — restating a requirement as the formal process it automates, and the duplication mandate / upward-events particularities that shape the component plan.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
