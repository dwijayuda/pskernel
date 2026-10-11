// Candidate source selection and IO only. Portable PSCV0 code owns parsing,
// printing and lowering. Native preflight output is never a compiler input.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { verifyPscv0Reference } from './pscv0-reference-identity.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=b=>createHash('sha256').update(b).digest('hex');
const blob=b=>createHash('sha1').update('blob '+b.length+'\0').update(b).digest('hex');
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(k=>o[k]).find(v=>typeof v==='string'):undefined;
const unwrap=(r,label)=>{assert.equal(tag(r),'ok',label+': '+String(r?.error));return r.value;};
const text=bytes=>new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
const builderSha='6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3';
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
  const start=baseline.indexOf('def psTranslateLeanToProofScript\n');
  assert(start>=0,'frozen baseline definition boundary missing');
  let original=baseline.slice(start);
  for(const [name] of APIs){
    assert.equal(original.split(name).length,2,'baseline unexpectedly references '+name);
    original=original.replace('def '+name+'\n','def old_'+name+'\n');
  }
  // Use direct definitional expansion, not `unfold`'s simp/equation rewriting.
  // Case analysis then exposes the success continuation before the printer
  // result is split. The source functions and universal statements stay exact.
  // The separate gate requires no theorem axioms; no audit policy is relaxed.
  const proofs=APIs.map(([name,parse,print])=>
    `theorem migration_${name} (source : String) :\n`+
    `    ${name} source = old_${name} source := by\n`+
    `  delta ${name} old_${name}\n`+
    `  cases ${parse} source with\n`+
    `  | error error => rfl\n`+
    `  | ok sourceModule =>\n`+
    `      change psTranslationMapError PsTranslationError.print (${print} sourceModule) =\n`+
    `        (match ${print} sourceModule with\n`+
    `         | Except.error error => Except.error (PsTranslationError.print error)\n`+
    `         | Except.ok output => Except.ok output)\n`+
    `      cases ${print} sourceModule <;> rfl\n\n#print axioms migration_${name}\n`).join('\n');
  return projected+'\n'+original+'\n'+proofs;
}
export async function readAuthoringInputs(){
  const identity=await verifyPscv0Reference();
  const manifestBytes=await readFile(path.join(root,'pscv0-authoring.json'));
  const manifest=JSON.parse(text(manifestBytes));
  assert.equal(manifest.schema,'psc0-pscv0-authoring-candidate/1');
  assert.equal(manifest.language,'pscv0');
  assert.equal(manifest.referenceSha256,identity.sha256);
  assert.equal(manifest.referenceBytes,identity.bytes);
  assert.equal(manifest.referenceGitBlobSha1,identity.gitBlobSha1);
  assert.equal(manifest.referenceRevision,'v7');
  assert.equal(manifest.referenceDocumentPath,'PSCV0_LANGUAGE_REFERENCE.md');
  assert.equal(manifest.referenceLeanCommit,'c29b6dda4f7c20e3eeaa717c4e565663c5cfa364');
  assert.equal(manifest.sourceSelection,'explicit-module-map-no-fallback');
  assert.equal(manifest.sourcePolicy,'pscv0-v7-only-no-legacy-fallback');
  assert.equal(manifest.backwardCompatibilityRequired,false);
  assert.equal(manifest.supersededLanguageReferenceAllowed,false);
  assert.equal(manifest.publicCompilerSelected,false);
  assert.equal(manifest.surfacePreparation,'current-portable-bootstrap-before-source-selection');
  assert.equal(manifest.modules.length,1,'review scope before extending candidate modules');
  const selected=manifest.modules[0];
  assert.equal(selected.module,'Ps.Syntax.Translate');
  assert.equal(selected.source,'packages/syntax/src-ps/Ps/Syntax/Translate.ps');
  assert.equal(selected.baselineSource,'packages/syntax/src/Ps/Syntax/Translate.lean');
  assert.deepEqual(selected.entryPoints,APIs.map(a=>a[0]));
  const baselineBytes=await readFile(safe(selected.baselineSource));
  assert.equal(blob(baselineBytes),selected.baselineGitBlob,'frozen predecessor changed');
  const sourceBytes=await readFile(safe(selected.source));
  return {manifest,manifestBytes,selected,baselineBytes,sourceBytes,baseline:text(baselineBytes),source:text(sourceBytes)};
}
async function record(inputs,views,outputDirectory,origin){
  const {manifest,manifestBytes,selected,sourceBytes,baselineBytes,baseline,source}=inputs;
  const {readable,lowered,roundtrip}=views;
  assert.equal((readable.match(/:= do\n/g)||[]).length,4,'source intent was not retained');
  const dir=path.join(path.resolve(outputDirectory),'authoring');await mkdir(dir,{recursive:true});
  const products={'Translate.ps':source,'Translate.lean':readable,'Translate.lowered.lean':lowered,
    'Translate.original.lean':baseline,'Translate.roundtrip.ps':roundtrip,
    'ReadableProof.lean':correspondence(readable,baseline),'LoweredProof.lean':correspondence(lowered,baseline)};
  for(const [name,contents] of Object.entries(products))await writeFile(path.join(dir,name),contents);
  const receipt={schema:'psc0-pscv0-authoring-materialization/1',sourceRevision:process.env.GITHUB_SHA,
    manifestSha256:sha(manifestBytes),module:selected.module,sourcePath:selected.source,
    sourceSha256:sha(sourceBytes),baselinePath:selected.baselineSource,baselineGitBlob:blob(baselineBytes),
    baselineSha256:sha(baselineBytes),surfaceSeed:origin,
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
export async function materializeAuthoring(seedDirectory,outputDirectory){
  assert(seedDirectory,'current generated surface bootstrap is required');
  const inputs=await readAuthoringInputs();
  const seed=path.resolve(seedDirectory);
  const report=JSON.parse(await readFile(path.join(seed,'build-report.json'),'utf8'));
  assert.equal(report.stage,'surface-bootstrap');
  assert.equal(report.source,process.env.GITHUB_SHA);
  assert.equal(report.referenceSha256,inputs.manifest.referenceSha256);
  assert.equal(report.builder,'retained self-hosted JavaScript PSC0 compiler');
  assert.equal(report.builderJsSha256,builderSha);
  assert.equal(sha(await readFile(path.join(seed,'index.js'))),report.bridgeJsSha256);
  assert.equal(sha(await readFile(path.join(seed,'index.ts'))),report.bridgeTypeScriptSha256);
  assert.equal(report.closure.length,20);
  for(const input of report.closure){
    assert(input.path.startsWith('packages/syntax/src/')||input.path.startsWith('packages/foundation/src/'));
    assert.equal(sha(await readFile(safe(input.path))),input.rawSha256,'surface bootstrap source changed: '+input.path);
  }
  const B=await import(pathToFileURL(path.join(seed,'index.js')).href);
  const previous=unwrap(B.psPscv0ParseSource(false,inputs.baseline),'predecessor source');
  const surface=unwrap(B.psPscv0ParseSource(true,inputs.source),'authoritative candidate PS source');
  assert.equal(previous.commentTrivia,false);assert.equal(surface.commentTrivia,false);
  assert.equal(B.psPscv0ReplayOriginal(surface),inputs.source,'source capture lost bytes');
  // Imported modules are externally selected by the host-owned closure. The
  // PSCV0 AST input must not silently add or reorder compiler dependencies.
  const sourceImports=text=>text.split(/\r?\n/u).filter(line=>/^import [A-Za-z_][A-Za-z_0-9.]*$/u.test(line));
  assert.deepEqual(sourceImports(inputs.source),sourceImports(inputs.baseline),
    'PSCV0 source import closure drift from the selected predecessor');
  // The generated PSCV0 parser/lowerer owns the authoritative syntax module.
  // This typed syntax value is passed directly to PSC0 elaboration; the Lean
  // text below is a checked readable projection, not a second compiler input.
  assert.equal(typeof B.psPscv0LowerModule,'function','portable PSCV0 AST lowering missing');
  const parsedModule=unwrap(B.psPscv0LowerModule(surface),'generated PSCV0 source AST');
  const readable=unwrap(B.psPscv0PrintSurfaceModule(false,surface),'readable Lean projection');
  const lowered=unwrap(B.psPscv0LowerToLean(true,inputs.source),'compiler input projection');
  const roundtrip=unwrap(B.psPscv0TranslateReadable(false,true,readable),'owned Lean reader round trip');
  assert.equal(unwrap(B.psPscv0LowerToLean(true,roundtrip),'round-trip lowering'),lowered);
  for(const [file,value] of [['readable.lean',readable],['lowered.lean',lowered],['roundtrip.ps',roundtrip]]){
    assert.equal(value,await readFile(path.join(root,'dist/pscv0-native-authoring',file),'utf8'),'native/generated disagreement: '+file);
  }
  const recorded=await record(inputs,{readable,lowered,roundtrip},outputDirectory,
    {stage:'current-generated-surface-bootstrap',source:report.source,jsSha256:report.bridgeJsSha256,
      tsSha256:report.bridgeTypeScriptSha256,builderJsSha256:report.builderJsSha256,nativeFallback:false});
  return {...recorded,parsedModule};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  if(process.argv[2]==='--native-preflight'){
    const directory=path.join(root,'dist/pscv0-native-authoring');
    const views={readable:await readFile(path.join(directory,'readable.lean'),'utf8'),
      lowered:await readFile(path.join(directory,'lowered.lean'),'utf8'),roundtrip:await readFile(path.join(directory,'roundtrip.ps'),'utf8')};
    await record(await readAuthoringInputs(),views,directory,{stage:'native-preflight-not-a-compiler-input'});
  }else await materializeAuthoring(process.env.PSCV0_SURFACE_SEED,process.argv[2]||path.join(root,'dist/pscv0-bridge'));
}
