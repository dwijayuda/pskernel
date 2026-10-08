import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const npm = process.platform === "win32" ? "npm.cmd" : "npm";

function run(args) {
  const result = spawnSync(npm, args, {
    cwd: root,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

const bootstrapCompiler = path.join(
  root,
  "dist",
  "bootstrap",
  "packages",
  "compiler",
  "index.js",
);

if (!existsSync(bootstrapCompiler)) {
  process.stdout.write("PSC1_BUILD_AUTO: bootstrap compiler missing; running one-time Lean bootstrap\n");
  run(["run", "bootstrap"]);
} else {
  process.stdout.write("PSC1_BUILD_AUTO: using existing generated JavaScript compiler\n");
}

run(["run", "build:psc"]);
