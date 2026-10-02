import assert from 'node:assert/strict';
import { test } from 'node:test';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const script = fileURLToPath(new URL('./summarize-joint-inventory.mjs', import.meta.url));
const n = value => ({ k:'s', p:{k:'a'}, v:value });
const c = value => ({ k:'const', n:n(value), ls:[] });
const sort = { k:'sort', l:{k:'imax',l:{k:'p',n:n('u')},r:{k:'s',o:{k:'z'}}} };
const decl = (name, value = null, kind = 'definition', type = sort) =>
  ({ name, kind, levelParameters:[], type, value, metadata:null });
const fixture = () => ({schemaVersion:1,authoritative:false,kernelAdmissionBlockers:[],
  prelude:[decl('Nat',null,'inductive'),decl('String',null,'axiom'),decl('Pair',null,'inductive'),
    decl('hidden',c('String'),'opaque'),decl('unused',null,'axiom')],
  compiler:[decl('entry',{k:'let',n:n('x'),t:c('Nat'),v:{k:'nat',v:'2'},
    b:{k:'app',f:c('hidden'),a:{k:'proj',n:n('Pair'),i:0,e:{k:'b',i:0}}}})],
  kernel:[decl('kernel',{k:'str',v:'hello'})]});

function summarize(input) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(),'psc2-inventory-'));
  try {
    fs.writeFileSync(path.join(temp,'input.json'),JSON.stringify(input));
    fs.writeFileSync(path.join(temp,'SOURCE.json'),'{}\n');
    const result = spawnSync(process.execPath,[script,path.join(temp,'input.json'),path.join(temp,'output.json'),
      'a'.repeat(40),'b'.repeat(64),path.join(temp,'SOURCE.json')],{encoding:'utf8'});
    return { ...result, report:result.status===0 ? JSON.parse(fs.readFileSync(path.join(temp,'output.json'))) : null };
  } finally { fs.rmSync(temp,{recursive:true,force:true}); }
}

test('joint inventory includes transitive, literal, projection, universe and opaque dependencies',()=>{
  const {status,stderr,report}=summarize(fixture());
  assert.equal(status,0,stderr);
  assert.deepEqual(report.unresolvedDependencies,[]);
  assert.deepEqual(report.requiredPrelude,['Nat','String','Pair','hidden']);
  assert.deepEqual(report.requiredAssumptions.map(x=>x.name),['String','hidden']);
  const entry=report.declarations.find(x=>x.name==='entry');
  assert.deepEqual(entry.expressionKinds,['app','b','const','let','nat','proj','sort']);
  assert.deepEqual(entry.universeKinds,['imax','p','s','z']);
  assert.equal(report.authoritative,false);
});

test('joint inventory reports missing declarations without certifying a closure',()=>{
  const data=fixture(); data.kernel[0].value=c('missing');
  const {status,report}=summarize(data);
  assert.equal(status,0); assert.deepEqual(report.unresolvedDependencies,['missing']);
  assert.equal(report.authoritative,false);
});

test('joint inventory rejects unknown expression, universe and duplicate declaration forms',()=>{
  for (const mutate of [data=>{data.kernel[0].value={k:'unknown'};},
    data=>{data.kernel[0].type={k:'sort',l:{k:'unknown'}};},
    data=>{data.kernel[0].name='entry';}]) {
    const data=fixture(); mutate(data); const result=summarize(data);
    assert.notEqual(result.status,0); assert.match(result.stderr,/INVENTORY_|DUPLICATE_DECLARATION/u);
  }
});
