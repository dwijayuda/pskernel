import fs from 'node:fs';
import { createHash } from 'node:crypto';
const [input, output, sourceCommit, compilerClosure, kernelSourceManifest] = process.argv.slice(2);
if (!kernelSourceManifest || !/^[a-f0-9]{40}$/u.test(sourceCommit) || !/^[a-f0-9]{64}$/u.test(compilerClosure)) {
  throw Error('usage: summarize-joint-inventory <raw.json> <summary.json> <commit> <compiler-closure-sha256> <kernel-SOURCE.json>');
}
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const raw = fs.readFileSync(input);
const inventory = JSON.parse(raw);
if (inventory.schemaVersion !== 1 || inventory.authoritative !== false) throw Error('INVENTORY_SCHEMA');
const name = n => {
  if (n?.k === 'a') return '';
  if (!['s','n'].includes(n?.k) || typeof n.v !== 'string') throw Error('INVENTORY_NAME');
  return [name(n.p), n.v].filter(Boolean).join('.');
};
const rows = [];
for (const owner of ['prelude', 'compiler', 'kernel']) {
  for (const declaration of inventory[owner]) {
    const dependencies = new Set();
    const expressionKinds = new Set();
    const universeKinds = new Set();
    const universes = levels => {
      const pending = [...levels];
      while (pending.length) {
        const level = pending.pop();
        if (!['z','s','p','max','imax'].includes(level?.k)) throw Error('INVENTORY_LEVEL');
        universeKinds.add(level.k);
        if (level.k === 'p') name(level.n);
        if (level.k === 's') pending.push(level.o);
        if (level.k === 'max' || level.k === 'imax') pending.push(level.l, level.r);
      }
    };
    const pending = [declaration.type, declaration.value].filter(Boolean);
    while (pending.length) {
      const expression = pending.pop();
      if (!['b','sort','const','app','lam','forall','let','nat','str','proj'].includes(expression?.k)) {
        throw Error('INVENTORY_EXPRESSION');
      }
      expressionKinds.add(expression.k);
      if (expression.k === 'const' || expression.k === 'proj') dependencies.add(name(expression.n));
      if (expression.k === 'nat') dependencies.add('Nat');
      if (expression.k === 'str') dependencies.add('String');
      if (expression.k === 'sort') universes([expression.l]);
      if (expression.k === 'const') universes(expression.ls);
      if (expression.k === 'app') pending.push(expression.f, expression.a);
      if (['lam','forall','let'].includes(expression.k)) pending.push(expression.t, expression.b);
      if (expression.k === 'let') pending.push(expression.v);
      if (expression.k === 'proj') pending.push(expression.e);
    }
    for (const related of [...(declaration.metadata?.constructors ?? []), ...(declaration.metadata?.families ?? []),
      ...(declaration.metadata?.family ? [declaration.metadata.family] : [])]) dependencies.add(related);
    rows.push({owner, name:declaration.name, kind:declaration.kind, levelParameters:declaration.levelParameters,
      expressionKinds:[...expressionKinds].sort(), universeKinds:[...universeKinds].sort(),
      dependencies:[...dependencies].sort(), metadata:declaration.metadata,
      declarationSha256:hash(JSON.stringify(declaration))});
  }
}
const byName = new Map();
for (const row of rows) {
  if (byName.has(row.name)) throw Error('DUPLICATE_DECLARATION:'+row.name);
  byName.set(row.name,row);
}
const required = new Set();
const missing = new Set();
const pending = rows.filter(row=>row.owner !== 'prelude').map(row=>row.name);
while (pending.length) {
  const n = pending.pop();
  if (required.has(n)) continue;
  required.add(n);
  const row = byName.get(n);
  if (!row) { missing.add(n); continue; }
  pending.push(...row.dependencies);
}
const report = {schemaVersion:1, authoritative:false, sourceCommit, compilerClosureSha256:compilerClosure,
  kernelSourceManifestSha256:hash(fs.readFileSync(kernelSourceManifest)), rawInventorySha256:hash(raw),
  declarationCount:rows.length, counts:Object.fromEntries(['compiler','kernel','prelude'].map(owner=>
    [owner,rows.filter(row=>row.owner===owner).length])),
  kernelAdmissionBlockers:inventory.kernelAdmissionBlockers, unresolvedDependencies:[...missing].sort(),
  requiredPrelude:rows.filter(row=>row.owner==='prelude' && required.has(row.name)).map(row=>row.name),
  requiredAssumptions:rows.filter(row=>required.has(row.name) && ['axiom','opaque','partial'].includes(row.kind))
    .map(row=>({owner:row.owner,name:row.name,kind:row.kind})), declarations:rows};
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({counts:report.counts,requiredPrelude:report.requiredPrelude.length,
  assumptions:report.requiredAssumptions.length,unresolved:report.unresolvedDependencies,
  blockers:report.kernelAdmissionBlockers},null,2));
