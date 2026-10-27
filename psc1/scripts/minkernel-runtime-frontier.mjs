// Linux Actions diagnostic, never an admission path or a foundation-pruning proof.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';

assert.equal(process.platform, 'linux');
assert.match(process.env.GITHUB_SHA || '', /^[a-f0-9]{40}$/);
const directory = 'dist/pskernel-min';
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const read = file => {
  const bytes = fs.readFileSync(file);
  assert.ok(bytes.length <= 128 * 1024 * 1024);
  return { file, bytes, value: JSON.parse(bytes.toString('utf8')), sha256: sha(bytes) };
};

// These keys preserve component kind and boundaries. Display names are not keys.
function nameParts(name) {
  const parts = [];
  for (let count = 0; ; count++) {
    assert.ok(count < 1024 && name && typeof name === 'object');
    if (name.k === 'a') return parts.reverse();
    assert.ok(name.k === 's' || name.k === 'n');
    assert.equal(typeof name.v, 'string');
    if (name.k === 'n') assert.match(name.v, /^(0|[1-9][0-9]*)$/);
    parts.push([name.k, name.v]); name = name.p;
  }
}
const key = name => JSON.stringify(nameParts(name));
const display = name => nameParts(name).map(p => p[1]).join('.');
const n = value => ({ k: 's', p: { k: 'a' }, v: value });
assert.notEqual(key(n('A.B')), key({ k: 's', p: n('A'), v: 'B' }));
assert.notEqual(key(n('1')), key({ k: 'n', p: { k: 'a' }, v: '1' }));

function children(expression) {
  switch (expression.k) {
    case 'b': case 'nat': case 'str': case 'sort': case 'const': return [];
    case 'app': return [['f', expression.f, 0], ['a', expression.a, 0]];
    case 'lam': case 'forall': return [['t', expression.t, 0], ['b', expression.b, 1]];
    case 'let': return [['t', expression.t, 0], ['v', expression.v, 0], ['b', expression.b, 1]];
    case 'proj': return [['e', expression.e, 0]];
    default: assert.fail('Unsupported canonical expression tag ' + expression.k);
  }
}
function usesBinder(expression, target) {
  const pending = [[expression, target]];
  while (pending.length) {
    const [node, index] = pending.pop();
    if (node.k === 'b' && node.i === index) return true;
    for (const [, child, binders] of children(node)) pending.push([child, index + binders]);
  }
  return false;
}
const b = i => ({ k: 'b', i });
assert.equal(usesBinder({ k: 'lam', t: { k: 'sort', l: { k: 'z' } }, b: b(1) }, 0), true);
assert.equal(usesBinder({ k: 'lam', t: { k: 'sort', l: { k: 'z' } }, b: b(0) }, 0), false);
assert.equal(usesBinder(b(1), 0), false); // Outer variable: independent, but must be lowered.
assert.equal(usesBinder({ k: 'let', t: b(0), v: b(0), b: b(0) }, 0), true);

// Locate actual raw value ranges without re-encoding names, escapes or key order.
function admissionRanges(text) {
  const white = p => { while (/\s/.test(text[p] || '') && p < text.length) p++; return p; };
  function stringEnd(p) {
    assert.equal(text[p], '"'); p++;
    while (p < text.length) {
      if (text[p] === '\\') p += 2;
      else if (text[p++] === '"') return p;
    }
    assert.fail('Unterminated string');
  }
  function valueEnd(p) {
    if (text[p] === '"') return stringEnd(p);
    if (text[p] !== '{' && text[p] !== '[') {
      while (p < text.length && !/[\s,\]}]/.test(text[p])) p++;
      return p;
    }
    const stack = [text[p++]];
    while (stack.length) {
      assert.ok(p < text.length);
      if (text[p] === '"') p = stringEnd(p);
      else if (text[p] === '{' || text[p] === '[') stack.push(text[p++]);
      else if (text[p] === '}' || text[p] === ']') {
        const open = stack.pop(); assert.equal(text[p++], open === '{' ? '}' : ']');
      } else p++;
    }
    return p;
  }
  let p = white(0); assert.equal(text[p++], '{');
  while (true) {
    p = white(p); assert.notEqual(text[p], '}');
    const end = stringEnd(p), field = JSON.parse(text.slice(p, end));
    p = white(end); assert.equal(text[p++], ':'); p = white(p);
    if (field === 'admissions') {
      assert.equal(text[p++], '['); const ranges = [];
      while (true) {
        p = white(p); if (text[p] === ']') return ranges;
        const start = p; p = valueEnd(p);
        ranges.push({ start, end: p }); p = white(p);
        if (text[p] !== ']') assert.equal(text[p++], ',');
      }
    }
    p = white(valueEnd(p)); assert.equal(text[p++], ',');
  }
}

const wire = read(directory + '/portable/vectors.admissions.json');
const source = read(directory + '/portable/vectors.source.json');
const portable = read(directory + '/portable/receipt.json');
const prelude = read(directory + '/closure/prelude.json');
assert.equal(wire.value.format, 'proofscript-checked-admissions');
assert.equal(wire.value.version, 2);
assert.equal(source.value.schema, 'psc1-min-source-compile/2');
assert.equal(source.value.providerChecked, false);
const ranges = admissionRanges(wire.bytes.toString('utf8'));
assert.equal(ranges.length, wire.value.admissions.length);
const owners = new Map(), batches = new Map();
for (const module of source.value.origins) for (const batch of module.batches) {
  const batchKey = JSON.stringify([module.moduleName, batch.sourceIndex]);
  batches.set(batchKey, { module: module.moduleName, ...batch });
  for (const member of batch.members) {
    const identity = key(member.nameWire);
    assert.ok(!owners.has(identity), 'Duplicate exact source-member identity');
    owners.set(identity, { module: module.moduleName, batchKey, role: member.role });
  }
}
const runtimeModule = ['Ps', 'MinKernel', 'Check'];
const sameModule = module => JSON.stringify(module) === JSON.stringify(runtimeModule);
const allRecords = wire.value.admissions.map((admission, index) => {
  const d = admission.declaration;
  const declared = admission.kind === 'constant' ? [d.n] : d.ts.flatMap(t => [t.n, ...t.cs.map(c => c.n)]);
  const ownership = declared.map(name => owners.get(key(name)));
  assert.ok(ownership.every(Boolean), 'Canonical member missing actual source origin');
  assert.ok(ownership.every(o => o.batchKey === ownership[0].batchKey));
  const range = ranges[index], raw = wire.bytes.toString('utf8').slice(range.start, range.end);
  assert.deepEqual(JSON.parse(raw), admission);
  const byteStart = Buffer.byteLength(wire.bytes.toString('utf8').slice(0, range.start));
  return { index, admission, owner: ownership[0], declared,
    raw: { offset: byteStart, bytes: Buffer.byteLength(raw), sha256: sha(raw) } };
});
const runtime = allRecords.filter(record => sameModule(record.owner.module));
assert.ok(runtime.length > 0 && runtime.length < allRecords.length);
assert.ok(runtime.length <= 1024, 'Diagnostic SCC work is bounded to the runtime pilot');
const sourceIdentity = portable.value.sourceIdentities.find(r => r.path ===
  'packages/pskernel-min/src/Ps/MinKernel/Check.lean');
assert.ok(sourceIdentity);
assert.equal(sha(fs.readFileSync(sourceIdentity.path)), sourceIdentity.sha256);
const recordForName = new Map();
for (const record of runtime) for (const name of record.declared) recordForName.set(key(name), record.index);
const recursors = new Map();
const foundation = new Map(prelude.value.map(d => [key(d.nameWire), d]));
for (const d of prelude.value) if (d.kind === 'recursor')
  recursors.set(key(d.nameWire), { name: d.nameWire, provenance: 'exported-prelude-metadata', ...d.metadata });
for (const [identity, owner] of owners) if (sameModule(owner.module) && owner.role === 'recursor') {
  const batch = batches.get(owner.batchKey);
  const members = batch.members.filter(m => m.role === 'inductiveType' || m.role === 'structureType');
  assert.equal(members.length, 1, 'Runtime pilot currently needs one family per source group');
  const family = members[0].nameWire;
  const record = runtime.find(r => r.admission.kind === 'inductive' && r.declared.some(n => key(n) === key(family)));
  assert.ok(record); const d = record.admission.declaration;
  assert.equal(d.ts.length, 1);
  let result = d.ts[0].t, binders = 0;
  while (result.k === 'forall') { binders++; result = result.b; }
  assert.equal(result.k, 'sort'); assert.ok(binders >= d.np);
  recursors.set(identity, { name: batch.members.find(m => key(m.nameWire) === identity).nameWire,
    provenance: 'actual-source-role-plus-canonical-family', parameters: d.np,
    motives: 1, minors: d.ts[0].cs.length, indices: binders - d.np });
  recordForName.set(identity, record.index);
}

const counts = Object.create(null), references = new Map(), spines = [], pis = [], loose = [];
function visit(root, contextDepth, path, record, dependencySet) {
  const pending = [[root, contextDepth, path, false]];
  while (pending.length) {
    const [node, depth, location, functionChild] = pending.pop();
    counts[node.k] = (counts[node.k] || 0) + 1;
    if (node.k === 'b') {
      assert.ok(Number.isSafeInteger(node.i) && node.i >= 0);
      if (node.i >= depth) loose.push({ record: record.index, path: location, index: node.i, depth });
    }
    if (node.k === 'const') { dependencySet.add(key(node.n)); references.set(key(node.n), node.n); }
    if (node.k === 'forall') pis.push({ record: record.index, path: location,
      dependent: usesBinder(node.b, 0), domainTag: node.t.k });
    if (!functionChild && (node.k === 'app' || node.k === 'const')) {
      const args = []; let head = node;
      while (head.k === 'app') { args.push(head.a); head = head.f; } args.reverse();
      const descriptor = head.k === 'const' ? recursors.get(key(head.n)) : null;
      if (descriptor) {
        const major = descriptor.parameters + descriptor.motives + descriptor.minors + descriptor.indices;
        const motive = descriptor.motives === 1 ? args[descriptor.parameters] : null;
        spines.push({ record: record.index, path: location, recursor: descriptor.name,
          provenance: descriptor.provenance, universeArguments: head.ls,
          parameters: descriptor.parameters, motives: descriptor.motives,
          minors: descriptor.minors, indices: descriptor.indices,
          argumentCount: args.length, majorPosition: major, hasMajor: args.length > major,
          postMajorArguments: Math.max(0, args.length - major - 1), argumentTags: args.map(a => a.k),
          motive: !motive ? { classification: 'missing' } : motive.k !== 'lam'
            ? { classification: 'not-a-lambda', tag: motive.k }
            : { classification: usesBinder(motive.b, 0) ? 'syntactically-dependent' : 'no-major-reference',
                bodyTag: motive.b.k, bodySha256: sha(JSON.stringify(motive.b)),
                note: 'No-major-reference is a diagnostic, not a proved translation or type/model check.' } });
      }
    }
    for (const [field, child, binders] of children(node))
      pending.push([child, depth + binders, location + '.' + field, node.k === 'app' && field === 'f']);
  }
}
const rows = runtime.map(record => {
  const d = record.admission.declaration, deps = new Set();
  if (record.admission.kind === 'constant') {
    visit(d.t, 0, 't', record, deps); visit(d.v, 0, 'v', record, deps);
  } else for (let i = 0; i < d.ts.length; i++) {
    visit(d.ts[i].t, 0, 'ts.' + i + '.t', record, deps);
    for (let j = 0; j < d.ts[i].cs.length; j++) visit(d.ts[i].cs[j].t, 0, 'ts.' + i + '.cs.' + j + '.t', record, deps);
  }
  return { record: record.index, kind: record.admission.kind === 'constant' ? d.k : 'inductive',
    names: record.declared, displays: record.declared.map(display), source: batches.get(record.owner.batchKey),
    rawAdmission: record.raw, levelParameters: d.lp, parameterCount: d.np ?? null,
    inductiveShapes: record.admission.kind === 'constant' ? [] : d.ts.map(t => ({
      name: t.n, constructors: t.cs.map(c => {
        const fields = []; let result = c.t;
        while (result.k === 'forall') { fields.push({ type: result.t,
          classification: result.t.k === 'const' && key(result.t.n) === key(t.n)
            ? 'direct-recursion' : result.t.k === 'const' ? 'constant-field'
            : result.t.k === 'forall' ? 'function-field-needs-positivity-analysis' : 'other-field' }); result = result.b; }
        return { name: c.n, telescope: fields, result };
      }) })),
    dependencies: [...deps].sort().map(identity => ({ key: identity,
      name: references.get(identity), runtimeRecord: recordForName.get(identity) ?? null,
      preludeKind: foundation.get(identity)?.kind ?? null })) };
});
assert.deepEqual(loose, [], 'The exact source graph must not contain loose bound variables');
const graph = new Map(rows.map(r => [r.record, [...new Set(r.dependencies
  .map(d => d.runtimeRecord).filter(i => i !== null))]]));
let nextIndex = 0;
const indices = new Map(), low = new Map(), active = new Set(), stack = [], components = [];
function connect(id) {
  indices.set(id, nextIndex); low.set(id, nextIndex++); stack.push(id); active.add(id);
  for (const other of graph.get(id)) {
    if (!indices.has(other)) { connect(other); low.set(id, Math.min(low.get(id), low.get(other))); }
    else if (active.has(other)) low.set(id, Math.min(low.get(id), indices.get(other)));
  }
  if (low.get(id) === indices.get(id)) {
    const component = []; let member;
    do { member = stack.pop(); active.delete(member); component.push(member); } while (member !== id);
    component.sort((a, b) => a - b); components.push(component);
  }
}
for (const id of graph.keys()) if (!indices.has(id)) connect(id);
const foundationEdges = new Map();
for (const [identity, d] of foundation) {
  const deps = new Set(), pending = [d.type, d.value];
  while (pending.length) {
    const expr = pending.pop(); if (!expr) continue;
    if (expr.k === 'const') deps.add(key(expr.n));
    for (const [, child] of children(expr)) pending.push(child);
  }
  if (d.kind === 'inductive') for (const c of d.metadata.constructorWires) deps.add(key(c));
  if (d.kind === 'constructor') deps.add(key(d.metadata.familyWire));
  if (d.kind === 'recursor') for (const family of d.metadata.familyWires) deps.add(key(family));
  foundationEdges.set(identity, deps);
}
const reached = new Set(rows.flatMap(r => r.dependencies.map(d => d.key)).filter(k => foundation.has(k)));
const pending = [...reached];
while (pending.length) for (const dep of foundationEdges.get(pending.pop()) || [])
  if (foundation.has(dep) && !reached.has(dep)) { reached.add(dep); pending.push(dep); }
const unresolved = [...new Set(rows.flatMap(r => r.dependencies.filter(d =>
  d.runtimeRecord === null && d.preludeKind === null).map(d => d.key)))];
assert.deepEqual(unresolved, [], 'Every runtime constant reference needs a measured provider');
const summary = { canonicalRecords: runtime.length,
  inductiveGroups: rows.filter(r => r.kind === 'inductive').length,
  definitions: rows.filter(r => r.kind === 'definition').length,
  expressions: counts, piNodes: pis.length, dependentPiNodes: pis.filter(p => p.dependent).length,
  maximalRecursorSpines: spines.length, recursorsWithMajor: spines.filter(s => s.hasMajor).length,
  noMajorReferenceMotives: spines.filter(s => s.motive.classification === 'no-major-reference').length,
  dependentMotives: spines.filter(s => s.motive.classification === 'syntactically-dependent').length,
  otherMotives: spines.filter(s => !['no-major-reference', 'syntactically-dependent'].includes(s.motive.classification)).length,
  reachedPreludeEntries: reached.size,
  reachedAxioms: [...reached].filter(k => foundation.get(k).kind === 'axiom').length };
const report = { schema: 'psc1-min-runtime-frontier/1', commit: process.env.GITHUB_SHA,
  authoritative: false, admissionAuthority: 'none', runtimeSourceModule: runtimeModule,
  runtimeSourceIdentity: sourceIdentity,
  inputs: [wire, source, portable, prelude].map(({ file, bytes, sha256 }) => ({ file, bytes: bytes.length, sha256 })),
  identityKey: 'JSON array of exact tagged name components; display strings never identify declarations',
  completeInputRecords: allRecords.length, summary, records: rows,
  runtimeDependencyComponents: components, pis, recursorSpines: spines,
  sourceDescriptors: [...recursors.values()].filter(d => d.provenance !== 'exported-prelude-metadata'),
  preludeFrontier: [...reached].sort().map(k => ({ name: foundation.get(k).nameWire, kind: foundation.get(k).kind })),
  caveats: ['This selected view is not independently admitted as a closed environment.',
    'The frontier follows serialized signatures/values and explicit constructor/family metadata; it is not a foundation-pruning theorem.',
    'Motive syntax does not establish well-typed specialization, reduction semantics, a universe model or a proof of all recursor rules.',
    'Current min/dual canonical admission remains unsupported; this diagnostic grants no checking authority.'] };
for (const input of report.inputs) assert.equal(sha(fs.readFileSync(input.file)), input.sha256);
fs.writeFileSync(directory + '/runtime-frontier.json', JSON.stringify(report, null, 2) + '\n');
console.log('PSC1_MIN_RUNTIME_FRONTIER ' + JSON.stringify({ commit: report.commit, ...summary,
  reportSha256: sha(fs.readFileSync(directory + '/runtime-frontier.json')) }));
