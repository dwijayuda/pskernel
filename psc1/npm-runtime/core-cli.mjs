// Isolated generated-JS PSKernel Core admission process.
// No native/Lean-WASM fallback; a rejection never produces an executable.
import { readFile } from 'node:fs/promises';
import { checkGeneratedAdmissionsWithPrelude } from './generated-core-provider.mjs';
import * as kernel from './index.js';

let data = '';
let bytes = 0;
for await (const chunk of process.stdin) {
  bytes += Buffer.byteLength(chunk);
  if (bytes > 16 * 1024 * 1024) throw new Error('PSC_JS_CORE_INPUT_BUDGET');
  data += chunk.toString();
}
const prelude = JSON.parse(await readFile(new URL('./prelude.json', import.meta.url), 'utf8'));
let result;
try {
  result = checkGeneratedAdmissionsWithPrelude(kernel, data, prelude, {maxDeclarations: 20000});
  if (typeof result?.accepted !== 'boolean') throw Error('invalid decision');
} catch (error) {
  result = {accepted:false, errorKind:'provider-internal-error',
    message:String(error?.message||error).slice(0,1024)};
}
process.stdout.write(JSON.stringify({
  protocol:'pskernel-core-js/1', provider:'psc0-generated-js-core',
  leanVersion:'4.34.0', profile:'lean4.34-core',
  ...result,
})+'\n');
