# XF Architecture Model — Instructions for Claude

> This file configures Claude (including Claude Code) to generate
> XF-compliant code. Read `INSTRUCTIONS.md` in this directory first —
> it contains the full canonical specification. This file adds
> Claude-specific guidance on top.

---

## Core reference

The complete XF model is in `INSTRUCTIONS.md`. Key facts at a glance:

- **3 layers:** Access (`repository/`) → Business (`business/`) → Interaction (`api/`)
- **5 types per layer:** Logical · Generalization · Injection · Utility · Transfer
- **3 injection components:** `R` (Access) · `B` (Business) · `A` (Interaction)
- **Access pattern:** `B.userBusiness.getUser(id)` — never `new UserBusiness()`
- **Init order:** `R.init()` → `B.init()` → `A.init()` (no args; centralised by `XF.init()`). Injections are static and non-instantiable.

---

## How to approach an XF task

When asked to create or modify code in an XF project, follow this sequence:

### Step 1 — Classify before writing

State your classification decision explicitly before generating code:

```
Layer:  Business (7.2)
Type:   Logical
Name:   UserBusiness
File:   business/logic/UserBusiness.ts
```

Do not skip this step. If the classification is ambiguous, ask.

### Step 2 — Check layer boundaries

Before writing any method that calls another component, verify:
- Am I in Interaction? I may call `B.*` — not `R.*` directly.
- Am I in Business? I may call `R.*` — not any framework or HTTP primitives.
- Am I in Access? I call external systems only — nothing inside the artefact.

If a call would violate the dependency rule, refactor: move the logic to the
correct layer, or surface the need for a new component.

### Step 3 — Name by convention

Derive the name from the domain concept, then append the suffix:

| Classification             | Append        |
|----------------------------|---------------|
| Access Logical             | `Repository`  |
| Business Logical           | `Business`    |
| Interaction Logical/svc    | `Service`     |
| Interaction Logical/view   | `View`        |
| Generalization             | its layer's logical suffix (`Repository`/`Business`/`Service`/`View`) |
| Any Utility                | `Utils`       |
| Injection                  | `R` / `B` / `A` |
| Transfer                   | (none)        |

### Step 4 — Place in the canonical folder

The four type-subfolder names are an immutable normative contract — use these
exact names (`/general`, `/logic`, `/transfers`, `/utils`):

```
api/logic/service/   → Interaction Services
api/logic/gui/       → Interaction Views
api/general/         → Interaction Generalizations
api/transfers/       → Interaction Transfers
api/utils/           → Interaction Utilities
api/A                → Interaction Injection

business/logic/      → Business Logicals
business/general/    → Business Generalizations
business/transfers/  → Business Transfers
business/utils/      → Business Utilities
business/B           → Business Injection

repository/logic/    → Access Logicals
repository/general/  → Access Generalizations
repository/transfers/→ Access Transfers
repository/utils/    → Access Utilities
repository/R         → Access Injection
```

---

## What to watch out for

### Common mistakes to avoid

**1. Business layer touching the framework**
```typescript
// ❌ Wrong — Business knows about HTTP
class UserBusiness {
    async getUser(req: Request, res: Response) { ... }
}

// ✓ Correct — Business is framework-agnostic
class UserBusiness {
    async getUser(id: string): Promise<User> { ... }
}
```

**2. Interaction calling Access directly**
```typescript
// ❌ Wrong — Interaction skips Business
class UserService {
    constructor(private r: R) {}
    async handleGet(req) {
        return this.r.userRepository.fetch(req.params.id) // direct Access call
    }
}

// ✓ Correct — Interaction goes through Business
class UserService {
    constructor(private b: B) {}
    async handleGet(req) {
        return this.b.userBusiness.getUser(req.params.id)
    }
}
```

**3. Logic inside a Transfer object**
```typescript
// ❌ Wrong — Transfer has business logic
class User {
    isAdmin(): boolean { return this.role === 'admin' }
}

// ✓ Correct — Transfer is pure data; logic goes in Business
class User { id: string; name: string; role: string }
class UserBusiness {
    isAdmin(user: User): boolean { return user.role === 'admin' }
}
```

**4. Instantiating Logicals directly**
```typescript
// ❌ Wrong — bypasses Injection
const repo = new UserRepository()

// ✓ Correct — always go through the injector
const user = R.userRepository.fetch(id)
```

**5. Utility with state**
```typescript
// ❌ Wrong — Utility keeps state
class DateUtils {
    private cache = new Map()
    format(d: Date) { ... }  // caching = side-effect = not a Utility
}

// ✓ Correct — pure function
class DateUtils {
    static format(d: Date, pattern: string): string { ... }
}
```

---

## Responding to XF questions

When asked to explain a classification or review code for XF compliance:

1. Identify the layer and type of each component.
2. Check that all dependency arrows point downward.
3. Check that no component performs work belonging to another layer.
4. Check that names match the canonical convention.
5. Check that files are in the correct folder.
6. Report any violations, distinguishing between:
   - **Structural violations** — decidable by static analysis (caps the
     artefact at Λ=2). Path, filename, naming, layer-direction, injection
     placement/uniqueness.
   - **Semantic violations** — require human review of a component's
     functional responsibility (cap the artefact at Λ=3).

Reference the conformity level as needed (Λ=0 … Λ=4); see INSTRUCTIONS.md §7.

---

## Generating new XF projects from scratch

When scaffolding a new XF project, always create this directory skeleton first:

```
src/
├── api/
│   ├── general/
│   ├── logic/
│   │   ├── gui/
│   │   └── service/
│   ├── transfers/
│   ├── utils/
│   └── A.<ext>
├── business/
│   ├── general/
│   ├── logic/
│   │   ├── instance/
│   │   └── device/
│   ├── transfers/
│   ├── utils/
│   └── B.<ext>
└── repository/
    ├── general/
    ├── logic/
    │   ├── local/
    │   └── remote/
    ├── transfers/
    ├── utils/
    └── R.<ext>
```

The `/logic` subdivisions (`gui`/`service`, `instance`/`device`,
`local`/`remote`) are recommended, not required. The `src/` matrix is an
**artifact root** — it may hang from any path, and multiple roots can coexist
in one project (verification runs per root). The execution entry point (main)
lives **outside** the artifact root.

Then create `R`, `B`, `A` injection stubs before any Logical component.

---

## Conformity checklist (use before finishing any XF task)

- [ ] Every component has a layer + type classification
- [ ] No upward dependencies (Access → Business, Business → Interaction)
- [ ] No Interaction → Access direct call
- [ ] All Logicals accessed through `R`, `B`, or `A`
- [ ] Transfer objects contain only data fields
- [ ] Utilities are stateless pure functions
- [ ] Naming matches the canonical convention
- [ ] Files are in the correct layer/type folder
- [ ] Exactly one Injection component per layer

---

*XF Architecture Model (CFAM) — edition XF-CFAM-001:2026. See INSTRUCTIONS.md for the full spec.*
