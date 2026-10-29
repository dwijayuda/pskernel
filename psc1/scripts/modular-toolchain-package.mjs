// Assemble the installable preview from qualified graph/kernel resources only.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 } from './kernel435-qualified-artifact.mjs';
import { verify } from '../host-tools/executable/verify.mjs';
import { readQualifiedModularGraph } from './modular-toolchain-provenance.mjs';
const input = JSON.parse(fs.readFileSync('scripts/modular-toolchain-input.json'));
const out = path.resolve('dist/modular-toolchain');
assert.equal(out, path.join(process.cwd(), 'dist/modular-toolchain'));
fs.mkdirSync(out, { recursive: true });
const json = (x) => JSON.stringify(x, null, 2) + '\n';
const write = (file, data) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, data);
};
function files(root, prefix = '') {
  return fs
    .readdirSync(path.join(root, prefix))
    .sort()
    .flatMap((name) => {
      const rel = prefix ? prefix + '/' + name : name,
        file = path.join(root, rel),
        s = fs.lstatSync(file);
      assert.ok(!s.isSymbolicLink(), 'package symlink:' + rel);
      if (s.isDirectory()) return files(root, rel);
      assert.ok(s.isFile());
      const bytes = fs.readFileSync(file);
      return [{ path: rel, bytes: bytes.length, sha256: sha256(bytes) }];
    });
}
function run(exe, args, cwd = process.cwd()) {
  const r = spawnSync(exe, args, { cwd, encoding: 'utf8', timeout: 240000, maxBuffer: 33554432 });
  assert.equal(r.error, undefined, String(r.error));
  assert.equal(r.status, 0, r.stdout + r.stderr);
  return r.stdout;
}
const qualified = await readQualifiedModularGraph(input.graph, path.join(out, 'graph-input'));
const graphArchive = qualified.archive;
const graphRoot = qualified.root;
const originalGraph = qualified.manifest;
assert.equal(originalGraph.sourceClosureDigest, input.graph.compilerSourceClosureDigest);
const rootArchive = await readQualifiedArtifact(input.root, path.join(out, 'root-input'));
const rootTars = files(rootArchive).filter((r) => path.basename(r.path) === input.root.tarball);
assert.equal(rootTars.length, 1);
const tar = path.join(rootArchive, rootTars[0].path);
assert.ok(
  run('tar', ['tzf', tar])
    .split('\n')
    .filter(Boolean)
    .every((p) => p.startsWith('package/') && !p.includes('\\') && !p.split('/').includes('..')),
);
const extracted = path.join(out, 'reference');
fs.mkdirSync(extracted);
run('tar', ['xzf', tar, '-C', extracted]);
const reference = path.join(extracted, 'package'),
  referenceMeta = JSON.parse(fs.readFileSync(path.join(reference, 'package.json')));
assert.equal(referenceMeta.name, 'proofscript');
assert.equal(referenceMeta.version, '0.1.0-psc1.13');
assert.equal(referenceMeta.bundledDependencies.length, 20);
const graphNames = new Set(originalGraph.packages.map((p) => p.name));
const graphBytes = originalGraph.files.reduce((n, r) => n + r.bytes, 0);
const extraPackages = referenceMeta.bundledDependencies
  .filter((name) => !graphNames.has(name))
  .map((name) => {
    const inventory = files(path.join(reference, 'node_modules', name));
    return { name, bytes: inventory.reduce((n, r) => n + r.bytes, 0), files: inventory.length };
  });
const inspection = {
  schema: 'psc1-modular-toolchain-inspection/1',
  testedCommit: process.env.GITHUB_SHA,
  graphBytes,
  graphFiles: originalGraph.files.length,
  graphPackages: graphNames.size,
  extraPackages,
  projectedGraphBytes: graphBytes + extraPackages.reduce((n, r) => n + r.bytes, 0),
  exactGraphBound: 134217728,
  oldCompilerExecuted: false,
};
write(path.join(out, 'inspection.json'), json(inspection));
console.log('PSC1_MODULAR_TOOLCHAIN_INSPECTION ' + JSON.stringify(inspection));

if (process.argv[2] !== 'inspect') {
  assert.equal(process.argv[2], 'build');
  const stage = path.join(out, 'package'),
    nodes = path.join(stage, 'node_modules');
  fs.mkdirSync(stage);
  fs.cpSync(path.join(graphRoot, 'node_modules'), nodes, { recursive: true });
  const version = input.version,
    coreNames = referenceMeta.bundledDependencies;
  for (const name of coreNames.filter((name) => !graphNames.has(name)))
    fs.cpSync(path.join(reference, 'node_modules', name), path.join(nodes, name), {
      recursive: true,
    });
  const host = path.join(nodes, '@proofscript/compiler/dist/host');
  const oldHost = path.join(reference, 'node_modules/@proofscript/compiler/dist/implementation');
  const oldDistribution = JSON.parse(
    fs.readFileSync(path.join(oldHost, 'UNIVERSAL_DISTRIBUTION.json')),
  );
  const kernelName = '@proofscript/pskernel-lean-wasm';
  const kernelMeta = JSON.parse(fs.readFileSync(path.join(nodes, kernelName, 'package.json')));
  const kernelVersion = kernelMeta.version;
  const sourceCode =
    [
      "import fs from 'node:fs';import crypto from 'node:crypto';",
      "const data=JSON.parse(fs.readFileSync(new URL('./source-manifest.json',import.meta.url)));",
      'export const sourcePackage=Object.freeze(data);',
      "export function readSources({kind='lean'}={}){if(kind!=='lean')throw Error('PSC1_PACKAGE_NO_SOURCE_VARIANT');",
      "return Object.freeze(data.files.map(row=>{const b=fs.readFileSync(new URL('../'+row.path,import.meta.url));",
      "if(b.length!==row.bytes||crypto.createHash('sha256').update(b).digest('hex')!==row.sha256)throw Error('PSC1_PACKAGE_SOURCE_IDENTITY');",
      "return Object.freeze({module:row.module,kind:'lean',text:new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(b)});}));}",
    ].join('\n') + '\n';
  const sourceTypes =
    "export interface SourceRecord {readonly module:string;readonly kind:'lean';readonly text:string;}\nexport const sourcePackage:Readonly<{name:string;version:string;internalRuntimeApi:false;admissionAuthority:false}>;\nexport function readSources(options?:{kind?:'lean'}):readonly SourceRecord[];\n";
  const installedPackages = [];
  for (const name of coreNames) {
    const pkg = path.join(nodes, name),
      meta = JSON.parse(fs.readFileSync(path.join(pkg, 'package.json')));
    if (name === kernelName) {
      installedPackages.push({
        name,
        version: meta.version,
        dependencies: meta.dependencies || {},
        peerDependencies: meta.peerDependencies || {},
        units: [],
      });
      continue; // Genuine official C++/Emscripten kernel payload and metadata are unchanged.
    }
    if (!graphNames.has(name)) {
      fs.rmSync(path.join(pkg, 'dist'), { recursive: true });
      // Source-only bridge/research interfaces must not import checked orchestration.
      meta.exports = {};
    }
    delete meta.main;
    delete meta.types;
    delete meta.scripts;
    delete meta.bundledDependencies;
    delete meta.peerDependencies;
    delete meta.peerDependenciesMeta;
    delete meta.optionalDependencies;
    meta.name = name;
    meta.version = version;
    meta.type = 'module';
    meta.license = 'Apache-2.0';
    meta.dependencies = graphNames.has(name)
      ? Object.fromEntries(
          Object.keys(originalGraph.packages.find((p) => p.name === name).dependencies).map((n) => [
            n,
            version,
          ]),
        )
      : {};
    meta.exports = {
      ...(graphNames.has(name) ? meta.exports : {}),
      '.': { types: './dist/index.d.ts', import: './dist/index.js' },
      './sources': './dist/source-manifest.json',
      './package.json': './package.json',
    };
    delete meta.exports['./compiler']; // Explicit preview API transition; never an unchecked replacement.
    const sourcePrefix = graphNames.has(name) ? 'sources' : 'src';
    const sourceRows = fs.existsSync(path.join(pkg, sourcePrefix))
      ? files(path.join(pkg, sourcePrefix))
          .filter((row) => row.path.endsWith('.lean'))
          .map((row) => ({
            ...row,
            path: sourcePrefix + '/' + row.path,
            module: row.path.replace(/\.lean$/, '').replaceAll('/', '.'),
          }))
      : [];
    write(
      path.join(pkg, 'dist/source-manifest.json'),
      json({
        schema: 'psc1-source-package/1',
        name,
        version,
        files: sourceRows,
        internalRuntimeApi: false,
        admissionAuthority: false,
      }),
    );
    write(path.join(pkg, 'dist/sources.js'), sourceCode);
    write(path.join(pkg, 'dist/sources.d.ts'), sourceTypes);
    write(
      path.join(pkg, 'dist/index.js'),
      "export {sourcePackage,readSources} from './sources.js';\n",
    );
    write(path.join(pkg, 'dist/index.d.ts'), "export * from './sources.js';\n");
    meta.proofscript = {
      ...(meta.proofscript || {}),
      npmArchitecture: 'psc1-installed-executable-graph/1',
      internalCompilerModules: graphNames.has(name),
      checkedHostApi: name === '@proofscript/compiler',
      publicApiPromotion: false,
      fullModularSelfHosting: false,
    };
    if (name === '@proofscript/compiler') {
      meta.dependencies[kernelName] = kernelVersion;
      meta.proofscript.defaultKernel = 'wasm';
      meta.proofscript.defaultEngine = 'js';
      meta.proofscript.compilerSelfHosting = qualified.qualification;
      meta.exports['./io'] = {
        types: './dist/host/host-tools/typed-io.d.ts',
        import: './dist/host/host-tools/typed-io.mjs',
      };
      meta.exports['./runtime-policy'] = './dist/host/host-tools/runtime-policy.mjs';
      meta.exports['./command'] = './dist/host/npm-cli/universal-cli.mjs';
      meta.peerDependencies = Object.fromEntries(
        Object.entries(referenceMeta.peerDependencies || {}).filter(
          ([n]) => !n.includes('compiler-rust') && !n.includes('compiler-wasm'),
        ),
      );
      meta.peerDependenciesMeta = Object.fromEntries(
        Object.keys(meta.peerDependencies).map((n) => [n, { optional: true }]),
      );
      write(
        path.join(pkg, 'dist/index.js'),
        "export * from './host/npm-cli/compiler-api.mjs';\nexport {sourcePackage,readSources} from './sources.js';\n",
      );
      write(
        path.join(pkg, 'dist/index.d.ts'),
        fs.readFileSync('npm-cli/universal.d.ts', 'utf8') + "\nexport * from './sources.js';\n",
      );
    }
    if (name === '@proofscript/cli') {
      meta.dependencies = { '@proofscript/compiler': version };
      const routes = {
        'proofscript-cli.mjs': [
          ["'../host-tools/runtime-policy.mjs'", "'@proofscript/compiler/runtime-policy'"],
          ["meta.name + ' ' + meta.version", "'proofscript ' + meta.version"],
        ],
        'cli-watch-worker.mjs': [["'./universal.mjs'", "'@proofscript/compiler'"]],
        'cli-project.mjs': [],
        'cli-watch.mjs': [],
      };
      const provenance = [];
      for (const [file, changes] of Object.entries(routes)) {
        const original = fs.readFileSync('npm-cli/' + file, 'utf8');
        let mapped = original;
        for (const [before, after] of changes) {
          assert.ok(mapped.includes(before));
          mapped = mapped.replace(before, after);
        }
        let restored = mapped;
        for (const [before, after] of [...changes].reverse())
          restored = restored.replace(after, before);
        assert.equal(restored, original, 'CLI relocation preserves bodies');
        write(path.join(pkg, 'dist', file), mapped);
        provenance.push({
          source: 'npm-cli/' + file,
          sourceSha256: sha256(original),
          file: 'dist/' + file,
          installedSha256: sha256(mapped),
          rewrites: changes,
        });
      }
      write(path.join(pkg, 'dist/HOST_SOURCE_MAP.json'), json(provenance));
      write(path.join(pkg, 'dist/universal-cli.mjs'), "import '@proofscript/compiler/command';\n");
      write(
        path.join(pkg, 'dist/index.js'),
        "export async function run(){await import('./proofscript-cli.mjs');}\n",
      );
      write(path.join(pkg, 'dist/index.d.ts'), 'export function run():Promise<void>;\n');
    }
    write(path.join(pkg, 'package.json'), json(meta));
    installedPackages.push({
      name,
      version,
      dependencies: meta.dependencies,
      peerDependencies: meta.peerDependencies || {},
      units: originalGraph.packages.find((p) => p.name === name)?.units || [],
    });
  }
  // Copy only host resources, never frozen compiler executors or implementation bundles.
  const runtimeFiles = new Set(
    oldDistribution.hostFiles
      .filter((row) => /^(host-tools|npm-cli|scripts)\//.test(row.path))
      .map((row) => row.path),
  );
  for (const file of [
    'host-tools/executable/verify.mjs',
    'host-tools/executable/loader.mjs',
    'host-tools/executable/tools.mjs',
  ])
    runtimeFiles.add(file);
  for (const file of runtimeFiles) {
    const source = fs.existsSync(file) ? file : path.join(oldHost, file);
    write(path.join(host, file), fs.readFileSync(source));
  }
  for (const variant of ['js', 'ts']) {
    const adapter =
      [
        "import path from 'node:path';",
        "import {installationRoot} from '../host-tools/installed-engine-resolver.mjs';",
        "import {loadExecutableCompiler} from '../host-tools/executable/loader.mjs';",
        "import {expectedGraphManifestSha256} from '../DISTRIBUTION_PIN.mjs';",
        "const root=path.resolve(installationRoot,'../../../..');",
        "const engine=await loadExecutableCompiler({root,manifestFile:path.resolve(root,'../dist/COMPILER_GRAPH.json'),",
        'manifestSha256:expectedGraphManifestSha256,variant:' + JSON.stringify(variant) + '});',
        'export function psCompilerServiceCandidate(input){return engine.candidate(input);}',
      ].join('\n') + '\n';
    const file = 'modular/' + variant + '.mjs';
    write(path.join(host, file), adapter);
    runtimeFiles.add(file);
  }
  const d = structuredClone(oldDistribution);
  d.version = version;
  d.compilerSourceClosureDigest = originalGraph.sourceClosureDigest;
  d.engines = Object.fromEntries(
    ['js', 'ts'].map((variant) => {
      const file = 'modular/' + variant + '.mjs',
        b = fs.readFileSync(path.join(host, file));
      return [
        variant,
        {
          kind: 'modular-graph',
          variant,
          qualification: 'qualified-checked-execution',
          sourceGraphManifestSha256: input.graph.manifestSha256,
          compilerSourceClosureDigest: d.compilerSourceClosureDigest,
          candidate: { path: file, bytes: b.length, sha256: sha256(b) },
          fullModularSelfHosting: false,
        },
      ];
    }),
  );
  for (const variant of ['rust', 'wasm-core'])
    d.engines[variant] = {
      kind: 'unqualified-source-cohort',
      compilerSourceClosureDigest: d.compilerSourceClosureDigest,
      qualification: 'not-qualified-for-current-modular-source',
      preservedReferenceVersion: '0.1.0-psc1.13',
    };
  // Reconcile archive metadata with qualified file pins. Python/PHP become
  // independent optional providers; no old checked compiler facade is retained.
  const optionalArchive = await readQualifiedArtifact(input.optional,path.join(out,'optional-input'));
  const optionalFiles = files(optionalArchive);
  const targetTars = path.join(out,'target-tarballs');fs.mkdirSync(targetTars);
  const selectedDescriptors = [d.targetConsumers.ts,...d.targetConsumers.ts.dependencies,
    d.targetConsumers.rust,...Object.values(d.dispatchPackages)];
  const archiveRepairs=[];
  for(const descriptor of selectedDescriptors){
    const basename=descriptor.package.replace('@','').replace('/','-')+'-'+descriptor.version+'.tgz';
    const matches=optionalFiles.filter(row=>path.basename(row.path)===basename);
    assert.equal(matches.length,1,basename);
    const source=path.join(optionalArchive,matches[0].path);
    const directory=path.join(out,'target-packages',descriptor.package.replace('@','').replace('/','-'));
    fs.mkdirSync(directory,{recursive:true});
    assert.ok(run('tar',['tzf',source]).split('\n').filter(Boolean).every(p=>p.startsWith('package/')&&!p.includes('\\')&&!p.split('/').includes('..')));
    run('tar',['xzf',source,'-C',directory]);
    const pkg=path.join(directory,'package'),before=files(pkg),byPath=new Map(before.map(row=>[row.path,row]));
    for(const pin of descriptor.files)assert.deepEqual(byPath.get(pin.path),pin,'qualified target input:'+descriptor.package+'/'+pin.path);
    let packedFile=source;
    if(['@proofscript/backend-python','@proofscript/backend-php'].includes(descriptor.package)){
      const meta=JSON.parse(fs.readFileSync(path.join(pkg,'package.json')));
      assert.deepEqual(meta.dependencies,{'@proofscript/compiler':'0.1.0-psc1.13'});
      meta.version=version;meta.dependencies={};delete meta.peerDependencies;delete meta.peerDependenciesMeta;
      delete meta.scripts;delete meta.exports['./compiler'];
      meta.proofscript={...meta.proofscript,npmArchitecture:'psc1-optional-provider/1',
        implementationOwner:meta.name,packageKind:'optional-emit-only-provider'};
      write(path.join(pkg,'package.json'),json(meta));
      const sourceManifest=JSON.parse(fs.readFileSync(path.join(pkg,'dist/source-manifest.json')));
      sourceManifest.version=version;write(path.join(pkg,'dist/source-manifest.json'),json(sourceManifest));
      write(path.join(pkg,'dist/index.js'),"export {sourcePackage,readSources} from './sources.js';\n");
      write(path.join(pkg,'dist/index.d.ts'),"export * from './sources.js';\n");
      for(const name of ['compiler.js','compiler.d.ts'])fs.rmSync(path.join(pkg,'dist',name));
      const allowed=new Set(['package.json','dist/source-manifest.json','dist/index.js','dist/index.d.ts','dist/compiler.js','dist/compiler.d.ts']);
      const after=new Map(files(pkg).map(row=>[row.path,row]));
      for(const pin of before.filter(row=>!allowed.has(row.path)))
        assert.deepEqual(after.get(pin.path),pin,'optional executable/runtime bytes preserved');
      const result=JSON.parse(run('npm',['pack',pkg,'--ignore-scripts','--json','--pack-destination',targetTars]));
      assert.equal(result.length,1);packedFile=path.join(targetTars,result[0].filename);
      descriptor.version=version;descriptor.files=files(pkg);
    } else fs.copyFileSync(source,path.join(targetTars,path.basename(source)));
    const actualSha=sha256(fs.readFileSync(packedFile));
    archiveRepairs.push({package:descriptor.package,priorArchiveSha256:descriptor.tarballSha256,
      archiveSha256:actualSha,payloadPinsPreserved:true,compilerDependencyRemoved:descriptor.package.startsWith('@proofscript/backend-')});
    descriptor.tarball=path.basename(packedFile);descriptor.tarballSha256=actualSha;
  }
  const compilerPackage=path.join(nodes,'@proofscript/compiler/package.json');
  const compilerMeta=JSON.parse(fs.readFileSync(compilerPackage));
  for(const name of ['@proofscript/backend-python','@proofscript/backend-php'])
    compilerMeta.peerDependencies[name]=version;
  write(compilerPackage,json(compilerMeta));
  installedPackages.find(row=>row.name==='@proofscript/compiler').peerDependencies=compilerMeta.peerDependencies;
  for(const key of Object.keys(d))
    if(!['schema','version','compilerSourceClosureDigest','leanCommit','defaultEngine','defaultKernel',
      'engines','kernels','targetConsumers','dispatchPackages','hostFiles','runner'].includes(key))delete d[key];
  d.qualification='checked-modular-preview';d.fullModularSelfHosting=false;
  d.compilerSelfHosting = qualified.qualification;
  write(path.join(out,'target-archive-correspondence.json'),json(archiveRepairs));
  d.hostFiles = [...runtimeFiles].sort().map((file) => {
    const b = fs.readFileSync(path.join(host, file));
    return { path: file, bytes: b.length, sha256: sha256(b) };
  });
  const runner = 'host-tools/execution/generated-service-runner.mjs';
  d.runner = d.hostFiles.find((row) => row.path === runner);
  assert.ok(d.runner);
  write(path.join(host, 'UNIVERSAL_DISTRIBUTION.json'), json(d));
  const exports = {
    '.': { types: './dist/index.d.ts', import: './dist/index.js' },
    './package.json': './package.json',
    './io': { types: './dist/io.d.ts', import: './dist/io.js' },
    './metadata': './dist/metadata.json',
  };
  for (const name of coreNames) {
    const short = name.slice('@proofscript/'.length);
    exports['./' + short] = {
      types: './dist/packages/' + short + '.d.ts',
      import: './dist/packages/' + short + '.js',
    };
    const backend = {
      'backend-js': 'js',
      'backend-ts': 'ts',
      'backend-rust': 'rust',
      'backend-wasm': 'wasm-core',
    }[short];
    const body = backend
      ? "import{compile as checked}from'@proofscript/compiler';export function compile(options){if(options.target!==undefined&&options.target!==" +
        JSON.stringify(backend) +
        ")throw Error('PSC1_PACKAGE_TARGET');return checked({...options,target:" +
        JSON.stringify(backend) +
        '});}\n'
      : 'export * from ' + JSON.stringify(name) + ';\n';
    write(path.join(stage, 'dist/packages', short + '.js'), body);
    write(
      path.join(stage, 'dist/packages', short + '.d.ts'),
      backend
        ? "import type{CompileOptions,CheckedCompilation}from'@proofscript/compiler';export function compile(options:Omit<CompileOptions,'target'>):CheckedCompilation;\n"
        : body,
    );
  }
  for (const row of originalGraph.graphEvidence.js) {
    const parts = row.specifier.split('/'), short = parts[1], module = parts[3];
    assert.ok(coreNames.includes('@proofscript/' + short));
    for (const variant of ['js', 'ts']) {
      const suffix = variant === 'ts' ? '.ts' : '';
      const forward = 'export * from ' + JSON.stringify(row.specifier + (suffix ? '/ts' : '')) + ';\n';
      for (const extension of ['mjs', 'd.mts'])
        write(path.join(stage, 'dist/generated', short, module + suffix + '.' + extension), forward);
    }
    exports['./' + short + '/generated/*/ts'] = {
      types:'./dist/generated/' + short + '/*.ts.d.mts',import:'./dist/generated/' + short + '/*.ts.mjs'};
    exports['./' + short + '/generated/*'] = {
      types:'./dist/generated/' + short + '/*.d.mts',import:'./dist/generated/' + short + '/*.mjs'};
  }
  write(path.join(stage, 'dist/index.js'), "export * from '@proofscript/compiler';\n");
  write(path.join(stage, 'dist/index.d.ts'), "export * from '@proofscript/compiler';\n");
  for (const ext of ['js', 'd.ts'])
    write(path.join(stage, 'dist/io.' + ext), "export * from '@proofscript/compiler/io';\n");
  write(
    path.join(stage, 'dist/psc.mjs'),
    "#!/usr/bin/env node\nimport{run}from'@proofscript/cli';await run();\n",
  );
  fs.chmodSync(path.join(stage, 'dist/psc.mjs'), 0o755);
  const rootMeta = {
    name: 'proofscript',
    version,
    type: 'module',
    license: 'Apache-2.0',
    engines: { node: '>=22.23.3' },
    description: 'Self-host-qualified modular JS/TS compiler with independent Lean Wasm checking',
    bin: { psc: './dist/psc.mjs', psc1: './dist/psc.mjs', proofscript: './dist/psc.mjs' },
    exports,
    files: ['dist', 'README.md', 'LICENSE', 'NOTICE'],
    bundledDependencies: coreNames,
    dependencies: Object.fromEntries(
      coreNames.map((n) => [n, n === kernelName ? kernelVersion : version]),
    ),
    peerDependencies: JSON.parse(
      fs.readFileSync(path.join(nodes, '@proofscript/compiler/package.json')),
    ).peerDependencies,
    proofscript: {
      npmArchitecture: 'psc1-installed-executable-graph/1',
      defaultKernel: 'wasm',
      defaultEngine: 'js',
      compilerSourceClosureDigest: d.compilerSourceClosureDigest,
      compilerSelfHosting: qualified.qualification,
      fullModularSelfHosting: false,
      finalCrossPlatformRelease: false,
      previewOnly: true,
    },
  };
  rootMeta.peerDependenciesMeta = Object.fromEntries(
    Object.keys(rootMeta.peerDependencies).map((n) => [n, { optional: true }]),
  );
  write(path.join(stage, 'package.json'), json(rootMeta));
  for (const name of ['LICENSE', 'NOTICE']) fs.copyFileSync(name, path.join(stage, name));
  write(
    path.join(stage, 'README.md'),
    [
      '# ProofScript modular compiler preview',
      '',
      'Install the root tarball offline; its 20 core dependencies are bundled. The thin psc command delegates to @proofscript/cli.',
      'Both JS/TS compiler engines execute genuine source-owned modules. The default independent kernel is official Lean 4.35.0 C++ compiled with Emscripten to linear-memory Wasm.',
      'This is a versioned preview. Lower packages expose source APIs and generated/* subpaths; their old ./compiler and checked-backend aliases are removed. Checked conveniences stay under proofscript and @proofscript/compiler.',
      'Python/PHP and target SDKs remain optional. Existing Rust/Wasm compiler executors refuse this newer source cohort. The qualified .13 distribution remains unchanged.',
      'The checked host requires the sealed umbrella installation scope; standalone lower generated modules resolve through ordinary dependencies, but standalone checked-host installation is not qualified.',
      'The exact compiler graph has independently checked Linux JS/TS G1/G2/G3 and complete graph/npm fixed points. See dist/COMPILER_SELFHOST_QUALIFICATION.json and metadata.compilerSelfHosting. Installed-host evidence is separate.',
      'Native binary reproduction, other-platform qualification, the 240-second self-compilation target and universal release remain unqualified. This is a Linux preview, not a universal toolchain release.',
      'Use psc --help, psc init, psc check, and psc build --out out --publication-protocol portable-file. Use --watch to rebuild captured inputs.',
    ].join('\n') + '\n',
  );
  write(path.join(stage, 'dist/COMPILER_SELFHOST_QUALIFICATION.json'), qualified.receiptBytes);
  const bootstrapPin = '@proofscript/compiler/dist/host/DISTRIBUTION_PIN.mjs';
  // Break only the bootstrap seal self-reference. Its trusted code is also pinned per request.
  write(path.join(nodes, bootstrapPin), '// Pending bootstrap seal.\n');
  const manifest = {
    ...originalGraph,
    schema: 'psc1-installed-executable-npm-graph/1',
    version,
    compilerCommit: process.env.GITHUB_SHA,
    sourceGraph: { manifestSha256: input.graph.manifestSha256, manifest: originalGraph },
    compilerSelfHosting: qualified.qualification,
    bootstrapPin,
    entry: Object.fromEntries(
      Object.entries(originalGraph.entry).map(([k, p]) => [k, p.replace(/^node_modules\//, '')]),
    ),
    packages: installedPackages,
    files: files(nodes).filter((row) => row.path !== bootstrapPin),
    publicApiPromotion: false,
    fullModularSelfHosting: false,
  };
  const manifestBytes = Buffer.from(json(manifest)),
    manifestSha256 = sha256(manifestBytes);
  write(path.join(stage, 'dist/COMPILER_GRAPH.json'), manifestBytes);
  write(
    path.join(nodes, bootstrapPin),
    'export const expectedDistributionSha256=' +
      JSON.stringify(sha256(json(d))) +
      ';\n' +
      'export const expectedCompilerSourceClosureDigest=' +
      JSON.stringify(d.compilerSourceClosureDigest) +
      ';\n' +
      'export const expectedGraphManifestSha256=' +
      JSON.stringify(manifestSha256) +
      ';\n' +
      'export const expectedSourceGraphManifestSha256=' +
      JSON.stringify(input.graph.manifestSha256) +
      ';\n',
  );
  verify(nodes, manifestBytes, manifestSha256);
  write(
    path.join(stage, 'dist/metadata.json'),
    json({
      schema: manifest.schema,
      version,
      compilerSourceClosureDigest: d.compilerSourceClosureDigest,
      defaultKernel: 'wasm',
      engine: 'modular-js-ts',
      compilerSelfHosting: qualified.qualification,
      publicApiPromotion: false,
      fullModularSelfHosting: false,
    }),
  );
  write(path.join(out,'compiler-admissions.json'),fs.readFileSync(path.join(graphArchive,'admissions.json')));
  assert.equal(sha256(fs.readFileSync(path.join(out,'compiler-admissions.json'))),manifest.admissionsDigest);
  write(path.join(out,'consumer-descriptors.json'),json(d));
  const tarballs = path.join(out, 'tarballs');
  fs.mkdirSync(tarballs);
  const packed = JSON.parse(
    run('npm', ['pack', stage, '--ignore-scripts', '--json', '--pack-destination', tarballs]),
  );
  assert.equal(packed.length, 1);
  const bytes = fs.readFileSync(path.join(tarballs, packed[0].filename));
  const receipt = {
    schema: 'psc1-modular-installed-package/1',
    testedCommit: process.env.GITHUB_SHA,
    version,
    tarball: packed[0].filename,
    bytes: bytes.length,
    sha256: sha256(bytes),
    manifestSha256,
    consumerDescriptorsSha256: sha256(json(d)),
    compilerAdmissionsSha256: manifest.admissionsDigest,
    sourceGraphManifestSha256: input.graph.manifestSha256,
    compilerSelfHosting: qualified.qualification,
    compilerSourceClosureDigest: d.compilerSourceClosureDigest,
    sourceUnits: manifest.units.length,
    corePackages: coreNames.length,
    installedGraphFiles: manifest.files.length,
    installedGraphBytes: manifest.files.reduce((n, row) => n + row.bytes, 0),
    defaultKernel: 'official-Lean-4.35.0-Emscripten-linear-memory-Wasm',
    referenceCompilerExecuted: false,
    fullModularSelfHosting: false,
    standaloneCheckedHostQualified: false,
  };
  write(path.join(out, 'package-receipt.json'), json(receipt));
  console.log('PSC1_MODULAR_TOOLCHAIN_PACKAGE ' + JSON.stringify(receipt));
}
