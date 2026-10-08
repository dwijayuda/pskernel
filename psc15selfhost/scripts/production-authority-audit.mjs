import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const cli=await readFile(path.join(root,"packages/cli/bin/psc.mjs"),"utf8");
const buildStart=cli.indexOf('} else if (command === "build")');
const uncheckedStart=cli.indexOf('} else if (command === "build-unchecked")');
if(buildStart<0||uncheckedStart<0||uncheckedStart<=buildStart) throw new Error("PSC_PRODUCTION_BUILD_COMMAND_SHAPE");
const checkedBlock=cli.slice(buildStart,uncheckedStart);
if(!checkedBlock.includes("scripts/checked-build.mjs")) throw new Error("PSC_PRODUCTION_BUILD_NOT_CHECKED");
if(checkedBlock.includes("compile-with-generated.mjs")) throw new Error("PSC_PRODUCTION_BUILD_UNCHECKED_BYPASS");
const uncheckedEnd=cli.indexOf('} else if',uncheckedStart+10);
const uncheckedBlock=cli.slice(uncheckedStart,uncheckedEnd<0?cli.length:uncheckedEnd);
if(!uncheckedBlock.includes("compile-with-generated.mjs")) throw new Error("PSC_BOOTSTRAP_UNCHECKED_PATH_MISSING");
const session=await readFile(path.join(root,"scripts/kernel-checked-session.mjs"),"utf8");
if(!session.includes("psc-checked-core-capability/1")||!session.includes("WeakMap")) throw new Error("PSC_CHECKED_CAPABILITY_BOUNDARY");
process.stdout.write("PSCV_PRODUCTION_AUTHORITY: PASS (checked build default; unchecked build explicit)\n");
// Compiler authority topology. These checks enforce repository ownership; they
// do not claim sandbox isolation against malicious code in the trusted host.
const read = file => readFile(path.join(root, file), 'utf8');
const owners = ['Model', 'Frontend', 'Candidate'];
for (const owner of owners) {
  const source = await read('packages/compiler/src/Ps/Compiler/' + owner + '.lean');
  if (/import\s+Ps\.Compiler\.(?:Api|Internal)|import\s+Ps\.Erasure\.Definition|\bpsEraseCoreModule(?:WithRuntimePrelude)?\b/u.test(source)) {
    throw new Error('PSC_CANDIDATE_IMPORTS_TRANSFORMATION: ' + owner);
  }
}
const facade = await read('packages/compiler/src/Ps/Compiler/Api.lean');
if (!/^import Ps\.Compiler\.Internal\s*$/mu.test(facade) || /^(?:def|structure|inductive)\s/mu.test(facade)) {
  throw new Error('PSC_BOOTSTRAP_API_FACADE');
}
for (const [folder, name] of [['driver-ts','DriverTs'],['driver-js','DriverJs'],['driver-wasm','DriverWasm'],['driver-rust','DriverRust']]) {
  const manifest = JSON.parse(await read('packages/' + folder + '/package.json'));
  if (manifest.proofscript.authorityRole !== 'bootstrap-transform') throw new Error('PSC_DRIVER_AUTHORITY_ROLE');
  const source = await read('packages/' + folder + '/src/Ps/' + name + '/Compiler.lean');
  if (!source.includes('import Ps.' + name + '.Bootstrap') || /^(?:def|structure|inductive)\s/mu.test(source)) throw new Error('PSC_DRIVER_BOOTSTRAP_FACADE');
}
const visited = new Set(), pending = ['scripts/checked-build.mjs'];
while (pending.length) {
  const file = pending.pop();
  if (visited.has(file)) continue;
  visited.add(file);
  const source = await read(file);
  if (file === 'scripts/compile-with-generated.mjs') throw new Error('PSC_PRODUCTION_IMPORTS_UNCHECKED_DRIVER');
  if (file === 'scripts/cache-utils.mjs' || file === 'scripts/compile-typescript-cached.mjs') throw new Error('PSC_PRODUCTION_IMPORTS_BOOTSTRAP_LOCAL_CACHE');
  const rawCalls = /\bpsCompiler(?:ErasedIr|VerifiedIr|TypeScript(?:Stages)?|JavaScript(?:Stages)?|Rust|Wasm)FromPrepared\b/u;
  // Additional product APIs also stay at the checked boundary. Literal property
  // accesses distinguish executable authority access from descriptor metadata.
  const productAccess = /(?:\.\s*psCompiler(?:PublicApi|UniformJavaScriptStages|JavaScriptDeclarations|WasmStages)FromPrepared\b|\[\s*['"]psCompiler(?:PublicApi|UniformJavaScriptStages|JavaScriptDeclarations|WasmStages)FromPrepared['"]\s*\])/u;
  if ((rawCalls.test(source) || productAccess.test(source)) && file !== 'scripts/kernel-checked-session.mjs') throw new Error('PSC_RAW_EMITTER_OUTSIDE_AUTHORITY: ' + file);
  for (const match of source.matchAll(/(?:from\s*|import\s*)['"](\.[^'"]+\.mjs)['"]/gu)) {
    const dependency = path.posix.normalize(path.posix.join(path.posix.dirname(file), match[1]));
    if (dependency.startsWith('../')) throw new Error('PSC_AUTHORITY_IMPORT_ESCAPE');
    pending.push(dependency);
  }
}
if (!visited.has('scripts/compiler-checked-service.mjs') || !visited.has('scripts/kernel-checked-session.mjs') ||
    !visited.has('scripts/certified-source.mjs')) throw new Error('PSC_CHECKED_SERVICE_TOPOLOGY');
const certification = await read('scripts/certified-source.mjs');
if (!certification.includes('pscv-cert/1') || !certification.includes('psc-certified-source-capability/1') ||
    !certification.includes('WeakMap')) throw new Error('PSC_CERTIFIED_SOURCE_AUTHORITY_BOUNDARY');
process.stdout.write('PSCV_AUTHORITY_TOPOLOGY: PASS (candidate/internal separation; checked/certified host production imports)\n');
