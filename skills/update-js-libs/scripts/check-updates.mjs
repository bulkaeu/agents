#!/usr/bin/env node
/**
 * List npm package updates and classify semver bump type.
 * Usage (from project root):
 *   node .claude/skills/update-js-libs/scripts/check-updates.mjs pkg1 pkg2
 *   node .claude/skills/update-js-libs/scripts/check-updates.mjs --all
 * Or personal install:
 *   node ~/.claude/skills/update-js-libs/scripts/check-updates.mjs --all
 */

import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const cwd = process.cwd();
const pkgJsonPath = join(cwd, "package.json");

function readPackageJson() {
  if (!existsSync(pkgJsonPath)) {
    console.error("package.json not found in", cwd);
    process.exit(1);
  }
  return JSON.parse(readFileSync(pkgJsonPath, "utf8"));
}

function parseVersion(v) {
  const m = String(v)
    .trim()
    .replace(/^v/, "")
    .match(/^(\d+)\.(\d+)\.(\d+)/);
  if (!m) return null;
  return { major: +m[1], minor: +m[2], patch: +m[3], raw: `${m[1]}.${m[2]}.${m[3]}` };
}

function compareVersions(a, b) {
  const va = parseVersion(a);
  const vb = parseVersion(b);
  if (!va || !vb) return 0;
  if (va.major !== vb.major) return va.major < vb.major ? -1 : 1;
  if (va.minor !== vb.minor) return va.minor < vb.minor ? -1 : 1;
  if (va.patch !== vb.patch) return va.patch < vb.patch ? -1 : 1;
  return 0;
}

function bumpType(from, to) {
  const a = parseVersion(from);
  const b = parseVersion(to);
  if (!a || !b) return "unknown";
  if (compareVersions(from, to) >= 0) return "none";
  if (a.major !== b.major) return "major";
  if (a.minor !== b.minor) return "minor";
  return "patch";
}

function npmView(pkg, field) {
  try {
    const out = execSync(`npm view ${JSON.stringify(pkg)} ${field} --json`, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 30000,
    }).trim();
    if (field === "versions") {
      const parsed = JSON.parse(out);
      return Array.isArray(parsed) ? parsed : [parsed];
    }
    try {
      return JSON.parse(out);
    } catch {
      return out.replace(/^"|"$/g, "");
    }
  } catch (e) {
    throw new Error(`npm view ${pkg} ${field}: ${e.stderr?.toString() || e.message}`);
  }
}

function getInstalledVersion(name) {
  const nmPath = join(cwd, "node_modules", name, "package.json");
  if (existsSync(nmPath)) {
    try {
      return JSON.parse(readFileSync(nmPath, "utf8")).version;
    } catch {
      /* fall through */
    }
  }
  try {
    const out = execSync(`npm ls ${JSON.stringify(name)} --depth=0 --json`, {
      encoding: "utf8",
      cwd,
      stdio: ["pipe", "pipe", "pipe"],
      timeout: 15000,
    });
    const tree = JSON.parse(out);
    const dep = tree.dependencies?.[name];
    if (dep?.version) return dep.version;
  } catch {
    /* ignore */
  }
  return null;
}

function highestSameMajor(versions, currentMajor) {
  const same = versions
    .map(parseVersion)
    .filter((v) => v && v.major === currentMajor)
    .sort((x, y) => compareVersions(x.raw, y.raw));
  return same.length ? same[same.length - 1].raw : null;
}

function collectPackageNames(pkgJson, args) {
  if (args.includes("--all")) {
    const deps = { ...pkgJson.dependencies, ...pkgJson.devDependencies };
    return Object.keys(deps).sort();
  }
  return args.filter((a) => a !== "--all" && !a.startsWith("-"));
}

function getSpec(pkgJson, name) {
  return pkgJson.dependencies?.[name] ?? pkgJson.devDependencies?.[name] ?? null;
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("Usage: check-updates.mjs <pkg>... | --all");
  process.exit(1);
}

const pkgJson = readPackageJson();
const names = collectPackageNames(pkgJson, args);

if (names.length === 0) {
  console.error("No package names provided");
  process.exit(1);
}

const results = [];
let hadError = false;

for (const name of names) {
  const currentSpec = getSpec(pkgJson, name);
  if (!currentSpec) {
    results.push({
      name,
      currentSpec: null,
      installed: null,
      latest: null,
      latestMinor: null,
      bumpType: "not-found",
      error: "not in package.json dependencies or devDependencies",
    });
    continue;
  }

  const installed = getInstalledVersion(name);
  const base = installed || currentSpec.replace(/^[\^~>=<]*/, "");

  try {
    const latest = npmView(name, "version");
    const versions = npmView(name, "versions");
    const parsed = parseVersion(base);
    const latestMinor =
      parsed && Array.isArray(versions)
        ? highestSameMajor(versions, parsed.major)
        : null;

    const bump = installed
      ? bumpType(installed, latest)
      : bumpType(base, latest);

    results.push({
      name,
      currentSpec,
      installed,
      latest,
      latestMinor,
      bumpType: bump,
    });
  } catch (err) {
    hadError = true;
    results.push({
      name,
      currentSpec,
      installed,
      latest: null,
      latestMinor: null,
      bumpType: "error",
      error: err.message,
    });
  }
}

console.log(JSON.stringify(results, null, 2));
process.exit(hadError ? 1 : 0);
