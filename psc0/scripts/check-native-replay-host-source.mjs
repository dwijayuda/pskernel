import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const seed = await readFile(new URL('./LeanCheckedSeed.lean', import.meta.url), 'utf8');
const session = seed.slice(seed.indexOf('def psCheckedSeedPreparedSession'), seed.indexOf('def psCheckedSeedSession'));
assert(!session.includes('psJsonQuote'), 'transport must not recursively quote the complete admission payload');
for (const marker of ['psCompilerAdmissionsFromPrepared prepared',
  'psCheckedSeedMessage "prepared" "admissions" admissions',
  'if currentAdmissions != admissions then',
  'psCheckedSeedMessage "emitted" "typescript" output']) {
  assert(session.includes(marker), `missing checked transport guard: ${marker}`);
}
const host = await readFile(new URL('../host/src/Ps/Host/TypeScriptCompiler.lean', import.meta.url), 'utf8');
assert(!host.includes('"npx"') && !host.includes('"npx.cmd"'));
for (const marker of ['IO.getEnv "PSC0_TSC"', 'IO.getEnv "PSC0_TYPESCRIPT_VERSION"',
  'psTypeScriptInstalledLauncher (System.FilePath.mk override)',
  'psJsonGetField metadata "name"', 'psJsonGetField metadata "bin"',
  'psJsonGetField bins "tsc"', 'IO.FS.FileType.file',
  'IO.FS.withFile launcher .read', 'PSC0_TYPESCRIPT_CLI_OVERRIDE',
  'if raw != "Version " ++ expected then',
  'if version == "7.0.2" then #["--ignoreConfig"] ++ args else args',
  'cmd := "node"']) {
  assert(host.includes(marker), 'missing installed TypeScript profile guard: ' + marker);
}
assert(!host.includes('endsWith "/typescript/bin/tsc"'), 'installed package metadata must select the launcher');
const compile = host.slice(host.indexOf('def psCompileTypeScriptFile'),
  host.indexOf('def psWriteAndCompileTypeScript'));
const verify = compile.indexOf('let version ← psTypeScriptVerifyVersion cli expected');
assert(verify >= 0 && verify < compile.indexOf('let output ← IO.Process.output'),
  'the selected launcher must report the exact profile version before compilation');
assert(!compile.includes('← psTypeScriptVersion'), 'compilation must retain its already verified launcher and version');
console.log('PSC2_NATIVE_REPLAY_HOST_SOURCE: PASS (installed TypeScript profiles, exact payload transport and emission integrity)');
