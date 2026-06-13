---
name: xf-classify
description: >
  Use this skill when the user asks to "classify this component", "where does
  this class belong in XF?", "what layer is this?", "what type is this?",
  "help me classify my code for XF", "what should I rename this to?", or
  "how do I migrate this to XF structure?". Also use when the user provides
  existing code and wants to know its XF classification before refactoring.
metadata:
  version: "0.4.0"
---

# XF Component Classifier

Analyse code components and produce their XF L×T classification with canonical
names and target file paths.

## Procedure

### 1. Read the code

If the user provided files, read them. If they pasted a snippet, analyse it
directly. If multiple components are present, classify each one.

### 2. Classify each component

For each component, apply the decision tree in `references/decision-tree.md`.
Determine:

1. **Layer (L)** — which of the 3 layers this component belongs to
2. **Type (T)** — which of the 5 types within that layer
3. **Canonical name** — derive from the domain concept + correct suffix
4. **Target path** — canonical folder for this L×T combination

### 3. Produce a classification table

Present results as a table:

| Current name | Layer | Type | Canonical name | Target path |
|---|---|---|---|---|
| UserDAO | Access | Logical | UserRepository | repository/logic/remote/UserRepository.ts |
| UserModel | Business | Transfer | User | business/transfers/User.ts |
| AuthController | Interaction | Logical/Service | AuthService | api/logic/service/AuthService.ts |

### 4. Flag ambiguous cases

If a component spans multiple layers (god object, mixed concerns), flag it:
- State the split: "This component combines Access and Business logic. Recommend
  splitting into `UserRepository` (Access/Logical) and `UserBusiness` (Business/Logical)."
- Provide the proposed split with concrete method assignments.

### 5. Identify naming conflicts

If the new canonical name clashes with an existing component:
- Suggest a more specific domain prefix: `RemoteUserRepository`, `LocalUserRepository`
- Never introduce technology names into the canonical name if a domain name exists

### 6. Summarise migration steps

After the table, list the rename and move steps in order:
1. Rename X → Y
2. Move to path Z
3. Update injection file (which injector, which property name)
4. Update all import sites

Do not generate the actual renamed files unless the user asks. Offer: "Should
I apply these changes to the files?"

## Classification shortcuts

Use `references/decision-tree.md` for the full decision tree. Quick heuristics:

- Has network/DB/file I/O as its **primary purpose** → **Access / Logical**
- Contains domain rules, business invariants, domain state → **Business / Logical**
- Is an HTTP handler, event listener, GUI controller, CLI entry → **Interaction / Logical**
- A structure that *is* the data (methods, if any, are self-contained — no deps, no domain process) → **Transfer** (assign to the layer that creates it)
- Stateless helper functions only → **Utility** (assign to the layer that uses it)
- Manages and exposes other Logicals in one layer → **Injection** (R, B, or A)
- Shared base class for multiple Logicals in the same layer → **Generalization**

When a component does not fit cleanly into one category, split it first, then
classify the parts.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — effective vs contextual logic, the logical/generalization parametricity test, and the meta-model framing behind classification.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
