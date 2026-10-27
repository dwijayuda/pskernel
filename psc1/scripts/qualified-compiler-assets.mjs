import {applyProjectLicense} from './packaging/license.mjs';
// Promote only exact, independently qualified generated compiler assets.
// Kernel packages and the frozen distribution retain their separate identities.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { verifyArtifact } from '../host-tools/generated-target-tools.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { qualificationProfile } from './selfhost-qualification-profiles.mjs';

const engines = ['js', 'ts', 'rust', 'wasm-core'];
const checkerCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const fixedPoint = 'passed-G1-G2-G3-exact-source-admission-IR-executable-and-four-target-observations';
const identityFields = ['sourceClosureDigest', 'sourceSha256', 'admissionsSha256',
  'originalIrSha256', 'specializedIrSha256'];
const write = (file, bytes) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, bytes);
};
const pin = (root, relative) => {
  const bytes = fs.readFileSync(path.join(root, relative));
  return { path: relative, bytes: bytes.length, sha256: sha(bytes) };
};
function inventory(root, prefix = '') {
  const result = [];
  for (const name of fs.readdirSync(path.join(root, prefix)).sort()) {
    const relative = prefix ? prefix + '/' + name : name;
    const stat = fs.lstatSync(path.join(root, relative));
    assert.ok(!stat.isSymbolicLink(), 'no compiler package symlinks');
    if (stat.isDirectory()) result.push(...inventory(root, relative));
    else { assert.ok(stat.isFile()); result.push(pin(root, relative)); }
  }
  return result;
}
function pack(directory, destination) {
  const result = spawnSync('npm', ['pack', directory, '--ignore-scripts', '--json',
    '--pack-destination', destination], { encoding: 'utf8', timeout: 240000,
    maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.error, undefined);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  const packed = JSON.parse(result.stdout);
  assert.equal(packed.length, 1);
  return path.join(destination, packed[0].filename);
}

export function auditQualifiedCompilerGeneration(directory, engine, input, sourceDigest) {
  const file = path.join(directory, 'qualification.json');
  const qualification = JSON.parse(fs.readFileSync(file));
  for (const [key, value] of Object.entries({
    schema: 'psc1-generated-target-qualification/1', target: engine, serviceKind: 'unified',
    testedCommit: input.commit, status: 'passed', mode: '--self-host',
    correctnessQualification: 'qualified', sourceClosureDigest: sourceDigest, fixedPoint,
    nativeDelegationBoundary: 'one-seed; native compiler executables removed; generated source semantics only',
  })) assert.equal(qualification[key], value, engine + ':' + key);
  assert.deepEqual(qualification.outputTargets, engines);
  assert.deepEqual(qualification.profile, qualificationProfile(qualification.profile.name));
  if (qualification.profile.name === 'correctness-3600s') assert.equal(engine, 'rust');
  assert.equal(qualification.generations.length, 3);
  assert.equal(qualification.attempts.length, 2);
  assert.ok(qualification.attempts.every(attempt => attempt.status === 'passed'));
  assert.equal(qualification.cases.length, 120);
  assert.equal(qualification.envelopeRefusals.length, 27);
  assert.match(input.manifestSha256, /^[a-f0-9]{64}$/);
  assert.match(input.executableSha256, /^[a-f0-9]{64}$/);
  assert.equal(qualification.executableSha256, input.executableSha256);
  const bootstrap = JSON.parse(fs.readFileSync(path.join(directory, 'G1-bootstrap.request.json')));
  assert.equal(bootstrap[0], 'psc1-unified-compiler-service/2');
  assert.equal(bootstrap[1], engine);
  assert.equal(bootstrap[2][0], 'psc1-compiler-service/1');
  const sources = bootstrap[2][6].map(([module, text]) => ({ module, kind: 'lean', text }));
  assert.equal(compilerSourceClosureDigest(sources), sourceDigest);
  assert.equal(sources.length, qualification.sourceModules);
  assert.equal(sources.length, qualification.sourceInventory.length);
  assert.ok(sources.every(source => !/^Ps\.Backend(Python|Php)\./.test(source.module)));
  qualification.sourceInventory.forEach((row, index) => {
    assert.equal(row.module, sources[index].module);
    assert.equal(row.bytes, Buffer.byteLength(sources[index].text));
    assert.equal(row.sha256, sha(sources[index].text));
  });
  let finalArtifact, compilerAdmissions;
  for (const [index, generation] of qualification.generations.entries()) {
    assert.equal(generation.generation, index + 1);
    assert.equal(generation.logicalAdmission, 'accepted');
    assert.equal(generation.checkerCommit, checkerCommit);
    for (const key of identityFields)
      assert.equal(generation[key], qualification.bootstrap[key], engine + ':' + key);
    assert.deepEqual(generation.observations, qualification.generations[0].observations);
    const candidateFile = index === 0 ? 'G1-bootstrap.candidate.json' : 'G' + (index + 1) + '-self.candidate.json';
    const candidate = JSON.parse(fs.readFileSync(path.join(directory, candidateFile)));
    assert.equal(candidate.status, 'candidate');
    if (index === 0) compilerAdmissions = candidate.admissionRequest.admissions;
    assert.equal(sha(candidate.source), generation.sourceSha256);
    assert.equal(sha(candidate.admissionRequest.admissions), generation.admissionsSha256);
    assert.equal(sha(JSON.stringify(candidate.originalIr)), generation.originalIrSha256);
    assert.equal(sha(JSON.stringify(candidate.specializedIr)), generation.specializedIrSha256);
    const manifestFile = path.join(directory, 'G' + (index + 1) + '-service/artifact.json');
    const artifact = verifyArtifact(manifestFile, generation.artifactSha256);
    assert.equal(artifact.serviceKind, 'unified');
    assert.equal(artifact.service, true);
    assert.equal(artifact.sourceSha256, generation.sourceSha256);
    assert.equal(sha(fs.readFileSync(path.join(artifact.directory, artifact.executable))),
      input.executableSha256);
    finalArtifact = { ...artifact, file: manifestFile };
  }
  assert.equal(qualification.generations[2].artifactSha256, input.manifestSha256);
  const io = JSON.parse(fs.readFileSync(path.join(directory, 'output-abi/qualification.json')));
  assert.equal(io.schema, 'psc1-output-abi-generated/1');
  assert.equal(io.status, 'passed');
  assert.equal(io.engine, engine);
  assert.equal(io.generation, 3);
  assert.equal(io.fixedPoint, fixedPoint);
  assert.equal(io.sourceClosureDigest, sourceDigest);
  assert.equal(io.serviceSha256, input.manifestSha256);
  assert.equal(io.cases.length, 35);
  assert.equal(io.cases.filter(row => row.status === 'candidate').length, 5);
  assert.equal(io.cases.filter(row => row.status === 'refused').length, 30);
  assert.ok(io.cases.filter(row => row.status === 'candidate').every(row =>
    row.independentAdmission === true && row.runtime === 'executed'));
  return { qualification, artifact: finalArtifact, qualificationFile: file, compilerAdmissions };
}

function optionalBundle(engine, compiler, assetsRoot, directory, tarballs, version) {
  const name = engine === 'rust' ? '@proofscript/compiler-rust-linux-x64' : '@proofscript/compiler-wasm';
  const payload = path.join(directory, 'payload');
  for (const resource of compiler.dependencies) {
    const relative = resource.path.slice(('selfhost/' + engine + '/').length);
    write(path.join(payload, relative), fs.readFileSync(path.join(assetsRoot, resource.path)));
  }
  if (engine === 'rust') fs.chmodSync(path.join(payload, 'service.bin'), 0o755);
  const transports = engine === 'rust'
    ? ['generated-rust-transport.mjs', 'generated-rust-guard.mjs', 'runtime-policy.mjs'] : ['generated-wasm-transport.mjs'];
  for (const file of transports)
    write(path.join(directory, 'runtime', file), fs.readFileSync(path.join('host-tools', file)));
  const manifest = {
    schema: 'psc1-compiled-compiler-execution-bundle/1', package: name, version, engine,
    compilerSourceClosureDigest: compiler.sourceClosureDigest, qualifiedCommit: compiler.qualifiedCommit,
    executableSha256: compiler.executableSha256, fixedPoint: compiler.fixedPoint,
    performanceQualification: compiler.performanceQualification,
    files: inventory(directory), publicationAuthority: false, kernelIncluded: false,
    kernelRequirement: 'independent official Lean 4.35; default root provider is linear-memory Wasm',
  };
  const manifestText = JSON.stringify(manifest, null, 2) + '\n';
  write(path.join(directory, 'BUNDLE_MANIFEST.json'), manifestText);
  const imports = engine === 'rust'
    ? "import {runGeneratedRustCompiler} from './runtime/generated-rust-transport.mjs';"
    : "import {loadWasmArtifact} from './runtime/generated-wasm-transport.mjs';";
  const initialize = engine === 'rust'
    ? "const execute=request=>runGeneratedRustCompiler({executable:path.join(root,'payload',artifact.executable),executableSha256:manifest.executableSha256,request});"
    : "const {psCompilerServiceCandidate:execute}=loadWasmArtifact(path.join(root,'payload/artifact.json'));";
  write(path.join(directory, 'index.mjs'),
    "import fs from 'node:fs';\nimport path from 'node:path';\nimport crypto from 'node:crypto';\nimport assert from 'node:assert/strict';\nimport {fileURLToPath} from 'node:url';\n" +
    imports + "\nconst root=path.dirname(fileURLToPath(import.meta.url));\n" +
    "const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');\n" +
    "const expectedManifest=" + JSON.stringify(sha(manifestText)) + ";\n" +
    "const manifestFile=path.join(root,'BUNDLE_MANIFEST.json');\n" +
    "const manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));\n" +
    "function verify(){assert.equal(hash(fs.readFileSync(manifestFile)),expectedManifest,'PSC1_BUNDLE_MANIFEST_IDENTITY');for(const row of manifest.files){const file=path.join(root,row.path),stat=fs.lstatSync(file);assert.ok(stat.isFile()&&!stat.isSymbolicLink()&&stat.size===row.bytes,'PSC1_BUNDLE_RESOURCE_KIND');assert.equal(hash(fs.readFileSync(file)),row.sha256,'PSC1_BUNDLE_RESOURCE_IDENTITY');}}\n" +
    "verify();\nconst artifact=JSON.parse(fs.readFileSync(path.join(root,'payload/artifact.json')));\n" +
    initialize + "\n" +
    "export const metadata=Object.freeze({package:manifest.package,engine:manifest.engine,compilerSourceClosureDigest:manifest.compilerSourceClosureDigest,qualifiedCommit:manifest.qualifiedCommit,fixedPoint:manifest.fixedPoint,publicationAuthority:false});\n" +
    "export function compileCandidate(request){assert.equal(typeof request,'string');assert.ok(Buffer.byteLength(request)<=128*1024*1024);verify();const result=execute(request);verify();assert.equal(typeof result,'string');return result;}\n" +
    "export function psCompilerJsServiceCandidate(request){return compileCandidate(JSON.stringify(['psc1-unified-compiler-service/2','js',JSON.parse(request)]));}\n");
  write(path.join(directory, 'index.d.ts'),
    "export const metadata: Readonly<{package:string;engine:'rust'|'wasm-core';compilerSourceClosureDigest:string;qualifiedCommit:string;fixedPoint:string;publicationAuthority:false}>;\n" +
    "export function compileCandidate(request:string):string;\nexport function psCompilerJsServiceCandidate(request:string):string;\n");
  write(path.join(directory, 'README.md'), '# ' + name + '\n\nUnpublished, exactly qualified G3 execution payload from the shared PSC1 compiler. No SDK or install-time build. This package returns candidates only; the root toolchain must independently admit exact graph bytes and validate output. Compiler Wasm retains GC; the separate official C++/Emscripten kernel retains linear memory. Rust execution is Linux x64/glibc only. Other-platform publication and the 240-second selfcompile target have separate qualification.\n');
  write(path.join(directory, 'package.json'), JSON.stringify({
    name, version, type: 'module', private: true, license: 'Apache-2.0', engines: { node: '>=22.23.3' },
    main: './index.mjs', types: './index.d.ts',
    exports: { '.': { types: './index.d.ts', import: './index.mjs' },
      './metadata': './BUNDLE_MANIFEST.json', './package.json': './package.json' },
    files: ['index.mjs', 'index.d.ts', 'BUNDLE_MANIFEST.json', 'payload/', 'runtime/', 'README.md'],
    ...(engine === 'rust' ? { os: ['linux'], cpu: ['x64'], libc: ['glibc'] } : {}),
  }, null, 2) + '\n');
  applyProjectLicense(directory);
  const tarball = pack(directory, tarballs);
  return { package: name, version, tarball: path.basename(tarball),
    sha256: sha(fs.readFileSync(tarball)), file: tarball, directory };
}

export async function readQualifiedCompilerAssets(input, destination, version) {
  assert.equal(input.schema, 'psc1-qualified-compiler-generation-inputs/1');
  assert.match(input.sourceClosureDigest, /^[a-f0-9]{64}$/);
  const localSources = readOwnedCompilerSources('Ps.CompilerUnified.Service')
    .map(source => ({ module: source.module, kind: 'lean', text: source.text }));
  assert.equal(compilerSourceClosureDigest(localSources), input.sourceClosureDigest,
    'qualification must match the current owned compiler source');
  assert.equal(Object.keys(input.engines).sort().join(','), [...engines].sort().join(','));
  assert.ok(destination.startsWith(path.resolve('dist') + path.sep));
  assert.equal(fs.existsSync(destination), false, 'fresh compiler promotion directory');
  fs.mkdirSync(destination, { recursive: true });
  const assetsRoot = path.join(destination, 'assets'), tarballs = path.join(destination, 'tarballs');
  fs.mkdirSync(assetsRoot); fs.mkdirSync(tarballs);
  const result = { sharedSourceClosureDigest: input.sourceClosureDigest, engines: {},
    root: assetsRoot, optionalPackages: {}, qualificationInputs: input, compilerAdmissions: [] };
  for (const engine of engines) {
    const selected = input.engines[engine];
    const archive = await readQualifiedArtifact(selected, path.join(destination, engine, 'input'));
    const source = path.join(archive, 'generated-unified-' + engine + '-compiler');
    const { qualification: q, artifact, qualificationFile, compilerAdmissions } =
      auditQualifiedCompilerGeneration(source, engine, selected, input.sourceClosureDigest);
    const admissionFile = path.join(destination, 'admissions', q.bootstrap.admissionsSha256 + '.json');
    if (result.compilerAdmissions.length === 0) {
      write(admissionFile, compilerAdmissions);
      result.compilerAdmissions.push({ file: admissionFile, sha256: q.bootstrap.admissionsSha256 });
    } else {
      assert.equal(q.bootstrap.admissionsSha256, result.compilerAdmissions[0].sha256,
        'all execution engines must admit the same compiler source graph');
      assert.equal(compilerAdmissions, fs.readFileSync(admissionFile, 'utf8'));
    }
    const prefix = 'selfhost/' + engine;
    write(path.join(assetsRoot, prefix, 'artifact.json'), fs.readFileSync(artifact.file));
    for (const file of artifact.files)
      write(path.join(assetsRoot, prefix, file.path), fs.readFileSync(path.join(artifact.directory, file.path)));
    write(path.join(assetsRoot, prefix, 'qualification.json'), fs.readFileSync(qualificationFile));
    const imports = engine === 'js' || engine === 'ts'
      ? "import {psCompilerServiceCandidate as execute} from './module.js';\n"
      : engine === 'wasm-core'
      ? "import {loadWasmArtifact} from '../../host-tools/generated-wasm-transport.mjs';\nimport {fileURLToPath} from 'node:url';\nconst {psCompilerServiceCandidate:execute}=loadWasmArtifact(fileURLToPath(new URL('./artifact.json',import.meta.url)));\n"
      : "import {runGeneratedRustCompiler} from '../../host-tools/generated-rust-transport.mjs';\nimport {fileURLToPath} from 'node:url';\n";
    const envelope = "JSON.stringify(['psc1-unified-compiler-service/2','js',JSON.parse(request)])";
    const invoke = engine === 'rust'
      ? "runGeneratedRustCompiler({executable:fileURLToPath(new URL('./service.bin',import.meta.url)),executableSha256:" +
        JSON.stringify(selected.executableSha256) + ",request:" + envelope + "})"
      : 'execute(' + envelope + ')';
    write(path.join(assetsRoot, prefix, 'adapter.mjs'), imports +
      'export function psCompilerJsServiceCandidate(request){return ' + invoke + ';}\n');
    const compiler = {
      sourceClosureDigest: q.sourceClosureDigest, qualifiedCommit: q.testedCommit,
      qualification: q.correctnessQualification, fixedPoint: q.fixedPoint,
      performanceQualification: q.performanceQualification, executableSha256: selected.executableSha256,
      selfCompileEvents: q.events.filter(event => event.role === 'generated-compiler' &&
        ['G2-self', 'G3-self'].includes(event.id)),
      adapter: pin(assetsRoot, prefix + '/adapter.mjs'),
      dependencies: ['artifact.json', ...artifact.files.map(file => file.path), 'qualification.json']
        .map(file => pin(assetsRoot, prefix + '/' + file)),
    };
    result.engines[engine] = compiler;
    console.log('PSC1_COMPILER_GENERATION_RECEIPT: ' + JSON.stringify({ engine,
      sourceClosureDigest: q.sourceClosureDigest, sourceModules: q.sourceModules,
      qualifiedCommit: q.testedCommit, manifestSha256: selected.manifestSha256,
      executableSha256: selected.executableSha256, profile: q.profile,
      fixedPoint: q.fixedPoint, selfCompileEvents: compiler.selfCompileEvents }));
    if (engine === 'rust' || engine === 'wasm-core')
      result.optionalPackages[engine] = optionalBundle(engine, compiler, assetsRoot,
        path.join(destination, engine, 'package'), tarballs, version);
  }
  write(path.join(destination, 'promotion-receipt.json'), JSON.stringify({
    schema: 'psc1-qualified-compiler-assets/1', testedCommit: process.env.GITHUB_SHA,
    sourceClosureDigest: result.sharedSourceClosureDigest, inputs: input, compilerAdmissions: result.compilerAdmissions,
    engines: result.engines, optionalPackages: result.optionalPackages, packageInstallation: 'not-run',
    publication: false,
  }, null, 2) + '\n');
  return result;
}
