// Qualified SDK/provider resources only. No legacy compiler API is executed.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { readQualifiedArtifact } from './kernel435-qualified-artifact.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { readManifestBytes, verify } from '../host-tools/executable/verify.mjs';
import { root, read, write, sha, run } from './modular-corpus-common.mjs';

const group = process.argv[2];
assert.ok(['core','optional'].includes(group));
const input = read('scripts/modular-corpus-input.json');
assert.equal(input.schema, 'psc1-modular-corpus-input/1');
const source = readOwnedCompilerSources('Ps.CompilerUnified.Service')
  .map(row => ({ module: row.module, kind: 'lean', text: row.text }));
assert.equal(compilerSourceClosureDigest(source), input.graph.compilerSourceClosureDigest);
const graphArchive = await readQualifiedArtifact(input.graph.artifact, path.join(root,'graph-input'));
const graph = { graphRoot: path.join(graphArchive,'compiler/candidate'),
  manifestFile: path.join(graphArchive,'compiler/manifest.json'),
  manifestSha256: input.graph.manifestSha256 };
const manifest = verify(graph.graphRoot, readManifestBytes(graph.manifestFile), graph.manifestSha256);
assert.equal(manifest.sourceClosureDigest, input.graph.compilerSourceClosureDigest);
const archive = await readQualifiedArtifact(input.targetResources, path.join(root,'target-input'));
const assembly = read(path.join(archive,'package-receipt.json'));
assert.equal(assembly.version, '0.1.0-psc1.11');
const prefix = path.join(root,'target-resources');
fs.mkdirSync(prefix, { recursive:true });
assert.equal(fs.readdirSync(prefix).length, 0);
write(path.join(prefix,'package.json'), { private:true, type:'module' });
const rows = [assembly,
  assembly.targetConsumers.ts, ...assembly.targetConsumers.ts.dependencies,
  assembly.targetConsumers.rust, ...Object.values(assembly.dispatchPackages)];
const tarballs = rows.map(row => {
  assert.match(row.tarball, /^[A-Za-z0-9_.-]+\.tgz$/);
  const file = path.join(archive,'tarballs',row.tarball);
  assert.equal(sha(fs.readFileSync(file)), row.sha256);
  return file;
});
const npm = path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
run(process.execPath, [npm,'install','--prefix',prefix,'--workspaces=false',
  '--package-lock=false','--cache',path.join(root,'empty-npm-cache'),
  '--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund',
  ...tarballs], { timeoutMs:240000, timeoutPolicy:'standard-240s' });
const referencePackage = path.join(prefix,'node_modules/proofscript');
const distribution = read(path.join(referencePackage,'UNIVERSAL_DISTRIBUTION.json'));
const { resolveCheckedTarget, verifyFile } = await import(pathToFileURL(
  path.join(referencePackage,'host-tools/installed-engine-resolver.mjs')).href);
const targets = group === 'core' ? ['js','ts','rust','wasm-core']
  : ['wasm-component','python','php'];
if (group === 'core') {
  const result = spawnSync('rustup',['run','1.90.0','rustc','--print','sysroot'],
    { encoding:'utf8',timeout:10000 });
  assert.equal(result.error, undefined); assert.equal(result.status,0,result.stderr);
  const sdk = result.stdout.trim(), pins = distribution.targetConsumers.rust.toolchain.files;
  assert.ok(path.isAbsolute(sdk)); assert.equal(pins.length,61);
  const component = pins.find(pin => pin.path === 'lib/rustlib/components');
  assert.ok(component);
  for (const pin of pins.filter(pin => pin !== component)) verifyFile(sdk,pin,512*1024*1024);
  const file = path.join(sdk,component.path), before = fs.readFileSync(file);
  if (sha(before) !== component.sha256) {
    assert.equal(fs.realpathSync(file),file);
    assert.ok(fs.lstatSync(file).isFile() && before.length < 4096);
    const text = before.toString('utf8'); assert.ok(text.endsWith('\n'));
    const lines = text.slice(0,-1).split('\n');
    assert.deepEqual([...lines].sort(), ['cargo-x86_64-unknown-linux-gnu',
      'rust-std-x86_64-unknown-linux-gnu','rustc-x86_64-unknown-linux-gnu'].sort());
    const permutations = values => values.length === 0 ? [[]] : values.flatMap((value,i) =>
      permutations(values.filter((_,j)=>i!==j)).map(rest=>[value,...rest]));
    const exact = permutations(lines).map(p=>Buffer.from(p.join('\n')+'\n'))
      .filter(bytes=>bytes.length===component.bytes && sha(bytes)===component.sha256);
    assert.equal(exact.length,1,'only the exact qualified bookkeeping permutation is allowed');
    assert.deepEqual(fs.readFileSync(file),before);
    fs.writeFileSync(file,exact[0],{flag:'r+'});
  }
}
const consumers = Object.fromEntries(targets.map(target =>
  [target, resolveCheckedTarget(target,distribution)]));
for (const consumer of Object.values(consumers))
  for (const selected of Object.values(consumer))
    assert.ok(selected.pins.every(pin => !pin.path.includes('/selfhost/')),
      'target resources cannot contain a reference compiler');
const oldExecutors = path.join(referencePackage,'selfhost');
assert.ok(fs.existsSync(oldExecutors));
fs.renameSync(oldExecutors,path.join(root,'disabled-reference-executors'));
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const disabled = path.resolve('.lake/build/modular-corpus-disabled-native');
fs.mkdirSync(disabled,{recursive:true});
for (const name of fs.readdirSync('.lake/build/bin')) {
  if (name === 'psc1_independent_checker') continue;
  const file = path.resolve('.lake/build/bin',name);
  if (fs.lstatSync(file).isFile()) fs.renameSync(file,path.join(disabled,name));
}
write(path.join(root,'resources.json'), {
  schema:'psc1-modular-corpus-resources/1',testedCommit:process.env.GITHUB_SHA,
  graph,group,targets,consumers,checker,checkerSha256:sha(fs.readFileSync(checker)),
  referencePackage,legacyCompilerSemanticsExecuted:false,input,
});
console.log('PSC1_MODULAR_CORPUS_RESOURCES '+JSON.stringify({group,targets,
  nativeFrontendsDisabled:true,referenceExecutorsDisabled:true}));
