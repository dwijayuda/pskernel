import fs from 'node:fs';
import { resolve } from 'node:path';
import { Lean4ExportReplay } from '../dist/src/integration/lean4export.js';
import { nameFromDotted } from '../dist/src/core/name.js';

const file = resolve(process.argv[2] ?? 'oracle/fixtures/lean434-init-prelude.ndjson');
if (!fs.existsSync(file)) throw new Error(`missing Init.Prelude fixture: ${file}`);
const text = fs.readFileSync(file, 'utf8');
const replay = new Lean4ExportReplay();
const stats = replay.replay(text);
const expected = { lines: 70484, names: 8295, levels: 115, expressions: 60035, declarations: 2038 };
for (const [k, v] of Object.entries(expected)) {
  if (stats[k] !== v) throw new Error(`Init.Prelude fixture drift: ${k}=${stats[k]} expected ${v}`);
}
const constants = replay.env.entries().length;
if (constants !== 2324) throw new Error(`Init.Prelude environment drift: constants=${constants} expected 2324`);
for (const n of ['Nat', 'Eq', 'Quot.lift', 'Lean.Syntax.rec_1', 'Lean.Syntax.rec_2']) {
  if (!replay.env.find(nameFromDotted(n))) throw new Error(`Init.Prelude replay missing ${n}`);
}
console.log(JSON.stringify({ ok: true, file, stats, constants }, null, 2));
