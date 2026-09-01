# The twelve factors — audit reference

Companion to [SKILL.md](SKILL.md). One section per factor, each self-contained so it can be
pasted alone into a factor agent's prompt. Principles paraphrase [12factor.net](https://12factor.net/);
each heading links the source page. "What to check" lists are starting points, not ceilings —
follow the evidence the project actually presents.

Grades: ✅ compliant · ⚠️ partial · ❌ violation · ➖ not applicable (with reason).

---

## I. Codebase — [12factor.net/codebase](https://12factor.net/codebase)

**Principle.** One codebase per app, tracked in version control, deployed many times. Multiple
codebases behind one "app" is a distributed system; multiple apps sharing one codebase should
factor the shared code into libraries.

**What to check**

- `.git/` (or other VCS dir) exists at the root.
- Monorepo? Fine per se — but check each deployable has one clear home (workspaces, `apps/`,
  `services/`) rather than several repos/dirs holding copies of the same service.
- Copied-not-shared code: identical utility/model files duplicated across services (compare
  names and content, not just paths).
- Vendored forks of the project's own sibling services.

**Violation signals**

- No version control at all.
- The same service deployed from two diverging directories or branches by convention.
- Shared business logic copy-pasted between apps instead of extracted into a dependency.

**N/A** — almost never; a library repo is still "one codebase".

---

## II. Dependencies — [12factor.net/dependencies](https://12factor.net/dependencies)

**Principle.** Declare all dependencies completely and exactly in a manifest, and isolate them
at runtime; declaration and isolation are only sufficient together. Never rely on implicit
system-wide packages or system tools (if the app shells out to one, vendor it).

**What to check**

- Manifest exists: `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Gemfile`,
  `Cargo.toml`, `pom.xml`/`build.gradle`, `composer.json`, ….
- Lockfile exists and is committed: `package-lock.json`/`yarn.lock`/`pnpm-lock.yaml`,
  `poetry.lock`/`uv.lock`, `go.sum`, `Gemfile.lock`, `Cargo.lock`, `composer.lock`.
- Version pinning: wildcard (`*`, `latest`) or unbounded ranges in the manifest.
- Grep source and scripts for shell-outs to tools assumed on the host: `curl`, `wget`,
  `imagemagick`/`convert`, `ffmpeg`, `jq` — are they declared anywhere (Dockerfile, package
  manager, vendored)?
- Global installs required by docs/scripts (`npm i -g`, `pip install` outside a venv).
- Isolation: venv/container/`node_modules` usage vs imports resolved from system site-packages.

**Violation signals**

- No lockfile; lockfile in `.gitignore`.
- README says "install X globally first" for something the app needs at runtime.
- CI installs different dependency versions than dev (e.g. no `npm ci`).

**N/A** — rare; even single-file scripts can declare (inline script metadata, shebang + comment).

---

## III. Config — [12factor.net/config](https://12factor.net/config)

**Principle.** Config is everything that varies between deploys: backing-service handles and
credentials, external-service credentials, per-deploy hostnames. Store it in environment
variables — granular and independently managed, never grouped into named "environments".
Internal app wiring (routes, DI config) is not config in this sense. Litmus test: could the
codebase be open-sourced this minute without leaking a credential?

**What to check**

- Grep source for hardcoded secrets/URLs: API keys, passwords in connection strings,
  `postgres://user:pass@host`, cloud keys (`AKIA…`), tokens, SMTP creds.
- `.env` committed? (`.env` in git with real values vs `.env.example`/`.env.template` with
  placeholders — the latter is good practice.)
- Per-environment config files baked into the repo with real per-deploy values
  (`config/production.yml`, `settings_prod.py`) vs reading `process.env`/`os.environ`.
- Environment-name branching in code: `if (env === "production")` controlling *values* (URLs,
  keys) rather than behavior toggles.
- How the app reads config: env vars (good), files outside VCS (fragile), constants (bad).

**Violation signals**

- Any real credential in the repo — automatic ❌, and flag it prominently. **Never quote the
  secret's value in the report; cite file:line and the variable name only.**
- Adding a new deploy would require editing code or committing a new config file.

**N/A** — apps with genuinely nothing varying per deploy (rare; pure libraries → ➖).

---

## IV. Backing services — [12factor.net/backing-services](https://12factor.net/backing-services)

**Principle.** Anything the app consumes over the network (database, queue, cache, SMTP, object
store, third-party API) is an attached resource, addressed by a URL/credentials from config.
Local and third-party services are indistinguishable in code: swapping local MySQL for a managed
one is a config change, not a code change.

**What to check**

- Where connection details live: env-var-driven (good) vs hardcoded hosts/ports in code.
- One connection point per resource, or scattered ad-hoc clients constructed inline?
- Would swapping Postgres host, Redis endpoint, or S3 bucket require code edits?
- In-process substitutes standing in for network services in prod paths (SQLite file as the
  production DB, in-memory queue) — also relevant to factor X.
- Distinct services (two shard DBs, cache vs session store) treated as distinct configurable
  resources.

**Violation signals**

- `localhost` / static IPs / service hostnames literal in application code (outside test setup
  and docker-compose defaults).
- Client construction copy-pasted with credentials inline.

**N/A** — apps that consume no network services (pure CLI transforms) → ➖.

---

## V. Build, release, run — [12factor.net/build-release-run](https://12factor.net/build-release-run)

**Principle.** Strict one-way separation: build (fetch deps, compile, at a commit) → release
(build + config, immutable, uniquely identified, append-only, rollback-able) → run (launch
processes against a release, minimal moving parts). No changing code at runtime.

**What to check**

- A build step exists and is reproducible: `Dockerfile`, CI workflow, `build` script.
- Releases identified: image tags, version stamps, git SHA in the artifact — vs deploying
  `latest` / rsyncing a working tree.
- Config injected at release/run time (env, secrets manager) vs baked into the build per
  environment (separate "prod build" with different constants).
- Runtime mutation ability: hot-patching containers, editing files on servers, `git pull` on
  the production box as the deploy mechanism.
- Rollback path: previous images/releases retained.

**Violation signals**

- Deploy documented as "ssh in and git pull && restart".
- One image per environment built from different code or with env-specific constants compiled in.
- No way to say which code version is running right now.

**N/A** — interpreted languages with no build still have release/run separation to assess; ➖
only when nothing is deployed anywhere (pure library → the consumer owns this factor).

---

## VI. Processes — [12factor.net/processes](https://12factor.net/processes)

**Principle.** The app runs as stateless, share-nothing processes. Anything persistent lives in
a stateful backing service. Memory/disk are a single-transaction cache at most — never assume
they survive to a future request; restarts wipe them. Sticky sessions are a violation, full stop.

**What to check**

- Session storage: in-memory session middleware (e.g. default `express-session` MemoryStore,
  file-backed sessions) vs Redis/Memcached/DB-backed.
- Local filesystem writes that must persist: user uploads saved to `./uploads`, generated
  reports on disk — vs object storage.
- In-process caches assumed durable or shared across instances (module-level maps holding
  cross-request state, "warm-up" data written to disk).
- Load-balancer/session affinity configs (`sticky`, `ip_hash`) in nginx/ingress/compose.
- Assets compiled at build time vs generated into the runtime filesystem.

**Violation signals**

- Correctness depends on the same instance serving a user's next request.
- Scaling to 2 replicas would break sessions, uploads, or in-memory queues.

**N/A** — single-shot CLI tools (no serving processes) → ➖.

---

## VII. Port binding — [12factor.net/port-binding](https://12factor.net/port-binding)

**Principle.** The app is self-contained: it exports its service by binding to a port via a
webserver library declared as a dependency — not by being injected into an external server
container at runtime. Applies beyond HTTP (any protocol). The port comes from config; a routing
layer maps public hostnames to it.

**What to check**

- The app starts its own server (Express/Fastify listen, uvicorn/gunicorn, embedded
  Jetty/Netty, `http.ListenAndServe`) with the port read from env (`PORT`) or config.
- Deployment artifacts implying container injection: `.war` deployed into an external Tomcat,
  PHP as `mod_php` inside Apache, code mounted into a shared server.
- Hardcoded port numbers scattered through code vs one configurable binding.

**Violation signals**

- App cannot run with just its declared dependencies — it needs a separately administered
  server container to host it.
- Port is a literal constant in several places, unconfigurable per deploy.

**N/A** — CLI tools, batch jobs, libraries that serve nothing → ➖. (A reverse proxy *in front*
of a port-binding app is fine and not a violation.)

---

## VIII. Concurrency — [12factor.net/concurrency](https://12factor.net/concurrency)

**Principle.** Scale out via the process model: work types map to process types (web, worker,
clock), and the process formation (types × counts) scales horizontally because processes share
nothing. Threads/async inside a process are fine. Processes never daemonize or write PID files —
the OS/platform process manager owns lifecycles, streams, and restarts.

**What to check**

- Distinct workloads separated: HTTP serving vs background jobs vs schedulers — separate
  entrypoints/process types (`Procfile`, compose services, k8s Deployments, systemd units) or
  all crammed into the web process (`setInterval` jobs, in-process cron)?
- Self-daemonization: `daemon()` calls, `nohup`-based start scripts, PID-file handling in the
  app.
- Horizontal scalability: anything (locks on local files, in-memory queues — see VI) preventing
  N replicas of a process type.
- A process manager is in charge (container orchestrator, systemd, Foreman-style) rather than
  the app supervising itself.

**Violation signals**

- Background work only happens because the single web instance runs timers — a second replica
  would double the jobs or corrupt state.
- App forks itself into the background and manages its own restart.

**N/A** — single-process CLI tools → ➖.

---

## IX. Disposability — [12factor.net/disposability](https://12factor.net/disposability)

**Principle.** Processes start in seconds and shut down gracefully on SIGTERM: web processes
stop listening, drain in-flight requests, exit; workers return the current job to the queue.
Jobs are reentrant (transactional/idempotent). The app is also robust against sudden,
non-graceful death — a robust queueing backend, crash-only design.

**What to check**

- SIGTERM/SIGINT handlers: `server.close()` + drain in Node, lifespan/shutdown hooks, Go
  signal handling — or nothing (process killed mid-request).
- Worker job handling on shutdown: requeue/NACK vs job lost.
- Idempotency/reentrancy of job handlers (safe to run twice?).
- Startup work: heavy migrations, cache warming, long sync loops before the app is ready;
  readiness signaling in orchestrated environments.
- Long-lived requests without reconnection strategy.

**Violation signals**

- Deploys drop requests or lose jobs because nothing handles termination.
- Startup takes minutes, making scaling and recovery sluggish.

**N/A** — short-lived CLI runs are inherently disposable → often ✅ trivially or ➖.

---

## X. Dev/prod parity — [12factor.net/dev-prod-parity](https://12factor.net/dev-prod-parity)

**Principle.** Keep development, staging, and production as similar as possible across three
gaps: time (deploy hours after writing, not weeks), personnel (authors deploy and watch), and
tools. Backing services should be the same type *and version* everywhere — adapters hide API
differences, but tiny incompatibilities surface only in production.

**What to check**

- Dev backing services vs prod: SQLite locally / Postgres in prod; in-memory cache locally /
  Redis in prod; mock queue locally / SQS in prod. (Check compose files, test configs, docs
  against prod config/IaC.)
- Version drift: dev containers or docs pinning a different major version than prod IaC.
- Containerized dev environment (docker-compose, devcontainer) mirroring prod services — a
  strong positive signal.
- CI pipeline deploying frequently (time gap) vs release branches shipped rarely.

**Violation signals**

- "Works locally, fails in prod" class differences designed into the setup.
- Test suite runs against a different database engine than production.

**N/A** — nothing deployed (pure library) → ➖; personnel gap usually unassessable from code —
say so rather than guessing.

---

## XI. Logs — [12factor.net/logs](https://12factor.net/logs)

**Principle.** Logs are an event stream; the app never concerns itself with routing or storing
it. Each process writes unbuffered to stdout; the execution environment captures, collates, and
routes the streams (to files, terminals, or analysis systems) — invisibly to the app.

**What to check**

- Logger configuration: stdout/stderr transports (good) vs file transports, rotation settings
  (`winston` File transport, `logging.FileHandler`, logrotate configs, `log4j` file appenders)
  inside the app.
- App-managed log directories (`logs/` created at runtime, `LOG_FILE` paths).
- Log shipping embedded in the app (in-process agents pushing to ELK/Splunk) vs
  environment-level routing.
- Buffering that delays or drops events on crash.

**Violation signals**

- The app cannot log without write access to a log directory.
- Rotating/archiving logs is the app's job.

**N/A** — ➖ is rare; even CLIs should write diagnostics to stderr rather than files by default.

---

## XII. Admin processes — [12factor.net/admin-processes](https://12factor.net/admin-processes)

**Principle.** One-off admin tasks (migrations, consoles, one-time fix scripts) run as one-off
processes in an identical environment to the long-running processes: same release, same
codebase, same config, same dependency isolation. Admin code ships with the app code.

**What to check**

- Migrations: run via the app's own tooling and config (`manage.py migrate`,
  `npm run migrate`, `rake db:migrate`) — vs hand-run SQL against prod, or SQL files that
  live outside the repo.
- One-off scripts: in the repo, using the app's config loading — vs pasted into a prod console.
- Console/REPL entrypoint available (`rails console`, a documented shell) using real config.
- Admin tasks' dependencies declared in the same manifest.

**Violation signals**

- Schema changes with no migration history in the repo.
- Fix scripts that construct their own DB connections with separate hardcoded credentials.

**N/A** — apps with no persistent state and no admin tasks → ➖.
