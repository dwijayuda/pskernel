import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { execFileSync } from "node:child_process";

const expectedPin = "65e74db49e89ad2bbd1e90aa4f784954db41fa3a";
const dependencyRoot = ".lake/packages/con-leche";
const pin = execFileSync("git", ["-C", dependencyRoot, "rev-parse", "HEAD"],
  { encoding: "utf8" }).trim();
if (pin !== expectedPin) throw Error("Unexpected set-model dependency revision: " + pin);

function imports(text) {
  // Strip nested Lean block comments before reading one-line import commands.
  let depth = 0, code = "";
  for (let i = 0; i < text.length; i++) {
    const pair = text.slice(i, i + 2);
    if (pair === "/-") { depth++; i++; continue; }
    if (depth && pair === "-/") { depth--; i++; continue; }
    if (depth) { if (text[i] === "\n") code += "\n"; continue; }
    if (pair === "--") {
      while (i < text.length && text[i] !== "\n") i++;
      code += "\n";
      continue;
    }
    code += text[i];
  }
  if (depth) throw Error("Unterminated Lean comment in dependency source");
  return [...code.matchAll(/^\s*(?:public\s+)?import\s+([^\n]+)/gm)]
    .flatMap(m => m[1].replace(/--.*$/, "").trim().split(/\s+/));
}
function collect(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(entry =>
    entry.isDirectory() ? collect(join(dir, entry.name)) :
    entry.name.endsWith(".lean") ? [join(dir, entry.name)] : []);
}
for (const file of collect("src")) {
  for (const name of imports(readFileSync(file, "utf8"))) {
    if (name.startsWith("ConLeche.") || name === "ConLeche" ||
        name.startsWith("Ps.KernelCore.Metatheory."))
      throw Error("Assurance dependency reached production: " + file + " -> " + name);
  }
}

const visited = new Set();
const external = new Set();
function visit(name) {
  if (visited.has(name)) return;
  visited.add(name);
  let file;
  if (name.startsWith("ConLeche.")) {
    if (!(name.startsWith("ConLeche.SetTheory.") || name === "ConLeche.SetModel.Ops"))
      throw Error("Non-mathematical Con Leche import in semantic proof closure: " + name);
    external.add(name);
    file = join(dependencyRoot, name.replaceAll(".", "/") + ".lean");
  } else if (name.startsWith("Ps.KernelCore.")) {
    if (name === "Ps.KernelCore.Metatheory.Judgments" ||
        name === "Ps.KernelCore.Metatheory.JudgmentAdequacy")
      throw Error("Legacy collapsed judgment imported into new model: " + name);
    const relative = name.replaceAll(".", "/") + ".lean";
    file = ["src", "metatheory"].map(root => join(root, relative)).find(existsSync);
    if (!file) throw Error("Missing local semantic dependency: " + name);
  } else {
    // Lean/Init/Std are the pinned host foundation, audited separately for axioms.
    if (!/^(Lean|Init|Std)(\.|$)/.test(name))
      throw Error("Unexpected semantic dependency: " + name);
    return;
  }
  for (const imported of imports(readFileSync(file, "utf8"))) visit(imported);
}
visit("Ps.KernelCore.Metatheory.SemanticAudit");
console.log("PSKERNEL_MODEL_DEPENDENCIES: PASS pin=" + pin +
  " pureMathModules=" + external.size + " closureModules=" + visited.size +
  " productionAssuranceImports=0 legacyJudgmentImports=0");
