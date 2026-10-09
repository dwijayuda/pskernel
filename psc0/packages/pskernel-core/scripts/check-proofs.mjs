import { readdirSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
function collect(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(e =>
    e.isDirectory() ? collect(join(dir, e.name)) :
    e.name.endsWith(".proof.lean") ? [join(dir, e.name)] : []);
}
const files = collect("proof").sort();
if (files.length !== 84) throw Error("Unexpected proof inventory: " + files.length);
for (const file of files) {
  console.log("CHECK " + file);
  const r = spawnSync("lake", ["env", "lean", file], { stdio: "inherit" });
  if (r.error) throw r.error;
  if (r.status !== 0) process.exit(r.status ?? 1);
}
console.log("PSKERNEL_CORE_PROOFS: PASS files=" + files.length);
