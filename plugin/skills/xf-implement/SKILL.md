---
name: xf-implement
description: >
  Use this skill when the user asks to "implement this in XF", "generate XF
  code for...", "build this feature following XF/CFAM", "write an XF component
  for...", "program this in XF", "code this the XF way", "turn this design into
  XF code", or hands you a feature/requirement and wants the actual
  XF-compliant implementation. Use after a plan exists (or build the plan
  inline) — this skill produces real source files.
metadata:
  version: "0.4.0"
---

# XF Implement

Generate XF / CFAM-compliant source code from a feature or requirement. This
skill goes from intent to files: it classifies the feature into components
across the three layers, derives canonical names and folder paths, and writes
each component honouring the structural contract of the model
(edition **XF-CFAM-001:2026**).

If the user only wants a design / component plan (no code yet), use
**`xf-specify`** instead. If they want to classify *existing* code, use
**`xf-classify`**. If they want to validate code already written, use
**`xf-review`**.

Read **`../_shared/catalogue.md`** (rule overview + conformance model) and, for
templates, **`../xf-scaffold/references/structure.md`** before writing.

> **Reuse before you build.** Before writing a Utility, a Generalization, or a layer adapter, check the `@xfcfam/*` reference libraries ([`../_shared/libraries.md`](../_shared/libraries.md)) — persistence, HTTP, SQL, filesystem, server transports, retry/cache/pagination, scheduling and state machines already exist. Extend them instead of reinventing.

## The model in one screen

- **L × T matrix** — 3 layers × 5 types = 15 cells, exhaustive and closed.
- **Layers** (low → high abstraction): **Access** (`/repository`),
  **Business** (`/business`), **Interaction** (`/api`). Dependencies are
  **strictly descending**: Interaction → Business → Access. Never upward,
  never lateral.
- **Types**: Logical, Generalization, Injection, Utility, Transfer.
- **Injection** — exactly one per layer: **R** (Access), **B** (Business),
  **A** (Interaction). It is the *only* place a Logical is instantiated, and
  the *only* conduit to reach a lower layer.
- **Canonical access pattern** — `<injection>.<component>.<operation>()`:
  `B.session.refresh()`, `R.database.fetch()`, `A.temperatureService.update()`.
  A Logical is reached **only** through its layer injection; never `new`-ed
  elsewhere.
- **Lifecycle** — init ascends `R.init() → B.init() → A.init()`; terminate
  descends `A → B → R`. The optional **XF** start-point element delegates
  exactly that. The entry point (`main`) lives **outside** the artefact root.

Primary supported language is **TypeScript** (the reference parser of
`xftools`). Other languages follow the same structural contract; adapt the
idioms (see the per-language table in `../xf-scaffold/references/structure.md`).

## Procedure

### 1. Restate the feature as a process

State, in one or two sentences, the process the feature automates and the data
it moves. This frames the decomposition. Example: "Authenticate a user from
email + password, returning a session token; persistence is a users table."

If the requirement is ambiguous about an external system, a domain rule, or an
entry-point shape, ask before coding — a wrong layer assignment is expensive to
undo.

### 2. Classify the feature into components and assign each an L×T cell

Decompose the feature top-down across the three layers. For each piece, decide
its **layer** and **type** using the `xf-classify` decision tree
(`../xf-classify/references/decision-tree.md`). Typical shape of a feature:

| Need | Layer | Type | Why |
|---|---|---|---|
| Reach an external system (DB, REST, FS, device) | Access | Logical | I/O is its primary purpose |
| Raw rows / payloads from that system | Access / Business | Transfer | dumb data |
| Domain rules, invariants, orchestration | Business | Logical | no protocol knowledge |
| Domain entity / value object that flows | Business | Transfer | dumb data |
| Entry point (HTTP handler, GUI screen, CLI, job) | Interaction | Logical | external actor calls in |
| Pure helper (hashing, formatting, parsing) | the layer that uses it | Utility | stateless, deterministic |
| Shared abstract base for same-layer Logicals | that layer | Generalization | contract only, horizontal |

Not every feature touches all three layers — implement only the cells the
feature actually needs.

### 3. Derive canonical names and target folder paths

Apply the nomenclature, then map each component to its canonical folder
(§7.4). The file name (no extension) **is** the canonical class name.

| Cell | Suffix / name | Folder |
|---|---|---|
| Access · Logical | `*Repository` | `src/repository/logic/{local,remote}/` |
| Business · Logical | `*Business` | `src/business/logic/{instance,device}/` |
| Interaction · Logical (systemic) | `*Service` | `src/api/logic/service/` |
| Interaction · Logical (graphical) | `*View` | `src/api/logic/gui/` |
| any · Generalization | shares its layer's logical suffix | `src/<layer>/general/` |
| Access / Business / Interaction · Injection | `R` / `B` / `A` | `src/<layer>/` (root) |
| any · Utility | `*Utils` | `src/<layer>/utils/` |
| any · Transfer | domain concept, **no suffix** (exception → `*Exception`) | `src/<layer>/transfers/` |

The `/logic` subdivisions (`local`/`remote`, `instance`/`device`,
`service`/`gui`) are recommended, not required. Name by the **domain**, never
by technology — `UserRepository`, not `PostgresUserRepository`.

### 4. Implement each component honouring the contract

Write each file. Hard rules to keep while generating:

1. **Injection access** — to use a lower layer, go through its injection:
   `R.<repo>.<op>()` from Business, `B.<biz>.<op>()` from Interaction. Never
   `import` a Logical across layers; never `new` a Logical outside its
   injection.
2. **Strictly descending dependencies** — a component may reference only the
   layer(s) below it. Interaction → Business → Access. No upward, no lateral
   Logical-to-Logical reference.
3. **Pure Utilities** — `*Utils` are non-instantiable, static-only, stateless,
   no I/O, no side effects, import no injection. Same input → same output.
4. **Transfers** — carry data, plus **self-contained** operations on their own
   data if useful (`Temperature.toFahrenheit()`). No dependencies on
   injections/logicals/utilities, and they never model a domain process — that
   is a Logical's job (§7.3.5). Errors that are a domain concept become
   `*Exception` (a Transfer subtype); generic runtime errors need no wrapping.
5. **Generalizations are horizontal** — abstract, same-layer only, no domain
   state, no injection calls; they carry the layer suffix. Ramify by
   cross-cutting policy (caching, retry, audit), never by functional split.
   A Generalization is *parametric over the domain* (applies to >1 concept
   unchanged); the moment it names a concrete concept it has become effective
   logic and belongs in a Logical. If two layers need the same pattern,
   **generate one Generalization per layer** (`StatefulRepository` +
   `StatefulBusiness` + `StatefulView`) — the cross-layer duplication is
   mandated (§6.2.2); never emit one shared base.
6. **Lifecycle wired in R / B / A** — every Logical declares invocable
   `init()` / `terminate()`; non-trivial setup goes in `init()`, not the
   constructor. Each injection's `init()` calls its slots' `init()` and
   `terminate()` calls them in reverse — symmetric.
7. **Optional XF element** — if the artefact is executable, add `XF` whose
   `init()` is exactly `R.init(); B.init(); A.init()` and whose `terminate()`
   is exactly `A.terminate(); B.terminate(); R.terminate()`. The entry point
   (`main`) lives outside the artefact root and only calls `XF.init()` /
   `XF.terminate()`.

Register every new Logical in its layer injection (add the slot + its
init/terminate). Prefer extending the `@xfcfam/xf` base Generalizations so the
lifecycle contract is wired for you (see `../xf-scaffold/references/structure.md`).

### 5. Worked example — user login

Process: authenticate a user from email + password against a users table and
return a session token. It needs Access (read the user), Business (verify the
credentials, mint the session), and Interaction (the HTTP entry point), plus a
`User` Transfer and a pure password Utility.

**Component plan**

| Component | Layer | Type | Canonical name | Folder |
|---|---|---|---|---|
| Users table reader | Access | Logical | `UserRepository` | `src/repository/logic/remote/` |
| Raw user record | Access | Transfer | `User` | `src/repository/transfers/` |
| Credential check + session mint | Business | Logical | `AuthBusiness` | `src/business/logic/instance/` |
| Issued session | Business | Transfer | `Session` | `src/business/transfers/` |
| Password hashing helper | Business | Utility | `PasswordUtils` | `src/business/utils/` |
| Login HTTP endpoint | Interaction | Logical | `AuthService` | `src/api/logic/service/` |

Language-agnostic pseudocode (TypeScript-flavoured; the canonical access
pattern is the load-bearing part):

```
// src/repository/transfers/User          — Transfer (dumb data)
type User = { id: string; email: string; passwordHash: string }

// src/repository/logic/remote/UserRepository  — Access · Logical
class UserRepository extends Repository {
  init()      { open the DB connection }
  terminate() { close the DB connection }
  findByEmail(email) -> User | null { SELECT ... WHERE email = ? }
}

// src/repository/R                        — Access · Injection
class R {
  private constructor()
  static readonly userRepository = new UserRepository()
  static init()      { R.userRepository.init() }
  static terminate() { R.userRepository.terminate() }
}

// src/business/utils/PasswordUtils        — Business · Utility (pure)
class PasswordUtils {
  private constructor()
  static verify(plain, hash) -> boolean { constant-time compare }
}

// src/business/transfers/Session          — Transfer (dumb data)
type Session = { token: string; userId: string; expiresAt: number }

// src/business/logic/instance/AuthBusiness — Business · Logical
class AuthBusiness extends Business {
  init()      {}
  terminate() {}
  login(email, password) -> Session {
    user = R.userRepository.findByEmail(email)        // ↓ descending, via R
    if (!user || !PasswordUtils.verify(password, user.passwordHash))
      throw InvalidCredentialsException(email)        // *Exception transfer
    return mintSession(user.id)
  }
}

// src/business/B                          — Business · Injection
class B {
  private constructor()
  static readonly authBusiness = new AuthBusiness()
  static init()      { B.authBusiness.init() }
  static terminate() { B.authBusiness.terminate() }
}

// src/api/logic/service/AuthService       — Interaction · Logical
class AuthService extends Service {
  init()      {}
  terminate() {}
  handleLogin(request) -> response {
    session = B.authBusiness.login(request.email, request.password) // ↓ via B
    return 200, { token: session.token }
  }
}

// src/api/A                               — Interaction · Injection
class A {
  private constructor()
  static readonly authService = new AuthService()
  static init()      { A.authService.init() }
  static terminate() { A.authService.terminate() }
}

// src/XF                                  — start-point element (optional)
class XF {
  private constructor()
  static init()      { R.init(); B.init(); A.init() }
  static terminate() { A.terminate(); B.terminate(); R.terminate() }
}

// main  — entry point, OUTSIDE the artefact root
import { XF } from "./src/XF"
XF.init()
onShutdown(() => XF.terminate())
```

Note how `AuthService` never imports `UserRepository`, and `AuthBusiness`
never does `new UserRepository()`: the descending reach is always
`B.x` / `R.x`. A second small example — a temperature reading — would mirror
this exactly: `TemperatureRepository` (read the sensor) ← `TemperatureBusiness`
(apply thresholds) ← `TemperatureService` (`A.temperatureService.update()`),
with a `Reading` Transfer flowing up.

### 6. Compliance checklist (map to the rule groups)

Before handing the code back, self-check against the catalogue
(`../_shared/catalogue.md`; per-rule detail in `../_shared/rules-detail.md`):

| Group | Check on the generated code |
|---|---|
| 1 — Folder structure | every file under a canonical layer/type folder; file name = class name; one injection per present layer |
| 2 — Layer isolation | only descending references; no upward/lateral; no cross-layer Logical inheritance |
| 3 — Logical | correct suffix (`Repository`/`Business`/`Service`/`View`); invocable `init()`/`terminate()`; no heavy constructor |
| 4 — Generalization | abstract, same-layer suffix, no domain state, no injection calls |
| 5 — Injection | named `R`/`B`/`A`; non-instantiable; immutable public slots; symmetric `init`/`terminate` over its slots only |
| 6 — Utility | `*Utils`, non-instantiable, static-only, no state, no side effects |
| 7 — Transfer | domain-named, no dependencies, no business operations; exceptions are a Transfer subtype |
| 8 — XF element | `init()` = `R;B;A`, `terminate()` = `A;B;R`, exact order, nothing else |
| 9 — Lifecycle exclusivity | only injections `new` / init / terminate Logicals; only `XF` drives the injections |

State the conformance level you are targeting: a clean structural
implementation reaches **Λ=3** (structurally conformant — the static ceiling);
**Λ=4** additionally requires human review of the semantic rules (does a
Repository contain only access logic? does a Transfer avoid modelling the
domain?). When you implemented into an existing XF artefact, confirm it with the
validator (step 7).

### 7. Verify with the validator (when the target is an XF artefact)

If you generated code **into an existing XF artefact root** (a `./src/` with the
canonical layers + a language manifest), don't stop at the self-check — run the
reference validator to confirm the new components didn't break conformance. Run
it with the Bash/shell tool:

```bash
npx @xfcfam/tools validate <artefact-root>        # one-off, no install
```

If the user will iterate, recommend installing it once (faster than re-fetching
with `npx` every time):

```bash
npm i -g @xfcfam/tools     # adds the `xftools` command
xftools validate <artefact-root>
```

Report the `Λ` it returns and fix any structural violation it flags before
handing the code back; the tool tops out at `Λ=3`, so the semantic checks in
step 6 remain your responsibility. **Skip the validator** when there is no
artefact root to point it at — a brand-new scaffold with nothing wired yet, a
single snippet, or a design with no `/src` — or when Node / npm is unavailable;
there, the step-6 self-check is the verification.

## Final note

Generate only the cells the feature needs, wire every Logical through its
injection, keep dependencies strictly descending, and place `main` outside the
root. When the user's project already has files, read them first and match the
existing conventions (extension, import style, base classes) instead of
imposing fresh boilerplate. If the feature is large or the design is contested,
run `xf-specify` first to agree the component plan, then return here to
implement it.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — effective vs contextual logic, the cross-layer duplication mandate, upward events, and transfers-with-operations — so generated code matches the model's intent.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
