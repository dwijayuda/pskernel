// CI candidate preparation: authored PS -> checked reference, never the reverse.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {readCanonicalEditCandidate} from '../host-tools/canonical-sources.mjs';
import {createLosslessSourceTool, createSourceOwnershipTool, createCheckedSourceConverter} from '../host-tools/source-refactoring.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {uploadPreparedSourceTree} from './prepare-source-git-tree.mjs';
import {projectNativeReferences} from './native-reference-projection.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(root);
const args = process.argv.slice(2);
assert.equal(args.length, 2, 'usage: refresh-canonical-sources.mjs --baseline <qualified-commit>');
assert.equal(args[0], '--baseline');
const baseline = args[1]; assert.match(baseline, /^[0-9a-f]{40}$/);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const decode = value => new TextDecoder('utf-8', {fatal:true, ignoreBOM:true}).decode(value);
const put = (file, value) => {fs.mkdirSync(path.dirname(file), {recursive:true}); fs.writeFileSync(file, value);};
function run(exe, argv, options = {}) {
 const result = spawnSync(exe, argv, {cwd:root, encoding:'utf8', timeout:240000, maxBuffer:64*1024*1024, ...options});
 assert.equal(result.error, undefined, String(result.error));
 assert.equal(result.status, 0, String(result.stdout) + String(result.stderr));
 return result.stdout;
}
const out = path.resolve('dist/canonical-source-refresh');
assert.ok(!fs.existsSync(out), 'Fresh refresh output required'); fs.mkdirSync(out, {recursive:true});
process.on('uncaughtExceptionMonitor', error => {
 put(path.join(out,'failure.json'),json({schema:'psc1-canonical-reference-refresh/1',status:'refused',
  message:String(error.message),cause:error.cause??null,baseline,testedCommit:process.env.GITHUB_SHA??null,
  workingReferencesChanged:false,refsChanged:false}));
});
const preparedCommit = run('git', ['rev-parse', 'HEAD']).trim();
const baseTree = run('git', ['rev-parse', 'HEAD^{tree}']).trim();
run('git', ['merge-base', '--is-ancestor', baseline, preparedCommit]);
const baselineBytes = Buffer.from(run('git', ['show', baseline + ':psc1/CANONICAL_SOURCES.json']));
const currentManifestBytes = fs.readFileSync('CANONICAL_SOURCES.json');
assert.ok(currentManifestBytes.equals(baselineBytes), 'Edit canonical PS only; manifest/reference refresh starts from the exact qualified baseline manifest.');
const candidate = readCanonicalEditCandidate(root), prior = candidate.manifest;
const changed = [...candidate.modules.values()].filter(row => row.changed);
assert.ok(changed.length > 0, 'No authored ProofScript change requires a reference refresh.');
function helpers(base) {
 const executable = name => path.join(base, '.lake/build/bin', name);
 const lexical = createLosslessSourceTool({executable:executable('psc1_lossless_source'), sha256:hash(fs.readFileSync(executable('psc1_lossless_source')))});
 const config = {lexicalTool:lexical, executable:executable('psc1_source_ownership'),
  sha256:hash(fs.readFileSync(executable('psc1_source_ownership'))),
  checkerExecutable:executable('psc1_independent_checker'), checkerSha256:hash(fs.readFileSync(executable('psc1_independent_checker')))};
 const ownership = createSourceOwnershipTool({...config,qualificationGraphProfile:'canonical-repository-40m'});
 return {lexical, ownership, converter:createCheckedSourceConverter({ownershipTool:ownership}),
  hashes:{lexical:hash(fs.readFileSync(executable('psc1_lossless_source'))), ownership:config.sha256, checker:config.checkerSha256}};
}
const tools = helpers(root), started = Date.now();
const shape = index => index.modules.map(module => ({module:module.module, imports:module.imports,
 origins:module.origins.map(origin => ({sourceIndex:origin.sourceIndex, sourceName:origin.sourceName,
  members:origin.members.map(member => ({index:member.index, name:member.name, role:member.role})),
  normalization:origin.normalization?.workerName ?? null}))}));
function sameGraphs(left, right, label) {
 assert.equal(left.admissionsSha256, right.admissionsSha256, label + ' admissions');
 assert.equal(left.originalIrSha256, right.originalIrSha256, label + ' original strict IR');
 assert.deepEqual(left.partialNames, right.partialNames, label + ' partial names');
 assert.deepEqual(shape(left), shape(right), label + ' imports/member ownership');
}
function refreshGroup(rows, audit, label) {
 console.log('PSC1_CANONICAL_REFRESH_STAGE: ' + label + '-fresh-canonical-admission');
 const text = audit.imports.map(module => 'import ' + module).join('\n') + '\n';
 const auditRow = {module:audit.module, ps:Buffer.from(text), lean:Buffer.from(text), changed:false};
 const all = [...rows, auditRow];
 const psSnapshots = all.map(row => tools.lexical.capture({module:row.module, grammar:'ps', bytes:row.ps}));
 const canonical = tools.ownership.analyze({snapshots:psSnapshots, entry:audit.module, assurance:'ordinary-checked'});
 const converted = tools.converter.convert({index:canonical, snapshots:psSnapshots, targetGrammar:'lean', commentPolicy:'owner-notes'});
 const projections = new Map(all.map(row => [row.module, Buffer.from(tools.converter.readCandidate(converted, row.module))]));
 const changedRows=rows.filter(row=>row.changed);
 const nativePatternProjection=changedRows.length?projectNativeReferences({root,out,label:label+'-refresh',
  sources:changedRows.map(row=>({module:row.module,bytes:projections.get(row.module)}))}):null;
 if(nativePatternProjection)for(const [module,bytes]of nativePatternProjection.modules)projections.set(module,bytes);
 // Keep all untouched Lean bytes, even when the pretty-printer would render them differently.
 const referenceBytes = new Map(all.map(row => [row.module, row.changed ? projections.get(row.module) : row.lean]));
 const leanSnapshots = all.map(row => tools.lexical.capture({module:row.module, grammar:'lean', bytes:referenceBytes.get(row.module)}));
 const bootstrap = tools.ownership.analyze({snapshots:leanSnapshots, entry:audit.module, assurance:'ordinary-checked'});
 sameGraphs(canonical, bootstrap, label + ' canonical/hybrid reference');
 sameGraphs(canonical, tools.converter.candidateIndex(converted), label + ' checked projection');
 const allowed = new Set(rows.map(row => row.module));
 for (const module of canonical.modules) if (module.module !== audit.module)
  for (const imported of module.imports) assert.ok(allowed.has(imported), label + ' imports must stay in their declared ownership graph: ' + imported);
 return {rows, audit, all, canonical, bootstrap, converted, projections, referenceBytes, psSnapshots,
  nativePatternProjection:nativePatternProjection?.evidence??null};
}
const importProbePath = path.join(out, 'canonical-imports.json');
run('lake', ['env', 'lean', '--run', 'scripts/CanonicalSourceProbe.lean', importProbePath,
 ...prior.owners.map(row => row.path)], {timeout:900000});
const importProbe = JSON.parse(fs.readFileSync(importProbePath, 'utf8'));
assert.equal(importProbe.files.length, prior.owners.length);
const parsedByPath = new Map(importProbe.files.map(row => [row.path, row]));
assert.equal(parsedByPath.size, prior.owners.length);
for (const owner of prior.owners) {
 const parsed = parsedByPath.get(owner.path);
 assert.equal(parsed?.status, 'accepted-parse-only', 'Canonical PS parse refused: ' + owner.path);
 assert.ok(Array.isArray(parsed.imports) && parsed.imports.every(name => typeof name === 'string'));
}
function orderedGroup(rows) {
 const byName = new Map(rows.map(row => [row.module, row])), result = [], seen = new Set(), active = new Set();
 function visit(name) {
  if (seen.has(name)) return;
  assert.ok(!active.has(name), 'Canonical import cycle: ' + name);
  const row = byName.get(name); assert.ok(row, 'Import crosses declared ownership graph: ' + name);
  active.add(name);
  for (const dependency of parsedByPath.get(row.path).imports) visit(dependency);
  active.delete(name); seen.add(name); result.push(row);
 }
 rows.forEach(row => visit(row.module)); return result;
}
function auditFor(priorAudit, rows) {
 const imports = rows.map(row => row.module), text = imports.map(name => 'import ' + name).join('\n') + '\n';
 return {...priorAudit, imports, sha256:hash(Buffer.from(text)), authored:false};
}
const compilerRows = orderedGroup(prior.owners.filter(row => row.path.startsWith('packages/')).map(row => candidate.modules.get(row.module)));
const libraryRows = orderedGroup(prior.owners.filter(row => row.path.startsWith('stdlib/ProofScript/')).map(row => candidate.modules.get(row.module)));
const compiler = refreshGroup(compilerRows, auditFor(prior.auditRoot, compilerRows), 'compiler');
const library = refreshGroup(libraryRows, auditFor(prior.libraryCorrespondence.auditRoot, libraryRows), 'library');
const changedCompilerReferences = compiler.rows.filter(row => !compiler.referenceBytes.get(row.module).equals(row.lean));
const changedLibraryReferences = library.rows.filter(row => !library.referenceBytes.get(row.module).equals(row.lean));
let nativeProjectionProbe;
if (changedCompilerReferences.length > 0) {
 try {
  console.log('PSC1_CANONICAL_REFRESH_STAGE: changed-reference-native-build');
  const shadow = path.join(out, 'native-projection'); fs.mkdirSync(shadow);
  const archive = path.join(out, 'native-input.tar');
  run('git', ['-C', path.dirname(root), 'archive', '--format=tar', '--output=' + archive, preparedCommit, 'psc1']);
  run('tar', ['xf', archive, '-C', shadow]);
  const nativeRoot = path.join(shadow, 'psc1');
  // Overlay captured bytes so the probe also covers allowed uncommitted PS edits.
  for (const group of [compiler, library]) for (const row of group.rows) {
   put(path.join(nativeRoot, row.path), row.ps);
   put(path.join(nativeRoot, row.bootstrap.path), group.referenceBytes.get(row.module));
  }
  const built = spawnSync('lake', ['build', 'psc1', 'psc1_unified_service_seed', 'psc1_lossless_source',
   'psc1_source_ownership', 'psc1_independent_checker', 'psc1_modular_pilot', 'psc1_backend_python', 'psc1_backend_php'],
   {cwd:nativeRoot, encoding:'utf8', timeout:3600000, maxBuffer:64*1024*1024});
  put(path.join(out, 'native-projection-build.log'), String(built.stdout || '') + String(built.stderr || ''));
  assert.equal(built.error, undefined, String(built.error));
  assert.equal(built.status, 0, 'Changed native reference projection failed; no reference tree will be prepared.');
  const rebuilt = helpers(nativeRoot);
  const checkedGraphs = [];
  for (const [label, group] of [['compiler',compiler], ['library',library]]) {
   console.log('PSC1_CANONICAL_REFRESH_STAGE: projected-helper-' + label + '-correspondence');
   const freshPs = group.all.map(row => rebuilt.lexical.capture({module:row.module, grammar:'ps', bytes:row.ps}));
   const freshLean = group.all.map(row => rebuilt.lexical.capture({module:row.module, grammar:'lean', bytes:group.referenceBytes.get(row.module)}));
   const ps = rebuilt.ownership.analyze({snapshots:freshPs, entry:group.audit.module, assurance:'ordinary-checked'});
   const lean = rebuilt.ownership.analyze({snapshots:freshLean, entry:group.audit.module, assurance:'ordinary-checked'});
   sameGraphs(ps, lean, 'rebuilt ' + label + ' correspondence');
   sameGraphs(ps, group.canonical, 'rebuilt ' + label + ' compiler consistency');
   checkedGraphs.push({group:label, admissionsSha256:ps.admissionsSha256, originalIrSha256:ps.originalIrSha256,
    canonicalChecker:ps.checker, bootstrapChecker:lean.checker, canonicalMetrics:ps.metrics, bootstrapMetrics:lean.metrics});
  }
  nativeProjectionProbe = {status:'passed', scope:'hybrid native compiler with only changed authored modules projected',
   nativeBuild:true, independentlyCheckedAfterNativeRebuild:true, helperHashes:rebuilt.hashes, checkedGraphs,
   changedReferences:changedCompilerReferences.map(row => ({module:row.module, path:row.bootstrap.path,
    beforeSha256:row.bootstrap.sha256, afterSha256:hash(compiler.referenceBytes.get(row.module))})),
   untouchedCompilerReferences:compilerRows.length - changedCompilerReferences.length,
   referenceFilesPromoted:false};
 } catch (error) {
  put(path.join(out, 'native-projection-failure.json'), json({schema:'psc1-canonical-reference-refresh/1', status:'refused',
   stage:'native-projection', message:String(error.message), baseline, preparedCommit,
   workingReferencesChanged:false, gitObjectsCreated:false, refsChanged:false}));
  throw error;
 }
} else {
 nativeProjectionProbe = {status:'not-required-unchanged-native-reference-bytes',
  scope:'all compiler reference bytes match qualified baseline pins', nativeBuild:false,
  changedReferences:[], untouchedCompilerReferences:compilerRows.length, referenceFilesPromoted:false};
}
function correspondence(group) {
 return {status:'passed', assurance:'ordinary-checked', modules:group.rows.length,
  bootstrapSourceClosureDigest:group.bootstrap.sourceClosureDigest,
  canonicalSourceClosureDigest:group.canonical.sourceClosureDigest,
  admissionsSha256:group.canonical.admissionsSha256, originalIrSha256:group.canonical.originalIrSha256,
  sourceCoreDeclarations:group.canonical.sourceCoreDeclarations,
  partialNamesPreserved:true, importsAndMemberOwnershipPreserved:true,
  bootstrapChecker:group.bootstrap.checker, canonicalChecker:group.canonical.checker, helperHashes:tools.hashes,
  reverseProjection:{admissionsSha256:group.converted.admissionsSha256, originalIrSha256:group.converted.originalIrSha256,
   nativePatternProjection:group.nativePatternProjection},
  commentPolicy:'changed references derive from canonical PS with raw comments retained; untouched reference bytes are preserved',
  formalSourcePreservationProof:false, receiptGrantsAdmissionAuthority:false};
}
const byModule = new Map([...compiler.rows.map(row => [row.module,compiler]), ...library.rows.map(row => [row.module,library])]);
const owners = [...compiler.rows, ...library.rows].map(row => {
 const previous = prior.owners.find(owner => owner.module === row.module);
 assert.ok(previous, 'Existing canonical owner required');
 const group = byModule.get(row.module);
 const reference = group.referenceBytes.get(row.module), observed = group.canonical.modules.find(item => item.module === row.module);
 assert.ok(observed);
 if (!row.changed) assert.ok(reference.equals(row.lean), 'Untouched reference bytes must remain unchanged.');
 return {...previous, bytes:row.ps.length, sha256:hash(row.ps), imports:observed.imports,
  bootstrap:{...previous.bootstrap, bytes:reference.length, sha256:hash(reference),
   generatedProjectionSha256:hash(group.projections.get(row.module))}};
});
const ownerMap = new Map(owners.map(row => [row.module,row]));
const oldProject = JSON.parse(fs.readFileSync(prior.primaryProject, 'utf8'));
assert.equal(oldProject.schemaVersion, 1);
const active = new Set(), seen = new Set(), projectRows = [];
function visit(module) {
 if (seen.has(module)) return;
 assert.ok(!active.has(module), 'Canonical project import cycle: ' + module);
 const row = ownerMap.get(module); assert.ok(row, 'Canonical project owner missing: ' + module);
 active.add(module); row.imports.forEach(visit); active.delete(module); seen.add(module); projectRows.push(row);
}
visit(oldProject.entryModule);
const project = {schemaVersion:1, entryModule:oldProject.entryModule, sources:projectRows.map(row => ({module:row.module,path:row.path}))};
const currentUnifiedDigest = compilerSourceClosureDigest(projectRows.map(row => ({module:row.module, kind:'ps', text:decode(candidate.modules.get(row.module).ps)})));
const refresh = {baseline, baselineManifestSha256:hash(baselineBytes), preparedCommit,
 runId:process.env.GITHUB_RUN_ID ?? null,
 changedCanonicalModules:changed.map(row => row.module),
 changedCompilerReferences:changedCompilerReferences.map(row => row.bootstrap.path),
 changedLibraryReferences:changedLibraryReferences.map(row => row.bootstrap.path),
 untouchedReferenceBytesPreserved:true, nativeProjectionProbe, elapsedMs:Date.now() - started};
const manifest = {...prior, preparedCommit, preparedRunId:process.env.GITHUB_RUN_ID ?? null, owners,
 auditRoot:compiler.audit,
 sourceOrdering:'real parser dependency order; compiler and standard library are separately checked graphs',
 correspondence:{...correspondence(compiler), nativeProjectionProbe, elapsedMs:Date.now() - started},
 libraryCorrespondence:{...correspondence(library), auditRoot:library.audit,
  initialPsVariant:prior.libraryCorrespondence.initialPsVariant},
 currentUnified:{entryModule:project.entryModule, modules:projectRows.length, sourceClosureDigest:currentUnifiedDigest,
  exactQualifiedProofScriptBytesRetained:currentUnifiedDigest === prior.qualifiedUnified.sourceClosureDigest},
 referenceRefresh:refresh};

// Check every captured input again before creating any candidate Git object.
assert.ok(fs.readFileSync('CANONICAL_SOURCES.json').equals(baselineBytes));
assert.equal(run('git', ['rev-parse', 'HEAD']).trim(), preparedCommit);
const stillCurrent = readCanonicalEditCandidate(root);
for (const row of candidate.modules.values()) {
 const current = stillCurrent.modules.get(row.module);
 assert.ok(current && current.ps.equals(row.ps) && current.lean.equals(row.lean), 'Source changed during reference qualification: ' + row.module);
}
const sources = new Map();
for (const row of changed) sources.set(row.path, decode(row.ps));
for (const group of [compiler,library]) for (const row of group.rows) {
 const bytes = group.referenceBytes.get(row.module);
 if (!bytes.equals(row.lean)) sources.set(row.bootstrap.path, decode(bytes));
}
sources.set('CANONICAL_SOURCES.json', json(manifest));
sources.set(prior.primaryProject, json(project));
for (const [file, text] of sources) put(path.join(out, 'prepared-files', file), text);
put(path.join(out, 'correspondence.json'), json({compiler:correspondence(compiler), library:correspondence(library), nativeProjectionProbe, refresh}));
put(path.join(out, 'conversion-evidence.json'), json({compiler:compiler.converted, library:library.converted}));
const entries = [...sources].map(([file, content]) => {
 const bytes = Buffer.from(content), header = Buffer.from('blob ' + bytes.length + '\0');
 return {path:'psc1/' + file, mode:'100644', type:'blob',
  sha:crypto.createHash('sha1').update(header).update(bytes).digest('hex'),
  bytes:bytes.length, sha256:hash(bytes), content};
});
const report = {schema:'psc1-canonical-reference-refresh/1', status:'prepared-checked-reference-refresh',
 baseline, baselineManifestSha256:hash(baselineBytes), preparedCommit, baseTree, treeSha:null,
 changedCanonicalModules:changed.map(row => row.module),
 changedReferences:[...changedCompilerReferences, ...changedLibraryReferences].map(row => row.bootstrap.path),
 sourceClosureDigest:currentUnifiedDigest, nativeProjectionProbe,
 workingReferencesChanged:false, commitsCreated:false, refsChanged:false,
 objectUploadStatus:process.env.PSC1_CREATE_SOURCE_TREE==='1'?'pending':'not-requested',
 entries:entries.map(({content,...entry}) => entry)};
const preparedFilesText=json({schema:'psc1-canonical-prepared-files/1',preparedCommit,baseTree,
 preparedRunId:process.env.GITHUB_RUN_ID??null,baseline,contentEncoding:'utf8',
 commitsCreated:false,refsChanged:false,entries});
put(path.join(out,'prepared-files.json'),preparedFilesText);
report.preparedFiles={path:'prepared-files.json',bytes:Buffer.byteLength(preparedFilesText),
 sha256:hash(Buffer.from(preparedFilesText))};
put(path.join(out,'refresh.json'),json(report));
console.log('PSC1_CANONICAL_REFRESH_CHECKS_PREPARED: '+JSON.stringify({
 baseline,preparedCommit,changedCanonicalModules:report.changedCanonicalModules,
 preparedFiles:report.preparedFiles,nativeProjectionProbe,commitsCreated:false,refsChanged:false}));
try{
 const uploaded=await uploadPreparedSourceTree({entries,baseTree,preparedCommit,out});
 report.treeSha=uploaded.treeSha;report.objectUploadStatus=uploaded.upload.status;
}catch(error){
 report.objectUploadStatus='failed';
 report.objectUploadFailure={message:String(error.message),code:String(error.cause?.code??error.code??error.name)};
 put(path.join(out,'refresh.json'),json(report));throw error;
}
put(path.join(out,'refresh.json'),json(report));
console.log('PSC1_CANONICAL_REFERENCE_REFRESH: '+JSON.stringify(report));
