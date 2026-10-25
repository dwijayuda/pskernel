// Host-only orchestration. Generated wire data cannot choose tools or publish.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createCompilerHostSession, compilerSourceClosureDigest } from './compiler-host-protocol.mjs';
import { validateClosureCounts } from '../scripts/compiler-closure-contract.mjs';

const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error(code); };
const json = value => JSON.stringify(value, null, 2) + '\n';
const clone = value => JSON.parse(JSON.stringify(value));
const inspect = file => { try { return fs.lstatSync(file); } catch (e) { if (e.code === 'ENOENT') return null; throw e; } };
const boundedRead = file => {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.size === 0 || stat.size > 128 * 1024 * 1024)
    fail('PSC1_SERVICE_STAGED_FILE_INVALID');
  return fs.readFileSync(file);
};
function identity(file, expected) {
  if (typeof file !== 'string' || !path.isAbsolute(file) ||
      !/^[0-9a-f]{64}$/.test(expected || '') || !fs.lstatSync(file).isFile() || sha(fs.readFileSync(file)) !== expected)
    fail('PSC1_SERVICE_TOOL_IDENTITY_CHANGED');
  return { path: file, sha256: expected };
}
function currentPointer(root) {
  const file = path.join(root, 'current'), stat = inspect(file);
  if (!stat) return null;
  if (!stat.isSymbolicLink()) fail('PSC1_SERVICE_CURRENT_INVALID');
  const value = fs.readlinkSync(file);
  if (!/^generations\/[0-9a-f]{64}$/.test(value)) fail('PSC1_SERVICE_CURRENT_INVALID');
  return value;
}
function publicationFault(phase) {
  if (process.env.PSC1_TEST_SERVICE_PUBLICATION_FAIL_AT === phase)
    fail('PSC1_SERVICE_INJECTED_PUBLICATION_FAILURE:' + phase);
}
function syncDirectory(directory) {
  const fd = fs.openSync(directory, 'r');
  try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}
function inventory(stage) {
  return fs.readdirSync(stage).sort().map(name => {
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
export function createGeneratedJsCompilerSession({ requestId, sources, entryModule, assurance,
    serviceFile, serviceSha256, runnerFile, runnerSha256,
    checkerExecutable, checkerSha256, publicationRoot, serviceDependencies = [] }) {
  if (process.version !== 'v22.23.3') fail('PSC1_SERVICE_NODE_PIN');
  if (typeof requestId !== 'string' || !requestId || typeof entryModule !== 'string' ||
      !['checked', 'ordinary-checked'].includes(assurance) ||
      !path.isAbsolute(publicationRoot || '')) fail('PSC1_SERVICE_REQUEST_INVALID');
  const captured = clone(sources);
  const sourceClosureDigest = compilerSourceClosureDigest(captured);
  const grammar = captured[0].kind;
  if (!captured.every(row => row.kind === grammar) ||
      !captured.some(row => row.module === entryModule)) fail('PSC1_SERVICE_CAPTURE_INVALID');
  const tools = {
    service: identity(serviceFile, serviceSha256), runner: identity(runnerFile, runnerSha256),
    checker: identity(checkerExecutable, checkerSha256),
    node: identity(process.execPath, sha(fs.readFileSync(process.execPath)))
  };
  // Trusted host-selected dependencies bind imported generated engine bytes too.
  // Generated wire fields cannot add paths or choose a checker.
  if (!Array.isArray(serviceDependencies)) fail('PSC1_SERVICE_DEPENDENCIES_INVALID');
  serviceDependencies.forEach((tool, index) => {
    if (!tool || typeof tool !== 'object') fail('PSC1_SERVICE_DEPENDENCIES_INVALID');
    tools['dependency' + index] = identity(tool.path, tool.sha256);
  });
  const verifyTools = () => Object.values(tools).forEach(tool => identity(tool.path, tool.sha256));
  const requestText = JSON.stringify(['psc1-compiler-service/1', requestId, sourceClosureDigest,
    grammar, assurance, entryModule, captured.map(row => [row.module, row.text])]);
  const request = Object.freeze({ requestId, sourceClosureDigest, grammar, assurance,
    entryModule, target: 'js', requestSha256: sha(requestText), serviceSha256,
    runnerSha256, checkerSha256, nodeVersion: process.version, nodeSha256: tools.node.sha256 });
  const root = path.resolve(publicationRoot);
  for (const directory of [root, path.join(root, 'generations')]) {
    const stat = inspect(directory);
    if (stat && !stat.isDirectory()) fail('PSC1_SERVICE_STORE_INVALID');
    fs.mkdirSync(directory, { recursive: true });
  }
  if (fs.readdirSync(root).some(name => !['generations', 'current', '.publish.lock'].includes(name)))
    fail('PSC1_SERVICE_STORE_UNMANAGED');
  const prior = currentPointer(root);
  const stage = fs.mkdtempSync(path.join(root, 'generations/.stage-'));
  fs.chmodSync(stage, 0o700);
  let state = 'pending', sealedFiles, receipt, candidate;
  const events = [];
  let failureDirectory = null, sealedAttempt = null;
  function retainFailure(error) {
    try {
      const failed=path.join(root,'generations','failed-'+crypto.randomUUID());
      if (inspect(stage)) fs.renameSync(stage,failed);
      else fs.mkdirSync(failed);
      failureDirectory=failed;
      fs.writeFileSync(path.join(failed,'failure.json'),json({schema:'psc1-generated-session-failure/1',
        request,state,failure:error.message,events,sealedAttempt,
        authoritative:false,publication:state==='published'?'committed':'not-committed'}));
    } catch (loggingError) { events.push({role:'host-diagnostic',error:loggingError.message}); }
  }
  const run = (role, args) => {
    const started = Date.now();
    const result = spawnSync(process.execPath, args, { encoding: 'utf8',
      timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
    events.push({ role, executable: process.execPath, args: [...args],
      status: result.status, signal: result.signal, elapsedMs: Date.now() - started,
      error: result.error?.message || null });
    if (result.error || result.status !== 0) {
      fs.writeFileSync(path.join(stage,role+'.stderr.txt'),result.stderr || '');
      fs.writeFileSync(path.join(stage,role+'.stdout.txt'),result.stdout || '');
      fail('PSC1_SERVICE_PROCESS_FAILED:' + role + ':' +
        (result.error?.code || result.signal || result.status));
    }
    return result.stdout;
  };
  return Object.freeze({
    request,
    stagingDirectory: stage,
    get state() { return state; },
    get events() { return clone(events); },
    get failureDirectory() { return failureDirectory; },
    execute() {
      if (state !== 'pending') fail('PSC1_SERVICE_SESSION_CONSUMED');
      state = 'running';
      try {
        verifyTools();
        fs.writeFileSync(path.join(stage, 'request.json'), requestText);
        const stdout = run('generated-compiler', [runnerFile, serviceFile, serviceSha256,
          path.join(stage, 'request.json'), path.join(stage, 'candidate.json')]);
        verifyTools();
        if (sha(boundedRead(path.join(stage, 'request.json'))) !== request.requestSha256)
          fail('PSC1_SERVICE_REQUEST_CHANGED');
        const raw = boundedRead(path.join(stage, 'candidate.json'));
        const execution = JSON.parse(stdout.trim());
        if (execution.protocol !== 'psc1-generated-service-run/1' ||
            execution.serviceSha256 !== serviceSha256 ||
            execution.requestSha256 !== request.requestSha256 ||
            execution.responseSha256 !== sha(raw)) fail('PSC1_SERVICE_EXECUTION_MISMATCH');
        candidate = JSON.parse(raw.toString('utf8'));
        if (!candidate || typeof candidate !== 'object' || Array.isArray(candidate))
          fail('PSC1_SERVICE_RESPONSE_FIELDS');
        if (candidate.status !== 'candidate')
          fail('PSC1_SERVICE_COMPILER_REFUSED:' + candidate.phase);
        const fields = ['admission','admissionRequest','assurance','candidateOnly','grammar',
          'logicalDeclarations','originalIr','origins','partialNames','protocol','publicNames',
          'requestId','runtimeRequirements','source','sourceClosureDigest','sourceDeclarations',
          'specializedIr','status','target'];
        if (Object.keys(candidate).sort().join(',') !== fields.sort().join(','))
          fail('PSC1_SERVICE_RESPONSE_FIELDS');
        if (candidate.status !== 'candidate') fail('PSC1_SERVICE_COMPILER_REFUSED:' + candidate.phase);
        for (const [key, value] of Object.entries({ protocol: 'psc1-compiler-service/1',
          requestId, sourceClosureDigest, grammar, assurance, target: 'js',
          candidateOnly: true, admission: 'not-run' })) {
          if (candidate[key] !== value) fail('PSC1_SERVICE_RESPONSE_MISMATCH:' + key);
        }
        if (!Array.isArray(candidate.origins) || candidate.origins.length !== captured.length ||
            typeof candidate.source !== 'string' || !candidate.source ||
            !Array.isArray(candidate.publicNames) ||
            candidate.publicNames.some(name => typeof name !== 'string' || !name) ||
            new Set(candidate.publicNames).size !== candidate.publicNames.length)
          fail('PSC1_SERVICE_RESPONSE_SHAPE');
        let sourceCount = 0;
        candidate.origins.forEach((row, index) => {
          if (!Array.isArray(row) || row.length !== 4 || row[0] !== captured[index].module ||
              row[1] !== Buffer.byteLength(captured[index].text) || !Array.isArray(row[3]))
            fail('PSC1_SERVICE_ORIGIN_MISMATCH');
          row[3].forEach((origin, sourceIndex) => {
            if (!Array.isArray(origin) || origin.length !== 5 || origin[0] !== sourceIndex ||
                typeof origin[1] !== 'string' || !Array.isArray(origin[4]))
              fail('PSC1_SERVICE_ORIGIN_MISMATCH');
            origin[4].forEach((member, memberIndex) => {
              if (!Array.isArray(member) || member.length !== 2 || member[0] !== memberIndex ||
                  typeof member[1] !== 'string') fail('PSC1_SERVICE_ORIGIN_MISMATCH');
              sourceCount++;
            });
          });
        });
        validateClosureCounts({ assurance, sourceCoreDeclarations: candidate.sourceDeclarations,
          coreDeclarations: candidate.logicalDeclarations, partialNames: candidate.partialNames },
          sourceCount, assurance);
        for (const graph of [candidate.originalIr, candidate.specializedIr]) {
          if (!Array.isArray(graph) || graph.length !== 5 || graph[0] !== 'psc1-ir/1' ||
              !graph.slice(1).every(Array.isArray)) fail('PSC1_SERVICE_IR_SHAPE');
        }
        const admissions = candidate.admissionRequest?.admissions;
        const checkerSession = createCompilerHostSession({ requestId, target: 'js',
          sources: captured, canonicalAdmissions: admissions, checkerExecutable });
        events.push({ role: 'independent-checker', executable: checkerExecutable,
          checkerSha256, admissionsSha256: sha(admissions), state: 'before' });
        receipt = checkerSession.admit(JSON.stringify(candidate.admissionRequest));
        verifyTools();
        events.push({ role: 'independent-checker', state: 'accepted',
          checkerCommit: receipt.checkerCommit, admissionsSha256: receipt.admissionsDigest });
        fs.writeFileSync(path.join(stage, 'target.mjs'), candidate.source);
        run('target-syntax', ['--check', path.join(stage, 'target.mjs')]);
        const apiCode = "import {pathToFileURL} from 'node:url';" +
          "const api=await import(pathToFileURL(process.argv[1]).href);" +
          "const names=JSON.parse(process.argv[2]);" +
          "if(JSON.stringify(Object.keys(api).sort())!==JSON.stringify(names.sort()))" +
          "throw Error('PSC1_SERVICE_TARGET_API_MISMATCH');";
        run('target-public-api', ['--input-type=module', '-e', apiCode,
          path.join(stage, 'target.mjs'), JSON.stringify(candidate.publicNames)]);
        fs.writeFileSync(path.join(stage, 'admissions.json'), admissions);
        fs.writeFileSync(path.join(stage, 'original-ir.json'), JSON.stringify(candidate.originalIr));
        fs.writeFileSync(path.join(stage, 'specialized-ir.json'), JSON.stringify(candidate.specializedIr));
        fs.writeFileSync(path.join(stage, 'sources.json'), json(captured));
        fs.writeFileSync(path.join(stage, 'session.json'), json({ request, tools, receipt, execution,
          events, candidateSha256: sha(raw), sourceSha256: sha(candidate.source),
          publicNames: candidate.publicNames, runtimeRequirements: candidate.runtimeRequirements,
          irValidation: 'original-and-transformed-validated-by-pinned-compiler-service',
          behaviorallyVerified: false, formalPreservation: 'not-provided' }));
        const expectedFiles = ['admissions.json','candidate.json','original-ir.json','request.json',
          'session.json','sources.json','specialized-ir.json','target.mjs'].sort();
        if (fs.readdirSync(stage).sort().join(',') !== expectedFiles.join(','))
          fail('PSC1_SERVICE_ARTIFACT_CHANGED');
        sealedFiles = inventory(stage);
        verifyTools();
        state = 'admitted-target-checked';
        return Object.freeze({ ...request, candidateSha256: sha(raw),
          sourceSha256: sha(candidate.source), admissionsSha256: receipt.admissionsDigest,
          originalIrSha256: sha(JSON.stringify(candidate.originalIr)),
          specializedIrSha256: sha(JSON.stringify(candidate.specializedIr)),
          publicNames: [...candidate.publicNames], execution: clone(execution),
          logicalAdmission: 'accepted', productionPublication: 'pending',
          behaviorallyVerified: false });
      } catch (error) { state = 'rejected'; retainFailure(error); throw error; }
    },
    publish() {
      if (state !== 'admitted-target-checked') fail('PSC1_SERVICE_NOT_ADMITTED');
      state = 'publishing';
      const lock = path.join(root, '.publish.lock');
      let lockFd;
      try {
        lockFd = fs.openSync(lock, 'wx', 0o600);
        if (currentPointer(root) !== prior) fail('PSC1_SERVICE_PRIOR_PUBLICATION_CHANGED');
        verifyTools();
        checkFiles(stage, sealedFiles);
        publicationFault('before-seal');
        const manifest = { schema: 'psc1-generated-service-bundle/1', request,
          checkerCommit: receipt.checkerCommit, files: sealedFiles,
          logicalAdmission: 'accepted', targetSyntaxAndApi: 'accepted',
          irValidation: 'by-pinned-compiler-service', behaviorallyVerified: false,
          claim: 'exact logical admission and bounded compiler checks; not a preservation proof' };
        const manifestText = json(manifest), generation = sha(manifestText);
        fs.writeFileSync(path.join(stage, 'manifest.json'), manifestText);
        for (const file of fs.readdirSync(stage)) {
          const fd = fs.openSync(path.join(stage, file), 'r');
          try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
        }
        syncDirectory(stage);
        const sealed = path.join(root, 'generations', generation);
        if (inspect(sealed)) fail('PSC1_SERVICE_GENERATION_ALREADY_EXISTS');
        fs.renameSync(stage, sealed);
        sealedAttempt=sealed;
        syncDirectory(path.join(root, 'generations'));
        publicationFault('after-seal');
        const pointer = path.join(root, '.current-' + crypto.randomUUID());
        fs.symlinkSync('generations/' + generation, pointer);
        try {
          publicationFault('before-commit');
          // The only publication commit point; old generations remain readable.
          fs.renameSync(pointer, path.join(root, 'current'));
        } finally { if (inspect(pointer)) fs.unlinkSync(pointer); }
        state = 'published';
        syncDirectory(root);
        return Object.freeze({ generation, directory: sealed,
          manifestSha256: generation, target: path.join(root, 'current/target.mjs') });
      } catch (error) { if (state !== 'published') state = 'rejected'; retainFailure(error); throw error; }
      finally {
        if (lockFd !== undefined) { fs.closeSync(lockFd); fs.unlinkSync(lock); }
      }
    }
  });
}
