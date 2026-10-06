import assert from "node:assert/strict";
import { test } from "node:test";
import { spawnSync } from "node:child_process";

for (const script of ["architecture-registry.mjs","trust-manifest.mjs"]) {
  test(script + " audit passes", () => {
    const run = spawnSync(process.execPath, [new URL(script, import.meta.url)], { encoding: "utf8" });
    assert.equal(run.status, 0, run.stderr || run.stdout);
    assert.match(run.stdout, /PASS/u);
  });
}
