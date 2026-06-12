# xf-architecture

> A Claude Code plugin for generating and verifying code that follows the
> **XF Architecture Model** (Cross-Framework Architecture Model, CFAM) —
> a technology-agnostic, layer-typed classification system for software
> components. Edition **XF-CFAM-001:2026**.

---

## Install

The `/plugin` commands run **inside Claude Code** (the CLI / interactive
session), not in other chat surfaces.

### From the marketplace (recommended)

```
/plugin marketplace add xfcfam/aikit
/plugin install xf-architecture@xfcfam
```

`xfcfam` is the **marketplace** name (defined in the repo-root
`.claude-plugin/marketplace.json`); `xf-architecture` is the **plugin**. Pin a
branch or tag with `@ref`, e.g. `/plugin marketplace add xfcfam/aikit@main`.

### From a local clone (for development)

```
git clone https://github.com/xfcfam/aikit
/plugin marketplace add ./aikit
/plugin install xf-architecture@xfcfam
```

After pushing changes upstream, refresh with:

```
/plugin marketplace update xfcfam
```

---

## Skills

| Skill | Trigger phrases | What it does |
|---|---|---|
| `xf-classify` | "classify this component", "what layer is this?", "help me migrate to XF" | Maps existing code to its L×T cell, canonical name, and target path. |
| `xf-specify` | "turn these requirements into an XF design", "what components do I need for…" | Translates requirements / user stories into an L×T component plan — design only, before any code. |
| `xf-implement` | "implement this feature in XF", "generate XF code for…", "build this following CFAM" | Generates XF-compliant components from a feature or requirement, wired through R/B/A. |
| `xf-scaffold` | "scaffold an XF project", "generate XF structure", "add a UserBusiness" | Generates the canonical folder layout, R/B/A injection stubs, and component boilerplate. |
| `xf-review` | "review for XF compliance", "check XF violations", "what conformity level is this?" | Audits code for layer / naming / folder / injection violations. Reports conformity level Λ=0..4. |
| `xf-test` | "write tests for this XF component", "how do I test XF code", "mock the injection for testing" | Designs tests that respect layer isolation (mock through R/B/A), with coverage by L×T cell. |
| `xf-document` | "document this XF artifact", "generate a component catalog / README" | Produces a component catalog by L×T cell, the injection map, the dependency view, and docs. |
| `xf-explain` | "explain XF", "how does injection work?", "what does Λ=2 mean?" | Answers questions about XF concepts with concrete code examples. |

---

## The XF Model — quick reference

**3 layers** ordered by abstraction:

```
Interaction  (api/)         ← entry points: HTTP, UI, events, CLI
     ↓
Business     (business/)    ← domain logic, business rules, domain state
     ↓
Access       (repository/)  ← external I/O: databases, APIs, files
```

Dependencies flow **downward only**. Interaction → Business → Access. Never upward or lateral.

**5 types** per layer:

| Type | Role |
|---|---|
| Logical | Core logic of the layer — one concern per component (the only type that may hold state) |
| Generalization | Shared abstract base for multiple Logicals in the same layer |
| Injection | Single entry point to all Logicals in the layer (`R` / `B` / `A`) |
| Utility | Pure stateless helpers, local to the layer |
| Transfer | The data that moves between components; may carry self-contained operations on its own data (exceptions are a Transfer subtype) |

**3 injection components** — the only way to access Logical components:

```
R  →  R.userRepository.fetch(id)        // Access layer
B  →  B.userBusiness.getUser(id)        // Business layer
A  →  A.userService.handleRequest(req)  // Interaction layer
```

**Startup order:** `R.init()` → `B.init()` → `A.init()` (terminate in reverse).
An optional `XF` start-point element centralises this: `XF.init()` runs
`R.init(); B.init(); A.init()`. The entry point (`main`) lives **outside** the
artifact root.

**Canonical naming:**

| Classification | Suffix | Example |
|---|---|---|
| Access Logical | `Repository` | `UserRepository` |
| Business Logical | `Business` | `UserBusiness` |
| Interaction Service | `Service` | `AuthService` |
| Interaction View | `View` | `LoginView` |
| Generalization | layer's logical suffix | `BaseUserRepository` |
| Utility | `Utils` | `DateUtils` |
| Transfer | *(none)* | `User`, `Session` |
| Exception | `Exception` | `NetworkException` |

**Conformity levels** — the model defines a deterministic level `Λ ∈ {0,1,2,3,4}`:

| Level | Meaning |
|---|---|
| Λ=0 | No conformant — nothing classified in the L×T matrix |
| Λ=1 | Partial — some components classified (injection-reachable), but not total |
| Λ=2 | Imperfect — all classified, but ≥1 **structural** violation |
| Λ=3 | Structurally conformant — all classified, 0 structural, ≥1 semantic. Well-formed; the ceiling a static tool can certify |
| Λ=4 | Perfectly conformant — all classified, 0 violations (requires human semantic review beyond Λ=3) |

---

## Supported languages

The scaffold and implement skills produce boilerplate for:

- TypeScript / JavaScript
- Python
- Swift
- Kotlin

The review, classify, document, and test skills work with any language
(structural rules are path-based; component / artifact rules need a parser,
fully implemented today for TypeScript).

---

## Canonical folder structure

```
src/
├── api/                    ← Interaction layer
│   ├── general/            ← Generalizations
│   ├── logic/              ← Logical components
│   │   ├── gui/            ← Views (recommended subdivision)
│   │   └── service/        ← Services (recommended subdivision)
│   ├── transfers/          ← Transfers
│   ├── utils/              ← Utilities
│   └── A                   ← Injection
├── business/               ← Business layer
│   ├── general/
│   ├── logic/
│   │   ├── instance/       ← (recommended)
│   │   └── device/         ← (recommended)
│   ├── transfers/
│   ├── utils/
│   └── B
└── repository/             ← Access layer
    ├── general/
    ├── logic/
    │   ├── local/          ← (recommended)
    │   └── remote/         ← (recommended)
    ├── transfers/
    ├── utils/
    └── R
```

The folder names (`/repository`, `/business`, `/api`, `/general`, `/logic`,
`/transfers`, `/utils`) are an immutable normative contract: conformity is
evaluated on the exact names. The L×T matrix is an **artifact root** and may
hang from any path — multiple roots can coexist in one tree, each verified
independently.

---

## Full specification

The XF Architecture Model specification is at [xfcfam.org](https://xfcfam.org).

For AI code generation without this plugin, use the raw instruction files:

- [`INSTRUCTIONS.md`](../INSTRUCTIONS.md) — universal, language-agnostic reference
- [`CLAUDE.md`](../CLAUDE.md) — Claude / Claude Code optimised
- [`AGENTS.md`](../AGENTS.md) — Copilot, Cursor, Windsurf, Aider
- [`.cursorrules`](../.cursorrules) — Cursor IDE rules file

---

## Contributing

Issues and pull requests are welcome at
[github.com/xfcfam/aikit](https://github.com/xfcfam/aikit).

Please follow the [XF Architecture Model specification](https://xfcfam.org)
when proposing changes to the skill content.

---

## License

[MIT](LICENSE) — © 2026 XFArch Contributors
