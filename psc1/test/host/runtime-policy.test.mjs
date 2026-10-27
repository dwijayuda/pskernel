// Policy unit boundaries, plus actual runtime syntax consumers. Not runtime qualification by spoofing versions.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {requireSupportedRuntime, runtimeArguments, syntaxArguments} from '../../host-tools/runtime-policy.mjs';
for (const version of ['22.0.0', '22.23.3', '24.0.0', '26.1.2', '30.0.0'])
  assert.equal(requireSupportedRuntime({node: version}).version, version);
for (const version of ['20.19.0', '21.9.0', '22.0.0-rc.1', 'invalid'])
  assert.throws(() => requireSupportedRuntime({node: version}), /PSC1_RUNTIME_VERSION/);
for (const version of ['1.4.0', '1.4.4', '2.0.0'])
  assert.equal(requireSupportedRuntime({node: '0.0.0', bun: version}).name, 'bun');
assert.throws(() => requireSupportedRuntime({node: '22.23.3', bun: '1.3.0'}), /requires bun/);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-syntax-'));
try {
  for (const [text, accepted] of [
    ["export const answer=42;\n", true],
    ["export const answer=;\n", false],
    ["const broken = ( ; export {broken};\n", false],
  ]) {
    const file = path.join(dir, 'target.mjs'); fs.writeFileSync(file, text);
    const r = spawnSync(process.execPath, runtimeArguments(syntaxArguments(file)), {encoding: 'utf8', timeout: 10000});
    assert.equal(r.error, undefined);
    assert.equal(r.status === 0, accepted, r.stdout + r.stderr);
  }
  const sentinel = path.join(dir, 'executed');
  const source = path.join(dir, 'side-effect.mjs');
  fs.writeFileSync(source, "import fs from 'node:fs';fs.writeFileSync(" + JSON.stringify(sentinel) + ",'no');export const answer=42;\n");
  const r = spawnSync(process.execPath, runtimeArguments(syntaxArguments(source)), {encoding: 'utf8', timeout: 10000});
  assert.equal(r.status, 0, r.stderr); assert.equal(fs.existsSync(sentinel), false);
} finally {fs.rmSync(dir, {recursive: true, force: true});}
console.log('PSC1_RUNTIME_POLICY: PASS ' + JSON.stringify(requireSupportedRuntime()));
