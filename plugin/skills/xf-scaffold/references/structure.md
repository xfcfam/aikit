# XF Canonical Structure & Templates

For the **full normative folder layout and the rule catalogue** (71
rules across 9 groups), read `../../_shared/catalogue.md`. This document
is the *generation guide* — the concrete code templates an LLM should
produce when asked to scaffold an XF artefact.

## Top-level layout

The artefact root contains the manifest of the target language
(`package.json`, `pyproject.toml`, `pom.xml`, `*.csproj`, …), the
entry point (`main.ts` / `main.py` / `Main.java` / …), the build
configuration, and a single `src/` directory with the XF body.

**The entry point lives at the artefact root, NOT inside `/src`.**
xftools validates only `/src`; the entry point is the consumer's
prerogative.

```
my-app/
├── package.json                  ← manifest (drives xftools language detection)
├── tsconfig.json
├── main.ts                       ← entry point (FUERA de /src)
└── src/                          ← validated tree
    ├── XF.ts                     ← (optional) XF start-point element
    ├── api/                      ← Interaction layer (§ 7.2.3)
    │   ├── A.ts                  ← Injection (canonical)
    │   ├── general/              ← Generalizations
    │   ├── logic/                ← Logicals
    │   │   ├── service/          ← *Service Logicals (recommended subfolder)
    │   │   └── gui/              ← *View Logicals (recommended subfolder)
    │   ├── transfers/            ← Transfers + Exceptions
    │   └── utils/                ← Utilities
    ├── business/                 ← Business layer (§ 7.2.2)
    │   ├── B.ts                  ← Injection
    │   ├── general/
    │   ├── logic/                ← *Business Logicals
    │   ├── transfers/
    │   └── utils/
    └── repository/               ← Access layer (§ 7.2.1)
        ├── R.ts                  ← Injection
        ├── general/
        ├── logic/                ← *Repository Logicals
        │   ├── local/            ← recommended subfolder
        │   └── remote/           ← recommended subfolder
        ├── transfers/
        └── utils/
```

Notes:

- `XF.ts` is optional. Use it when the artefact is an executable
  (CLI, service, daemon, app). Library packages typically skip it. The
  entry point (`main`) lives at the artefact root, OUTSIDE `/src`.
- The canonical type subfolders are `/general`, `/logic`, `/transfers`,
  `/utils` (rule `structure-type-mismatch`). The `service/`/`gui/`/
  `local/`/`remote/` subdivisions inside `logic/` are *recommended*
  only (rule `structure-domain-subdivision` guards against the wrong
  subdivision criterion), not mandatory.

---

## Canonical patterns (TypeScript)

### `R.ts` — Access Injection

```typescript
import { UserRepository } from './logic/remote/UserRepository.js'
import { ConfigRepository } from './logic/local/ConfigRepository.js'

export class R {
  private constructor() {}

  static readonly userRepository   = new UserRepository()
  static readonly configRepository = new ConfigRepository()

  static async init(): Promise<void> {
    await R.userRepository.init()
    await R.configRepository.init()
  }

  static async terminate(): Promise<void> {
    await R.configRepository.terminate()
    await R.userRepository.terminate()
  }
}
```

Notes:

- `private constructor()` → not instantiable (`injection-instantiable`).
- `static readonly` fields → immutable, public references
  (`injection-member-mutable`, `injection-member-public`); each must be a
  logical of this layer (`injection-non-repository`).
- `init` / `terminate` orchestrate every Logical of the layer
  (`injection-init-missing` / `injection-terminate-missing`,
  `injection-lifecycle-symmetry`); their bodies may contain nothing but
  the slot lifecycle calls (`injection-init-mismatch` /
  `injection-terminate-mismatch`). Calling `await R.x.init()` from
  `R.init` is the only legitimate invocation site (rule
  `lifecycle-logic-init`).
- Empty version (library placeholder):
  ```typescript
  export class R {
    private constructor() {}
    static async init(): Promise<void> {}
    static async terminate(): Promise<void> {}
  }
  ```
  Used by `@xfcfam/fs`, `@xfcfam/rest`, `@xfcfam/sql` and
  similar packages that contribute Generalizations but no Logicals.

### `B.ts` — Business Injection

```typescript
import { UserBusiness } from './logic/UserBusiness.js'
import { OrderBusiness } from './logic/OrderBusiness.js'

export class B {
  private constructor() {}

  static readonly userBusiness  = new UserBusiness()
  static readonly orderBusiness = new OrderBusiness()

  static async init(): Promise<void> {
    await B.userBusiness.init()
    await B.orderBusiness.init()
  }

  static async terminate(): Promise<void> {
    await B.orderBusiness.terminate()
    await B.userBusiness.terminate()
  }
}
```

### `A.ts` — Interaction Injection

```typescript
import { UserService } from './logic/service/UserService.js'
import { MainView } from './logic/gui/MainView.js'

export class A {
  private constructor() {}

  static readonly userService = new UserService()
  static readonly mainView    = new MainView()

  static async init(): Promise<void> {
    await A.userService.init()
    await A.mainView.init()
  }

  static async terminate(): Promise<void> {
    await A.mainView.terminate()
    await A.userService.terminate()
  }
}
```

### `XF.ts` — XF start-point element (optional)

```typescript
import { R } from './repository/R.js'
import { B } from './business/B.js'
import { A } from './api/A.js'

export class XF {
  private constructor() {}

  static async init(): Promise<void> {
    await R.init()
    await B.init()
    await A.init()
  }

  static async terminate(): Promise<void> {
    await A.terminate()
    await B.terminate()
    await R.terminate()
  }
}
```

- `XF.init()` body is exactly `R.init(); B.init(); A.init()` and
  `XF.terminate()` is exactly `A.terminate(); B.terminate(); R.terminate()`
  (rules `xf-init-mismatch` / `xf-terminate-mismatch`); both must be
  declared (`xf-init-missing` / `xf-terminate-missing`).
- `XF` contains only the lifecycle delegations — no static or
  instance state of its own. Only `XF` may invoke `init()` / `terminate()`
  on an injection (`lifecycle-injection-init` /
  `lifecycle-injection-terminate`).

### `main.ts` — entry point (lives OUTSIDE `/src`)

```typescript
import { XF } from './src/XF.js'

async function main(): Promise<void> {
  await XF.init()
  process.on('SIGTERM', () => void XF.terminate())
  // wire up servers / CLI / event loops here
}

void main()
```

---

## Component templates (TypeScript on `@xfcfam/xf`)

The `@xfcfam/xf` core package ships base Generalizations that every
Logical / Transfer / Utility extends. **Always prefer extending these
over rolling your own base class** — that's how the canonical lifecycle
contract gets wired automatically.

### Logical (Access layer — Repository)

```typescript
import { Repository } from '@xfcfam/xf'
import type { User } from '../transfers/User.js'

interface UsersState { client: HttpClient }

export class UserRepository extends Repository<UsersState> {
  constructor() { super({ client: new HttpClient() }) }
  async init()      { await this.state.client.connect() }
  async terminate() { await this.state.client.disconnect() }

  async fetch(id: string): Promise<User> {
    return this.state.client.get(`/users/${id}`)
  }
}
```

For stateless Repositories use `StatelessRepository` (no state field
required). For HTTP, SQL, filesystem use the dedicated wrapper
packages: `@xfcfam/rest` exposes `RestRepository`,
`@xfcfam/sql` exposes `DatabaseRepository`, `@xfcfam/fs`
exposes `FileRepository`.

### Logical (Business layer)

```typescript
import { StatelessBusiness } from '@xfcfam/xf'
import { R } from '../../repository/R.js'
import type { User } from '../transfers/User.js'

export class UserBusiness extends StatelessBusiness {
  async init() {}
  async terminate() {}

  async getUser(id: string): Promise<User> {
    return R.userRepository.fetch(id)
  }
}
```

Note the cross-layer access pattern: `R.<repository>.<operation>()`.
Never `new UserRepository()` inside a Business component — that
violates `lifecycle-logic-instantiation`. Never reference
`UserRepository` directly from `'../../repository/...'` and call it —
that violates `layer-reference`.

### Logical (Interaction layer — Service)

```typescript
import { StatelessService } from '@xfcfam/xf'
import { B } from '../../business/B.js'

export class UserService extends StatelessService {
  async init() {}
  async terminate() {}

  async handleGetUser(id: string) {
    return B.userBusiness.getUser(id)
  }
}
```

`*Service` Logicals serve programmatic clients (REST, RPC, websocket);
for human-facing GUI screens extend `StatelessView` (or `View`) and use
the `*View` suffix instead.

### Transfer (data, no logic)

```typescript
export interface User {
  id: string
  name: string
  email: string
}
```

Transfers carry only data and must not reference an injection, logical,
generalization or utility (`transfer-dependency`); an operation that
models a business process violates `transfer-business-logic`. Use
Utilities for pure operations on Transfers. Transfers live in
`<layer>/transfers/`.

### Exception (typed transfer of the exception flow)

```typescript
export class UserNotFoundException extends Error {
  constructor(public readonly userId: string) {
    super(`User not found: ${userId}`)
    this.name = 'UserNotFoundException'
  }
}
```

**Use custom Exceptions only when the error represents a domain
concept**. Generic runtime exceptions (`throw new Error("file
unreadable")`) are valid XF transfer vehicles — do not wrap them
gratuitously.

### Utility (static, stateless)

```typescript
export class StringUtils {
  private constructor() {}

  static slugify(text: string): string {
    return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  }
}
```

Utilities live in `<layer>/utils/`, bear the `Utils` suffix
(`utility-naming`), are not instantiable (`utility-instantiable`), have
no instance members (`utility-member-instance`) and no mutable state
(`utility-mutable-state`). A utility that models the domain, calls
logicals via injections, or causes observable side effects violates the
semantic rule `utility-mismatch`.

### Generalization (abstract base for Logicals)

```typescript
import { Business } from '@xfcfam/xf'
import type { ValidationResult } from '../transfers/ValidationResult.js'

export abstract class ValidatedBusiness<T> extends Business<T> {
  protected abstract validate(input: unknown): ValidationResult
}
```

Generalizations live in `<layer>/general/`, prevent direct instantiation
(`general-instantiable`), carry the layer suffix
(`general-naming-repository` / `-business` / `-service` / `-view`),
declare no domain state (`general-domain-state`), and may inherit only
from a same-layer generalization (`general-inheritance`). **Ramify
Generalizations by cross-cutting policy (caching, retry, audit), never by
functional split.**

---

## Per-language quick reference

For Python / Java / Kotlin / Swift / C# / C++ the same structural
contract applies: layer folders, type sub-folders, the L×T matrix,
the canonical `R` / `B` / `A` / `XF` patterns. Adapt the language
idioms:

| Concept | TS / JS | Java / Kotlin | Swift | C# | Python | C++ |
| --- | --- | --- | --- | --- | --- | --- |
| Non-instantiable | `private constructor()` | `private` ctor | `private init()` | `private` ctor | factory + convention | `private:` ctor |
| Immutable static | `readonly` | `final` | `static let` | `readonly` | `Final[T]` | `const` |
| Abstract class | `abstract class` | `abstract class` | (protocol) | `abstract class` | `ABC` | pure-virtual |
| Lifecycle | `async init/terminate` | same | same | same | `async def` | same |

xftools today has a real parser only for **TypeScript**. The other
languages have stub parsers and the structural-only rules apply.
See `_shared/catalogue.md` § "Languages".

---

## Project `CLAUDE.md` — ambient XF awareness

Every **full-project scaffold** also writes a `CLAUDE.md` at the artefact's repo
root. This is what makes future sessions treat the project as XF **without the
user ever typing "XF"**: Claude Code auto-loads `CLAUDE.md` at the start of every
session, so a generic request ("add a login endpoint") gets XF treatment because
the ambient context says the repo is XF and routes the work to the XF skills.

Write the template below verbatim, substituting `<project>`. **Never overwrite an
existing `CLAUDE.md`** — if one is present, append only the
`## Architecture — XF / CFAM` section to it, or (to leave the user's root file
untouched) write to `.claude/CLAUDE.md`, which Claude Code also auto-loads.

````markdown
# <project>

## Architecture — XF / CFAM (read this first)

This repository is an **XF artefact** (Cross-Framework Architecture Model, CFAM,
edition XF-CFAM-001:2026). Apply the XF model to **every** code request in this
repo — implement, review, test, refactor, document — **even when the request
does not mention "XF"**, unless the user explicitly opts out.

When the `xf-architecture` plugin is installed, route the work to its skills:

| Request | Skill |
| --- | --- |
| add / implement / build a feature or component | `xf-implement` |
| design / plan a feature before coding | `xf-specify` |
| classify existing code, or "what layer/type is this?" | `xf-classify` |
| review / audit / "is this right?" / conformance level | `xf-review` |
| write or design tests | `xf-test` |
| document the architecture / component catalog | `xf-document` |
| explain a concept or why a rule exists | `xf-explain` |
| add a folder or component skeleton | `xf-scaffold` |

If the `xf-architecture` plugin is not installed, follow the conventions below
and the full model at https://xfcfam.org.

### Conventions (summary — the skills carry the full rules)

- **3 layers, dependencies descending only:** Interaction (`src/api`) →
  Business (`src/business`) → Access (`src/repository`). Information may flow
  upward via events; dependencies never do.
- **Reach logicals only through the injections** `R` / `B` / `A`
  (`B.userBusiness.getUser(id)`); never `new` a logical elsewhere.
- **Canonical names:** `*Repository` / `*Business` / `*Service` / `*View` /
  `*Utils`; Transfers are the domain concept (no suffix); injections are
  `R` / `B` / `A`; the optional start-point element is `XF`.
- **Canonical folders:** `<layer>/{general,logic,transfers,utils}` + the
  injection file.

### Conformance

This artefact targets conformance level **Λ ≥ 3**. Validate with:

```bash
npx @xfcfam/tools validate ./        # one-off; or `xftools validate ./` after `npm i -g @xfcfam/tools`
```

Full model and ecosystem: https://xfcfam.org
````

Keep this file short — it is a pointer that sets the ambient convention, not a
copy of the spec. The skills and `INSTRUCTIONS.md` hold the detail.
