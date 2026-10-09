import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildChecked } from './checked-build.mjs';

// Development/self-host adapter. The public npm launcher supplies release pins.
// All emitted outputs still pass the same kernel, IR, target and publication gate.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [compiler, entry, output, ...extra] = process.argv.slice(2);
if (!compiler || !entry || !output || extra.length) {
  throw new Error('usage: compile-with-generated.mjs <compiler.js> <entry.lean|entry.ps> <output.ts|output.js>');
}
process.stdout.write('PSC0_EXTENSIONS: []\n');
const receipt = await buildChecked({
  compilerPath: path.resolve(root, compiler),
  entryPath: path.resolve(root, entry),
  outputPath: path.resolve(root, output),
});
process.stdout.write('PSC0_CHECKED_BUILD: PASS ' + JSON.stringify(receipt) + '\n');
