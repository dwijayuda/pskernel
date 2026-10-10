import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { loadGeneratedCompiler, stripBootstrapImports } from './sh1-source-snapshot.mjs';
import { checkCoreAdmissions } from './checked-kernel-core.mjs';
import { typeScriptProfileArgs } from './typescript-cli.mjs';

const sourceRef = '963030dc2d154008fccc82e7c8ed29331f138799';
const compilerRef = 'fcd875c8f38db4b0524090bd10c7c2fd5024053d';
const compilerDigest = '5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15';
const nativeDigest = '88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const expectedDecisions = ['accepted', 'rejected-invalid', 'rejected-invalid',
  'rejected-invalid', 'rejected-invalid', 'unsupported', 'accepted'];
const cleanEnv = { ...process.env, NODE_OPTIONS: '', NODE_PATH: '' };
function tag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  const values = Object.getOwnPropertySymbols(value).map(key => value[key]);
  return values.find(value => typeof value === 'string');
}
function diagnostic(value, depth = 0) {
  if (typeof value === 'bigint') return value.toString();
  if (typeof value === 'string') return value.slice(0,512);
  if (value === null || typeof value !== 'object') return value;
  if (depth > 8) return '[depth limit]';
  const out = { tag: tag(value) };
  for (const [key, item] of Object.entries(value).slice(0,20)) out[key] = diagnostic(item, depth+1);
  return out;
}
function unwrap(value, stage) {
  if (tag(value) === 'ok') return value.value;
  const error = new Error('PSC0_CORE_JS_' + stage);
  error.detail = diagnostic(value); throw error;
}
function run(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: 'utf8', maxBuffer: 16*1024*1024,
    timeout: 60000, killSignal: 'SIGKILL', env: cleanEnv, ...options });
  if (result.error || result.status !== 0) {
    const error = new Error('PSC0_CORE_JS_CHILD: ' + (result.error?.code ?? result.signal ?? result.status));
    error.detail = { command: path.basename(command), stdout: result.stdout?.slice(-16000),
      stderr: result.stderr?.slice(-16000) };
    throw error;
  }
  return result.stdout;
}

async function exerciseRuntime(file, digest) {
  const bytes = await readFile(file); assert.equal(sha(bytes), digest);
  const start = performance.now();
  // This is release-controlled experimental generated code. A Node subprocess
  // provides lifecycle separation; it is not an arbitrary-JavaScript sandbox.
  const kernel = await import('data:text/javascript;base64,' + bytes.toString('base64'));
  const importedMs = performance.now() - start;
  assert.equal(kernel.psKernelTargetIdentityV1.contract, 'KernelContract-v1');
  assert.equal(kernel.psKernelTargetIdentityV1.leanVersion, '4.34.0');
  assert.equal(tag(kernel.psKernelProviderDefault.nativeEvaluator), 'none');
  assert.equal(kernel.psKernelNatGcd(9007199254740993n, 3n), 3n);
  assert.equal(kernel.psKernelCoreSemanticRoot, true);
  const decisions = expectedDecisions.map((_, index) => kernel.psKernelJsProbeDecision(BigInt(index)));
  assert.deepEqual(decisions, expectedDecisions);
  process.stdout.write(JSON.stringify({ decisions, importedMs, elapsedMs: performance.now()-start,
    maxRssKiB: process.resourceUsage().maxRSS, nativeEvaluator: 'none',
    largeNaturalExact: true, node: process.version }) + '\n');
}

async function produce(providerRoot, compilerSearch, tsc, out) {
  await mkdir(out, { recursive: true });
  const evidence = { schemaVersion: 1, kind: 'psc0-core-javascript-feasibility',
    status: 'running', sourceRef, compilerRef, compilerSha256: compilerDigest,
    node: process.version, lean: '4.34.0', typescript: '7.0.2',
    semanticCoreModified: false, productDefaultChanged: false,
    qualifiedProvider: false, generatedKernelSelfHostFixedPoint: false,
    compilerSemanticPreservationProved: false, fullCompilerAdmissionsReplay: false,
    canonicalProviderAdapterCompiled: false, stages: [] };
  let stage = 'inputs';
  let currentSource;
  const save = () => writeFile(path.join(out, 'evidence.json'), JSON.stringify(evidence,null,2)+'\n');
  const begin = async name => {
    stage = name; evidence.stages.push({ name, startedAt: new Date().toISOString() });
    process.stdout.write('PSC0_CORE_JS_STAGE: ' + name + '\n'); await save();
  };
  try {
    await begin('inputs');
    assert.equal(process.version, 'v22.23.3');
    assert.equal(run('git', ['rev-parse', 'HEAD'], {cwd: providerRoot}).trim(), sourceRef);
    assert.equal(run('lake', ['env','lean','--githash'], {cwd: providerRoot}).trim(),
      '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
    assert.equal(run(process.execPath, [tsc, '--version']).trim(), 'Version 7.0.2');
    const binary = path.join(providerRoot, '.lake/build/bin/psc_kernel_core_provider');
    assert.equal(sha(await readFile(binary)), nativeDigest);
    let compilerFile;
    async function find(directory) {
      for (const entry of await readdir(directory,{withFileTypes:true})) {
        const file = path.join(directory,entry.name);
        if (entry.isDirectory()) await find(file);
        else if (!compilerFile && entry.isFile() && file.endsWith('.js') &&
          sha(await readFile(file)) === compilerDigest) compilerFile=file;
      }
    }
    await find(compilerSearch); assert(compilerFile, 'qualified F bytes missing');
    const {compiler} = await loadGeneratedCompiler(compilerFile, {expectedSha256:compilerDigest});
    const ordered = []; const visited = new Set(); const active = new Set();
    async function visit(moduleName) {
      assert(/^Ps\.KernelCore(?:\.[A-Za-z][A-Za-z0-9_]*)+$/u.test(moduleName), 'outside selected Core');
      if (visited.has(moduleName)) return;
      assert(!active.has(moduleName), 'Core import cycle'); active.add(moduleName);
      const relative = 'packages/pskernel-core/src/' + moduleName.replaceAll('.', '/') + '.lean';
      const bytes = await readFile(path.join(providerRoot,relative)); const source = bytes.toString('utf8');
      assert(Buffer.from(source,'utf8').equals(bytes), 'invalid source UTF-8');
      for (const line of source.split(/\r?\n/u)) {
        if (/^\s*import\s/u.test(line)) {
          const match = line.match(/^import ([A-Za-z0-9_.]+)\s*$/u);
          assert(match, 'unsupported import line'); await visit(match[1]);
        }
      }
      active.delete(moduleName); visited.add(moduleName);
      ordered.push({path:relative,source,sha256:sha(bytes)});
    }
    await visit('Ps.KernelCore.SelfHost'); assert.equal(ordered.length,79);
    const fixtureRelative = 'test/fixtures/KernelJsProbe.lean';
    const fixture = await readFile(path.join(root,fixtureRelative),'utf8');
    ordered.push({path:fixtureRelative,source:fixture,sha256:sha(fixture)});
    evidence.sourceFiles=ordered.map(({path:sourcePath,sha256})=>({path:sourcePath,sha256}));
    evidence.sourceClosureSha256=sha(JSON.stringify(evidence.sourceFiles));
    evidence.coreModuleCount=79; evidence.probeModuleCount=1;
    await save();

    await begin('native-public-api-comparison');
    const driver = fixture + '\ndef main : IO Unit := do\n' +
      expectedDecisions.map((_,index)=>'  IO.println (psKernelJsProbeDecision ' + index + ')').join('\n') + '\n';
    const nativeSource=path.join(out,'native-probe.lean'); await writeFile(nativeSource,driver);
    const nativeStart=performance.now();
    const nativeOutput=run('lake',['env','lean','--run',nativeSource],{cwd:providerRoot});
    const nativeDecisions=nativeOutput.trim().split(/\r?\n/u);
    assert.deepEqual(nativeDecisions,expectedDecisions);
    evidence.nativeComparison={decisions:nativeDecisions,elapsedMs:performance.now()-nativeStart};

    await begin('generated-F-preparation');
    let state=compiler.psCompilerPreparationStart(compiler.PsCompilerSourceKind.lean);
    for (const item of ordered) {
      currentSource=item.path;
      const start=performance.now();
      const source=stripBootstrapImports(item.source);
      const attempted=compiler.psCompilerPreparationStep(state,source);
      if (tag(attempted) !== 'ok') {
        // Diagnose only the first failed module using the same pure API and
        // unchanged prior environment. Never rewrite input or bypass refusal.
        try {
        const parsed=unwrap(compiler.psCompilerParseSource(compiler.PsCompilerSourceKind.lean,source),'DIAGNOSTIC_PARSE');
        let declarations=parsed.declarations; let prefix=state; let index=0;
        while (tag(declarations)==='cons') {
          const declaration=declarations.head;
          const single={imports:parsed.imports,declarations:compiler.List.cons(declaration,compiler.List.nil())};
          const next=compiler.psCompilerPreparationStepParsed(prefix,single);
          if (tag(next)!=='ok') {
            const parts=[]; let names=declaration.name?.segments;
            while (tag(names)==='cons') { parts.push(names.head); names=names.tail; }
            evidence.firstFailedDeclaration={index,name:parts.join('.'),kind:tag(declaration),
              sourceSpan:diagnostic(declaration.span),error:diagnostic(next),value:diagnostic(declaration.value)};
            process.stdout.write('PSC0_CORE_JS_FAILED_DECLARATION: ' + JSON.stringify(evidence.firstFailedDeclaration) + '\n');
            break;
          }
          prefix=next.value; declarations=declarations.tail; index++;
        }
        } catch (diagnosticError) {
          evidence.declarationLocatorError=diagnosticError.message;
        }
      }
      state=unwrap(attempted, 'PREPARE');
      process.stdout.write('PSC0_CORE_JS_PREPARED: ' + item.path + ' ' + Math.round(performance.now()-start) + 'ms\n');
    }
    currentSource=undefined;
    const prepared=unwrap(compiler.psCompilerPreparationFinish(state),'PREPARATION_FINISH');
    const admissions=unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared),'ADMISSIONS');
    assert.equal(typeof admissions,'string');
    await writeFile(path.join(out,'kernel.admissions.json'),admissions);
    evidence.canonicalAdmissionsSha256=sha(admissions);

    await begin('native-admission-of-generated-candidates');
    assert.equal(sha(await readFile(binary)),nativeDigest);
    const admission=checkCoreAdmissions(admissions,{binaryPath:binary,timeoutMs:60000,workingDirectory:providerRoot});
    assert.equal(sha(await readFile(binary)),nativeDigest);
    evidence.nativeAdmission=admission; assert.equal(admission.accepted,true);

    await begin('same-original-ir-checked-typescript');
    const options=compiler.psIrCheckDefaultOptions;
    const checked=compiler.psIrCheckOptionsWithLimits(options.maxSteps,options.maxTypeSteps,options.maxFindings);
    const typeScript=unwrap(compiler.psCompilerCheckedTypeScriptFromPrepared(checked,prepared),'CHECKED_EMISSION');
    assert.equal(typeof typeScript,'string');
    evidence.originalIrCheckedBeforeEmission=true;
    const tsPath=path.join(out,'kernel.ts'); await writeFile(tsPath,typeScript);
    evidence.typeScriptSha256=sha(typeScript);

    await begin('typescript7-target-validation');
    run(process.execPath,[tsc,...typeScriptProfileArgs([tsPath,'--target','ES2022','--module','ES2022',
      '--moduleResolution','bundler','--strict','--noEmitOnError','--skipLibCheck','--pretty','false'],'7.0.2')],
      {timeout:120000});
    const jsPath=path.join(out,'kernel.js'); const js=await readFile(jsPath);
    evidence.javascriptSha256=sha(js); evidence.javascriptBytes=js.length;
    evidence.typescriptValidationPassed=true;

    await begin('generated-js-public-api-comparison');
    const runtime=run(process.execPath,['--max-old-space-size=1024',fileURLToPath(import.meta.url),
      'runtime',jsPath,evidence.javascriptSha256],{timeout:60000});
    evidence.generatedRuntime=JSON.parse(runtime);
    assert.deepEqual(evidence.generatedRuntime.decisions,nativeDecisions);
    evidence.boundedPublicApiParity=true;
    evidence.status='feasibility-passed'; await save();
    process.stdout.write('PSC0_CORE_JS_FEASIBILITY: PASS\n');
  } catch(error) {
    evidence.status='blocked'; evidence.failure={stage,source:currentSource,message:error.message,detail:error.detail};
    await save(); process.stderr.write('PSC0_CORE_JS_FEASIBILITY: BLOCKED ' + JSON.stringify(evidence.failure) + '\n');
    process.exitCode=1;
  }
}

const [mode,...args]=process.argv.slice(2);
if (mode==='runtime' && args.length===2) await exerciseRuntime(path.resolve(args[0]),args[1]);
else if (mode==='produce' && args.length===4) await produce(...args.map(value=>path.resolve(value)));
else throw new Error('usage: kernel-js-probe.mjs produce <provider-root> <F-artifact-directory> <tsc> <out> | runtime <kernel.js> <sha256>');
