// One immutable source snapshot per process. The server owns cancellation and
// kills the complete process group, including the unchanged compiler children.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';
import path from 'node:path';
import {admissionDeclarations} from './checked-types.mjs';

const sha256 = value => crypto.createHash('sha256').update(value).digest('hex');
const compilerRoot = fileURLToPath(new URL('../compiler/package/', import.meta.url));
const MAX_BYTES = 8 * 1024 * 1024;
const LEAN_COMMIT = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
let compilerVersion = 'unavailable';
let consumed = false;

function sourceDigest(sources) {
  return sha256(JSON.stringify(sources.map(source => ({
    module: source.module, kind: source.kind, utf8Sha256: sha256(source.text),
  }))));
}

function refusalMessage(candidate) {
  const labels = {
    parse: 'PSC1 could not parse this module.',
    elaboration: 'PSC1 rejected this declaration during elaboration.',
    capture: 'PSC1 refused the declared source closure.',
    preparation: 'PSC1 could not prepare this source for the selected assurance.',
    erasure: 'PSC1 could not erase the checked source for the selected target.',
    'public-api': 'PSC1 cannot compile this public interface with the current JS target.',
  };
  return (labels[candidate.phase] || 'PSC1 refused this compilation.') +
    ' Compiler phase: ' + candidate.phase + '; code: ' + candidate.code +
    (candidate.declaration ? '; declaration: ' + candidate.declaration : '') + '.';
}

function validateRequest(request) {
  if (!request || !Array.isArray(request.sources) || !request.sources.length || request.sources.length > 512 ||
      typeof request.entryModule !== 'string' || !request.sources.some(item => item.module === request.entryModule))
    throw Error('PSC1_LSP_SOURCE_REQUEST');
  const names = new Set();
  let bytes = 0;
  for (const source of request.sources) {
    if (!source || typeof source.module !== 'string' || names.has(source.module) ||
        !['ps', 'lean'].includes(source.kind) || typeof source.text !== 'string')
      throw Error('PSC1_LSP_SOURCE_REQUEST');
    names.add(source.module);
    bytes += Buffer.byteLength(source.text);
    if (bytes > MAX_BYTES) throw Error('PSC1_LSP_SOURCE_LIMIT');
  }
  const assurance = request.assurance || 'checked';
  if (!['checked', 'ordinary-checked'].includes(assurance)) throw Error('PSC1_LSP_ASSURANCE');
  if (Buffer.byteLength(JSON.stringify(request)) > MAX_BYTES) throw Error('PSC1_LSP_SOURCE_LIMIT');
  return {sources: request.sources.map(source => ({module: source.module, kind: source.kind, text: source.text})),
    entryModule: request.entryModule, assurance, engine: 'js', target: 'js', kernel: 'wasm'};
}

function validateCandidate(candidate, options) {
  const envelope = candidate.admissionRequest;
  if (candidate.candidateOnly !== true || candidate.admission !== 'not-run' ||
      candidate.protocol !== 'psc1-compiler-service/1' || candidate.target !== 'js' ||
      candidate.grammar !== options.sources[0].kind || candidate.assurance !== options.assurance ||
      candidate.sourceClosureDigest !== sourceDigest(options.sources) ||
      typeof candidate.requestId !== 'string' || !candidate.requestId ||
      envelope?.protocol !== 'psc1-compiler-host/1' || envelope.op !== 'admit' ||
      envelope.requestId !== candidate.requestId || envelope.target !== 'js' ||
      envelope.sourceClosureDigest !== candidate.sourceClosureDigest ||
      typeof envelope.admissions !== 'string' || Buffer.byteLength(envelope.admissions) > 128 * 1024 * 1024 ||
      !Array.isArray(candidate.origins) || candidate.origins.length !== options.sources.length ||
      !Array.isArray(candidate.partialNames) ||
      candidate.partialNames.some(name => typeof name !== 'string' || !name) ||
      new Set(candidate.partialNames).size !== candidate.partialNames.length)
    throw Error('PSC1_LSP_CANDIDATE_IDENTITY');
  // Preserve the existing host's complete source-member/ordinary-partial count
  // consistency checks. These validate transport metadata, not proof semantics.
  let sourceMembers = 0;
  candidate.origins.forEach((origin, index) => {
    const source = options.sources[index];
    if (!Array.isArray(origin) || origin.length !== 4 || origin[0] !== source.module ||
        origin[1] !== Buffer.byteLength(source.text) || !Array.isArray(origin[2]) || !Array.isArray(origin[3]))
      throw Error('PSC1_LSP_ORIGIN_IDENTITY');
    origin[3].forEach((declaration, sourceIndex) => {
      if (!Array.isArray(declaration) || declaration.length !== 5 || declaration[0] !== sourceIndex ||
          typeof declaration[1] !== 'string' || !Number.isSafeInteger(declaration[2]) ||
          !Number.isSafeInteger(declaration[3]) || !Array.isArray(declaration[4]))
        throw Error('PSC1_LSP_ORIGIN_IDENTITY');
      declaration[4].forEach((member, memberIndex) => {
        if (!Array.isArray(member) || member.length !== 2 || member[0] !== memberIndex ||
            typeof member[1] !== 'string' || !member[1]) throw Error('PSC1_LSP_ORIGIN_IDENTITY');
        sourceMembers++;
      });
    });
  });
  if (!sourceMembers || candidate.sourceDeclarations !== sourceMembers ||
      !Number.isSafeInteger(candidate.logicalDeclarations) ||
      candidate.logicalDeclarations !== sourceMembers + candidate.partialNames.length ||
      (options.assurance === 'checked' && candidate.partialNames.length !== 0))
    throw Error('PSC1_LSP_CLOSURE_IDENTITY');
}

async function analyze(request, timings) {
  const options = validateRequest(request);
  const manifest = JSON.parse(fs.readFileSync(path.join(compilerRoot, 'package.json'), 'utf8'));
  if (manifest.name !== 'proofscript' || manifest.version !== '0.1.0-psc1.12')
    throw Error('PSC1_LSP_COMPILER_IDENTITY');
  compilerVersion = manifest.version;
  // Resolve only the release we bundle, never workspace node_modules or a path
  // supplied by project metadata. The original host verifies its execution pins.
  const api = await import(pathToFileURL(path.join(compilerRoot, 'dist/index.js')).href);
  let prepared;
  const candidateStarted = performance.now();
  try { prepared = api.compileCandidate(options); }
  finally { timings.candidateMs = Math.round(performance.now() - candidateStarted); }
  if (prepared?.status !== 'candidate-only' || prepared.engine !== 'js' || prepared.target !== 'js' ||
      prepared.logicalAdmission !== 'not-run' || prepared.publicationAuthority !== false ||
      !/^[a-f0-9]{64}$/.test(prepared.compilerSourceClosureDigest) ||
      prepared.compilerSourceClosureDigest !== manifest.proofscript?.compilerSourceClosureDigest)
    throw Error('PSC1_LSP_COMPILER_IDENTITY');
  const candidate = prepared.candidate;
  if (!candidate || !['candidate', 'refused'].includes(candidate.status))
    throw Error('PSC1_LSP_CANDIDATE_PROTOCOL');
  if (candidate.status === 'refused') {
    const precision = Number.isSafeInteger(candidate.line) && candidate.line > 0 &&
      Number.isSafeInteger(candidate.column) && candidate.column > 0 ? 'declaration' : 'module';
    return {state: 'rejected', summary: refusalMessage(candidate), declarations: [],
      diagnostics: [{module: candidate.module || options.entryModule, message: refusalMessage(candidate),
        code: 'PSC1_' + String(candidate.phase).toUpperCase().replace(/[^A-Z0-9]/g, '_') + '_' +
          String(candidate.code).toUpperCase().replace(/[^A-Z0-9]/g, '_'),
        ...(precision === 'declaration' ? {line: candidate.line, column: candidate.column} : {}),
        precision, phase: candidate.phase}], logicalAdmission: 'not-run'};
  }
  validateCandidate(candidate, options);
  // Editor checking needs logical admission of this exact compiler graph, not
  // target execution or a publication store. Both called functions are public
  // APIs of the unchanged qualified distribution. In particular this does not
  // bypass, modify or spoof the Linux-only publication platform guard.
  const admissionsSha256 = sha256(candidate.admissionRequest.admissions);
  let checked;
  const kernelStarted = performance.now();
  try { checked = await api.checkCanonicalAdmissions(candidate.admissionRequest.admissions, {provider: 'wasm'}); }
  finally { timings.kernelMs = Math.round(performance.now() - kernelStarted); }
  if (checked?.schema !== 'psc1-universal-kernel-result/1' || checked.provider !== 'wasm' ||
      typeof checked.accepted !== 'boolean' || checked.agreement !== true ||
      checked.admissionsSha256 !== admissionsSha256 || checked.leanVersion !== '4.35.0' ||
      checked.leanCommit !== LEAN_COMMIT || checked.wasmMemoryModel !== 'linear' ||
      checked.results?.wasm?.accepted !== checked.accepted ||
      checked.results.wasm.protocol !== 'pskernel-lean/1' || checked.results.wasm.provider !== 'lean4-cpp' ||
      checked.results.wasm.leanVersion !== '4.35.0' || checked.results.wasm.leanCommit !== LEAN_COMMIT ||
      checked.results.wasm.profile !== 'lean4.35-core')
    throw Error('PSC1_LSP_CHECKER_IDENTITY');
  if (!checked.accepted)
    throw Error('PSC1_CHECKER_REJECTED: The genuine Lean Wasm kernel rejected the exact compiler admissions.');
  const metadataStarted = performance.now();
  const admitted = admissionDeclarations(candidate.admissionRequest.admissions);
  const partialNames = new Set(Array.isArray(candidate.partialNames) ? candidate.partialNames : []);
  const sources = new Map(options.sources.map(source => [source.module, source]));
  const declarations = [];
  for (const origin of candidate.origins) {
    if (!Array.isArray(origin) || origin.length !== 4 || !sources.has(origin[0]) ||
        origin[1] !== Buffer.byteLength(sources.get(origin[0]).text) || !Array.isArray(origin[3]))
      throw Error('PSC1_LSP_ORIGIN_IDENTITY');
    for (const declaration of origin[3]) {
      if (!Array.isArray(declaration) || declaration.length !== 5 || typeof declaration[1] !== 'string' ||
          !Number.isSafeInteger(declaration[2]) || !Number.isSafeInteger(declaration[3]) || !Array.isArray(declaration[4]))
        throw Error('PSC1_LSP_ORIGIN_IDENTITY');
      const members = declaration[4].map(member => member?.[1]).filter(name => typeof name === 'string');
      const primary = admitted.get(declaration[1]);
      // Ordinary partial definitions may have an admitted opaque inhabitant, but
      // that never verifies their runtime implementation or termination.
      const partial = partialNames.has(declaration[1]) || members.some(name => partialNames.has(name));
      // Inductive constructor/recursor members can be generated by the genuine
      // checker from their admitted inductive block rather than separate rows.
      // Require an actual admitted primary declaration; never infer verification
      // from a matching piece of source text or an unchecked candidate alone.
      const verified = !partial && Boolean(primary);
      declarations.push({module: origin[0], name: declaration[1], line: declaration[2], column: declaration[3],
        kind: primary?.kind || (partial ? 'definition' : 'declaration'), ...(primary?.type ? {type: primary.type} : {}),
        verified, status: partial ? 'unchecked-partial' : verified ? 'checked' : 'metadata-only',
        members, typeSource: primary?.type ? 'elaborated-core' : 'unavailable'});
    }
  }
  const partial = partialNames.size > 0;
  timings.metadataMs = Math.round(performance.now() - metadataStarted);
  return {state: partial ? 'partial' : 'checked',
    summary: partial ? 'Logical declarations passed the genuine Lean checker; partial runtime bodies remain unverified.' :
      'The current source snapshot was analyzed by PSC1 and its exact logical declarations passed the genuine Lean checker.',
    diagnostics: [], declarations, logicalAdmission: 'accepted',
    receipt: {schema: 'psc1-editor-logical-admission/1',
      scope: 'Exact compiler-produced canonical graph independently checked; no target execution or publication.',
      sourceClosureDigest: candidate.sourceClosureDigest, admissionsSha256,
      compilerSourceClosureDigest: prepared.compilerSourceClosureDigest,
      kernelProviders: ['wasm'], leanVersion: checked.leanVersion, leanCommit: checked.leanCommit,
      wasmMemoryModel: checked.wasmMemoryModel, assurance: options.assurance,
      logicalAdmission: 'accepted', formalPreservation: 'not-provided',
      targetValidation: 'not-run', publication: 'not-requested'}};
}

process.on('message', async request => {
  if (consumed) return;
  consumed = true;
  const started = performance.now();
  const timings = {candidateMs: 0, kernelMs: 0, metadataMs: 0};
  let result;
  try { result = await analyze(request, timings); }
  catch (error) {
    const message = String(error?.message || error).slice(0, 8192);
    const rejected = /PSC1_CHECKER_REJECTED|PSC1_SERVICE_ADDITIONAL_CHECKER_REFUSED/.test(message);
    result = {state: rejected ? 'rejected' : 'error', summary: message,
      diagnostics: [{module: request?.entryModule || '', message,
        code: message.match(/\bPSC1_[A-Z0-9_]+/)?.[0] || 'PSC1_LSP_COMPILER_FAILURE',
        precision: 'module', phase: rejected ? 'kernel' : 'infrastructure'}],
      declarations: [], logicalAdmission: rejected ? 'rejected' : 'unavailable'};
  }
  let payload = {...result, elapsedMs: Math.round(performance.now() - started), timings, goalsAvailable: false, compilerVersion};
  if (Buffer.byteLength(JSON.stringify(payload)) > 8 * 1024 * 1024)
    payload = {state: 'error', summary: 'PSC1_LSP_RESULT_LIMIT: editor metadata exceeds 8 MiB.',
      diagnostics: [{module: request?.entryModule || '', message: 'Editor metadata exceeds 8 MiB.',
        code: 'PSC1_LSP_RESULT_LIMIT', precision: 'module', phase: 'infrastructure'}],
      declarations: [], logicalAdmission: 'unavailable', elapsedMs: payload.elapsedMs, timings,
      goalsAvailable: false, compilerVersion};
  if (process.connected) process.send(payload, () => { process.disconnect(); process.exit(0); });
  else process.exit(1);
});
process.on('disconnect', () => { if (!consumed) process.exit(0); });
