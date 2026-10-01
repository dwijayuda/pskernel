import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { packageBySection, parseImports } from "./workspace-layout.mjs";

// Diagnostic host tooling: never substitute this audit for the real fixed point.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
function lake(args) {
  const result = spawnSync("lake", args, { cwd: root, encoding: "utf8", stdio: "inherit" });
  if (result.error) throw result.error;
  return result.status ?? 1;
}
export async function auditSelfhostReplay() {
  if (lake(["build", "Ps.Erasure.Expr", "Ps.Host.ProjectCompiler"]) !== 0) {
    throw new Error("PSC2_FIXED_POINT_AUDIT_LEAN_BUILD_FAILED");
  }
  const script = "scripts/SelfhostReplayAudit.lean";
  if (lake(["env", "lean", "--run", script, "--behavior"]) !== 0) {
    throw new Error("PSC2_FIXED_POINT_ERASURE_BEHAVIOR_FAILED");
  }
  const config = JSON.parse(await readFile(path.join(root, "psconfig.json"), "utf8"));
  const visited = new Set();
  async function visit(relative) {
    if (visited.has(relative)) return;
    visited.add(relative);
    const source = await readFile(path.join(root, relative), "utf8");
    for (const name of parseImports(source)) {
      const parts = name.split(".");
      const folder = parts[0] === "Ps" ? packageBySection.get(parts[1]) : undefined;
      if (!folder) throw new Error(`PSC2_FIXED_POINT_PARSE_IMPORT_UNMAPPED: ${name}`);
      await visit(path.posix.join("packages", folder, "src", ...parts) + ".lean");
    }
  }
  await visit(config.entry);
  const status = lake(["env", "lean", "--run", script, ...[...visited].sort()]);
  // A known parse failure is diagnostic. The unchanged real bootstrap check
  // still gates success and reports its first exact replay failure afterward.
  console.log(`PSC2_FIXED_POINT_PARSE_AUDIT_EXIT: ${status}`);
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await auditSelfhostReplay();
}
