import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist/pskernel-one');
const source = fs.readFileSync(path.join(out, 'KernelOne.lean'), 'utf8');
const declarations = [...source.matchAll(/^(def|inductive) ([^\s(]+)/gm)];
const compiler = process.env.PSC1 ?? path.join(root, '.lake/build/bin/psc1');
const results = [];
for (let i = 0; i < declarations.length; i++) {
  const input = source.slice(0, declarations[i + 1]?.index ?? source.length);
  const file = path.join(out, 'emit-prefix.lean'); fs.writeFileSync(file, input);
  const r = spawnSync(compiler, ['typescript', file], {cwd: root, encoding: 'utf8', timeout: 30000});
  const result = {declaration: declarations[i][2], inputSha256: createHash('sha256').update(input).digest('hex'),
    status: r.status, signal: r.signal, stderr: r.stderr};
  results.push(result);
  if (r.status !== 0) {
    console.log(`PSKERNEL_ONE_FIRST_EMIT_BLOCKER: ${JSON.stringify(result)}`); break;
  }
}
fs.writeFileSync(path.join(out, 'emit-prefix-results.json'), JSON.stringify(results, null, 2) + '\n');
