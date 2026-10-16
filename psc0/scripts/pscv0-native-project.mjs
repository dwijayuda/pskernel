// One real cross-file source graph, checked and emitted by the native Lean CLI.
// Validate executable JS/TS, entry-only surface, original-file provenance and
// generate the equivalent Rust consumer against the very same output identities.
import assert from "node:assert/strict";
import {readFile, writeFile} from "node:fs/promises";
import {pathToFileURL} from "node:url";
import path from "node:path";

const stem = path.resolve(process.argv[2]);
const executable = path.resolve(process.argv[3] ?? stem + ".js");
const manifest = JSON.parse(await readFile(stem + ".js.origins.json", "utf8"));
const mapping = JSON.parse(await readFile(stem + ".js.map", "utf8"));
assert.equal(manifest.target, "javascript");
assert.equal(manifest.assurance, "ordinary-checked", "saved project JavaScript artifact assurance");
assert.deepEqual(manifest.exports.map(e => e.semantic), ["App.compute"],
  "only entry-module public declarations are executable exports");
const exported = new Map(manifest.symbols.map(s => [s.semantic, s.output]));
const functionName = exported.get("App.compute");
assert(functionName, "missing App.compute export identity");
const sourceFiles = new Set(mapping.sources.map(s => path.basename(s)));
for (const source of ["App.ps", "Facade.ps", "Vault.ps"])
  assert(sourceFiles.has(source), "project source map lost " + source);
const sourceOrigins = new Set(manifest.origins.map(o => path.basename(o.file)));
for (const source of ["App.ps", "Facade.ps", "Vault.ps"])
  assert(sourceOrigins.has(source), "project declaration provenance lost " + source);

const output = await import(pathToFileURL(executable).href);
assert.equal(typeof output[functionName], "function", "missing linked exported implementation");
assert.equal(output[functionName](7n), 18n, "cross-module private-helper calculation");
if (!process.argv[3]) {
  const rust = JSON.parse(await readFile(stem + ".rs.origins.json", "utf8"));
  assert.equal(rust.assurance, "ordinary-checked", "saved project Rust artifact assurance");
  const rustFn = rust.symbols.find(s => s.semantic === "App.compute")?.output;
  assert(rustFn, "missing Rust entry symbol");
  await writeFile(path.join(path.dirname(stem), "project-checks.rs"),
    '#![forbid(unsafe_code)]\n#[path="app.rs"] mod app;\n' +
    'fn nat(s: &str) -> app::PsNat { s.parse().unwrap() }\n' +
    'fn main() { assert_eq!(app::' + rustFn + '(nat("7")), nat("18"));' +
    ' println!("PSCV0_NATIVE_PROJECT_RUST: PASS linked 3-module application"); }\n');
}
console.log("PSCV0_NATIVE_PROJECT: PASS linked App.compute(7)=18, entry exports and three-file provenance");
