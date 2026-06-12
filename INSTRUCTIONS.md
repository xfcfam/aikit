# XF Architecture Model — AI Code Generation Instructions

> **Canonical reference for XF-compliant code generation.**
> This file is intended to be read by any AI code-generation tool. It describes
> the XF Architecture Model (Cross-Framework Architecture Model, CFAM) in
> sufficient detail to produce XF-compliant software artefacts in any language
> or framework.

---

## 1. What is the XF Model?

The XF Architecture Model is a **technology-agnostic, layer-typed classification
system** for software components. Every component in an XF artefact belongs to
**exactly one layer** and **exactly one type**. This gives a total of 15 possible
categories (3 layers × 5 types).

The model applies equally to any programming language, framework, or paradigm.
It does not impose a technology stack — it imposes a structural discipline.

---

## 2. The Two Dimensions

### 2.1 Layers (L)

Layers are ordered by **level of abstraction**, from lowest to highest:

| ID  | Layer          | Also written | Responsibility |
|-----|----------------|--------------|----------------|
| 7.1 | **Access**     | Repository   | Communication with external systems (databases, APIs, file systems, hardware). Implements protocols, normalises raw data, hides I/O details. |
| 7.2 | **Business**   | Business     | Domain logic, business rules, domain state. Technology-independent. Has no knowledge of UI or external protocols. |
| 7.3 | **Interaction**| API / UI     | Entry points: graphical interfaces, REST/RPC services, event handlers, CLI, schedulers. Orchestrates Business; never accesses Access directly. |

**Dependency rule:** dependencies flow strictly downward.

```
Interaction  →  Business  →  Access
```

- Interaction may call Business.
- Business may call Access.
- Access calls nothing inside the artefact.
- No upward or lateral dependencies between layers.

### 2.2 Types (T)

Types describe the **functional role** of a component within its layer:

| Type              | Role |
|-------------------|------|
| **Logical**       | Implements the effective logic of the layer. One logical component per distinct concern. |
| **Generalization**| Abstracts common behaviour shared by multiple Logical components in the same layer. Logical components extend or implement it. |
| **Injection**     | Manages the lifecycle and centralised access to all Logical components in the layer. Exactly one Injection component per layer. |
| **Utility**       | Pure auxiliary operations (no state, no side-effects beyond their return value). Scope is local to the layer. |
| **Transfer**      | Data structures that travel between components or across layers. No logic. |

---

## 3. The 3 Injection Components

Every XF artefact has **exactly three Injection components**, one per layer:

| Symbol | Layer       | Conventional name |
|--------|-------------|-------------------|
| `R`    | Access      | R (Repository injector) |
| `B`    | Business    | B (Business injector)   |
| `A`    | Interaction | A (API/UI injector)     |

These are the **sole entry points** for accessing Logical components from outside
their layer. External code never instantiates Logical components directly.

### Canonical access pattern

```
<injector>.<component>.<operation>()
```

**Examples:**

```
B.session.refresh()        // Business layer → SessionBusiness
R.database.fetch(query)    // Access layer  → DatabaseRepository
A.temperatureService.update(data)  // Interaction layer → TemperatureService
```

### Initialisation order

At application startup, injection components are initialised in bottom-up order:

```
R.init()   →   B.init()   →   A.init()
```

Injection components are **static and non-instantiable**; their `init()` /
`terminate()` take **no arguments**. A higher layer reaches a lower one
statically through its injector — Business calls `R.<repo>.<op>()`, Interaction
calls `B.<biz>.<op>()`:

```
R.init()    // Access: wires its repositories
B.init()    // Business: wires its logicals (reaches Access via R.*)
A.init()    // Interaction: wires its services/views (reaches Business via B.*)
```

An optional `XF` start-point element centralises this as `XF.init()` (and
`XF.terminate()` in reverse order). The entry point (`main`) lives outside the
artifact root and calls only `XF.init()` / `XF.terminate()`.

---

## 4. Canonical Naming Conventions

| Component category                   | Suffix / convention   | Examples |
|--------------------------------------|-----------------------|----------|
| Access Logical                       | `Repository`          | `DatabaseRepository`, `IdentityRepository` |
| Business Logical                     | `Business`            | `UserBusiness`, `SessionBusiness` |
| Interaction Logical — service        | `Service`             | `AuthService`, `TemperatureService` |
| Interaction Logical — GUI/view       | `View`                | `LoginView`, `MainView`, `DashboardView` |
| Generalization (any layer)           | shares its layer's logical suffix | `AbstractRepository`/`...Repository`, `...Business`, `...Service`/`...View` |
| Injection                            | `R`, `B`, `A`         | (single-letter files or objects) |
| Utility (any layer)                  | `Utils`               | `StringUtils`, `DateUtils`, `TemperatureUtils` |
| Transfer (any layer)                 | Concept name, no suffix | `User`, `Temperature`, `Session`, `AuthToken` |
| Exception / error type (Transfer subtype) | `Exception`      | `NetworkException`, `AuthenticationException` |

> **Rule:** names are derived from the domain concept, not from the technology
> used. A component that reads from PostgreSQL is `DatabaseRepository`, not
> `PostgresConnector`.

---

## 5. Canonical Folder Structure

The folder layout is the physical materialisation of the L×T matrix. The
three layer-folder names (`/repository`, `/business`, `/api`) and the four
type-subfolder names (`/general`, `/logic`, `/transfers`, `/utils`) are an
**immutable normative contract**: conformity operates on these exact names.
A folder named `/access` instead of `/repository`, or `/structs` instead of
`/transfers`, is **not** recognised as conformant.

```
src/
├── api/                    ← Interaction layer (7.3)
│   ├── general/            ← Generalizations
│   ├── logic/              ← Logical components
│   │   ├── gui/            ← (recommended) Views
│   │   └── service/        ← (recommended) Services
│   ├── transfers/          ← Transfer objects
│   ├── utils/              ← Utilities
│   └── A                   ← Injection component
├── business/               ← Business layer (7.2)
│   ├── general/
│   ├── logic/
│   │   ├── instance/       ← (recommended) instance-scoped logic
│   │   └── device/         ← (recommended) device-scoped logic
│   ├── transfers/
│   ├── utils/
│   └── B                   ← Injection component
└── repository/             ← Access layer (7.1)
    ├── general/
    ├── logic/
    │   ├── local/          ← (recommended) local storage, files
    │   └── remote/         ← (recommended) network, APIs
    ├── transfers/
    ├── utils/
    └── R                   ← Injection component
```

The `/logic` subdivisions shown above (`gui`/`service`, `instance`/`device`,
`local`/`remote`) are **recommended, not required** — an artefact that omits
them is still conformant. The file name (without extension) **must** equal the
component's canonical class name.

> **Artifact root.** The L×T matrix above is an **artifact root**: any point
> in the file tree from which a complete L×T matrix hangs. `/src` is the
> *recommended* location, but the matrix may hang from **any** path, and
> **multiple artifact roots can coexist** in one project (one artifact ↔ one
> root, biunivocally). Conformity verification runs per root. The execution
> **entry point** (`main.ts`, `App.java`, `main.go`, …) lives **outside** the
> artifact root — it is not a classifiable component.

An optional `XF` start-point element at the root of the artifact can wire the
lifecycle (`XF.init()` / `XF.terminate()`); it does not belong to any layer
and is not a classifiable component.

---

## 6. Classification Rules

### What belongs in each layer

**Access layer (7.1) — ONLY:**
- Repository connections (DB, REST clients, file I/O, hardware drivers)
- Protocol-specific adapters (serialisation/deserialisation, query building)
- Data normalisation from external format to Transfer objects
- No business logic whatsoever

**Business layer (7.2) — ONLY:**
- Domain rules and invariants
- State of domain entities
- Computations that express business intent
- No awareness of UI, HTTP, databases, or any specific technology

**Interaction layer (7.3) — ONLY:**
- Entry points: HTTP routes, event listeners, GUI controllers, CLI commands
- Orchestration of Business logic for a given interaction
- Mapping between Transfer objects and external representations
- No direct access to Access layer

### What is FORBIDDEN across the model

| Forbidden                                               | Because |
|---------------------------------------------------------|---------|
| Interaction calling Access directly                     | Violates layer isolation |
| Business knowing about HTTP, SQL, or UI frameworks      | Violates technology-agnosticism |
| Multiple Injection components in the same layer         | Exactly one per layer |
| Logic inside Transfer objects                           | Transfers are pure data |
| Utility components with state or side-effects           | Must be pure functions |
| Upward dependencies (Access → Business, etc.)           | Violates dependency rule |

---

## 7. Conformity Levels

Conformity is a function Λ that assigns every artefact exactly one of **five**
discrete, ordered, mutually exclusive levels: Λ(artefact) ∈ {0,1,2,3,4}. A
higher level implies all conditions of the lower ones plus additional
conditions. Transitions happen only by classifying unclassified components or
by correcting violations.

| Level | Denomination | Condition |
|-------|--------------|-----------|
| **Λ=0** | No conformant | Nothing classified in the L×T matrix. No recognisable XF structure. |
| **Λ=1** | Partially conformant | ≥1 component classified in L×T and accessible through an injection, but totality is **not** satisfied — unclassified components coexist with XF components. Typical of progressive migration. |
| **Λ=2** | Imperfectly conformant | Totality satisfied (every component classified) **but** ≥1 **structural** violation. Correcting all structural violations raises it to Λ=3. |
| **Λ=3** | Structurally conformant | Totality satisfied, **0** structural violations, ≥1 **semantic** violation. A **well-formed artefact** — structure (classification, layer direction, naming, injection placement/uniqueness) is entirely correct. **Maximum level a static tool can certify.** |
| **Λ=4** | Perfectly conformant | Totality satisfied, **0** violations of any kind (structural **and** semantic). The 3→4 distinction requires **human semantic review** beyond the static Λ=3 result. |

A **structural** violation caps the artefact at Λ=2; with no structural
violations, a **semantic** violation caps it at Λ=3 (but allows it). Λ is
deterministic — given the full set of violations, the level is uniquely
determined — but its full evaluation is **not** automatable: a static tool can
decide up to Λ=3 and must not report Λ=4 as definitive without flagging that
the catalog's semantic rules require human evaluation.

---

## 8. Practical Code Generation Guidelines

When generating XF-compliant code, follow these rules in order:

1. **Classify first.** Before writing any class/function/module, decide: which
   layer does this belong to? Which type? The name and location follow from the
   classification.

2. **One concern per Logical component.** Do not create god-classes. Each
   Logical component handles one domain concept or one I/O endpoint.

3. **Transfer objects are dumb.** They carry data between layers. No validation
   logic, no formatting, no business rules inside them.

4. **Inject, don't instantiate.** Code in Business never calls `new DatabaseRepository()`.
   It accesses it through `R.databaseRepository`. Code in Interaction never
   calls `new UserBusiness()` — it uses `B.userBusiness`.

5. **Utilities are pure.** `StringUtils.truncate(text, maxLen)` returns a value.
   It never touches a database, calls an API, or modifies shared state.

6. **Generalizations are horizontal, not vertical.** An Access generalization
   (e.g. `AbstractRepository`, sharing the `Repository` suffix) is shared by
   `DatabaseRepository` and `FileRepository` (same layer). It is NOT a
   cross-layer parent.

7. **Keep `init()` minimal.** Injection `init()` methods instantiate Logical
   components and wire dependencies. They do not run business logic.

8. **Respect folder placement.** A file in `business/logic/` must be a Business
   Logical component. A file in `repository/utils/` must be a pure utility
   scoped to the Access layer. Misplacement is a conformity violation.

---

## 9. Quick Reference Card

```
Layer         Type            Suffix      Folder
──────────────────────────────────────────────────────────
Access        Logical         Repository  repository/logic/
Access        Generalization  Repository  repository/general/
Access        Injection       R           repository/R
Access        Utility         Utils       repository/utils/
Access        Transfer        (none)      repository/transfers/

Business      Logical         Business    business/logic/
Business      Generalization  Business    business/general/
Business      Injection       B           business/B
Business      Utility         Utils       business/utils/
Business      Transfer        (none)      business/transfers/

Interaction   Logical/Service Service     api/logic/service/
Interaction   Logical/View    View        api/logic/gui/
Interaction   Generalization  Service/View api/general/
Interaction   Injection       A           api/A
Interaction   Utility         Utils       api/utils/
Interaction   Transfer        (none)      api/transfers/
```

> A **Generalization** shares its layer's logical suffix (e.g. an Access
> generalization ends in `Repository`, a Business one in `Business`); it is
> not a `Base*` prefix.

---

## 10. Example Skeleton (language-agnostic pseudocode)

```
// ── Access layer ──────────────────────────────────────────
// repository/logic/remote/UserRepository
class UserRepository {
    fetch(id): UserTransfer { /* DB/API call */ }
    save(user: UserTransfer): void { /* persist */ }
}

// repository/R  (Injection)
class R {                                   // Injection — static, non-instantiable
    private constructor() {}
    static readonly userRepository = new UserRepository()  // the injection is the only place a Logical is `new`-ed
    static init()      { R.userRepository.init() }
    static terminate() { R.userRepository.terminate() }
}

// ── Business layer ────────────────────────────────────────
// business/transfers/User  (Transfer — no logic)
struct User { id, name, email }

// business/logic/UserBusiness
class UserBusiness {
    getUser(id): User {
        raw = R.userRepository.fetch(id)   // reach Access statically through R
        return map(raw, User)              // domain rule: validate & map
    }
    init() {}  terminate() {}
}

// business/B  (Injection)
class B {                                   // Injection — static, non-instantiable
    private constructor() {}
    static readonly userBusiness = new UserBusiness()
    static init()      { B.userBusiness.init() }
    static terminate() { B.userBusiness.terminate() }
}

// ── Interaction layer ─────────────────────────────────────
// api/logic/service/UserService
class UserService {
    handleGetUser(request): Response {
        user = B.userBusiness.getUser(request.params.id)   // reach Business through B
        return Response.ok(user)
    }
    init() {}  terminate() {}
}

// api/A  (Injection)
class A {                                   // Injection — static, non-instantiable
    private constructor() {}
    static readonly userService = new UserService()
    static init()      { A.userService.init() }
    static terminate() { A.userService.terminate() }
}

// XF  (optional start-point element, at the root of src/)
class XF {
    private constructor() {}
    static init()      { R.init(); B.init(); A.init() }
    static terminate() { A.terminate(); B.terminate(); R.terminate() }
}

// ── Application bootstrap (entry point — OUTSIDE the artifact root) ──
XF.init()
// on shutdown: XF.terminate()

// ── Usage (inside Interaction only) ──────────────────────
router.get('/user/:id', req => A.userService.handleGetUser(req))
```

---

*XF Architecture Model (CFAM) — edition XF-CFAM-001:2026.*
