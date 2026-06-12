# XF reference libraries (`@xfcfam/*`)

Before implementing a Utility, a Generalization, or a whole layer adapter from
scratch, **check whether a published reference library already provides it** and
extend or compose it instead of reinventing. These packages are the official
TypeScript reference implementation of the XF model; each is published to npm and
depends on the core `@xfcfam/xf`. Full catalog and docs: <https://xfcfam.org>.

## Reuse rule

1. Need persistence, HTTP, a filesystem, SQL, a server transport, or
   retry / cache / pagination / scheduling / a state machine? Reach for the
   matching `@xfcfam/*` package **first**.
2. Extend the library's base Generalization for your layer
   (e.g. `class UserRepository extends StatelessRepository<…>`) — don't
   re-derive the lifecycle/injection contract by hand.
3. Only hand-write a component when no library covers the need, and keep it in
   the canonical folder for its L×T cell.

## Packages

| Package | Layer · role | What it provides |
|---|---|---|
| `@xfcfam/xf` | Core | Abstract layer Generalizations — `Repository<T>`, `Business<T>`, `View<T>` / `Service` and their `Stateless` / `Observable` / `Cacheable` / `Retryable` / `Paginated` / `Schedule` / `Validated` / `StateMachine` / `EventSourced` variants — the Injection contracts `R` / `B` / `A`, and the `XF` lifecycle orchestrator. |
| `@xfcfam/xf-rest` | Access | REST repository over `ky`: `RestRepository` + `RetryRestRepository`; `ParseUtils` / `ReviverUtils` for XML, CSV, custom content types, and date revival. |
| `@xfcfam/xf-fs` | Access | Filesystem over `node:fs`: `FileRepository` + its `Cached` / `Audited` variants. |
| `@xfcfam/xf-sql` | Access | SQL over the Kysely query builder (dialect-agnostic): `DatabaseRepository` + `TransactionalDatabaseRepository`. Pair with a dialect adapter. |
| `@xfcfam/xf-sql-postgres` | Access | PostgreSQL dialect adapter for `xf-sql` (Kysely `PostgresDialect` + `pg`; maps Postgres `SQLSTATE` to typed Exceptions). |
| `@xfcfam/xf-server` | Interaction + Business | Transport-agnostic inbound-server contract: the abstract `ServerBusiness` / `EntryService` (registry + lifecycle + request pipeline). No transport of its own. |
| `@xfcfam/xf-server-http` | Interaction + Business | HTTP transport over Fastify — REST · WebSocket · SSE · GraphQL on one port: `HttpServerBusiness` + `RestService` / `ObjectRestService` / `WebSocketService` / `GraphQLService`. |
| `@xfcfam/xf-server-grpc` · `-tcp` · `-udp` | Interaction + Business | Sketches — typed transport skeletons compiled against the `xf-server` contract (not production-ready). |

**Install pattern:** every adapter needs the core —
`pnpm add @xfcfam/xf @xfcfam/<pkg>`.

> The library's base classes (e.g. `StatelessBusiness`, `StatelessService`) are
> conveniences of the reference implementation, **not** prescriptions of the
> model. The XF model prescribes only the L×T classification and the
> descending-dependency direction; a component that achieves those with a
> different mechanism is equally conformant.
