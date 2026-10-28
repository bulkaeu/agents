import { Plugin } from "@opencode/plugin"
import { execFileSync } from "node:child_process"
import { existsSync, realpathSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

// A plan run's subagents must run on the tiers CONVENTIONS.md names, and a controller cannot be
// trusted to pass `model` or to report which model ran: one run dispatched every implementer and
// reviewer on its own model while its Run log named the tiers. Once a session has loaded a
// dispatching plan skill, every `subagent` call in it must name one of the models
// `tiers.sh opencode` prints; anything else is refused before the subagent starts.

const PLAN_SKILL = /skill_content name=\\*"(plan-(?:add|build|continue|review|finish))\\*"/

function tiersScript(): string | undefined {
  const candidates: string[] = []
  try {
    // This file is linked from the agents repo: <repo>/opencode/plugins/<name>/index.ts.
    const repo = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "..", "..")
    candidates.push(join(repo, "skills", "plan-shared", "scripts", "tiers.sh"))
  } catch {}
  candidates.push(join(homedir(), ".agents", "skills", "plan-shared", "scripts", "tiers.sh"))
  return candidates.find((path) => existsSync(path))
}

// Every pinned id on the opencode tiers line: each tier's model and its fallback.
function allowedModels(): { line: string; ids: string[] } {
  const script = tiersScript()
  if (!script) throw new Error("plan-dispatch-guard: tiers.sh not found; is the agents repo installed?")
  const line = execFileSync("bash", [script, "opencode"], { encoding: "utf8" }).trim()
  const ids = [...line.matchAll(/`([^`]+)`/g)].map((m) => m[1])
  if (ids.length === 0) throw new Error(`plan-dispatch-guard: no model ids in: ${line}`)
  return { line, ids }
}

const base = (id: string) => id.split("#")[0]

export default Plugin.define({
  id: "plan-dispatch-guard",
  async setup(ctx) {
    const planSessions = new Set<string>()
    const isPlanSession = async (sessionID: string) =>
      planSessions.has(sessionID) || (await ctx.storage.get(`plan-session/${sessionID}`)) === true

    // Sticky: a context summary can drop the skill text later, so the mark is stored once seen.
    const mark = async (sessionID: string) => {
      if (planSessions.has(sessionID)) return
      planSessions.add(sessionID)
      await ctx.storage.set(`plan-session/${sessionID}`, true)
    }

    // An @-mention selects the skill at admission, before its text is resolved: match the id.
    await ctx.session.hook("prompt", async (event) => {
      const skills = (event.prompt.skills ?? []) as Array<string | { id?: string; name?: string }>
      const ids = skills.map((skill) => (typeof skill === "string" ? skill : (skill.id ?? skill.name ?? "")))
      if (ids.some((id) => /^plan-(?:add|build|continue|review|finish)$/.test(id))) await mark(event.sessionID)
    })
    // A skill whose admission predates this plugin shows only as its text in the transcript.
    // In a plan session the subagent schema the model sees is rewritten: the host's own wording says
    // "NEVER set this unless the user explicitly asks", and a controller obeys it over the skill.
    await ctx.session.hook("context", async (event) => {
      if (!planSessions.has(event.sessionID) && PLAN_SKILL.test(JSON.stringify(event.messages))) {
        await mark(event.sessionID)
      }
      if (!(await isPlanSession(event.sessionID))) return
      const input = event.tools.subagent?.input as
        | { properties?: Record<string, { description?: string }>; required?: string[] }
        | undefined
      if (!input?.properties?.model) return
      const { line } = allowedModels()
      input.properties.model.description =
        "REQUIRED in this plan run: the tier model for this dispatch, exactly as written on the tiers " +
        `line (implementer: standard; reviewer: strong, unless DISPATCH.md §3 steps it up):\n${line}`
      input.required = [...new Set([...(input.required ?? []), "model"])]
    })

    await ctx.tool.transform((editor) => {
      // A plan skill loaded by the skill tool marks the session at once, before a subagent call in the
      // same step can run.
      editor.update("skill", (tool) => {
        const execute = tool.execute
        tool.execute = async (input: any, context: any) => {
          if (/^plan-(?:add|build|continue|review|finish)$/.test(String(input?.id ?? ""))) {
            await mark(context.sessionID)
          }
          return execute(input, context)
        }
      })
      editor.update("subagent", (tool) => {
        const execute = tool.execute
        tool.execute = async (input: any, context: any) => {
          if (await isPlanSession(context.sessionID)) {
            const { line, ids } = allowedModels()
            const model = typeof input?.model === "string" ? input.model.trim() : ""
            if (!model) {
              throw new Error(
                `plan run: this subagent call has no \`model\`, so it would run on the controller's model. ` +
                  `Pass the tier's id from this run's tiers line and call again:\n${line}`,
              )
            }
            if (!ids.some((id) => id === model || base(id) === base(model))) {
              throw new Error(
                `plan run: \`${model}\` is not a tier model. Use one of: ${ids.join(", ")} ` +
                  `(from: ${line})`,
              )
            }
          }
          return execute(input, context)
        }
      })
    })
  },
})
