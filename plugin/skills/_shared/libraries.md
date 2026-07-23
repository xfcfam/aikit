# XF reference libraries — discovery (technology-agnostic)

Before hand-writing a Utility, a Generalization, or a whole layer adapter, check
whether a published **XF reference library for the developer's stack** already
covers it, and extend / compose it instead of reinventing.

**There is no static package list here, on purpose.** Across npm, NuGet, PyPI,
Maven and others, the set of packages — their versions, status and
correspondence to a given technology — changes constantly; a baked-in catalogue
would be stale the day after it is written and would silently misadvise. So the
existence and version of a concrete package is **resolved live** against the
relevant registry (below). What this file holds is only the **stable, model-level
map** of *what kinds of reusable building block to look for*.

## Reuse rule

1. Need persistence, HTTP, a filesystem, SQL, a server transport, or a
   cross-cutting policy (retry / cache / pagination / scheduling / a state
   machine / observable state)? A reference library probably already provides the
   matching Generalization or Utility — reach for it **first**.
2. Extend the library's base Generalization for your layer (e.g. a
   `…Repository` base) instead of re-deriving the lifecycle / injection contract.
3. Hand-write a component only when no library covers the need — always valid,
   since the libraries are *conveniences, not prescriptions* — and keep it in the
   canonical folder for its L×T cell.

## Capability map (stable — *what* to look for)

The model anticipates these *kinds* of reusable building block. The concrete
package name differs per ecosystem and is resolved live (next section):

| Capability | XF role | Building block to look for |
|---|---|---|
| Core abstractions | every layer | the layer Generalizations (`Repository` / `Business` / `Service` / `View`) and their stateless / observable / cacheable / retryable / paginated / scheduled / validated / state-machine variants; the `R` / `B` / `A` injection contracts; the `XF` lifecycle orchestrator |
| HTTP / REST client | Access | a `RestRepository`-type Generalization (+ a retry variant) and content-type / date parse `*Utils` |
| Filesystem | Access | a `FileRepository`-type Generalization (+ cached / audited variants) |
| SQL / database | Access | a `DatabaseRepository`-type Generalization (+ a transactional variant) and per-dialect adapters |
| Inbound server / transport | Interaction + Business | a transport-agnostic server contract + transport adapters (REST · WebSocket · SSE · GraphQL · gRPC · …) |
| Cross-cutting policy | any layer (as a Generalization) | retry · cache · pagination · scheduling · observable state · validation · state machine |

## Resolve concrete packages live (per ecosystem)

1. **Detect the ecosystem** from the artefact's manifest: `package.json` → npm ·
   `*.csproj` / `*.sln` → NuGet · `pyproject.toml` / `requirements.txt` → PyPI ·
   `pom.xml` / `build.gradle` → Maven / Gradle.
2. **Search the official XF namespace in that registry** for the capability, and
   read the **current version and status from the registry itself** — never from
   memory or from this file:
   - **npm** — `npm search @xfcfam` · `npm view @xfcfam/<pkg> version` (scope `@xfcfam/*`)
   - **NuGet** — `dotnet package search XFCFAM` (the official XF namespace, as/when published)
   - **PyPI** — search / `pip index versions <pkg>` in the official `xfcfam` namespace
   - **Maven Central** — search the `org.xfcfam` group
3. **If a library exists**, prefer it and pin the version the registry reports.
   **If none exists for that ecosystem yet**, hand-write the component per the
   model (equally conformant) — do not block on a missing library.

> **Reference implementation today:** the model's reference libraries are
> TypeScript, published to **npm under the `@xfcfam/*` scope** (core + REST,
> filesystem, SQL and server adapters). Treat even that as something to **confirm
> live** (`npm search @xfcfam`) rather than a fixed list — the namespace grows,
> and other ecosystems (NuGet / PyPI / Maven) come online over time. Full
> ecosystem: <https://xfcfam.org>.

> The library base classes are **conveniences** of a reference implementation,
> **not** prescriptions of the model. XF prescribes only the L×T classification
> and the descending-dependency direction; a component that achieves those by any
> mechanism is equally conformant.
