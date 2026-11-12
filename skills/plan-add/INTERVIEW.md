# The interview — settle the decisions before the rows are written

A step of `plan-add`, kept in its own file. A plan written from a thin request carries its author's
guesses as if they were decisions. A reviewer finds some of them later, at a reviewer's price, and
the build finds the rest. The interview gets them out first, while changing one costs a sentence.

## When it runs

**Only when a decision that changes what gets built is still open.** That is either:

- a new plan from a request with no agreed design; or
- an addition that contradicts what the plan already decided.

An addition whose rows could be written from the request and the repository alone runs no
interview: say in one line that it was skipped, and go on to write the rows. An interview that fires
on every small request is the failure this guard exists to prevent.

## Hard rules

- **Facts are yours to find; decisions are the user's to make.** Never ask what the repository, a
  document or a read-only command can answer. Never settle a decision on the user's behalf —
  recommending is not deciding.
- **Facts stated to the user are read, not recalled.** A fact about the machine or the repository
  that reaches a question, the Summary or a row — free disk, an OS version, whether a tool is
  installed — was read by a command in this session. A remembered fact is a guess with a confident
  voice, and a plan built on it is wrong before its first row runs.
- **Every question carries a recommended answer**, worded so that "yes" accepts it. A question
  without one hands the thinking back to the user.
- **Never ask a question whose answer depends on one still open.** It belongs to a later round.
- **Do not manufacture decisions.** A choice the user would not notice either way is not theirs
  to make: take the project's convention and list it at the close as *author's call*. A one-file
  change has two or three real decisions, and its interview is one round.
- **No plan edit, no code, no ticket during the interview.** The rows are written after it closes.
- **The user can end it at any point.** "Enough" or "just plan it" goes straight to the close,
  with every decision still open listed as *assumed* on its recommended answer.

## 1. Read what exists

The request is the idea. When the work is an addition, read the plan whole: the interview is then
about the addition, and what the plan already decided stays settled unless the addition contradicts
it, which makes that contradiction a round-one question.

Then read enough of the project — its instructions, and the code the idea touches — that round
one asks nothing the repository answers.

## 2. Map the decisions

Privately, list the decisions the work hangs on and which of them wait on which. The ground to
cover is territory, not a script, and never read out as a list:

- what done looks like, and how anyone would observe it — the plan's done-states come from here
  ([CONVENTIONS.md](../plan-shared/CONVENTIONS.md), *Terms*);
- what is out of scope, and what would make the result a failure even if it works;
- the approach, wherever more than one is reasonable, and what each costs;
- anything hard to take back — whatever [the stop-list](../plan-shared/STOPS.md) names. Each
  becomes a gated row, so the user should hear about it now;
- the check that proves it, and can fail;
- order and slicing: what has to land first, and whether each piece can be shown working alone.

## 3. Ask in rounds

The **frontier** is every decision whose prerequisites are settled. Ask the whole frontier in one
message, then wait. Number questions across the interview, never reusing a number:

```text
Settled: D1 <one clause> · D2 <one clause>

Q4 — <title>: <the question; real options only, each with its cost>
→ Recommend: <answer> — <why, in a clause>

Q5 — <title>: …
→ Recommend: …
```

- **The `Settled:` line opens every round after the first**, in full. It is the interview's
  record, and what a context summary leaves you to resume from.
- **Accept short answers**: "yes", "all yes", "yes, except 5: …". An answer that settles a
  question you had not asked yet is taken, not re-asked.
- **A question that needs a fact waits for the fact, not for the user.** Look it up, read-only.
  A sweep too wide to do in-thread goes to one `Explore` helper, with the tier and model of
  `plan-add`'s explorer ([DISPATCH.md](../plan-build/DISPATCH.md) §3); only the questions
  downstream of it wait, and the rest of the frontier is asked now.
- **An answer that contradicts a settled decision** is said out loud and that decision re-asked.
  Never overwrite one silently.
- **"I don't know"** takes the recommendation and is marked *assumed*, unless the answer changes
  what gets built — then name what would settle it, and carry it to the close as open.

After each round, recompute the frontier: settled answers unblock the questions behind them and
sometimes remove a branch altogether.

## 4. Close

The interview is done when the frontier is empty, or the user ended it. Show the list, and ask
once whether it is the shared understanding. Apply corrections to the list. The list is not
printed for a later command to pick up: it is the content of the plan's `## Decisions` section,
written when the rows are.

```text
## Decisions

D1  <the decision, one line> — <user · accepted · author's call · assumed>
D2  …
Out of scope: <what was ruled out, and why>
Gated: <what will need a yes when the plan runs>
Open: <what could not be settled, and what would settle it>
```

- **Each line says whose decision it is.** *User* — their own words; *accepted* — your
  recommendation, which they agreed to; *author's call* — a convention you took without asking;
  *assumed* — never answered. A reader of the plan must be able to tell a decision from a guess.
- **An `Open` line becomes a row of its own** — a spike, a lookup, a question for someone else —
  rather than a guess buried in another step. It is not a failure of the interview.

## Examples

**A new plan from one sentence.** "Add CSV export to the reports page." Reading the code answers
where reports are built and that a streaming helper exists, so neither is asked. Round one asks
which reports, who may export, and whether large exports run in the background, each with a
recommendation. The third answer opens a branch — where the file is kept, and for how long — which
becomes round two. Eight decisions in two rounds become the plan's `## Decisions`.

**An addition that contradicts the plan.** The plan's body already fixed the storage layout, and
the addition needs a second bucket, so the contradiction is Q1. Settling it is what lets the new
rows be written; the plan's earlier decisions stand unless the answer changes them.

**The user stops early.** After round one: "enough, plan it." The four decisions not yet asked
are written as *assumed* on their recommendations, and the rows are written at once.

**A small change.** "Rename the flag to `--dry-run`." If keeping the old name as an alias is the
only real decision, it is one question in one round and three lines in `## Decisions`. If the
plan's convention already answers it, there is nothing open, and no interview runs.
