import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { packageBySection, parseImports } from "./workspace-layout.mjs";

// Diagnostic host tooling: never substitute this audit for the real fixed point.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root, encoding: "utf8", stdio: "inherit", timeout: 300000,
  });
  if (result.error) {
    throw new Error(`PSC2_FIXED_POINT_AUDIT_COMMAND_FAILED: ${result.error.message}`, { cause: result.error });
  }
  return result.status ?? 1;
}
export async function auditSelfhostReplay() {
  if (run("lake", ["build", "Ps.Erasure.Expr", "Ps.Host.ProjectCompiler", "psc2_selfhost_replay_audit"]) !== 0) {
    throw new Error("PSC2_FIXED_POINT_AUDIT_LEAN_BUILD_FAILED");
  }
  const executable = path.join(root, ".lake", "build", "bin",
    process.platform === "win32" ? "psc2_selfhost_replay_audit.exe" : "psc2_selfhost_replay_audit");
  if (run(executable, ["--behavior"]) !== 0) {
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
  const status = run(executable, [...visited].sort());
  // A known parse failure is diagnostic. The unchanged real bootstrap check
  // still gates success and reports its first exact replay failure afterward.
  console.log(`PSC2_FIXED_POINT_PARSE_AUDIT_EXIT: ${status}`);
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await auditSelfhostReplay();
}
