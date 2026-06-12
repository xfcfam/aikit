# XF Classification Decision Tree

Use this tree to classify any software component into the XF L×T matrix.
Walk from top to bottom. The first branch that matches determines the
classification.

For the **full canonical catalogue** of rules, types and conformance
levels, consult `../../_shared/catalogue.md`.

---

## Step 0 — Detect XF start-point element

> Is this component named exactly `XF` and located at `/src/XF.<ext>`?

- **YES** → **XF start-point element**. It is neither a Logical nor a
  Transfer; it sits outside the L×T matrix as the artefact-level
  lifecycle orchestrator. Its only legitimate content is the
  delegations `R.init(); B.init(); A.init()` (and the inverse on
  terminate). See rules `xf-init-missing`, `xf-terminate-missing`,
  `xf-init-mismatch`, `xf-terminate-mismatch`.
- **NO** → continue to Step 1

---

## Step 1 — Detect Injection

> Is this component's **sole purpose** to instantiate, hold, and expose other
> components of a single layer, and is it named R, B, or A?

- **YES** → **Injection**. Assign to the layer whose components it manages.
  - Holds Repository instances → Access Injection (`R`)
  - Holds Business instances → Business Injection (`B`)
  - Holds Service/View instances → Interaction Injection (`A`)
- **NO** → continue to Step 2

---

## Step 2 — Detect Transfer or Exception

> Does this component contain **only data fields** (properties,
> attributes)? No methods, no computed values, no I/O, no dependencies?
> (Constructors that only assign fields, and `getters` that return a
> stored field without computation, are considered "data only".)

- **YES** → continue with the Exception sub-check:

  > Does the name end in `Exception` AND does the type extend the
  > language's native error type (`Error`, `Exception`, `Throwable`,
  > `BaseException`, …)?

  - **YES** → **Exception** (a sub-kind of Transfer, lives in
    `<layer>/transfers/`). Used as a vehicle of the exception flow.
    Rules: `transfer-naming`, `transfer-inheritance`. **Custom
    Exceptions are an opt-in for domain concepts** — the native runtime
    exception types of the language are also valid vehicles and do NOT
    require wrapping.
  - **NO** → **Transfer**. Assign to the layer that **produces** the
    data:
    - Raw data from external system → `repository/transfers/`
    - Domain entity or value object → `business/transfers/`
    - API request/response shape → `api/transfers/`
- **NO** → continue to Step 3

---

## Step 3 — Detect Utility

> Does this component contain **only pure functions** (no instance state,
> no I/O, no side effects, always deterministic given the same inputs)?
> Is its scope limited to supporting **one specific layer**?

- **YES** → **Utility**. Assign to the layer that exclusively uses it:
  - Used only in Access logic → Access Utility (`repository/utils/`)
  - Used only in Business logic → Business Utility (`business/utils/`)
  - Used only in Interaction logic → Interaction Utility (`api/utils/`)
  - Operates on **primitive types** (`StringUtils`, `DateUtils`, `NumberUtils`,
    `ArrayUtils` — no domain semantics) → **Access Utility** (`repository/utils/`),
    and it **may be referenced from any layer** without violating isolation
    (§7.3.4, the explicit primitive-types exception).
  - A *domain* utility that seems "used across layers" is a smell — utilities
    are layer-local. Split it, or move the shared capability to a Logical in
    the lowest layer that needs it (§6.2.2), reachable downward.
- **NO** → continue to Step 4

---

## Step 4 — Detect Generalization

> Is this component an **abstract base** whose logic abstracts a structural
> pattern shared by multiple Logical components **in the same layer**, with no
> effective logic of its own?

Apply the **parametricity test** (§7.3.2 — the definitive criterion):

- A component is a **Generalization** if its logic applies to **more than one
  domain concept without modification** — it is *parametric over the domain*.
  `StatefulBusiness<T>` (observe/notify works for any `T`), `RestRepository`
  (the REST protocol, any resource).
- A component is a **Logical** if its logic is **bound to one specific domain
  concept** and cannot apply to another without modification.
  `TemperatureBusiness` (threshold validation, unit conversion). If a
  "generalization" starts naming a concrete concept (`Temperature`, `User`),
  its logic has become **effective** — move it into the Logical.

This is the *effective vs contextual logic* split (§7.3.1): effective logic
(irreducible to its concept) lives only in Logicals; contextual logic
(shareable/generic) lives in Generalization/Utility/Transfer.

- **YES (parametric, no domain state)** → **Generalization**. Assign to the
  layer of the Logicals it generalises:
  - Shared by Repository classes → Access Generalization (`repository/general/`)
  - Shared by Business classes → Business Generalization (`business/general/`)
  - Shared by Service/View classes → Interaction Generalization (`api/general/`)
  - Generalizations carry their layer's logical suffix and may hold *operative*
    attributes (observer list, HTTP client) but **never domain state**.
  - **Cross-layer duplication is mandated**: if two layers need the same
    pattern, each implements its own (`StatefulRepository` ＋ `StatefulBusiness`
    ＋ `StatefulView`) — never one shared base (§6.2.2).
- **NO** → continue to Step 5

---

## Step 5 — Determine Layer of the Logical

The component is a **Logical**. Determine which layer:

### 5a — Is it an Access Logical?

> Does this component's **primary purpose** involve communicating with an
> **external system**: a database, REST API, GraphQL, message queue, file
> system, hardware peripheral, device sensor?

- Does it build queries, read files, send HTTP requests, write to a stream?
- Does it normalise raw external data into Transfer objects?
- Does it hide protocol or I/O details from the rest of the application?

**YES to any** → **Access / Logical** (`repository/logic/`)
- Canonical suffix: `Repository`
- Recommended subfolders: `local/` (DB, files, on-device) · `remote/` (network, APIs)

---

### 5b — Is it a Business Logical?

> Does this component implement **domain rules, business invariants, domain
> state, or orchestration of domain operations** — without any knowledge of
> HTTP, databases, UI frameworks, or external protocols?

- Does it apply conditional rules based on domain concepts?
- Does it manage the lifecycle of domain entities?
- Could it run in a pure unit test with zero framework imports?

**YES to any** → **Business / Logical** (`business/logic/`)
- Canonical suffix: `Business`
- Recommended subfolders: `instance/` (per-session or per-user) · `device/` (hardware/device state)

---

### 5c — Is it an Interaction Logical?

> Is this component an **entry point** — a place where an external actor
> (user, HTTP client, timer, event bus) initiates a call into the application?

- HTTP route handlers, REST/RPC controllers
- Graphical UI screens, ViewModels, Presenters
- CLI command handlers
- Background job schedulers, event consumers
- WebSocket/SSE listeners

**YES to any** → **Interaction / Logical** (`api/logic/`)
- Canonical suffix:
  - If it serves a **programmatic client** (REST, RPC, websocket) → `Service`
  - If it serves a **human user** (GUI screen, view) → `View`
- Recommended subfolders: `service/` · `gui/`

---

## Step 6 — Handle ambiguous / mixed-concern components

If a component does not match cleanly because it mixes concerns from two layers:

1. **Name the concerns explicitly.** List what belongs in each layer.
2. **Propose the split.** Assign each concern to its correct component.
3. **Show the method distribution.** Which methods move where?
4. **Flag god objects.** A component that touches DB, domain logic, and HTTP
   handling in one class must be split into three (Repository + Business + Service).

Common mixed-concern patterns:

| Anti-pattern | Split into |
|---|---|
| `UserManager` with DB + rules + HTTP response | `UserRepository` + `UserBusiness` + `UserService` |
| `UserDTO` with computed fields | `User` (Transfer) + method in `UserBusiness` |
| `AppUtils` used everywhere | Layer-specific utils: `DateUtils` (business/utils/), `HttpUtils` (api/utils/) |
| Service that calls DB directly | `UserService` calls `B.userBusiness`, not `R.userRepository` |

---

## Quick reference summary

```
Named XF?                → XF start-point element (lifecycle orchestrator)
Named R / B / A?         → Injection (Access / Business / Interaction)
Data + name *Exception?  → Exception (sub-Transfer, /<layer>/transfers/)
Data only?               → Transfer  (layer that produces it)
Pure functions?          → Utility   (layer that uses it)
Abstract base?           → Generalization (same layer as the Logicals)
Has I/O (DB/API/FS)?     → Access / Logical → suffix Repository
Domain rules?            → Business / Logical → suffix Business
Entry point?             → Interaction / Logical → suffix Service or View
```

The canonical suffixes are enforced by the naming rules of the catalogue:
`injection-naming-r` / `-b` / `-a` (group 5); `logic-naming-repository`
/ `-business` / `-service` / `-view` (group 3); `general-naming-repository`
/ `-business` / `-service` / `-view` (group 4); `utility-naming`
(group 6); `transfer-naming` (group 7, covers exceptions). The canonical
folder layout is enforced by the structure rules of group 1
(`structure-layer-mismatch`, `structure-type-mismatch`,
`structure-injection-missing`, `structure-injection-multiplicity`,
`structure-component-naming`) and the file/class name must equal the
canonical class name (`structure-component-naming`). See
`../../_shared/rules-detail.md` for the authoritative ids.
