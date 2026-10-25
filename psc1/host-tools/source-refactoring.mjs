// Lexical tooling only. No parser, proof admission, emitter or publication authority.
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { supervisorLimit } from '../scripts/selfhost-qualification-profiles.mjs';

export const losslessProfile = 'psc1-practical-core-v1/lean4.35.0/lossless-1';
export const losslessLimits = Object.freeze({
  sourceBytes: 1048576, responseBytes: 33554432, pieces: 262144,
  edits: 4096, timeoutMs: 240000, addressSpaceBytes: 4294967296, stackBytes: 8388608,
});
const protocol = 'psc1-lossless-capture/1';
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const refuse = code => { throw new Error('PSC1_LOSSLESS_' + code); };
const decoder = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
const supervisor = fileURLToPath(new URL('../scripts/bounded-process.py', import.meta.url));

function exactKeys(value, keys) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...keys].sort().join(',')) refuse('FIELDS');
}
function bytesCopy(value, limit = losslessLimits.sourceBytes) {
  if (!(value instanceof Uint8Array) || value.byteLength > limit) refuse('BYTES_OR_LIMIT');
  const copy = Buffer.from(value);
  try {
    if (!Buffer.from(decoder.decode(copy)).equals(copy)) refuse('UTF8');
  } catch { refuse('UTF8'); }
  return copy;
}
function deepFreeze(value) {
  if (value && typeof value === 'object') {
    for (const child of Object.values(value)) deepFreeze(child);
    Object.freeze(value);
  }
  return value;
}
function regularFile(file, limit) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > limit) refuse('FILE');
  return fs.readFileSync(file);
}
function pinnedTool(file, expected) {
  if (typeof file !== 'string' || !path.isAbsolute(file) ||
      !/^[0-9a-f]{64}$/.test(expected)) refuse('TOOL_IDENTITY');
  if (hash(regularFile(file, 268435456)) !== expected) refuse('TOOL_IDENTITY');
}
function boundary(bytes, offset) {
  return Number.isSafeInteger(offset) && offset >= 0 && offset <= bytes.length &&
    (offset === bytes.length || (bytes[offset] & 0xc0) !== 0x80);
}
function positionEqual(a, b) {
  return a.byteOffset === b.byteOffset && a.line === b.line && a.column === b.column;
}
function validPosition(p, bytes) {
  exactKeys(p, ['byteOffset', 'line', 'column']);
  if (!boundary(bytes, p.byteOffset) || !Number.isSafeInteger(p.line) || p.line < 1 ||
      !Number.isSafeInteger(p.column) || p.column < 1) refuse('POSITION');
}
function validSpan(s, bytes) {
  exactKeys(s, ['start', 'stop']);
  validPosition(s.start, bytes); validPosition(s.stop, bytes);
  if (s.start.byteOffset > s.stop.byteOffset) refuse('SPAN');
}
function advance(position, text, grammar) {
  let { byteOffset, line, column } = position;
  for (const char of text) {
    const initialPsBom = grammar === 'ps' && byteOffset === 0 && char === '\uFEFF';
    byteOffset += Buffer.byteLength(char);
    if (char === '\n') { line++; column = 1; }
    else if (!initialPsBom) column++;
  }
  return { byteOffset, line, column };
}
function atOffset(bytes, offset, grammar) {
  return advance({ byteOffset: 0, line: 1, column: 1 },
    decoder.decode(bytes.subarray(0, offset)), grammar);
}
function validToken(token, bytes) {
  exactKeys(token, ['kind', 'text', 'span']);
  if (!['identifier', 'natural', 'string', 'character', 'symbol', 'endOfInput'].includes(token.kind) ||
      typeof token.text !== 'string' || !token.text.isWellFormed()) refuse('TOKEN');
  validSpan(token.span, bytes);
  const raw = bytes.subarray(token.span.start.byteOffset, token.span.stop.byteOffset);
  if (!Buffer.from(token.text).equals(raw)) refuse('TOKEN_TEXT');
}
function validateResponse(wire, bytes, grammar) {
  exactKeys(wire, ['protocol', 'grammar', 'status', 'byteLength', 'pieces', 'tokens', 'diagnostic']);
  if (wire.protocol !== protocol || wire.grammar !== grammar || wire.byteLength !== bytes.length ||
      !['accepted', 'lexically-refused'].includes(wire.status) ||
      !Array.isArray(wire.pieces) || !wire.pieces.length ||
      wire.pieces.length > losslessLimits.pieces || !Array.isArray(wire.tokens) ||
      wire.tokens.length > losslessLimits.pieces) refuse('RESPONSE');
  let cursor = { byteOffset: 0, line: 1, column: 1 }, tokenIndex = 0;
  const chunks = [];
  for (const [ordinal, piece] of wire.pieces.entries()) {
    exactKeys(piece, ['ordinal', 'kind', 'span', 'raw', 'token']);
    validSpan(piece.span, bytes);
    if (piece.ordinal !== ordinal || !positionEqual(piece.span.start, cursor) ||
        typeof piece.raw !== 'string' || !piece.raw.isWellFormed()) refuse('PIECE');
    const raw = Buffer.from(piece.raw);
    if (!bytes.subarray(cursor.byteOffset, piece.span.stop.byteOffset).equals(raw)) refuse('RAW');
    cursor = advance(cursor, piece.raw, grammar);
    if (!positionEqual(piece.span.stop, cursor)) refuse('POSITION');
    const zero = raw.length === 0;
    if (piece.kind === 'token') {
      validToken(piece.token, bytes);
      if (JSON.stringify(piece.token) !== JSON.stringify(wire.tokens[tokenIndex++]) ||
          JSON.stringify(piece.span) !== JSON.stringify(piece.token.span)) refuse('PROJECTION');
      const eof = piece.token.kind === 'endOfInput';
      if (eof !== zero || eof !== (ordinal === wire.pieces.length - 1)) refuse('EOF');
    } else {
      if (piece.token !== null) refuse('TRIVIA_TOKEN');
      if (piece.kind === 'unlexed') {
        if (wire.status !== 'lexically-refused' || wire.pieces.length !== 1) refuse('UNLEXED');
      } else {
        if (zero || wire.status !== 'accepted') refuse('TRIVIA');
        if (piece.kind === 'whitespace') {
          if (!/^[ \t\r\n]+$/.test(piece.raw)) refuse('WHITESPACE');
        } else if (piece.kind === 'lineComment') {
          if (!piece.raw.startsWith('--') || piece.raw.includes('\n')) refuse('COMMENT');
        } else if (piece.kind === 'blockComment') {
          if (!piece.raw.startsWith('/-') || !piece.raw.endsWith('-/')) refuse('COMMENT');
        } else if (piece.kind === 'byteOrderMark') {
          if (grammar !== 'ps' || ordinal !== 0 || piece.raw !== '\uFEFF') refuse('BOM');
        } else refuse('PIECE_KIND');
      }
    }
    chunks.push(raw);
  }
  if (cursor.byteOffset !== bytes.length || tokenIndex !== wire.tokens.length ||
      !Buffer.concat(chunks).equals(bytes)) refuse('COVERAGE');
  let diagnosticCoordinatesVerified = null;
  if (wire.status === 'accepted') {
    if (wire.diagnostic !== null || !wire.tokens.length ||
        wire.tokens.at(-1).kind !== 'endOfInput') refuse('ACCEPTANCE');
  } else {
    if (wire.tokens.length || wire.pieces[0].kind !== 'unlexed') refuse('REFUSAL');
    const diagnostic = wire.diagnostic;
    const codes = ['unterminatedBlockComment', 'unterminatedString', 'newlineInString',
      'unterminatedCharacter', 'fuelExhausted', 'invalidSource'];
    if (!diagnostic || !codes.includes(diagnostic.code)) refuse('DIAGNOSTIC');
    exactKeys(diagnostic, diagnostic.code === 'invalidSource' ? ['code', 'span', 'reason'] : ['code', 'span']);
    if (diagnostic.code === 'fuelExhausted') {
      if (diagnostic.span !== null) refuse('DIAGNOSTIC');
    } else {
      // Existing lexer diagnostics are preserved as advisory data. Malformed
      // character errors can point inside a UTF-8 scalar; they are never edit ranges.
      exactKeys(diagnostic.span, ['start', 'stop']);
      const positions = [diagnostic.span.start, diagnostic.span.stop];
      for (const p of positions) {
        exactKeys(p, ['byteOffset', 'line', 'column']);
        if (!Number.isSafeInteger(p.byteOffset) || p.byteOffset < 0 || p.byteOffset > bytes.length ||
            !Number.isSafeInteger(p.line) || p.line < 1 ||
            !Number.isSafeInteger(p.column) || p.column < 1) refuse('DIAGNOSTIC_POSITION');
      }
      if (positions[0].byteOffset > positions[1].byteOffset) refuse('DIAGNOSTIC_POSITION');
      diagnosticCoordinatesVerified = positions.every(p => boundary(bytes, p.byteOffset) &&
        positionEqual(p, atOffset(bytes, p.byteOffset, grammar)));
    }
    if (diagnostic.code === 'invalidSource' &&
        (typeof diagnostic.reason !== 'string' || !diagnostic.reason.isWellFormed() ||
         diagnostic.reason.length > 1024)) refuse('DIAGNOSTIC');
  }
  return { diagnosticCoordinatesVerified };
}

/** The caller pins a trusted native helper. Source data can never select tools.
 * Snapshots are opaque capabilities local to this tool instance, not serializable
 * edit permissions. All exposed metadata is deeply frozen; bytes are copied.
 */
export function createLosslessSourceTool({ executable, sha256 }) {
  if (process.platform !== 'linux') refuse('HOST_UNQUALIFIED');
  pinnedTool(executable, sha256);
  const snapshots = new WeakMap();
  const saved = snapshot => {
    const record = snapshots.get(snapshot);
    if (!record) refuse('SNAPSHOT');
    return record;
  };
  return Object.freeze({
    capture({ module, grammar, bytes, uri = null }) {
      if (typeof module !== 'string' || !module || !module.isWellFormed() ||
          Buffer.byteLength(module) > 4096 || module.includes('\0') ||
          !['lean', 'ps'].includes(grammar) ||
          (uri !== null && (typeof uri !== 'string' || !uri.isWellFormed() ||
            Buffer.byteLength(uri) > 16384 || uri.includes('\0')))) refuse('IDENTITY');
      const source = bytesCopy(bytes);
      pinnedTool(executable, sha256);
      const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-lossless-'));
      try {
        const input = path.join(directory, 'source'), output = path.join(directory, 'capture.json');
        fs.writeFileSync(input, source, { mode: 0o600, flag: 'wx' });
        const limit = supervisorLimit(losslessLimits.timeoutMs, 'standard-240s');
        const request = {
          command: ['prlimit', '--as=' + losslessLimits.addressSpaceBytes,
            '--stack=' + losslessLimits.stackBytes, '--', executable, grammar, input, output],
          directory: path.join(directory, 'supervisor'), timeoutMs: limit.timeoutMs,
          timeoutPolicy: limit.timeoutPolicy, maxBuffer: losslessLimits.responseBytes,
        };
        const result = spawnSync('python3', [supervisor, JSON.stringify(request)], {
          encoding: 'utf8', timeout: limit.supervisorGuardMs, maxBuffer: losslessLimits.responseBytes,
          // Pinned Lean starts a separate main thread by default. Keep lexical
          // work on the bounded process stack and disable unused task workers.
          env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0',
            LEAN_STACK_SIZE_KB: '8192' },
        });
        pinnedTool(executable, sha256);
        if (result.error || result.status !== 0) refuse('SUPERVISOR');
        let metrics;
        try { metrics = JSON.parse(result.stdout); } catch { refuse('SUPERVISOR_RESPONSE'); }
        if (metrics.error || metrics.status !== 0 || metrics.signal) {
          // Bounded helper diagnostics accompany refusal; no output becomes a snapshot.
          const diagnostic = name => regularFile(
            path.join(request.directory, 'tool.' + name + '.txt'), losslessLimits.responseBytes,
          ).subarray(0, 4096).toString('utf8');
          throw new Error('PSC1_LOSSLESS_PROCESS', {
            cause: { metrics, stdout: diagnostic('stdout'), stderr: diagnostic('stderr') },
          });
        }
        if (!regularFile(input, losslessLimits.sourceBytes).equals(source)) refuse('INPUT_CHANGED');
        let wire;
        try { wire = JSON.parse(decoder.decode(regularFile(output, losslessLimits.responseBytes))); }
        catch { refuse('RESPONSE_JSON'); }
        const { diagnosticCoordinatesVerified } = validateResponse(wire, source, grammar);
        const sourceSha256 = hash(source);
        const sourceId = hash(JSON.stringify([protocol, module, grammar, losslessProfile, sourceSha256]));
        const snapshot = deepFreeze({
          protocol, sourceId, sourceSha256, module, grammar, profile: losslessProfile, uri,
          byteLength: source.length, status: wire.status, diagnostic: wire.diagnostic,
          diagnosticCoordinatesVerified,
          pieces: wire.pieces.map(p => ({ ...p, id: sourceId + ':' + p.ordinal })),
          authority: { lexicalOnly: true, admission: 'not-run', publication: false },
          metrics: { elapsedMs: metrics.elapsedMs, maxRssKiB: metrics.maxRssKiB,
            peakTreeRssKiB: metrics.peakTreeRssKiB, timeoutMs: metrics.timeoutMs },
        });
        snapshots.set(snapshot, source);
        return snapshot;
      } finally { fs.rmSync(directory, { recursive: true, force: true }); }
    },
    reconstruct(snapshot) {
      const source = saved(snapshot);
      return Buffer.from(source);
    },
    stageTextEdits(snapshot, currentBytes, edits) {
      const source = saved(snapshot), current = bytesCopy(currentBytes);
      if (!current.equals(source)) refuse('STALE_SNAPSHOT');
      if (!Array.isArray(edits) || edits.length > losslessLimits.edits) refuse('EDITS');
      const chunks = [];
      let cursor = 0, previousStart = -1, size = source.length;
      for (const edit of edits) {
        exactKeys(edit, ['startByte', 'endByte', 'replacement']);
        const { startByte, endByte } = edit;
        if (!boundary(source, startByte) || !boundary(source, endByte) ||
            endByte < startByte || startByte < cursor || startByte <= previousStart) refuse('EDIT_RANGE');
        const replacement = bytesCopy(edit.replacement);
        size += replacement.length - (endByte - startByte);
        if (size > losslessLimits.sourceBytes) refuse('EDIT_LIMIT');
        chunks.push(source.subarray(cursor, startByte), replacement);
        cursor = endByte; previousStart = startByte;
      }
      chunks.push(source.subarray(cursor));
      const candidate = Buffer.concat(chunks);
      // A lexical snapshot is not permission to publish, even if no bytes changed.
      return { bytes: candidate, basedOn: snapshot.sourceId, sha256: hash(candidate),
        admission: 'not-run', semanticEquivalence: 'not-claimed', publicationAuthority: false };
    },
  });
}
