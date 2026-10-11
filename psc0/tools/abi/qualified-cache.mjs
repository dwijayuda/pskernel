// Single-source contract for reusing the exact previously qualified generated
// PSCV0 v7 frontend in *compiler-only* development. This never grants kernel
// admission or allows a stale frontend after portable-source changes.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { V7_REFERENCE_SHA } from './transport.mjs';

export const QUALIFIED_FRONTEND_SOURCE='a640a2d22adeabd4ca7919839a8991667bcc3eae';
export const QUALIFIED_FRONTEND_MODULES=20;
export const hash=v=>createHash('sha256').update(v).digest('hex');

export async function loadQualifiedCompilerCache({root,cache,installed}){
  assert(root&&cache&&installed,'root, pinned bootstrap cache and retained compiler directory are required');
  const dir=path.join(cache,'bootstrap');
  const report=JSON.parse(await readFile(path.join(dir,'build-report.json'),'utf8'));
  assert.equal(report.schema,'psc0-pscv0-portable-bridge-build/1');
  assert.equal(report.stage,'surface-bootstrap');
  assert.equal(report.source,QUALIFIED_FRONTEND_SOURCE,
    'unsupported cached source identity: renew the qualification before changing the cached frontend');
  assert.equal(report.referenceSha256,V7_REFERENCE_SHA);
  assert.equal(report.builder,'retained self-hosted JavaScript PSC0 compiler');
  assert(Array.isArray(report.closure)&&report.closure.length===QUALIFIED_FRONTEND_MODULES,
    'frozen v7 generated frontend closure changed');
  const names=new Set();
  const start=performance.now();
  for(const module of report.closure){
    assert.equal(module.sourceKind,'lean','source bootstrap must use the frozen original Lean reader');
    assert(typeof module.path==='string'&&
      /^packages\/(syntax|foundation)\/src\/Ps\/(Syntax|Foundation)\/(?:[A-Za-z_0-9]+\/)*[A-Za-z_0-9]+\.lean$/.test(module.path),
      'unapproved cached frontend path '+String(module.path));
    assert(!names.has(module.path),'duplicate cached frontend input: '+module.path);
    names.add(module.path);
    const original=await readFile(path.join(root,module.path));
    assert.equal(hash(original),module.rawSha256,
      'FAST_CACHE_STALE: '+module.path+
      ' differs from qualified source. Do not reuse an old grammar for a new v7 parser.');
  }
  const js=await readFile(path.join(dir,'index.js'));
  assert.equal(hash(js),report.bridgeJsSha256,'cached frontend JS digest mismatch');
  const retainedJs=path.join(installed,'node_modules/@proofscript/compiler/dist/index.js');
  assert.equal(hash(await readFile(retainedJs)),report.builderJsSha256,
    'wrong retained compiler instance for source cache');
  const [B,C]=await Promise.all([
    import(pathToFileURL(path.join(dir,'index.js')).href),
    import(pathToFileURL(retainedJs).href)
  ]);
  assert.equal(B.psPscv0ReferenceSha256,V7_REFERENCE_SHA);
  assert.equal(B.psPscv0LanguageEdition,'pscv0');
  return {B,C,report,checkedModules:names.size,
    sourceValidationMs:Math.round(performance.now()-start)};
}
