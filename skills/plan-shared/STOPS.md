# The stop-list

The one list of things a plan skill must not do without an explicit yes. `plan-build`,
`plan-continue` and `plan-finish` all cite this file; none of them keeps its own copy, because two
copies of a safety list drift and the drift is silent.

**Exhaustive.** Everything not listed here is work, not a question. Inventing a reason to ask costs
the user the time these skills exist to save.

## The list

| Stop | Why |
| --- | --- |
| `git push --force`, deleting a remote branch, `git reset --hard`, amending a pushed commit | Destroys work or published history |
| Deleting a branch, worktree, or file that **neither this run nor the plan it serves** created | Not its to delete. A resumed run may delete what an earlier session of the same plan made |
| **Deleting data** — rows in a database, objects in a bucket, records in any live system | Not reversible from a working tree |
| Database migration apply or rollback | `migration-apply-confirmation.md` owns this; needs an explicit yes |
| Closing, reassigning, or deleting a tracker issue | `plan-ticket-tracking.md` owns this — creating is authorised, destructive edits are not |
| A step the plan itself marks `BLOCKED` or waiting on the user | The plan already said to stop |
| A red check whose fix is not obvious, or a doc change needing a judgment call on wording or scope | Guessing produces work the user has to undo |
| Anything outward-facing to a *new* destination — first push of a new repo, a branch with no upstream, filing into a tracker not yet agreed | Approval for one destination is not approval for another |
| **Deploying** — shipping to any running environment | Not ordinary work, whatever the plan says |
| **Publishing to a live surface** — a package registry, a public site, a shared channel | The audience cannot be un-notified |
| **Sending** — an email, a chat message, a notification, a webhook to someone else's system | Same; a sent message cannot be recalled |
| **A push whose row is parked** — the plan's push row is `⛔`, or depends on a `⛔` row | The plan held that push back on purpose. This stop binds the close-out too: "push to the existing upstream" does not override it |
| **A foreign path** in a dispatched row's diff — in its `paths-<n>.txt`, in no report's **Changed** (`plan-build/EXECUTION.md`) | Likely a peer's work: never restored, removed or committed. **Halts the run** |
| **No usable report** from a dispatched row — a crash, or no **Changed** | Its own paths are unknown, so nothing in the tree is safe to restore. **Halts the run** |
| A row's `diff` exits 3 because its base is **not an ancestor** of `HEAD` | History moved under the run and no paths file exists. **Halts the run** |
| **A commit in `@{u}..HEAD`** that the Run log does not record and the user did not name | Pushing would publish someone else's commit. Stops the push |

**What stays ordinary:** `git add` and `git commit` of work in scope, by explicit path; pushing to a
branch's **existing upstream** when no push row is parked and
the upstream branch's name equals the local branch's — compare `git rev-parse --abbrev-ref @{u}`,
minus its remote, with `git branch --show-current`. A mismatch, usually a worktree branch still
tracking `main`, is a stop: offer `git push -u origin HEAD:<branch>`. Writing under `~/` — scratch
files, fixtures, caches — is ordinary too, being reversible and local. "Touches anything outside
this checkout" is deliberately *not* a stop: it would park every step that writes a temp file.

**"Reversible and local" is the test, never "the plan said so".** A step that deploys, migrates,
publishes, sends or deletes data stops whether or not its author marked it `BLOCKED`. An author who
forgot to flag a deploy must not thereby authorise it.

## Asked alone

Four stops are never folded into a batch question: **migration, deploy, publish, send.** Each is
listed separately with its exact command, because a yes to "these six things" is exactly the
blanket approval `migration-apply-confirmation.md` refuses — and a deploy, a publish or a sent
message is no more recoverable than a migration.

The three marked **Halts the run** are not batched or deferred either: the run stops at once and
waits for the user (`plan-build/RULES.md` §1–2), because continuing could commit or erase a peer's
work. Everything else that stopped goes into **one** batch question. A run with four stopped items, one of
them a deploy, asks two questions: the batch of three, and the deploy on its own. Not four, and not
one.

## Evidenced action

A `BLOCKED — wait for user` step whose awaited action is **already evidenced** — in this session's
context, or on disk — is verified and recorded, not stopped. Evidence is the action's output, or
the user saying it ran — never the command text printed for them. The marker gates the action, not
the bookkeeping after it. A migration someone already applied still may not be re-run; recording that
it happened is not running it.

## A harness prompt is not a stop-list item

The harness may prompt before a command this list calls ordinary. That prompt is the
environment's gate, and it is legitimate: answer it and continue.
**Never** rephrase a command, chain it, or wrap it to slip past a matcher. "Uninterrupted" and "fix
by default" govern what you decide to do, never how a command gets past a hook.

## When you stop

Say what you were about to do and give the exact command, so a yes is one word. Finish everything
else first: a stopped item never justifies leaving the fixable ones undone.
