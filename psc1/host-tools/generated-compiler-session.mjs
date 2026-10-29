// Host-only orchestration. Generated wire data cannot choose tools or publish.
import fs from 'node:fs';
import { requireSupportedRuntime, syntaxArguments, runtimeArguments } from './runtime-policy.mjs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import {
  createCompilerHostSession,
  compilerSourceClosureDigest,
} from './compiler-host-protocol.mjs';
import { validateClosureCounts } from './contracts/compiler-closure.mjs';

import { openPublicationStore } from './transactional-publication.mjs';
import { prepareCheckedTarget } from './checked-targets.mjs';

const sha = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = (code) => {
  throw new Error(code);
};
const json = (value) => JSON.stringify(value, null, 2) + '\n';
const clone = (value) => JSON.parse(JSON.stringify(value));
const inspect = (file) => {
  try {
    return fs.lstatSync(file);
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw e;
  }
};
const boundedRead = (file) => {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.size === 0 || stat.size > 128 * 1024 * 1024)
    fail('PSC1_SERVICE_STAGED_FILE_INVALID');
  return fs.readFileSync(file);
};
function identity(file, expected) {
  if (
    typeof file !== 'string' ||
    !path.isAbsolute(file) ||
    !/^[0-9a-f]{64}$/.test(expected || '') ||
    !fs.lstatSync(file).isFile() ||
    sha(fs.readFileSync(file)) !== expected
  )
    fail('PSC1_SERVICE_TOOL_IDENTITY_CHANGED');
  return { path: file, sha256: expected };
}
function publicationFault(phase) {
  if (process.env.PSC1_TEST_SERVICE_PUBLICATION_FAIL_AT === phase)
    fail('PSC1_SERVICE_INJECTED_PUBLICATION_FAILURE:' + phase);
}
function inventory(stage) {
  return fs
    .readdirSync(stage)
    .sort()
    .map((name) => {
      if (!/^[a-z][a-z0-9.-]*$/.test(name)) fail('PSC1_SERVICE_ARTIFACT_PATH');
      const bytes = boundedRead(path.join(stage, name));
      return { path: name, bytes: bytes.length, sha256: sha(bytes) };
    });
}
function checkFiles(stage, expected) {
  if (json(inventory(stage)) !== json(expected)) fail('PSC1_SERVICE_ARTIFACT_CHANGED');
}

/** Caller is the trusted host. Only this object can consume its own actual
 * generated-process result and independent-checker state. A copied receipt or
 * hash, generated JSON field, or fabricated wrapper cannot publish a session.
 */
export function createGeneratedJsCompilerSession({
  requestId,
  sources,
  entryModule,
  assurance,
  outputAbi = 'scalar',
  target = 'js',
  publicationProtocol = 'legacy-symlink',
  evidence = 'full',
  operation = 'compile',
  serviceKind = 'js-adapter',
  typescript,
  rust,
  componentTools,
  optionalProvider,
  serviceFile,
  serviceExecute,
  serviceSha256,
  runnerFile,
  runnerSha256,
  checkerExecutable,
  checkerSha256,
  checkerScriptFile,
  checkerScriptSha256,
  publicationRoot,
  serviceDependencies = [],
  additionalCheckers = [],
}) {
  const sessionStarted = performance.now();
  const timings = {
    resourceVerificationMs: 0,
    compilerProcessMs: 0,
    independentKernelMs: 0,
    targetMs: 0,
    evidenceMs: 0,
  };
  requireSupportedRuntime();
  if (
    typeof requestId !== 'string' ||
    !requestId ||
    typeof entryModule !== 'string' ||
    !['checked', 'ordinary-checked'].includes(assurance) ||
    !['full', 'minimal'].includes(evidence) ||
    !['compile', 'check'].includes(operation) ||
    !['scalar', 'io-dispatcher'].includes(outputAbi) ||
    !['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php'].includes(target) ||
    !['js-adapter', 'unified-embedded', 'unified-bundle'].includes(serviceKind) ||
    (target !== 'js' && serviceKind === 'js-adapter') ||
    (serviceExecute !== undefined && typeof serviceExecute !== 'function') ||
    !path.isAbsolute(publicationRoot || '')
  )
    fail('PSC1_SERVICE_REQUEST_INVALID');
  const compilerTarget =
    target === 'wasm-component' ? 'wasm-core' : ['python', 'php'].includes(target) ? 'js' : target;
  const captured = clone(sources);
  const sourceClosureDigest = compilerSourceClosureDigest(captured);
  const grammar = captured[0].kind;
  if (
    !captured.every((row) => row.kind === grammar) ||
    !captured.some((row) => row.module === entryModule)
  )
    fail('PSC1_SERVICE_CAPTURE_INVALID');
  // Coalesce aliases within this capture, never across verification boundaries.
  const capturedTools = new Map();
  const captureIdentity = (file, expected) => {
    const prior = capturedTools.get(file);
    if (prior) {
      if (prior.sha256 !== expected) fail('PSC1_SERVICE_TOOL_IDENTITY_CHANGED');
      return prior;
    }
    const pin = identity(file, expected);
    capturedTools.set(file, pin);
    return pin;
  };
  const tools = {
    service: captureIdentity(serviceFile, serviceSha256),
    runner: captureIdentity(runnerFile, runnerSha256),
    checker: captureIdentity(checkerExecutable, checkerSha256),
    node:
      checkerExecutable === process.execPath
        ? captureIdentity(process.execPath, checkerSha256)
        : captureIdentity(process.execPath, sha(fs.readFileSync(process.execPath))),
  };
  if (checkerScriptFile !== undefined)
    tools.checkerScript = captureIdentity(checkerScriptFile, checkerScriptSha256);
  // Trusted host-selected dependencies bind imported generated engine bytes too.
  // Generated wire fields cannot add paths or choose a checker.
  if (!Array.isArray(serviceDependencies)) fail('PSC1_SERVICE_DEPENDENCIES_INVALID');
  serviceDependencies.forEach((tool, index) => {
    if (!tool || typeof tool !== 'object') fail('PSC1_SERVICE_DEPENDENCIES_INVALID');
    tools['dependency' + index] = captureIdentity(tool.path, tool.sha256);
  });
  if (!Array.isArray(additionalCheckers) || additionalCheckers.length > 2)
    fail('PSC1_SERVICE_ADDITIONAL_CHECKERS_INVALID');
  const extraChecks = additionalCheckers.map((checker, index) => {
    if (
      !checker ||
      !/^[a-z][a-z0-9-]{0,31}$/.test(checker.name || '') ||
      additionalCheckers.slice(0, index).some((prior) => prior.name === checker.name)
    )
      fail('PSC1_SERVICE_ADDITIONAL_CHECKERS_INVALID');
    const script = captureIdentity(checker.scriptFile, checker.scriptSha256);
    tools['additional-checker-' + index] = script;
    return { name: checker.name, script };
  });
  if (typescript) {
    if (target !== 'ts' || !Array.isArray(typescript.pins))
      fail('PSC1_SERVICE_TYPESCRIPT_CONSUMER');
    typescript.pins.forEach((pin, index) => {
      tools['typescript-' + index] = captureIdentity(pin.path, pin.sha256);
    });
    if (
      ![typescript.entry, typescript.executable].every((file) =>
        typescript.pins.some((pin) => pin.path === file),
      )
    )
      fail('PSC1_SERVICE_TYPESCRIPT_ENTRY');
  }
  if (rust) {
    if (target !== 'rust' || !Array.isArray(rust.pins)) fail('PSC1_SERVICE_RUST_CONSUMER');
    rust.pins.forEach((pin, index) => {
      tools['rust-' + index] = captureIdentity(pin.path, pin.sha256);
    });
    if (![rust.rustc, rust.inspector].every((file) => rust.pins.some((pin) => pin.path === file)))
      fail('PSC1_SERVICE_RUST_ENTRY');
  }
  for (const [label, consumer] of [
    ['component', componentTools],
    ['provider', optionalProvider],
  ]) {
    if (!consumer) continue;
    if (
      !Array.isArray(consumer.pins) ||
      (label === 'component' ? target !== 'wasm-component' : !['python', 'php'].includes(target))
    )
      fail('PSC1_SERVICE_DISPATCH_CONSUMER');
    consumer.pins.forEach((pin, index) => {
      tools[label + '-' + index] = captureIdentity(pin.path, pin.sha256);
    });
    if (!consumer.pins.some((pin) => pin.path === consumer.executable))
      fail('PSC1_SERVICE_DISPATCH_ENTRY');
  }
  const additionalAdmissions = [];
  const verificationTools = [...capturedTools.values()];
  const verifyTools = () => {
    const started = performance.now();
    try {
      verificationTools.forEach((tool) => identity(tool.path, tool.sha256));
    } finally {
      timings.resourceVerificationMs += performance.now() - started;
    }
  };
  const scalarRequest = [
    'psc1-compiler-service/1',
    requestId,
    sourceClosureDigest,
    grammar,
    assurance,
    entryModule,
    captured.map((row) => [row.module, row.text]),
  ];
  const inner =
    outputAbi === 'scalar'
      ? scalarRequest
      : ['psc1-compiler-service/2', ...scalarRequest.slice(1), 'io-dispatcher'];
  const requestText = JSON.stringify(
    operation === 'check'
      ? ['psc1-check-service/1', 'check', inner]
      : serviceKind === 'js-adapter'
        ? inner
        : ['psc1-unified-compiler-service/2', compilerTarget, inner],
  );
  const request = Object.freeze({
    requestId,
    sourceClosureDigest,
    grammar,
    assurance,
    entryModule,
    target,
    ...(compilerTarget === target ? {} : { compilerTarget }),
    ...(outputAbi === 'scalar' ? {} : { outputAbi }),
    requestSha256: sha(requestText),
    serviceSha256,
    runnerSha256,
    checkerSha256,
    nodeVersion: process.version,
    nodeSha256: tools.node.sha256,
    ...(checkerScriptFile ? { checkerScriptSha256 } : {}),
    ...(extraChecks.length
      ? {
          additionalCheckers: extraChecks.map((c) => ({
            name: c.name,
            scriptSha256: c.script.sha256,
          })),
        }
      : {}),
  });
  const root = path.resolve(publicationRoot);
  const publication =
    operation === 'check' ? null : openPublicationStore(root, publicationProtocol);
  if (operation === 'check') fs.mkdirSync(root, { recursive: true, mode: 0o700 });
  const stage = fs.mkdtempSync(
    path.join(root, operation === 'check' ? '.check-' : 'generations/.stage-'),
  );
  fs.chmodSync(stage, 0o700);
  let state = 'pending',
    sealedFiles,
    receipt,
    candidate,
    targetArtifact;
  const events = [];
  let failureDirectory = null,
    sealedAttempt = null;
  function retainFailure(error) {
    try {
      const failed = path.join(root, 'generations', 'failed-' + crypto.randomUUID());
      if (inspect(stage)) fs.renameSync(stage, failed);
      else fs.mkdirSync(failed);
      failureDirectory = failed;
      fs.writeFileSync(
        path.join(failed, 'failure.json'),
        json({
          schema: 'psc1-generated-session-failure/1',
          request,
          state,
          failure: error.message,
          events,
          sealedAttempt,
          authoritative: false,
          publication: state === 'published' ? 'committed' : 'not-committed',
        }),
      );
    } catch (loggingError) {
      events.push({ role: 'host-diagnostic', error: loggingError.message });
    }
  }
  const run = (role, args, executable = process.execPath, digestEnv) => {
    if (
      ![
        process.execPath,
        ...(typescript ? [typescript.executable] : []),
        ...(rust ? [rust.rustc, rust.inspector] : []),
        ...(componentTools ? [componentTools.executable] : []),
        ...(optionalProvider ? [optionalProvider.executable] : []),
      ].includes(executable)
    )
      fail('PSC1_SERVICE_EXECUTABLE');
    const started = Date.now();
    const env = { ...process.env };
    for (const key of Object.keys(env))
      if (
        key === 'NODE_OPTIONS' ||
        key.startsWith('RUST') ||
        key.startsWith('CARGO') ||
        key === 'LD_PRELOAD' ||
        key === 'LD_LIBRARY_PATH' ||
        key.startsWith('DYLD_')
      )
        delete env[key];
    if ([componentTools?.executable, optionalProvider?.executable].includes(executable))
      env.PSC1_OPTIONAL_PARENT_PID = String(process.pid);
    else delete env.PSC1_OPTIONAL_PARENT_PID;
    if (digestEnv !== undefined) {
      if (
        role !== 'optional-provider' ||
        Object.keys(digestEnv).join(',') !== 'PSC1_BACKEND_REQUEST_SHA256' ||
        !/^[a-f0-9]{64}$/.test(digestEnv.PSC1_BACKEND_REQUEST_SHA256)
      )
        fail('PSC1_SERVICE_PROVIDER_ENV');
      env.PSC1_BACKEND_REQUEST_SHA256 = digestEnv.PSC1_BACKEND_REQUEST_SHA256;
    } else delete env.PSC1_BACKEND_REQUEST_SHA256;
    if (componentTools || optionalProvider) verifyTools();
    const result = spawnSync(
      executable,
      executable === process.execPath ? runtimeArguments(args) : args,
      {
        encoding: 'utf8',
        env,
        timeout: 240000,
        maxBuffer: 32 * 1024 * 1024,
        killSignal: 'SIGKILL',
        windowsHide: true,
      },
    );
    if (componentTools || optionalProvider) verifyTools();
    events.push({
      role,
      executable,
      args: [...args],
      status: result.status,
      signal: result.signal,
      elapsedMs: Date.now() - started,
      error: result.error?.message || null,
    });
    if (result.error || result.status !== 0) {
      fs.writeFileSync(path.join(stage, role + '.stderr.txt'), result.stderr || '');
      fs.writeFileSync(path.join(stage, role + '.stdout.txt'), result.stdout || '');
      fail(
        'PSC1_SERVICE_PROCESS_FAILED:' +
          role +
          ':' +
          (result.error?.code || result.signal || result.status) +
          ':' +
          (result.stderr || result.stdout || '').slice(0, 8192),
      );
    }
    return result.stdout;
  };
  function admit(admissions, admissionTarget, wire) {
    const checkerSession = createCompilerHostSession({
      requestId,
      target: admissionTarget,
      sources: captured,
      canonicalAdmissions: admissions,
      checkerExecutable,
      checkerScript: checkerScriptFile,
    });
    events.push({
      role: 'independent-checker',
      executable: checkerExecutable,
      checkerSha256,
      admissionsSha256: sha(admissions),
      state: 'before',
    });
    const kernelStarted = performance.now();
    receipt = checkerSession.admit(JSON.stringify(wire));
    timings.independentKernelMs = performance.now() - kernelStarted;
    verifyTools();
    events.push({
      role: 'independent-checker',
      state: 'accepted',
      checkerCommit: receipt.checkerCommit,
      admissionsSha256: receipt.admissionsDigest,
    });
    // Mandatory independent official Lean admission above is preserved. Extra host-selected providers
    // check the identical captured canonical bytes before any publication can occur.
    for (const checker of extraChecks) {
      verifyTools();
      const started = Date.now();
      const checked = spawnSync(process.execPath, runtimeArguments([checker.script.path]), {
        input: admissions,
        encoding: 'utf8',
        timeout: 120000,
        maxBuffer: 32 * 1024 * 1024,
        killSignal: 'SIGKILL',
        windowsHide: true,
      });
      events.push({
        role: 'additional-independent-checker',
        name: checker.name,
        executable: process.execPath,
        scriptSha256: checker.script.sha256,
        status: checked.status,
        signal: checked.signal,
        elapsedMs: Date.now() - started,
        admissionsSha256: sha(admissions),
        error: checked.error?.message || null,
      });
      verifyTools();
      if (checked.error || checked.status !== 0) fail('PSC1_SERVICE_ADDITIONAL_CHECKER_PROCESS');
      let result;
      try {
        result = JSON.parse(checked.stdout);
      } catch {
        fail('PSC1_SERVICE_ADDITIONAL_CHECKER_JSON');
      }
      if (
        result.protocol !== 'pskernel-lean/1' ||
        result.provider !== 'lean4-cpp' ||
        result.leanVersion !== '4.35.0' ||
        result.leanCommit !== receipt.checkerCommit ||
        result.profile !== 'lean4.35-core' ||
        result.accepted !== true
      )
        fail('PSC1_SERVICE_ADDITIONAL_CHECKER_REFUSED');
      additionalAdmissions.push({
        name: checker.name,
        scriptSha256: checker.script.sha256,
        admissionsSha256: sha(admissions),
        checkerCommit: result.leanCommit,
        accepted: true,
        responseSha256: sha(checked.stdout),
      });
    }
  }
  return Object.freeze({
    request,
    stagingDirectory: stage,
    get state() {
      return state;
    },
    get events() {
      return clone(events);
    },
    get failureDirectory() {
      return failureDirectory;
    },
    execute() {
      if (state !== 'pending') fail('PSC1_SERVICE_SESSION_CONSUMED');
      state = 'running';
      try {
        verifyTools();
        fs.writeFileSync(path.join(stage, 'request.json'), requestText);
        const compilerStarted = performance.now();
        const stdout = serviceExecute
          ? (() => {
              const response = serviceExecute(requestText);
              if (typeof response !== 'string' || Buffer.byteLength(response) > 128 * 1024 * 1024)
                fail('PSC1_SERVICE_RESPONSE_LIMIT');
              fs.writeFileSync(path.join(stage, 'candidate.json'), response, { flag: 'wx' });
              events.push({
                role: 'generated-compiler',
                transport: 'private-loaded-engine',
                elapsedMs: performance.now() - compilerStarted,
                status: 0,
              });
              return JSON.stringify({
                protocol: 'psc1-generated-service-run/1',
                serviceSha256,
                requestSha256: request.requestSha256,
                responseSha256: sha(response),
              });
            })()
          : run('generated-compiler', [
              runnerFile,
              serviceFile,
              serviceSha256,
              ...(serviceKind === 'js-adapter'
                ? []
                : [serviceKind === 'unified-embedded' ? 'embedded' : 'bundle']),
              path.join(stage, 'request.json'),
              path.join(stage, 'candidate.json'),
            ]);
        timings.compilerProcessMs = performance.now() - compilerStarted;
        verifyTools();
        if (sha(boundedRead(path.join(stage, 'request.json'))) !== request.requestSha256)
          fail('PSC1_SERVICE_REQUEST_CHANGED');
        const raw = boundedRead(path.join(stage, 'candidate.json'));
        const execution = JSON.parse(stdout.trim());
        if (
          execution.protocol !== 'psc1-generated-service-run/1' ||
          execution.serviceSha256 !== serviceSha256 ||
          execution.requestSha256 !== request.requestSha256 ||
          execution.responseSha256 !== sha(raw)
        )
          fail('PSC1_SERVICE_EXECUTION_MISMATCH');
        candidate = JSON.parse(raw.toString('utf8'));
        if (!candidate || typeof candidate !== 'object' || Array.isArray(candidate))
          fail('PSC1_SERVICE_RESPONSE_FIELDS');
        if (candidate.status !== 'candidate')
          fail('PSC1_SERVICE_COMPILER_REFUSED:' + candidate.phase);
        if (operation === 'check') {
          const fields = [
            'protocol',
            'status',
            'candidateOnly',
            'admission',
            'requestId',
            'sourceClosureDigest',
            'grammar',
            'assurance',
            'admissions',
            'sourceDeclarations',
            'logicalDeclarations',
            'partialNames',
            'origins',
            'irValidation',
            'cache',
            'preparationMs',
          ];
          if (
            Object.keys(candidate).sort().join(',') !== fields.sort().join(',') ||
            candidate.protocol !== 'psc1-check-candidate/1' ||
            candidate.status !== 'candidate' ||
            candidate.candidateOnly !== true ||
            candidate.admission !== 'not-run' ||
            candidate.requestId !== requestId ||
            candidate.sourceClosureDigest !== sourceClosureDigest ||
            candidate.grammar !== grammar ||
            candidate.assurance !== assurance ||
            candidate.irValidation !== 'strict-original-no-transform' ||
            typeof candidate.admissions !== 'string' ||
            !Array.isArray(candidate.origins) ||
            candidate.origins.length !== captured.length
          )
            fail('PSC1_SERVICE_CHECK_RESPONSE');
          let count = 0;
          for (let i = 0; i < captured.length; i++) {
            const row = candidate.origins[i];
            if (
              !Array.isArray(row) ||
              row.length !== 4 ||
              row[0] !== captured[i].module ||
              row[1] !== Buffer.byteLength(captured[i].text) ||
              !Array.isArray(row[3])
            )
              fail('PSC1_SERVICE_ORIGIN_MISMATCH');
            for (let j = 0; j < row[3].length; j++) {
              const origin = row[3][j];
              if (
                !Array.isArray(origin) ||
                origin.length !== 5 ||
                origin[0] !== j ||
                typeof origin[1] !== 'string' ||
                !Array.isArray(origin[4])
              )
                fail('PSC1_SERVICE_ORIGIN_MISMATCH');
              for (let k = 0; k < origin[4].length; k++) {
                if (
                  !Array.isArray(origin[4][k]) ||
                  origin[4][k].length !== 2 ||
                  origin[4][k][0] !== k ||
                  typeof origin[4][k][1] !== 'string'
                )
                  fail('PSC1_SERVICE_ORIGIN_MISMATCH');
                count++;
              }
            }
          }
          validateClosureCounts(
            {
              assurance,
              sourceCoreDeclarations: candidate.sourceDeclarations,
              coreDeclarations: candidate.logicalDeclarations,
              partialNames: candidate.partialNames,
            },
            count,
            assurance,
          );
          admit(candidate.admissions, 'check', {
            protocol: 'psc1-compiler-host/1',
            op: 'admit',
            requestId,
            target: 'check',
            sourceClosureDigest,
            admissions: candidate.admissions,
          });
          verifyTools();
          state = 'admitted-check-only';
          return Object.freeze({
            ...request,
            logicalAdmission: 'accepted',
            admissionsSha256: receipt.admissionsDigest,
            irValidation: 'strict-original-no-transform',
            targetGeneration: 'not-run',
            productionPublication: 'not-requested',
            cache: candidate.cache,
            preparationMs: candidate.preparationMs,
            timings: { ...timings, sessionMs: performance.now() - sessionStarted },
            ...(extraChecks.length ? { additionalAdmissions: clone(additionalAdmissions) } : {}),
          });
        }
        const fields = [
          'admission',
          'admissionRequest',
          'assurance',
          'candidateOnly',
          'grammar',
          'logicalDeclarations',
          'originalIr',
          'origins',
          'partialNames',
          'protocol',
          'publicNames',
          'requestId',
          'runtimeRequirements',
          'source',
          'sourceClosureDigest',
          'sourceDeclarations',
          'specializedIr',
          'status',
          'target',
          ...(outputAbi === 'scalar' ? [] : ['outputAbi']),
        ];
        if (Object.keys(candidate).sort().join(',') !== fields.sort().join(','))
          fail('PSC1_SERVICE_RESPONSE_FIELDS');
        if (candidate.status !== 'candidate')
          fail('PSC1_SERVICE_COMPILER_REFUSED:' + candidate.phase);
        for (const [key, value] of Object.entries({
          protocol: outputAbi === 'scalar' ? 'psc1-compiler-service/1' : 'psc1-compiler-service/2',
          ...(outputAbi === 'scalar' ? {} : { outputAbi }),
          requestId,
          sourceClosureDigest,
          grammar,
          assurance,
          target: compilerTarget,
          candidateOnly: true,
          admission: 'not-run',
        })) {
          if (candidate[key] !== value) fail('PSC1_SERVICE_RESPONSE_MISMATCH:' + key);
        }
        if (
          !Array.isArray(candidate.origins) ||
          candidate.origins.length !== captured.length ||
          typeof candidate.source !== 'string' ||
          !candidate.source ||
          !Array.isArray(candidate.publicNames) ||
          candidate.publicNames.some((name) => typeof name !== 'string' || !name) ||
          new Set(candidate.publicNames).size !== candidate.publicNames.length
        )
          fail('PSC1_SERVICE_RESPONSE_SHAPE');
        let sourceCount = 0;
        candidate.origins.forEach((row, index) => {
          if (
            !Array.isArray(row) ||
            row.length !== 4 ||
            row[0] !== captured[index].module ||
            row[1] !== Buffer.byteLength(captured[index].text) ||
            !Array.isArray(row[3])
          )
            fail('PSC1_SERVICE_ORIGIN_MISMATCH');
          row[3].forEach((origin, sourceIndex) => {
            if (
              !Array.isArray(origin) ||
              origin.length !== 5 ||
              origin[0] !== sourceIndex ||
              typeof origin[1] !== 'string' ||
              !Array.isArray(origin[4])
            )
              fail('PSC1_SERVICE_ORIGIN_MISMATCH');
            origin[4].forEach((member, memberIndex) => {
              if (
                !Array.isArray(member) ||
                member.length !== 2 ||
                member[0] !== memberIndex ||
                typeof member[1] !== 'string'
              )
                fail('PSC1_SERVICE_ORIGIN_MISMATCH');
              sourceCount++;
            });
          });
        });
        validateClosureCounts(
          {
            assurance,
            sourceCoreDeclarations: candidate.sourceDeclarations,
            coreDeclarations: candidate.logicalDeclarations,
            partialNames: candidate.partialNames,
          },
          sourceCount,
          assurance,
        );
        for (const graph of [candidate.originalIr, candidate.specializedIr]) {
          if (
            !Array.isArray(graph) ||
            graph.length !== 5 ||
            graph[0] !== 'psc1-ir/1' ||
            !graph.slice(1).every(Array.isArray)
          )
            fail('PSC1_SERVICE_IR_SHAPE');
        }
        const admissions = candidate.admissionRequest?.admissions;
        admit(admissions, compilerTarget, candidate.admissionRequest);
        const targetStarted = performance.now();
        targetArtifact = prepareCheckedTarget(
          stage,
          candidate,
          { target, typescript, rust, componentTools, optionalProvider, outputAbi },
          run,
        );
        if (['js', 'ts', 'wasm-core'].includes(target)) {
          if (target !== 'wasm-core')
            run('target-syntax', syntaxArguments(path.join(stage, targetArtifact.runtimeFile)));
          const apiCode =
            "import {pathToFileURL} from 'node:url';" +
            'let api=await import(pathToFileURL(process.argv[1]).href);' +
            (target === 'wasm-core' ? 'api=api.default;' : '') +
            'const names=JSON.parse(process.argv[2]);' +
            'if(JSON.stringify(Object.keys(api).sort())!==JSON.stringify(names.sort()))' +
            "throw Error('PSC1_SERVICE_TARGET_API_MISMATCH');";
          run('target-public-api', [
            '--input-type=module',
            '-e',
            apiCode,
            path.join(stage, targetArtifact.runtimeFile),
            JSON.stringify(candidate.publicNames),
          ]);
        }
        timings.targetMs = performance.now() - targetStarted;
        const evidenceStarted = performance.now();
        if (evidence === 'full') {
          fs.writeFileSync(path.join(stage, 'admissions.json'), admissions);
          fs.writeFileSync(
            path.join(stage, 'original-ir.json'),
            JSON.stringify(candidate.originalIr),
          );
          fs.writeFileSync(
            path.join(stage, 'specialized-ir.json'),
            JSON.stringify(candidate.specializedIr),
          );
          fs.writeFileSync(path.join(stage, 'sources.json'), json(captured));
        } else {
          // Wire files have already been consumed, checked and bound in memory.
          fs.unlinkSync(path.join(stage, 'request.json'));
          fs.unlinkSync(path.join(stage, 'candidate.json'));
        }
        fs.writeFileSync(
          path.join(stage, 'session.json'),
          json({
            request,
            ...(evidence === 'full'
              ? { tools }
              : {
                  resourceManifestSha256: sha(json(tools)),
                  resourceFiles: verificationTools.length,
                }),
            evidence,
            receipt,
            execution,
            events,
            ...(extraChecks.length ? { additionalAdmissions } : {}),
            candidateSha256: sha(raw),
            candidateSourceSha256: sha(candidate.source),
            sourceSha256: sha(
              boundedRead(
                path.join(
                  stage,
                  targetArtifact.sourceFile ||
                    (target === 'rust'
                      ? 'target.rs'
                      : target === 'ts'
                        ? 'target.ts'
                        : target === 'wasm-core'
                          ? 'target.wasm.hex'
                          : 'target.mjs'),
                ),
              ),
            ),
            publicNames: candidate.publicNames,
            runtimeRequirements: candidate.runtimeRequirements,
            targetArtifact,
            publicationProtocol,
            irValidation: 'original-and-transformed-validated-by-pinned-compiler-service',
            behaviorallyVerified: false,
            formalPreservation: 'not-provided',
          }),
        );
        const expectedFiles = [
          ...(evidence === 'full'
            ? [
                'admissions.json',
                'candidate.json',
                'original-ir.json',
                'request.json',
                'sources.json',
                'specialized-ir.json',
              ]
            : []),
          'session.json',
          ...targetArtifact.files,
        ].sort();
        if (fs.readdirSync(stage).sort().join(',') !== expectedFiles.join(','))
          fail('PSC1_SERVICE_ARTIFACT_CHANGED');
        sealedFiles = inventory(stage);
        timings.evidenceMs = performance.now() - evidenceStarted;
        verifyTools();
        state = 'admitted-target-checked';
        return Object.freeze({
          ...request,
          candidateSha256: sha(raw),
          candidateSourceSha256: sha(candidate.source),
          sourceSha256: sha(
            boundedRead(
              path.join(
                stage,
                targetArtifact.sourceFile ||
                  (target === 'rust'
                    ? 'target.rs'
                    : target === 'ts'
                      ? 'target.ts'
                      : target === 'wasm-core'
                        ? 'target.wasm.hex'
                        : 'target.mjs'),
              ),
            ),
          ),
          admissionsSha256: receipt.admissionsDigest,
          originalIrSha256: sha(JSON.stringify(candidate.originalIr)),
          specializedIrSha256: sha(JSON.stringify(candidate.specializedIr)),
          publicNames: [...candidate.publicNames],
          targetArtifact: clone(targetArtifact),
          execution: clone(execution),
          logicalAdmission: 'accepted',
          evidence,
          timings: { ...timings, sessionMs: performance.now() - sessionStarted },
          productionPublication: 'pending',
          ...(extraChecks.length ? { additionalAdmissions: clone(additionalAdmissions) } : {}),
          behaviorallyVerified: false,
        });
      } catch (error) {
        state = 'rejected';
        retainFailure(error);
        throw error;
      }
    },
    publish() {
      if (state !== 'admitted-target-checked') fail('PSC1_SERVICE_NOT_ADMITTED');
      state = 'publishing';
      try {
        verifyTools();
        checkFiles(stage, sealedFiles);
        const manifest = {
          schema: 'psc1-generated-service-bundle/1',
          request,
          targetFile: targetArtifact.targetFile,
          runtimeFile: targetArtifact.runtimeFile,
          targetConsumer: targetArtifact.consumer,
          publicationProtocol,
          checkerCommit: receipt.checkerCommit,
          files: sealedFiles,
          ...(extraChecks.length ? { additionalAdmissions: clone(additionalAdmissions) } : {}),
          logicalAdmission: 'accepted',
          targetSyntaxAndApi: 'accepted',
          irValidation: 'by-pinned-compiler-service',
          behaviorallyVerified: false,
          claim: 'exact logical admission and bounded compiler checks; not a preservation proof',
        };
        const result = publication.publish({
          stage,
          manifest,
          verify: verifyTools,
          fault: publicationFault,
        });
        sealedAttempt = result.directory;
        state = 'published';
        return Object.freeze({
          ...result,
          target: publicationProtocol === 'legacy-symlink' ? result.currentAlias : result.target,
          runtimeTarget: path.join(result.directory, targetArtifact.runtimeFile),
        });
      } catch (error) {
        if (error.committedPublication) {
          state = 'published';
          sealedAttempt = error.committedPublication.directory;
        } else state = 'rejected';
        retainFailure(error);
        throw error;
      }
    },
  });
}
