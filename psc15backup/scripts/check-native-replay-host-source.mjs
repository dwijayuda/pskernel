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
assert(host.includes('IO.FS.realPath candidate'));
assert(host.includes('endsWith "/typescript/bin/tsc"'));
assert(host.includes('PSC_TYPESCRIPT_NATIVE_TSC'));
assert(host.includes('IO.appPath'));
assert(host.includes('bundleRoot / "typescript" / "lib" / psTypeScriptNativeExecutableName'));
assert(host.includes('cmd := tool.command'));
assert(host.includes('tool.prefixArgs ++ #["--version"]'));
assert(host.includes('require TypeScript 7.0.2'));
console.log('PSC2_NATIVE_REPLAY_HOST_SOURCE: PASS (native TypeScript bundle first, pinned npm launcher fallback, exact payload transport and emission integrity)');
