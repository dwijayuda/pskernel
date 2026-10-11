// Candidate source selection and IO only. All parsing, source printing and
// semantic lowering are performed by the hash-pinned portable PSCV0 bridge.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=b=>createHash('sha256').update(b).digest('hex');
const blob=b=>createHash('sha1').update('blob '+b.length+'\0').update(b).digest('hex');
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(k=>o[k]).find(v=>typeof v==='string'):undefined;
const unwrap=(r,label)=>{assert.equal(tag(r),'ok',label+': '+String(r?.error));return r.value;};
const text=bytes=>new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
function safe(relative){
  assert(typeof relative==='string'&&!path.isAbsolute(relative)&&!relative.includes('\\'));
  assert(!relative.split('/').some(s=>s==='..'||s===''||s==='.'));
  return path.join(root,relative);
}
const APIs=[
  ['psTranslateLeanToProofScript','psParseLeanSource','psPrintProofScriptModule'],
  ['psTranslateProofScriptToLean','psParseProofScriptSource','psPrintLeanModule'],
  ['psCanonicalizeLeanSource','psParseLeanSource','psPrintLeanModule'],
  ['psCanonicalizeProofScriptSource','psParseProofScriptSource','psPrintProofScriptModule'],
];
function correspondence(projected,baseline){
  // The immutable baseline has exactly these four nonrecursive definitions.
  // Rename only their heads; do not manufacture alternative implementations.
  const start=baseline.indexOf('def psTranslateLeanToProofScript\n');
  assert(start>=0,'frozen baseline definition boundary missing');
  let original=baseline.slice(start);
  for(const [name] of APIs){
    assert.equal(original.split(name).length,2,'baseline unexpectedly references '+name);
    original=original.replace('def '+name+'\n','def old_'+name+'\n');
  }
  const proofs=APIs.map(([name,parse,print])=>
    `theorem migration_${name} (source : String) :\n`+
    `    ${name} source = old_${name} source := by\n`+
    `  unfold ${name} old_${name}\n`+
    `  cases parsed : ${parse} source with\n`+
    `  | error error => rfl\n`+
    `  | ok sourceModule =>\n`+
    `      cases printed : ${print} sourceModule <;> rfl\n\n`+
    `#print axioms migration_${name}\n`).join('\n');
  return projected+'\n'+original+'\n'+proofs;
}
export async function materializeAuthoring(seedDirectory,outputDirectory){
  assert(seedDirectory,'PSCV0_SURFACE_SEED must identify the retained generated bridge');
  const manifestBytes=await readFile(path.join(root,'pscv0-authoring.json'));
  const manifest=JSON.parse(text(manifestBytes));
  assert.equal(manifest.schema,'psc0-pscv0-authoring-candidate/1');
  assert.equal(manifest.language,'pscv0');
  assert.equal(manifest.sourceSelection,'explicit-module-map-no-fallback');
  assert.equal(manifest.publicCompilerSelected,false);
  assert.equal(manifest.modules.length,1,'review scope before extending candidate modules');
  const selected=manifest.modules[0];
  assert.equal(selected.module,'Ps.Syntax.Translate');
  assert.equal(selected.source,'packages/syntax/src-ps/Ps/Syntax/Translate.ps');
  assert.equal(selected.baselineSource,'packages/syntax/src/Ps/Syntax/Translate.lean');
  assert.deepEqual(selected.entryPoints,APIs.map(a=>a[0]));
  const seed=path.resolve(seedDirectory);
  const report=JSON.parse(await readFile(path.join(seed,'build-report.json'),'utf8'));
  assert.equal(report.source,manifest.surfaceSeed.source);
  assert.equal(report.referenceSha256,manifest.referenceSha256);
  assert.equal(report.builder,'retained self-hosted JavaScript PSC0 compiler');
  assert.equal(sha(await readFile(path.join(seed,'index.js'))),manifest.surfaceSeed.jsSha256);
  assert.equal(report.bridgeJsSha256,manifest.surfaceSeed.jsSha256);
  assert.equal(sha(await readFile(path.join(seed,'index.ts'))),manifest.surfaceSeed.tsSha256);
  assert.equal(report.closure.length,19);
  for(const input of report.closure){
    assert(input.path.startsWith('packages/syntax/src/')||input.path.startsWith('packages/foundation/src/'));
    assert.equal(sha(await readFile(safe(input.path))),input.rawSha256,'surface seed source changed: '+input.path);
  }
  const B=await import(pathToFileURL(path.join(seed,'index.js')).href);
  const baselineBytes=await readFile(safe(selected.baselineSource));
  assert.equal(blob(baselineBytes),selected.baselineGitBlob,'frozen predecessor changed');
  const sourceBytes=await readFile(safe(selected.source));
  const baseline=text(baselineBytes),source=text(sourceBytes);
  const oldSurface=unwrap(B.psPscv0ParseSource(false,baseline),'predecessor source');
  const surface=unwrap(B.psPscv0ParseSource(true,source),'authoritative candidate PS source');
  assert.equal(oldSurface.commentTrivia,false,'first migration requires lossless comment handling before adding trivia');
  assert.equal(surface.commentTrivia,false,'canonical comment placement is not yet supported');
  assert.equal(B.psPscv0ReplayOriginal(surface),source,'source capture lost bytes');
  const readable=unwrap(B.psPscv0PrintSurfaceModule(false,surface),'readable Lean projection');
  const lowered=unwrap(B.psPscv0LowerToLean(true,source),'compiler input projection');
  const roundtrip=unwrap(B.psPscv0TranslateReadable(false,true,readable),'owned Lean reader round trip');
  assert.equal(unwrap(B.psPscv0LowerToLean(true,roundtrip),'round-trip lowering'),lowered);
  assert.equal((readable.match(/:= do\n/g)||[]).length,4,'source intent was not retained');
  const dir=path.join(path.resolve(outputDirectory),'authoring');await mkdir(dir,{recursive:true});
  const products={'Translate.ps':source,'Translate.lean':readable,'Translate.lowered.lean':lowered,
    'Translate.original.lean':baseline,'Translate.roundtrip.ps':roundtrip,
    'ReadableProof.lean':correspondence(readable,baseline),'LoweredProof.lean':correspondence(lowered,baseline)};
  for(const [name,contents] of Object.entries(products))await writeFile(path.join(dir,name),contents);
  const receipt={schema:'psc0-pscv0-authoring-materialization/1',sourceRevision:process.env.GITHUB_SHA,
    manifestSha256:sha(manifestBytes),module:selected.module,sourcePath:selected.source,
    sourceSha256:sha(sourceBytes),baselinePath:selected.baselineSource,baselineGitBlob:blob(baselineBytes),
    baselineSha256:sha(baselineBytes),surfaceSeed:manifest.surfaceSeed,
    readableLeanSha256:sha(readable),loweredLeanSha256:sha(lowered),
    products:Object.fromEntries(Object.entries(products).map(([name,contents])=>[name,sha(contents)])),
    candidateSourceAuthority:'ps',noFallback:true,originalCommentTrivia:false,candidateCommentTrivia:false,
    lostComments:0,highLevelDoBodies:4,ownedLeanReaderRoundTrip:true,
    sourceLines:source.split('\n').length-1,baselineLines:baseline.split('\n').length-1,
    compilerDiagnosticCoordinates:'generated lowered Lean; full PS diagnostic remapping pending',
    publicCompilerChanged:false,newFullSelfhostFixedPoint:false};
  await writeFile(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
  console.log('PSCV0_AUTHORING_MATERIALIZED: '+JSON.stringify(receipt));
  return {manifest,receipt,selected,source,readable,lowered};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  await materializeAuthoring(process.env.PSCV0_SURFACE_SEED,process.argv[2]||path.join(root,'dist/pscv0-bridge'));
}
