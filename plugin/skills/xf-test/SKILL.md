---
name: xf-test
description: >
  Use this skill when the user asks to "write tests for this XF component",
  "how do I test XF code", "design a test strategy for my XF artifact", "mock
  the injection for testing", "how do I test a Business logical in isolation",
  "test my XF repository", or "what should test coverage look like for XF".
  Also trigger when the user wants help unit-testing XF / CFAM code while
  respecting layer isolation.
metadata:
  version: "0.2.0"
---

# XF Test Designer

Design and generate tests for an **XF Architecture Model (CFAM)** artefact
that respect layer isolation. The model's downward-only dependency rule and
its injection conduit make testing mechanical: each Logical is tested in
isolation by swapping the **layer below** for a test double, injected through
that layer's injection (`R` / `B` / `A`). Tests never reach across layers.

For the canonical structure and the rule catalog, read
`../_shared/catalogue.md` and `../_shared/rules-detail.md`. Treat them as
authoritative; they mirror the normative spec (`xfa-es.tex`, edition
`XF-CFAM-001:2026`).

## Procedure

### 1. Identify what is under test and its layer

Read the code (or the path) and classify each subject by its L×T cell — the
path gives it directly (`business/logic/SessionBusiness.ts` →
`(Business, Logical)`). The layer dictates **what you mock**:

| Subject (Logical) | Mock this | Leave real |
| --- | --- | --- |
| **Business** logical | `R` (Access) | the Business logical itself |
| **Interaction** logical (Service / View) | `B` (Business) | the Interaction logical |
| **Access** logical (Repository) | the external system (fake / contract) | the Repository |

The rule is uniform: **test a Logical by injecting test doubles through its
layer injection, mocking only the layer immediately below — never reach
across layers** (an Interaction test mocks `B`, not `R`).

### 2. Unit-test Business logicals as pure domain logic

Business holds domain rules and is framework-free, so it is the cheapest to
test. Replace the Access injection `R` with a double exposing the same slots,
then assert on the domain behaviour:

```
# pseudocode — testing SessionBusiness in isolation
fakeR = stub R with:
    sessionRepository.renew()  -> returns Session(id="s1", userId="u1")

inject fakeR into the Business layer        # the only seam needed
result = B.session.refresh()                # exercise via the injection

assert result.id == "s1"
assert fakeR.sessionRepository.renew was called once
```

No real database, HTTP, or filesystem is involved — Access is entirely
mocked, so the test exercises only domain logic.

### 3. Test Interaction by mocking Business; test Access against fakes/contracts

**Interaction (Service / View)** — mock the Business injection `B`; assert
that the entry point delegates correctly and shapes the response. Do not mock
`R`: an Interaction component must not know Access exists.

```
# pseudocode — testing UserService
fakeB = stub B with:
    userBusiness.getUser("u1") -> returns User(id="u1", name="Ada")

inject fakeB into the Business seam
response = A.userService.handleGetUser("u1")

assert response.name == "Ada"
assert fakeB.userBusiness.getUser was called with "u1"
```

**Access (Repository)** — Access is the boundary to the outside world, so it
is tested against **fakes or contract tests** for the external system
(in-memory DB, mock HTTP server, temp filesystem, a recorded contract). This
is the one layer whose tests legitimately touch I/O — keep them separate
(integration tier) from the pure unit tests of Business/Interaction.

### 4. Verify directionality and lifecycle

Beyond behaviour, add tests (or static checks) that protect the model's
invariants — these are the architecture's load-bearing rules:

- **Directionality** — no upward or lateral calls; a layer reaches the one
  below **only** through that layer's injection, and logicals are never
  `new`-ed outside their injection. Much of this is caught statically by
  `xftools` / the `xf-review` skill (rules `layer-reference`, `layer-skip`,
  `lifecycle-logic-instantiation`); a test can additionally assert that a
  Business subject made no call your fake `R` did not expose.
- **Lifecycle order** — `init` runs `R → B → A` and `terminate` runs the
  reverse. A focused test can spy on the injections and assert the call order
  (and, if an `XF` element exists, that `XF.init()` is exactly
  `R.init(); B.init(); A.init()`).

### 5. Treat Transfers as pure data and Utilities as pure functions

- **Transfers** are dumb data — there is **no behaviour to mock**. Construct
  one as a literal and use it as a fixture; do not write tests "for" a
  Transfer (any logic that looked testable on it belongs in a `*Utils`).
  Exception transfers (`*Exception`) are asserted on like any thrown value.
- **Utilities** are pure, static, stateless functions — **straightforward
  unit tests**: feed inputs, assert outputs, no mocks, no setup.

```
# pseudocode — utility is a pure function
assert StringUtils.slugify("Hello World") == "hello-world"
```

### 6. Locate tests outside the root; organise coverage by L×T cell

- **Tests live OUTSIDE the artefact root** (e.g. `/test`, `__tests__`, a
  sibling tree) and are **not L×T components** — they never appear in the
  matrix, the catalog, or the conformance count. `xftools` validates only the
  root; the test tree is the consumer's prerogative, exactly like `main`.
- **Suggest coverage organised by L×T cell.** Mirror the matrix so gaps are
  visible: every Logical has an isolation test; Utilities have pure-function
  tests; Access logicals have a contract/integration test; Transfers are
  fixtures, not test targets. A coverage checklist per cell:

| Cell | Test kind | Mock | Tier |
| --- | --- | --- | --- |
| Access · Logical | contract / integration | external system (fake) | integration |
| Business · Logical | isolation unit | `R` | unit |
| Interaction · Logical | isolation unit | `B` | unit |
| any · Utility | pure-function unit | none | unit |
| any · Transfer | fixture only | — | — |
| Injection / `XF` | lifecycle-order unit | the slots | unit |

## TypeScript note

In TypeScript the injection seam is the static class `R` / `B` / `A`. Inject
doubles by either (a) passing fakes through `init()` if the injection accepts
them, or (b) module-mocking the injection (`vi.mock('../business/B.js')`
in Vitest, or `jest.mock`) so `B.session.refresh()` resolves to a stub.
Prefer typing the fake against the real logical's interface so a signature
drift breaks the test. The `@xfcfam/*` packages' `StatelessBusiness` /
`StatelessView` bases make Business and Interaction logicals trivial to
instantiate with no real lifecycle. Keep Access (integration) tests in a
separate suite from the Business/Interaction unit suites.

## Notes

- **Mock only the layer directly below.** Mocking `R` while testing an
  Interaction component is a smell — it means the Interaction logical is
  reaching past Business, which is itself an XF violation to fix, not to test
  around.
- **Never mock a Transfer or a Utility** — they have no collaborators worth
  faking; use real instances.
- The architecture invariants (directionality, lifecycle) are best enforced
  statically: run `xftools validate <root>` or the `xf-review` skill, and
  reserve runtime tests for behaviour plus a few targeted invariant spies.
- If a component is hard to test in isolation, it usually signals a
  classification problem — suggest `xf-classify` to re-check its L×T cell
  before writing elaborate test scaffolding.

## References

- **Foundations & particularities:** [`../_shared/foundations.md`](../_shared/foundations.md) — why layer isolation and lifecycle exclusivity make testing mechanical, and the dependency vs data-flow distinction behind event-based assertions.
- **Normative spec:** <https://xfcfam.org> — edition XF-CFAM-001:2026. Clause map in [`../_shared/spec.md`](../_shared/spec.md).
- **Rule catalog:** [`../_shared/catalogue.md`](../_shared/catalogue.md) · [`../_shared/rules-detail.md`](../_shared/rules-detail.md) — 9 groups, 71 rules, conformance level Λ=0..4.
- **Reference libraries:** [`../_shared/libraries.md`](../_shared/libraries.md) — reuse the published `@xfcfam/*` packages before implementing utilities or generalizations by hand.
