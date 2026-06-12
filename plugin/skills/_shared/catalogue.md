# `@xfcfam/tools`

CLI validator for the **XF / CFAM Architecture Model**. Given a project
root, it classifies every source file into the XF L × T matrix
(layer × component type), runs the normative rule catalog of the model
(`xfa-en.tex § 11.3`, edition **XF-CFAM-001:2026** — **71 rules across 9
groups**), and emits a single conformance level `Λ ∈ {0,1,2,3,4}` per the
§ 11.4 algorithm.

xftools is built **as an XF artefact itself** — `xftools validate ./`
runs the validator over its own source. Dogfood as acceptance test.

## What it does

xftools answers one question: **does this codebase actually follow the
XF architecture?** It does so by:

1. **Detecting the language** from manifests at the project root
   (`tsconfig.json`, `pyproject.toml`, `pom.xml`, `*.csproj`, …).
2. **Walking `/src`** for every source file of that language.
3. **Classifying** each file by its path: which XF layer
   (Access / Business / Interaction) and which type (Logical /
   Generalization / Injection / Utility / Transfer).
4. **Parsing** the source via the language-specific parser
   (TS Compiler API today; one stub per other language pending real
   implementation).
5. **Running the rule catalog** (`§ 11.3`, 71 rules / 9 groups) —
   structural-scope rules (path + filename only), component-scope rules
   (single-file class shape), artefact-scope rules (cross-file
   relationships). 61 rules are **structural** (decided statically); 10
   are **semantic** (declared, but require human review — the tool never
   fails them).
6. **Emitting a conformance report** via the § 11.4 four-stage
   algorithm: classification, totality check, catalog evaluation, level
   determination → a final `Λ ∈ {0,1,2,3,4}`.

The exit code is `0` if `Λ ≥ 3` (structurally conformant or better),
`1` if `Λ < 3`, `2` on usage / runtime errors.

## Languages

| Language | Detection | Parser | Coverage |
| --- | --- | --- | --- |
| **TypeScript** | `tsconfig.json` | TS Compiler API | Full catalog (all 61 structural rules) |
| Java | `pom.xml` / `build.gradle` | `java-parser` CST (when installed) | Path rules + AST rules with `appliesTo: java` |
| JavaScript | `package.json` | Stub | Path-based rules + the JS-applicable AST rules |
| Python | `pyproject.toml` / `setup.py` | Stub | Path-based rules only |
| Kotlin | `build.gradle.kts` | Stub | Path-based rules only |
| Swift | `Package.swift` | Stub | Path-based rules only |
| C# | `*.csproj` / `*.sln` | Stub | Path-based rules only |
| C++ | `CMakeLists.txt` / `conanfile.txt` | Stub | Path-based rules only |

Path-based rules (folder layout, filename suffixes) apply to every
language because they depend only on paths. Rules that need AST data
(class shape, imports, inheritance, call sites) require a real parser —
TypeScript is the reference parser today; Java has a CST parser that
loads on demand. Where a parser is a stub or a language lacks a
construct, the relevant rules declare an `appliesTo` set and the engine
skips them; xftools prints a warning so coverage is explicit. The
TypeScript dogfood is therefore the meaningful acceptance test.

Some rules are also **language-aware**: they check syntactic
constructs that don't exist in every language (e.g.
`injection-mutable-references` needs `readonly` / `final` / `val` /
`let` / `const` and is skipped on JavaScript and Python). These rules
declare an `appliesTo` set; the rule engine consults it before
running them.

## Install

```bash
npm i -g @xfcfam/tools
```

This installs the `xftools` command globally. Run it against any XF
artefact:

```bash
xftools validate <path> [--json]
```

`<path>` must point to an XF artefact: a directory that contains `./src/`
plus a manifest file at the root. `--json` switches the output to a
structured JSON document instead of the human-readable console format.

> One-off, without a global install: `npx @xfcfam/tools validate <path>`.

## Commands

| Command | What it does |
| --- | --- |
| `xftools validate <path> [--json]` | Validate that the XF artefact at `<path>` conforms to the model. Classifies every component, runs the rule catalog, and prints a conformance level `Λ ∈ {0..4}`. `--json` emits a structured report instead of console text. Exit code `0` if `Λ ≥ 3`, `1` if `Λ < 3`, `2` on usage / runtime errors. |
| `xftools -v`, `xftools --version` | Print the installed xftools version, the rule-catalog edition it validates against (`XF-CFAM-001:2026`), and the link to the specification. |
| `xftools -h`, `xftools --help` | List the available commands with a short description. |

`validate` is the only tool today; more will be added under the same
`xftools <command>` interface as the toolkit grows.

```bash
$ xftools -v
xftools 0.1.2
Rule catalog: XF-CFAM-001:2026 (71 rules / 9 groups)
Specification: https://xfcfam.org
```

### Example output

```
────────────────────────────────────────────────────────────────────────
XF Validation — /path/to/artefact
Catalog: XF-CFAM-001:2026 — 71 rules / 9 groups
────────────────────────────────────────────────────────────────────────
Conformance level:   Λ=3 [static ceiling]    (structurally conformant — zero structural violations)
Components scanned:  29
Structural violations: 0
Semantic violations:   0

✓ No structural violations. Artefact is structurally conformant (Λ=3).
  Reaching Λ=4 (perfectly conformant) requires human review of the
  10 semantic rules — a static tool cannot certify them.
```

When violations exist they are grouped by **scope** (`structural`,
`component`, `artefact`) and printed under their own headers, each
carrying the rule id, message, and file + line location.

## Conformance levels (XF spec § 11.2 / § 11.4)

The level is `Λ(𝔄) ∈ {0,1,2,3,4}`, computed by the four-stage algorithm
of § 11.4 (classify → totality → catalog → level):

| Level | Meaning |
| :---: | --- |
| **Λ=0** | Non-conformant: no classified component. |
| **Λ=1** | Partially conformant: the **totality condition** fails (≥1 component is not classified in the L × T matrix). The algorithm stops here. |
| **Λ=2** | Imperfectly conformant: totality holds, but ≥1 **structural** violation. |
| **Λ=3** | Structurally conformant: 0 structural violations, ≥1 **semantic** rule still pending. |
| **Λ=4** | Perfectly conformant: no violation of any kind. |

**Static ceiling.** A static tool cannot decide the 10 semantic rules,
so it reports **at most Λ=3** when there are no structural violations,
and flags that reaching Λ=4 requires human review of the semantic rules.
The XF start-point element is excluded from the totality predicate
(§ 11.4 Stage 2 — it is not a component).

## Rule catalog (XF-CFAM-001:2026)

The catalog mirrors the normative spec (`xfa-en.tex § 11.3`): **71 rules
across 9 thematic groups** — **61 structural** (decided statically) and
**10 semantic** (declared; require human review, never failed by this
tool). Each rule carries its canonical kebab-case `id`, group number,
verifiability, and `specRef`.

Verifiability legend: **structural** = decided by static analysis;
**semantic** = requires human architectural review (the tool declares it
but always returns no violation).

| Rule | Group | Verifiability | Description (short) | Spec |
| :--- | :---: | :---: | :--- | :--- |
| `structure-layer-mismatch` | 1 | structural | An element directly under /src is not a canonical layer folder or the XF element. | §7.4, §8.1 |
| `structure-type-mismatch` | 1 | structural | An element directly under a layer folder is not a canonical type subfolder or the layer injection. | §7.4 |
| `structure-injection-missing` | 1 | structural | A present layer folder lacks its canonical injection file (R / B / A). | §7.3.3 |
| `structure-injection-multiplicity` | 1 | structural | A layer declares more than one canonical injection file. | §7.3.3 |
| `structure-component-naming` | 1 | structural | A component class name does not match its file name (without extension). | §7.4 |
| `structure-domain-subdivision` | 1 | semantic | The /repository/logic or /api/logic subdivision groups by domain instead of by the legitimate layer criterion. | §7.2.1, §7.2.3 |
| `layer-reference` | 2 | structural | A component references another component of a higher abstraction layer (upward reference). | §6.2.2 |
| `layer-inheritance` | 2 | structural | A component inherits from a component classified in a different layer (either direction). | §6.2.2 |
| `layer-skip` | 2 | structural | A component references a lower-abstraction component skipping the intermediate layer (transfers and Access primitive utils excepted). | §6.2.2 |
| `logic-naming-repository` | 3 | structural | An Access Layer logical component must bear the suffix Repository. | §7.3.1, §7.2.1 |
| `logic-naming-business` | 3 | structural | A Business Layer logical component must bear the suffix Business. | §7.3.1, §7.2.2 |
| `logic-naming-service` | 3 | structural | An Interaction Layer logical implementing a systemic interaction point must bear the suffix Service. | §7.3.1, §7.2.3 |
| `logic-naming-view` | 3 | structural | An Interaction Layer logical implementing a graphical interaction point must bear the suffix View. | §7.3.1, §7.2.3 |
| `logic-mismatch-repository` | 3 | semantic | An Access Layer logical contains logic outside the responsibility of that layer. | §7.2.1 |
| `logic-mismatch-business` | 3 | semantic | A Business Layer logical contains logic outside the responsibility of that layer. | §7.2.2 |
| `logic-mismatch-api` | 3 | semantic | An Interaction Layer logical contains logic outside the responsibility of that layer. | §7.2.3 |
| `logic-initialization-missing` | 3 | structural | A logical component does not declare or inherit an invocable init() operation. | §7.3.1, §8.2 |
| `logic-termination-missing` | 3 | structural | A logical component does not declare or inherit an invocable terminate() operation. | §7.3.1, §8.2 |
| `logic-constructor-mismatch` | 3 | structural | A logical component performs non-trivial initialization in its constructor instead of in init(). | §8.2 |
| `logic-inheritance` | 3 | structural | A logical inherits from something other than a logical or generalization of its own layer. | §7.3.1, §7.3.2 |
| `general-naming-repository` | 4 | structural | An Access Layer generalization component must end with the suffix Repository. | §7.3.2, §7.2.1 |
| `general-naming-business` | 4 | structural | A Business Layer generalization component must end with the suffix Business. | §7.3.2, §7.2.2 |
| `general-naming-service` | 4 | structural | An Interaction Layer generalization for systemic interaction points must end with the suffix Service. | §7.3.2, §7.2.3 |
| `general-naming-view` | 4 | structural | An Interaction Layer generalization for graphical interaction points must end with the suffix View. | §7.3.2, §7.2.3 |
| `general-mismatch-repository` | 4 | semantic | An Access Layer generalization contains logic outside the responsibility of that layer. | §7.3.2, §7.2.1 |
| `general-mismatch-business` | 4 | semantic | A Business Layer generalization contains logic outside the responsibility of that layer. | §7.3.2, §7.2.2 |
| `general-mismatch-api` | 4 | semantic | An Interaction Layer generalization contains logic outside the responsibility of that layer. | §7.3.2, §7.2.3 |
| `general-injection-reference` | 4 | structural | A generalization component invokes logical components through an injection (R / B / A). | §7.3.2 |
| `general-domain-state` | 4 | structural | A generalization component declares mutable instance attributes (domain state). | §7.3.1, §7.3.2 |
| `general-instantiable` | 4 | structural | A generalization component must prevent its direct instantiation (abstract class or private constructor). | §7.3.2 |
| `general-initialization-missing` | 4 | structural | A generalization component does not declare or inherit an invocable init() operation. | §7.3.2, §8.2 |
| `general-termination-missing` | 4 | structural | A generalization component does not declare or inherit an invocable terminate() operation. | §7.3.2, §8.2 |
| `general-constructor-mismatch` | 4 | structural | A generalization component performs non-trivial initialization in its constructor instead of in init(). | §8.2 |
| `general-inheritance` | 4 | structural | A generalization inherits from an internal XF component that is not a same-layer generalization. | §7.3.2 |
| `injection-naming-r` | 5 | structural | The Access Layer injection component must be named R. | §7.3.3 |
| `injection-naming-b` | 5 | structural | The Business Layer injection component must be named B. | §7.3.3 |
| `injection-naming-a` | 5 | structural | The Interaction Layer injection component must be named A. | §7.3.3 |
| `injection-non-repository` | 5 | structural | The R injection declares a static slot that is not an Access Layer logical (Repository). | §7.3.3 |
| `injection-non-business` | 5 | structural | The B injection declares a static slot that is not a Business Layer logical (Business). | §7.3.3 |
| `injection-non-api` | 5 | structural | The A injection declares a static slot that is not an Interaction Layer logical (Service / View). | §7.3.3 |
| `injection-mismatch` | 5 | structural | An injection declares a member other than a static logical reference or static init() / terminate(). | §7.3.3 |
| `injection-instantiable` | 5 | structural | An injection component must prevent its instantiation (private constructor or abstract class). | §7.3.3 |
| `injection-member-mutable` | 5 | structural | The static logical references of an injection component must be immutable (readonly / final / val / const). | §7.3.3 |
| `injection-member-public` | 5 | structural | The static logical references of an injection component must have public visibility. | §7.3.3 |
| `injection-init-missing` | 5 | structural | An injection component does not declare an invocable static init() operation. | §7.3.3, §8.2 |
| `injection-terminate-missing` | 5 | structural | An injection component does not declare an invocable static terminate() operation. | §7.3.3, §8.2 |
| `injection-init-mismatch` | 5 | structural | The init() body of an injection contains statements other than slot init() invocations. | §7.3.3 |
| `injection-terminate-mismatch` | 5 | structural | The terminate() body of an injection contains statements other than slot terminate() invocations. | §7.3.3 |
| `injection-lifecycle-symmetry` | 5 | structural | Every slot initialized in an injection init() must be terminated in terminate(), and vice versa. | §8.2 |
| `injection-inheritance` | 5 | structural | An injection component must not inherit from any component (internal or external). | §7.3.3 |
| `utility-naming` | 6 | structural | A utility component must bear the suffix Utils. | §7.3.4 |
| `utility-mismatch` | 6 | semantic | A utility component models the domain, calls logicals via injections, or causes observable side effects. | §7.3.4 |
| `utility-instantiable` | 6 | structural | A utility component must prevent its instantiation (private constructor or abstract class). | §7.3.4 |
| `utility-member-instance` | 6 | structural | A utility component declares instance members (non-static attributes or methods). | §7.3.4 |
| `utility-mutable-state` | 6 | structural | A utility component declares mutable attributes. | §7.3.4 |
| `utility-inheritance` | 6 | structural | A utility component inherits from something other than a utility of its same layer. | §7.3.4 |
| `transfer-naming` | 7 | semantic | A transfer component bears a suffix added to the domain concept it models. | §7.3.5 |
| `transfer-dependency` | 7 | structural | A transfer component references an injection, logical, generalization or utility component. | §7.3.5 |
| `transfer-business-logic` | 7 | semantic | An operation of a transfer component models a business process of the domain. | §7.3.5 |
| `transfer-inheritance` | 7 | structural | A transfer component inherits from a component that is not a transfer component. | §7.3.5 |
| `xf-init-missing` | 8 | structural | The XF element does not declare an invocable static init() operation. | §8.3 |
| `xf-terminate-missing` | 8 | structural | The XF element does not declare an invocable static terminate() operation. | §8.3 |
| `xf-init-mismatch` | 8 | structural | The XF.init() body must be exactly R.init(); B.init(); A.init() in that order. | §8.3 |
| `xf-terminate-mismatch` | 8 | structural | The XF.terminate() body must be exactly A.terminate(); B.terminate(); R.terminate() in that order. | §8.3 |
| `lifecycle-logic-instantiation` | 9 | structural | A component other than the injection instantiates a logical component via new. | §7.3.3 |
| `lifecycle-logic-init` | 9 | structural | A component other than the layer injection invokes init() on a logical component. | §7.3.3, §8.2 |
| `lifecycle-logic-terminate` | 9 | structural | A component other than the layer injection invokes terminate() on a logical component. | §8.2 |
| `lifecycle-injection-init` | 9 | structural | A component other than the XF element invokes init() on an injection component. | §7.3.3, §8.3 |
| `lifecycle-injection-terminate` | 9 | structural | A component other than the XF element invokes terminate() on an injection component. | §8.3 |
| `lifecycle-xf-init` | 9 | structural | A component other than XF itself invokes init() on the XF element. | §8.3 |
| `lifecycle-xf-terminate` | 9 | structural | A component other than XF itself invokes terminate() on the XF element. | §8.3 |

For the per-group prose with applicability notes, see
**[RULES.md](./RULES.md)**.

## Documentation

The full XF / CFAM specification and ecosystem live at
**[xfcfam.org](https://xfcfam.org)**.

## License

MIT.
