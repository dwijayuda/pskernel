// Owned compiler worker, not an executable third-party extension host.
// No kernel selection, process spawning, source-file loading or output writes.
// Canonical prepared terms and checked-session handles NEVER leave this process.
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { createCheckedPreparedSession } from './checked-session.mjs';
import { readImports } from './source-graph.mjs';
import { FRONTEND_PROTOCOL as protocol, receiveFrames, sendFrame } from './frontend-wire.mjs';
const require = createRequire(import.meta.url);
const hash = text => createHash('sha256').update(text).digest('hex');
let compiler, session, checked, active, kernelReply, previous = 0, usedCheck = false;
const die = () => process.exit(1);
const send = value => sendFrame(process.stdout, value, die);
function requireKind(kind) {
  if (!['ps', 'lean'].includes(kind)) throw new Error('PSC_FRONTEND_SOURCE_KIND');
  return kind === 'ps' ? compiler.PsCompilerSourceKind.proofScript : compiler.PsCompilerSourceKind.lean;
}
async function command(op, data) {
  if (op === 'init') {
    if (compiler || !/^[a-f0-9]{64}$/u.test(data.compilerSha256)) throw new Error('PSC_FRONTEND_INIT');
    const source = require.resolve('@proofscript/compiler');
    if (hash(readFileSync(source)) !== data.compilerSha256) throw new Error('PSC_FRONTEND_COMPILER_IDENTITY');
    compiler = await import(pathToFileURL(source).href);
    if (hash(readFileSync(source)) !== data.compilerSha256 || compiler.psProofScriptGrammarEdition !== 'ps-0.9-r3' || compiler.psProofScriptGrammarMode !== 'new-only') throw new Error('PSC_FRONTEND_COMPILER_IDENTITY');
    session = createCheckedPreparedSession(compiler, admissions => new Promise((resolve, reject) => {
      if (kernelReply || active.op !== 'check') return reject(new Error('PSC_FRONTEND_ADMISSION_ORDER'));
      kernelReply = resolve;
      send({ protocol, id: active.id, kind: 'admissions', value: admissions });
    }), data.kernelIdentity);
    return { pid: process.pid, compilerSha256: data.compilerSha256, psProofScriptGrammarEdition: compiler.psProofScriptGrammarEdition, psProofScriptGrammarMode: compiler.psProofScriptGrammarMode };
  }
  if (!session) throw new Error('PSC_FRONTEND_NOT_INITIALIZED');
  if (op === 'imports') {
    requireKind(data.kind);
    if (typeof data.source !== 'string' || Buffer.byteLength(data.source) > 4 * 1024 * 1024) throw new Error('PSC_FRONTEND_SOURCE_LIMIT');
    return readImports(compiler, data.source, data.kind);
  }
  if (op === 'check') {
    if (usedCheck) throw new Error('PSC_FRONTEND_CHECK_REUSE');
    usedCheck = true;
    if (!Array.isArray(data.sources) || data.sources.length > 2048 || data.sources.some(s => typeof s !== 'string') || data.sources.reduce((total, s) => total + Buffer.byteLength(s), 0) > 32 * 1024 * 1024) throw new Error('PSC_FRONTEND_SOURCE_LIMIT');
    checked = await session.checkSources(requireKind(data.kind), data.sources, data.binding);
    return { canonicalAdmissionsSha256: checked.canonicalAdmissionsSha256, sourceSha256: checked.sourceSha256, binding: checked.binding };
  }
  if (!checked) throw new Error('PSC_FRONTEND_UNCHECKED_MODULE');
  if (op === 'emit') return session.emit(checked);
  if (op === 'assert-current') { session.assertCurrent(checked); return true; }
  throw new Error('PSC_FRONTEND_UNKNOWN_OPERATION');
}
receiveFrames(process.stdin, frame => {
  if (frame.protocol !== protocol || !Number.isSafeInteger(frame.id) || frame.id < 1) return die();
  if (frame.op === 'kernel-result') {
    if (!kernelReply || active?.id !== frame.id) return die();
    const accept = kernelReply; kernelReply = undefined; accept(frame.data); return;
  }
  if (active || frame.id !== previous + 1 || typeof frame.op !== 'string' || !frame.data || typeof frame.data !== 'object' || Array.isArray(frame.data)) return die();
  previous = frame.id; active = frame;
  command(frame.op, frame.data).then(value => {
    active = undefined; send({ protocol, id: frame.id, kind: 'result', value });
  }, error => {
    active = undefined;
    send({ protocol, id: frame.id, kind: 'error', message: String(error?.message || error).slice(0, 2000) });
  });
}, die);
process.stdin.on('end', () => process.exit(0));
process.stdout.on('error', die);
