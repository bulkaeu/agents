import { Plugin } from "@opencode/plugin"

// Contributor-tier and free models (e.g. Meta Muse Spark *-contributor, *-free) may use prompts and
// responses for training. Strip common secret formats, and the infrastructure details private
// plans carry (AWS account and instance identifiers, Elastic IPs, SSM parameter paths, where
// production credentials live), from every outgoing request to such models. Persisted history
// is untouched, so other models still see originals.

const RULES: [RegExp, string][] = [
  // Infrastructure — ARNs first: they embed account ids and parameter/secret names.
  [/\barn:aws[\w-]*:[^\s"'`)\]]+/g, "[REDACTED ARN]"],
  [/\b(?:i|eipalloc|eipassoc|eni|vol|snap|ami|sg|vpc|subnet|igw|nat|rtb|acl|lt)-[0-9a-f]{8}(?:[0-9a-f]{9})?\b/g, "[REDACTED AWS ID]"],
  [/(?<![0-9A-Za-z.])\d{4}-?\d{4}-?\d{4}(?![0-9A-Za-z.])/g, "[REDACTED ACCOUNT]"],
  [/(?<![\d.])(?!127\.0\.0\.1\b|0\.0\.0\.0\b)(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?![\d.])/g, "[REDACTED IP]"],
  [/\bec2-\d{1,3}(?:-\d{1,3}){3}\b/gi, "ec2-[REDACTED IP]"],
  // SSM/Secrets Manager names: after an ssm-ish word within the line, or right after "parameter";
  // local filesystem paths are left alone.
  [/((?:ssm|secretsmanager|secret[-_ ]id|get-parameters?|getparameters?|get_parameters?|parametername|parameter store|--name|--path)[^\n/]{0,40}?|\bparam(?:eter)?s?[\s:=`"']+)(?!\/(?:Users|home|tmp|private|var|opt|etc|usr)\/)\/[A-Za-z0-9_.\-]+(?:\/[A-Za-z0-9_.\-]+)+/gi, "$1[REDACTED PATH]"],
  [/(?<![\w/.~-])\/(?:prod|production|staging|stage|dev|test|qa)\/[A-Za-z0-9_.\-\/]+/gi, "[REDACTED PATH]"],
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g, "[REDACTED PRIVATE KEY]"],
  [/\b(?:AKIA|ASIA)[0-9A-Z]{16}\b/g, "[REDACTED]"],
  [/\b(?:sk|pk|rk)-[A-Za-z0-9_-]{16,}/g, "[REDACTED]"],
  [/\b(?:sk|pk|rk)_(?:live|test)_[A-Za-z0-9]{16,}/g, "[REDACTED]"],
  [/\bgh[pousr]_[A-Za-z0-9]{30,}/g, "[REDACTED]"],
  [/\bgithub_pat_[A-Za-z0-9_]{30,}/g, "[REDACTED]"],
  [/\bxox[abprs]-[A-Za-z0-9-]{10,}/g, "[REDACTED]"],
  [/\bAIza[0-9A-Za-z_-]{35}\b/g, "[REDACTED]"],
  [/\beyJ[\w-]{5,}\.[\w-]{5,}\.[\w-]{5,}/g, "[REDACTED JWT]"],
  [/\b([a-z][a-z0-9+.-]*:\/\/)[^\s:@/]+:[^\s@/]+@/gi, "$1[REDACTED]@"],
  [/\bBearer\s+(?!\[REDACTED)(?=[A-Za-z._~+\/=-]*\d)[A-Za-z0-9._~+\/=-]{8,}/gi, "Bearer [REDACTED]"],
  // key: value — the whole value, to the closing quote or the end of the line. Any suffix may follow
  // the keyword (SECRET_KEY_BASE, DB_PASSWORD_PROD) except token_count / tokens / author; `==` is a
  // comparison, not a separator.
  [
    // Bare "pass" is not a key: it matched prose such as "would pass: add a case" and hid the rest.
    /((?:pass(?:word|wd|phrase)|pwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|client[_-]?secret|authorization|auth|credentials?)(?!_?counts?\b|(?<=token)s\b|(?<=auth)ors?\b)\w*["']?\s*(?::|=(?!=))\s*["']?)(?!\[REDACTED)[^\s"'`=][^\n"'`]*/gi,
    "$1[REDACTED]",
  ],
]

export const redact = (text: string) => RULES.reduce((acc, [re, to]) => acc.replace(re, to), text)

function scrub(value: unknown): unknown {
  if (typeof value === "string") return redact(value)
  if (Array.isArray(value)) {
    value.forEach((item, i) => (value[i] = scrub(item)))
  } else if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) (value as Record<string, unknown>)[key] = scrub(item)
  }
  return value
}

// Free tiers may train on or log requests too; big-pickle is free without "free" in its id.
// OpenRouter routers may pick any of the above, and the hook only sees the router's id.
const needsRedaction = (model: { id: string }) =>
  /-contributor|[-:/]free\b|^big-pickle$|^openrouter\/(auto|fusion|pareto-code|bodybuilder)$/.test(model.id)

export default Plugin.define({
  id: "contributor-redact",
  async setup(ctx) {
    for (const kind of ["context", "compaction", "generate", "title"] as const) {
      await ctx.session.hook(kind, (event) => {
        if (!needsRedaction(event.model)) return
        scrub(event.system)
        scrub(event.messages)
      })
    }
  },
})
