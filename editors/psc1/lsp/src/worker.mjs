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

async function analyze(request) {
  const options = validateRequest(request);
  const manifest = JSON.parse(fs.readFileSync(path.join(compilerRoot, 'package.json'), 'utf8'));
  if (manifest.name !== 'proofscript' || manifest.version !== '0.1.0-psc1.12')
    throw Error('PSC1_LSP_COMPILER_IDENTITY');
  compilerVersion = manifest.version;
  // Resolve only the release we bundle, never workspace node_modules or a path
  // supplied by project metadata. The original host verifies its execution pins.
  const api = await import(pathToFileURL(path.join(compilerRoot, 'dist/index.js')).href);
  const prepared = api.compileCandidate(options);
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
  if (candidate.candidateOnly !== true || candidate.admission !== 'not-run' ||
      candidate.sourceClosureDigest !== sourceDigest(options.sources) ||
      candidate.admissionRequest?.sourceClosureDigest !== candidate.sourceClosureDigest ||
      typeof candidate.admissionRequest?.admissions !== 'string' || !Array.isArray(candidate.origins))
    throw Error('PSC1_LSP_CANDIDATE_IDENTITY');
  const checked = api.compile(options);
  if (checked.status !== 'accepted' || checked.logicalAdmission !== 'accepted' ||
      checked.receipt?.logicalAdmission !== 'accepted' ||
      checked.receipt.sourceClosureDigest !== candidate.sourceClosureDigest ||
      checked.compilerSourceClosureDigest !== prepared.compilerSourceClosureDigest ||
      checked.receipt.admissionsSha256 !== sha256(candidate.admissionRequest.admissions))
    throw Error('PSC1_LSP_CHECKED_IDENTITY');
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
  return {state: partial ? 'partial' : 'checked',
    summary: partial ? 'Logical declarations passed the genuine Lean checker; partial runtime bodies remain unverified.' :
      'The current source snapshot passed PSC1 compilation and the genuine Lean checker.',
    diagnostics: [], declarations, logicalAdmission: 'accepted',
    receipt: {sourceClosureDigest: checked.receipt.sourceClosureDigest,
      admissionsSha256: checked.receipt.admissionsSha256,
      compilerSourceClosureDigest: checked.compilerSourceClosureDigest,
      kernelProviders: checked.kernelProviders, assurance: options.assurance,
      logicalAdmission: checked.logicalAdmission, formalPreservation: checked.formalPreservation,
      publication: checked.publication}};
}

process.on('message', async request => {
  if (consumed) return;
  consumed = true;
  const started = performance.now();
  let result;
  try { result = await analyze(request); }
  catch (error) {
    const message = String(error?.message || error).slice(0, 8192);
    const rejected = /PSC1_CHECKER_REJECTED|PSC1_SERVICE_ADDITIONAL_CHECKER_REFUSED/.test(message);
    result = {state: rejected ? 'rejected' : 'error', summary: message,
      diagnostics: [{module: request?.entryModule || '', message,
        code: message.match(/\bPSC1_[A-Z0-9_]+/)?.[0] || 'PSC1_LSP_COMPILER_FAILURE',
        precision: 'module', phase: rejected ? 'kernel' : 'infrastructure'}],
      declarations: [], logicalAdmission: rejected ? 'rejected' : 'unavailable'};
  }
  let payload = {...result, elapsedMs: Math.round(performance.now() - started), goalsAvailable: false, compilerVersion};
  if (Buffer.byteLength(JSON.stringify(payload)) > 8 * 1024 * 1024)
    payload = {state: 'error', summary: 'PSC1_LSP_RESULT_LIMIT: editor metadata exceeds 8 MiB.',
      diagnostics: [{module: request?.entryModule || '', message: 'Editor metadata exceeds 8 MiB.',
        code: 'PSC1_LSP_RESULT_LIMIT', precision: 'module', phase: 'infrastructure'}],
      declarations: [], logicalAdmission: 'unavailable', elapsedMs: payload.elapsedMs,
      goalsAvailable: false, compilerVersion};
  if (process.connected) process.send(payload, () => { process.disconnect(); process.exit(0); });
  else process.exit(1);
});
process.on('disconnect', () => { if (!consumed) process.exit(0); });
