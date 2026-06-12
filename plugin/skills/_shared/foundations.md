# XF / CFAM — foundations & particularities

The **why** behind the model. The rule catalogue
([`catalogue.md`](./catalogue.md)) tells a skill *what* the model
prescribes; this file tells it *why* — the philosophy from which every rule
is derived, and the subtle particularities a faithful toolkit must get right.

Source of truth: the normative specification, edition **XF-CFAM-001:2026**
(<https://xfcfam.org>). Clause map in [`spec.md`](./spec.md). The foundations
themselves live in **§5** (theoretical foundations) and **§6.2** (guiding
principles); the particularities are scattered through **§6–§9**. Citations
below point at the exact clause — cite it, don't paraphrase the model into
something it doesn't say.

> **§5 is informative, not normative.** The reasoning in this file *justifies*
> the prescriptions; it is not itself a set of rules. When a developer asks
> "why", answer from here. When they ask "must I", answer from the catalogue.

---

## 1. Why the model exists

### Software is the automation of formal processes (§5.1)

A software system **does not create processes; it formalizes them.** The
engineering object is to build systems that execute, autonomously and
reproducibly, processes that *preexist* in the domain they model. From this
follows the **isomorphism principle**: the internal structure of an artefact
is isomorphic to the structure of the process it models. Architecture is
therefore **a derived property of the process** — not a discretionary
developer choice, not a convention imposed by the framework. An architecture
that does *not* derive from the process structure injects exactly the
*accidental complexity* (Brooks) that accumulates as technical debt.

Practical consequence: **analysis of the process precedes design of the
architecture.** A skill that generates or reviews code should reason from
"what process does this automate?" before "what classes do I write?".

### The fragmentation it solves is terminological, not structural (§5.3–§5.4)

The industry already converges on the same component categories — `Repository`
for data access, `Service`/`Controller` for entry points — because the
processes being modelled share the same structure. The problem is that each
framework names that convergence with an incompatible proprietary taxonomy.
Two recurring inconsistencies:

- **Heterotechnical synonymy** — the same concept under different names:
  data access is `Repository` (Spring), `QuerySet` (Django), `DAO` (J2EE),
  `Model` (Node). The developer re-learns what they already know.
- **Interframework homonymy** — the same term for different concepts:
  `Service` means business logic (Spring), a background task (Android), a
  general-purpose singleton (Angular), and a deployment unit (microservices).

The root cause is **semantic coupling to the framework**: architecture that
cannot be described independently of its tools has stopped being a conceptual
model. XF's contribution **is not structure — it is vocabulary**: it couples
nomenclature to the formal process so the structure, already present, becomes
recognizable and communicable across any technology (§5.2, final paragraph).

### XF is a reference model, not an architecture (§5.2, §5.5) — META-MODEL framing

This is the single most-misunderstood point, and a toolkit must never get it
wrong. **XF does not compete with Clean, Hexagonal, Onion, DDD, MVC, or
layered architectures.** It is a *reference model* in the ISO/IEC/IEEE 42010
sense — a conceptual abstraction layer *over* all architectural styles. Those
styles are **instances** that project into the XF vocabulary (Clean's
entities/use-cases/adapters map onto Business/Interaction/Access; Hexagonal's
ports-and-adapters map onto the injection conduit; etc.).

- ✅ "Clean Architecture's use-case layer instantiates the XF Business layer."
- ❌ "XF versus Clean Architecture" / "XF is better than Hexagonal."

When asked to compare, present XF as the **formal mapping target** that
explains *why* those architectures converge, never as a rival on the same
shelf. The reason XF can occupy this position is its **scale** (next section).

### The artefact is the canonical scale (§5.2, "escala canónica")

The input→process→output pattern is scale-invariant (it recurs at statement,
function, component, subsystem level — cybernetics, general systems theory,
CSP). XF deliberately fixes **one** scale as canonical: the **artefact** —
the minimum scale at which a *complete* formal process realizes biunivocally
as code structure.

- **Below** the artefact (classes, functions): encapsulations of
  responsibility that serve the process but are not complete processes — a
  class has no "interaction stage" of its own.
- **Above** the artefact (distributed systems, ecosystems, organizations):
  composition of *multiple* processes, not a single one.

Conformance is therefore assessed **per artefact**, never per application. An
application may compose several XF artefacts (via the `@xfcfam` ecosystem)
plus non-XF legacy code, each with its own conformance level.

---

## 2. The three layers, derived (§5.2, §5.5)

Every formal process admits a canonical decomposition into three stages of
**distinct formal status**:

| Stage (ES / EN) | Status | Becomes layer |
|---|---|---|
| **Procesamiento** / Processing | structurally **necessary** | **Negocio** / Business (`/business`) |
| **Interacción** / Interaction | structurally optional | **Interacción** / Interaction (`/api`) |
| **Acceso** / Access | structurally optional | **Acceso** / Access (`/repository`) |

Processing is the only *necessary* stage (no transforming logic ⇒ no process).
Interaction and access are *optional* but **exhaustive and mutually
exclusive** as the two — and only two — directions of communication with the
environment: a process either *receives* an invocation or *invokes* outward.
There is no third structural kind of communication. (A purely computational
artefact may leave Access and Interaction empty and still be conformant —
§5.5 *completitud*.)

This is not a design convention. **Four independent formal traditions
converge** on exactly this structure (§5.2): BPMN 2.0 (Activities / catch
Events / throw Events), CSP & the π-calculus (internal action τ / channel
receive `c?x` / channel send `c!v`), the Actor Model (process message /
optional send / optional receive), and Input-Process-Output. Cite this when a
developer asks "why exactly three layers?".

Each stage corresponds **biunivocally** to one layer (§5.5), giving the three
formal properties that are the correctness criteria of any XF artefact:

- **Completeness** (*completitud*) — the three layers exhaustively cover the
  process with no overlap; every component classifies into exactly one.
- **Strict separation** (*separación estricta*) — each layer implements only
  its stage's logic; logic of one stage living in another layer's component is
  a violation.
- **Directionality** (*direccionalidad*) — dependencies are strictly
  descending (Interaction → Business → Access). This derives from the
  **causal order** of the stages: interaction precedes processing precedes
  access; an upward dependency would mean an earlier stage depends on a later
  one, contradicting the process's causal structure.

### The OSI analogy is orthogonal extension, not subdivision (§5.5)

OSI stratifies communication **between** artefacts and, by design, stops at
the Application Layer boundary — it never specifies the *interior* of an
application. XF does **not** subdivide OSI's Application Layer (there is
nothing there to subdivide); it **extends OSI's stratification principle to an
orthogonal dimension** — the *internal* structure of each artefact. The two
stratifications are independent and complementary.

XF preserves OSI's four formal properties on the new axis: service
encapsulation via primitives (the **injection** is each layer's named service
access point), strictly unidirectional dependency, implementation isolation
(enables technological agnosticism), and service composition. And it pursues
OSI's *lasting* contribution — which was never the protocol stack (TCP/IP won)
but **standardization**: a common vocabulary, implementation independence, and
cross-validation/pedagogy — applied to the artefact's interior.

---

## 3. The four guiding principles (§6.2)

These are axioms; no other rule may contradict them, and they are
interdependent (satisfying one presupposes the others).

1. **Technological agnosticism (§6.2.1).** No restriction on language,
   framework, paradigm, platform, deployment, or domain. *Agnostic about
   technology, not about structure* — the canonical names (`R`/`B`/`A`,
   `/repository`·`/business`·`/api`, the suffixes) are **prescribed over**
   framework conventions, not as optional style. Spring's `@Repository` still
   becomes an XF `*Repository`.

2. **Layer isolation (§6.2.2).** Every component depends only on its own layer
   or lower-abstraction layers; dependencies are strictly descending. A
   *dependency* is defined broadly (§6.2.2): A depends on B if A must know B's
   definition or behaviour to compile, instantiate, or execute — invocation
   through the injection, inheritance/interface, a typed
   attribute/parameter/return, or an import all count. See §5 of this file for
   the particularities this principle generates.

3. **Architecture precedence over the tool (§6.2.3).** Structure derives from
   the process, not the framework. Traditional development inverts causality
   (Problem → Framework → Architecture); XF restores it (Problem →
   Architecture → Framework). Framework constructs (annotations, decorators,
   base classes) are **encapsulated inside** the XF component that uses them,
   never visible across the artefact.

4. **Closed & exhaustive typing (§6.2.4).** The type system is **closed**
   (exactly 5 types × 3 layers = 15 categories, non-extensible) and
   **exhaustive** (every component classifies into exactly one cell; none
   falls outside, none needs dual classification). This is what makes the
   model *verifiable*: a component that resists classification signals an
   architectural violation to fix, not a gap in the taxonomy.

---

## 4. Effective vs. contextual logic — the basis of the type system (§7.3.1)

The five types are not arbitrary; they partition logic into **effective** and
**contextual**:

- **Effective logic** (*lógica efectiva*) — the minimal set of operations that
  justify a component's existence; logic *inherent to the domain concept it
  models* that cannot be abstracted into any other component without losing
  that concept's specificity. This lives **only** in **Logical** components.
  A Logical answers: *"what does this artefact do with this domain concept?"*
- **Contextual logic** (*lógica contextual*) — everything shareable, reusable,
  or expressible generically. It lives in **Generalization**, **Utility**, or
  **Transfer** components, which *support* the effective logic without
  replacing or containing it.

A Logical's internal structure is precise (§7.3.1): **state** (data with
direct domain correspondence — operative attributes like a connection
reference, an init flag, or a retry counter are **not** state), **operations**
(atomic effective-logic units, 1:1 with a domain action), **statements**, and
**conditions** (preconditions in Meyer's sense; an unmet condition typically
propagates an exception transfer, though defaults/retry/fallback are allowed).
Only Logical components may hold state.

---

## 5. Particularities a toolkit must get right

The particularities below are where naïve "downward-only, one-component-per-
concern" intuition diverges from the actual model. Each is load-bearing.

### 5.1 Dependency direction ≠ data-flow direction — upward via events (§6.2.2)

Isolation constrains **who may know whom**, not **how data travels at
runtime**. Information may flow **upward** with no upward dependency. When a
lower-layer component must communicate a state change to upper layers (a
Business component detecting connectivity loss, a real-time WebSocket update),
the model prescribes **event-oriented / observer** communication: upper-layer
components register as observers and react; the lower layer mutates state and
notifies **without ever invoking or knowing its observers**. Coupling stays
descending; information ascends. So "downward only" is about *dependencies* —
never tell a developer that data cannot flow up.

### 5.2 The cross-layer duplication mandate (§6.2.2, §7.3.2)

Inheritance is restricted to the **same layer**. When two or more layers need
the *same* structural pattern (stateful observation, scheduled tasks), each
layer **must implement its own generalization independently, even if the code
is structurally identical** — `StatefulRepository`, `StatefulBusiness`,
`StatefulView` are three separate classes. The model prescribes this
duplication *explicitly*: a cross-layer generalization would create a
structural dependency between layers and destroy local-change resistance. This
is counterintuitive but normative — never "DRY up" a pattern across layers.

### 5.3 Shared non-trivial behaviour goes to the lowest layer (§6.2.2)

Distinct from 5.2 (which is about *inheritance* of a structural pattern): when
components of several layers need a shared non-trivial *capability* (debug
tracing, metrics, encryption, reading persisted config), encapsulate it in a
**Logical component in the lowest layer that needs it**, reachable downward
through that layer's injection — not as a cross-layer generalization or
utility.

### 5.4 The Access primitive-utils exception (§7.3.4)

Utilities are layer-local **except** Access-layer utilities that operate on
**primitive types** (`StringUtils`, `DateUtils`, `NumberUtils`, `ArrayUtils`).
These carry no domain semantics and are "prior to" the XF stratification (in
the OSI sense — the raw material all layers operate on), so the model
prescribes they live in `/repository/utils` and **may be referenced from any
layer** without violating isolation. A utility over a *domain* concept
(`TemperatureUtils`, `QueryUtils`) stays layer-local. This is exactly the
carve-out the `layer-skip` rule encodes.

### 5.5 Logical vs. Generalization — the parametricity test (§7.3.2)

The defining test: a component is a **Generalization** if its logic applies to
**more than one domain concept without modification** (it is *parametric over
the domain*); it is a **Logical** if its logic is **bound to a specific domain
concept**. `StatefulBusiness<T>` is a generalization (observe/notify works for
any `T`); `TemperatureBusiness` is logical (threshold validation, unit
conversion — temperature-specific). A "generalization" that starts referencing
a concrete concept (`Temperature`, `User`) has turned effective and must move
into the Logical. Generalizations may hold *operative* mutable attributes
(observer list, HTTP client) but **never domain state** — and they carry their
layer's logical suffix.

### 5.6 Transfers ARE the data and may carry self-contained operations (§7.3.5, §9)

A Transfer **is** the data structure (a Logical *maintains* evolving state; a
Transfer *is* the structure and models no business process). The boundary is
**not** "Transfers have no methods" — that is a DTO oversimplification the XF
model explicitly rejects. A Transfer **may declare operations, provided they
are self-contained**: they operate only on the structure's own data (query,
transform, derive, combine) and access **no other component** and model **no
business process**. `Temperature.toFahrenheit()` is fine; deciding whether to
turn on the heating is a business process and belongs in a Business Logical.

Consequences a toolkit must honour:

- **Rich data structures are Transfers, not Logicals.** Framework/stdlib
  objects that carry self-contained operations — collections, date/time types,
  futures/promises, UI controls, timers, result wrappers — **project to
  Transfer components** in the layer of the concept they model, with no
  rewrite. This is what lets external identifiers classify cleanly (and lets a
  structural pass reach Λ=3).
- **Unification is a capability, not a prescription** (§9.3). One Transfer for
  a concept may be shared across every layer that works with it (a Business
  `User`, an Access `Query`/`HttpRequest`/`Cursor`, an Interaction
  `Button`/`MouseEvent`/`Viewport`), avoiding the redundant
  `UserEntity`/`UserModel`/`UserDTO` proliferation. It is *recommended* design,
  not required — two equivalent transfers in different layers are redundancy,
  not a violation. It works because transfer references, even crossing layers,
  always go **descending** (a higher layer consumes a lower layer's transfer,
  never the reverse) and **without modification**.
- **Exceptions are a Transfer subtype** (`*Exception`). Native runtime
  exceptions (`Error`, `Exception`, `BaseException`) are valid vehicles of the
  exception flow; a custom `*Exception` is an opt-in for an error that is a
  *domain* concept, never a blanket wrapping mandate.

### 5.7 The injection conduit and lifecycle exclusivity (§7.3.3, §8)

Each layer has exactly one **Injection** — `R`/`B`/`A` — the *Singleton
Gathering* that is the sole, named service-access point to its Logicals. It is
**non-instantiable and static**: slots are immutable public static references,
fixed after `init()` (global structural constancy — composition never changes
mid-run). The canonical access pattern is `<injection>.<component>.<operation>()`
(`B.session.refresh()`, `R.database.fetch()`) — **all** access to a Logical,
including same-layer, routes through the injection; a Logical is never `new`-ed
elsewhere and never imported-and-called directly across layers.

Lifecycle orchestration is **exclusively reserved** (§8, rule group 9):
only a layer's injection may instantiate / `init()` / `terminate()` its
Logicals; only the optional **`XF`** start-point element may drive the
injections, with `XF.init()` exactly `R.init(); B.init(); A.init()` and
`XF.terminate()` exactly the reverse. The artefact's **scope begins at the
layer folders / the XF element, not at `main()`** — the entry point lives
outside the artefact root and only calls `XF.init()` / `XF.terminate()`.

### 5.8 Conformance is deterministic but not fully automatable (§11)

The level `Λ(𝔄) ∈ {0,1,2,3,4}` is computed by a deterministic four-stage
algorithm (classify → totality → catalogue → level). But its application is
**not** fully automatable: 10 of the 71 rules are **semantic** (they need
human architectural judgement — "does this Business Logical actually contain
Access logic?"). A static tool therefore reports a **ceiling of Λ=3**
("structurally conformant / well-formed") and flags that Λ=4 ("perfectly
conformant") requires human semantic review. Never describe the static result
as an upper *bound* in a way that implies the artefact can't be better — it is
a ceiling on what *static analysis can certify*, not on the artefact's actual
conformance.

---

## 6. Glossary of coined terms (ES ↔ EN)

The full ontology is §12 of the spec. The terms a toolkit most needs:

| Spanish | English | One-line meaning |
|---|---|---|
| Proceso formal | Formal process | Precisely-specified, automatable input→transform→output |
| Tripartición | Tripartition | Processing (necessary) + interaction/access (exhaustive comms) |
| Artefacto | Artefact | The canonical scale — one complete process, three layers, one execution space; conformance is per-artefact |
| Matriz L×T | L×T matrix | 3 layers × 5 types = 15 closed, exhaustive cells |
| Lógica efectiva | Effective logic | Irreducible domain logic; lives only in Logicals |
| Lógica contextual | Contextual logic | Shareable/generic support logic; Generalization/Utility/Transfer |
| Estado | State | Data with direct domain correspondence; only Logicals hold it |
| Componente de inyección | Injection | `R`/`B`/`A` — non-instantiable static service-access point to a layer's Logicals |
| Componente de transferencia | Transfer | *Is* the data; self-contained operations allowed; models no business process |
| Agnosticismo tecnológico | Technological agnosticism | No tech restrictions — but structure & names are prescribed |
| Aislamiento entre capas | Layer isolation | Dependencies strictly descending; info may still ascend via events |
| Acoplamiento semántico al marco | Semantic coupling to the framework | The anti-pattern XF removes: architecture defined by tooling, not process |

---

## How a skill should use this file

- **Explaining the model or answering "why?"** → quote the relevant §5/§6.2
  reasoning from here, then cite the clause and link <https://xfcfam.org>.
- **Classifying / implementing / reviewing** → apply §4 (effective vs
  contextual) and §5 (the particularities) so the L×T decision matches the
  model's intent, not a surface heuristic. The catalogue
  ([`catalogue.md`](./catalogue.md)) remains authoritative for *which rule*
  fires.
- **Never** restate the foundations as if they were rules, and never frame XF
  as a rival architecture (§1, meta-model framing).
