// Exact lexical snapshots and read-only semantic ownership. No edit publication authority.
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { compilerSourceClosureDigest, runIndependentChecker } from './compiler-host-protocol.mjs';
import { supervisorLimit } from '../scripts/selfhost-qualification-profiles.mjs';

export const losslessProfile = 'psc1-practical-core-v1/lean4.35.0/lossless-1';
export const losslessLimits = Object.freeze({
  sourceBytes: 1048576, responseBytes: 33554432, pieces: 262144,
  edits: 4096, timeoutMs: 240000, addressSpaceBytes: 4294967296, stackBytes: 8388608,
});
const protocol = 'psc1-lossless-capture/1';
const losslessTools = new WeakMap();
const ownershipTools = new WeakMap();
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const refuse = code => { throw new Error('PSC1_LOSSLESS_' + code); };
const decoder = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
const supervisor = fileURLToPath(new URL('../scripts/bounded-process.py', import.meta.url));

function exactKeys(value, keys) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).length !== keys.length ||
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
  const tool = Object.freeze({
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
  losslessTools.set(tool, { saved });
  return tool;
}


function runSourceHelper({ executable, sha256 }, mode, encoded, consume) {
  pinnedTool(executable, sha256);
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-ownership-'));
  try {
    const input = path.join(directory, 'request.json'), output = path.join(directory, 'index.json');
    const admissionsFile = path.join(directory, 'admissions.json'), irFile = path.join(directory, 'ir.json');
    fs.writeFileSync(input, encoded, { flag: 'wx', mode: 0o600 });
    const limit = supervisorLimit(240000, 'standard-240s');
    const control = {
      command: ['prlimit', '--as=' + losslessLimits.addressSpaceBytes,
        '--stack=' + losslessLimits.stackBytes, '--', executable,
        mode, input, output, admissionsFile, irFile],
      directory: path.join(directory, 'supervisor'), timeoutMs: limit.timeoutMs,
      timeoutPolicy: limit.timeoutPolicy, maxBuffer: losslessLimits.responseBytes,
    };
    const result = spawnSync('python3', [supervisor, JSON.stringify(control)], {
      encoding: 'utf8', timeout: limit.supervisorGuardMs, maxBuffer: losslessLimits.responseBytes,
      env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0',
        LEAN_STACK_SIZE_KB: '8192' },
    });
    pinnedTool(executable, sha256);
    if (result.error || result.status !== 0) refuse('OWNERSHIP_SUPERVISOR');
    let metrics;
    try { metrics = JSON.parse(result.stdout); } catch { refuse('OWNERSHIP_SUPERVISOR_RESPONSE'); }
    if (metrics.error || metrics.status !== 0 || metrics.signal) {
      throw new Error('PSC1_LOSSLESS_OWNERSHIP_PROCESS', { cause: {
        metrics, stderr: regularFile(path.join(control.directory, 'tool.stderr.txt'),
          losslessLimits.responseBytes).subarray(0, 4096).toString('utf8'),
      } });
    }
    if (regularFile(input, losslessLimits.responseBytes).toString('utf8') !== encoded)
      refuse('OWNERSHIP_INPUT_CHANGED');
    let wire;
    try { wire = JSON.parse(decoder.decode(regularFile(output, losslessLimits.responseBytes))); }
    catch { refuse('OWNERSHIP_RESPONSE_JSON'); }
    return consume({ wire, admissionsFile, irFile, metrics });
  } finally { fs.rmSync(directory, { recursive: true, force: true }); }
}

/** Read-only semantic provenance over genuine lexical capabilities. The host
 * pins both tools; source bytes cannot choose executables, policies or checkers.
 * Independent admission covers exact logical graph bytes, not refactoring equivalence.
 */
export function createSourceOwnershipTool({
  lexicalTool, executable, sha256, checkerExecutable, checkerSha256,
}) {
  const lexical = losslessTools.get(lexicalTool);
  if (!lexical) refuse('OWNERSHIP_LEXICAL_TOOL');
  pinnedTool(executable, sha256);
  pinnedTool(checkerExecutable, checkerSha256);
  const indexes = new WeakMap();
  const protocol = 'psc1-source-ownership/1';
  const roles = new Set(['sourceDeclaration', 'inductiveType', 'structureType',
    'constructor', 'recursor', 'normalizedWorker', 'publicWrapper']);
  const select = snapshots => {
    if (!Array.isArray(snapshots) || !snapshots.length || snapshots.length > 256)
      refuse('OWNERSHIP_CLOSURE');
    const seen = new Set();
    let total = 0;
    return snapshots.map(snapshot => {
      const bytes = Buffer.from(lexical.saved(snapshot));
      if (snapshot.status !== 'accepted' || seen.has(snapshot.module))
        refuse('OWNERSHIP_SOURCE');
      seen.add(snapshot.module);
      total += bytes.length;
      if (total > losslessLimits.responseBytes) refuse('OWNERSHIP_REQUEST_LIMIT');
      const positions = new Map();
      for (const piece of snapshot.pieces) {
        positions.set(piece.span.start.byteOffset, piece.span.start);
        positions.set(piece.span.stop.byteOffset, piece.span.stop);
      }
      const tokens = snapshot.pieces.filter(p => p.kind === 'token');
      return { snapshot, bytes, module: snapshot.module, kind: snapshot.grammar,
        text: decoder.decode(bytes), positions, tokens,
        tokenStarts: new Map(tokens.map((p, i) => [p.span.start.byteOffset, i])) };
    });
  };
  const coreName = name => {
    if (!Array.isArray(name) || !name.length || name.length > 4096) refuse('OWNERSHIP_NAME');
    for (const component of name) {
      if (!Array.isArray(component) || component.length !== 2 ||
          !['s', 'n'].includes(component[0]) || typeof component[1] !== 'string' ||
          !component[1].isWellFormed() || Buffer.byteLength(component[1]) > 4096 ||
          (component[0] === 'n' && !/^(0|[1-9][0-9]*)$/.test(component[1])))
        refuse('OWNERSHIP_NAME');
    }
    return JSON.stringify(name);
  };
  function spanInSource(span, row) {
    validSpan(span, row.bytes);
    for (const p of [span.start, span.stop]) {
      if (!row.positions.has(p.byteOffset) || !positionEqual(p, row.positions.get(p.byteOffset)))
        refuse('OWNERSHIP_POSITION');
    }
  }
  const tool = Object.freeze({
    analyze({ snapshots, entry, assurance = 'checked' }) {
      const rows = select(snapshots);
      if (!['checked', 'ordinary-checked'].includes(assurance) ||
          typeof entry !== 'string' || !rows.some(row => row.module === entry) ||
          rows.some(row => row.kind !== rows[0].kind)) refuse('OWNERSHIP_REQUEST');
      const grammar = rows[0].kind;
      const sourceClosureDigest = compilerSourceClosureDigest(rows);
      const requestId = hash(JSON.stringify([protocol, sourceClosureDigest, entry, assurance]));
      const encoded = JSON.stringify(['psc1-compiler-service/1', requestId,
        sourceClosureDigest, grammar, assurance, entry, rows.map(row => [row.module, row.text])]);
      if (Buffer.byteLength(encoded) > losslessLimits.responseBytes) refuse('OWNERSHIP_REQUEST_LIMIT');
      pinnedTool(executable, sha256); pinnedTool(checkerExecutable, checkerSha256);
      return runSourceHelper({ executable, sha256 }, 'index', encoded,
        ({ wire, admissionsFile, irFile, metrics }) => {
          if (wire?.status === 'refused') {
            exactKeys(wire, ['protocol', 'status', 'requestId', 'sourceClosureDigest', 'error']);
            if (wire.protocol !== protocol || wire.requestId !== requestId ||
                wire.sourceClosureDigest !== sourceClosureDigest) refuse('OWNERSHIP_REFUSAL_IDENTITY');
            throw new Error('PSC1_LOSSLESS_OWNERSHIP_REFUSED', { cause: wire.error });
          }
          exactKeys(wire, ['protocol', 'status', 'requestId', 'sourceClosureDigest',
            'grammar', 'assurance', 'entry', 'modules', 'sourceCoreDeclarations',
            'logicalCoreDeclarations', 'partialNames']);
          if (wire.protocol !== protocol || wire.status !== 'prepared' || wire.requestId !== requestId ||
              wire.sourceClosureDigest !== sourceClosureDigest || wire.grammar !== grammar ||
              wire.assurance !== assurance || wire.entry !== entry ||
              !Array.isArray(wire.modules) || wire.modules.length !== rows.length ||
              !Array.isArray(wire.partialNames) || wire.partialNames.some(n => typeof n !== 'string') ||
              !Number.isSafeInteger(wire.sourceCoreDeclarations) || wire.sourceCoreDeclarations < 0 ||
              !Number.isSafeInteger(wire.logicalCoreDeclarations) || wire.logicalCoreDeclarations < 0)
            refuse('OWNERSHIP_RESPONSE');
          const names = new Set();
          let members = 0;
          const modules = wire.modules.map((module, moduleIndex) => {
            const row = rows[moduleIndex], snapshot = row.snapshot;
            exactKeys(module, ['module', 'byteLength', 'imports', 'sourceDeclarations', 'origins']);
            if (module.module !== row.module || module.byteLength !== row.bytes.length ||
                !Array.isArray(module.imports) || module.imports.some(n => typeof n !== 'string') ||
                !Array.isArray(module.origins) || module.origins.length !== module.sourceDeclarations)
              refuse('OWNERSHIP_MODULE');
            const origins = module.origins.map((origin, sourceIndex) => {
              exactKeys(origin, ['sourceIndex', 'sourceName', 'nameSpan', 'span', 'members', 'normalization']);
              if (origin.sourceIndex !== sourceIndex || !Array.isArray(origin.sourceName) ||
                  !origin.sourceName.length || origin.sourceName.some(n => typeof n !== 'string' || !n) ||
                  !Array.isArray(origin.members) || !origin.members.length) refuse('OWNERSHIP_ORIGIN');
              spanInSource(origin.span, row); spanInSource(origin.nameSpan, row);
              if (origin.span.start.byteOffset > origin.nameSpan.start.byteOffset ||
                  origin.span.stop.byteOffset < origin.nameSpan.stop.byteOffset ||
                  origin.nameSpan.start.byteOffset === origin.nameSpan.stop.byteOffset)
                refuse('OWNERSHIP_NAME_SPAN');
              const tokens = [];
              const startToken = row.tokenStarts.get(origin.nameSpan.start.byteOffset);
              if (startToken === undefined) refuse('OWNERSHIP_TOKEN_ALIGNMENT');
              for (let i = startToken; i < row.tokens.length &&
                  row.tokens[i].span.stop.byteOffset <= origin.nameSpan.stop.byteOffset; i++)
                tokens.push(row.tokens[i]);
              if (!tokens.length || tokens[0].span.start.byteOffset !== origin.nameSpan.start.byteOffset ||
                  tokens.at(-1).span.stop.byteOffset !== origin.nameSpan.stop.byteOffset ||
                  tokens.some(p => !['identifier', 'symbol'].includes(p.token.kind)))
                refuse('OWNERSHIP_TOKEN_ALIGNMENT');
              const sourceOwnerId = hash(JSON.stringify([protocol, snapshot.sourceId, sourceIndex]));
              const outputMembers = origin.members.map((member, memberIndex) => {
                exactKeys(member, ['index', 'name', 'displayName', 'role']);
                const identity = coreName(member.name);
                if (member.index !== memberIndex || names.has(identity) || !roles.has(member.role) ||
                    typeof member.displayName !== 'string' || !member.displayName.isWellFormed() ||
                    member.displayName !== member.name.reduce((prefix, c) => prefix ? prefix + '.' + c[1] : c[1], ''))
                  refuse('OWNERSHIP_MEMBER');
                names.add(identity); members++;
                return { ...member, ownerId: sourceOwnerId,
                  id: hash(JSON.stringify([sourceOwnerId, memberIndex, member.role, member.name])) };
              });
              if (origin.normalization !== null) {
                exactKeys(origin.normalization, ['workerName', 'span']);
                const worker = coreName(origin.normalization.workerName);
                spanInSource(origin.normalization.span, row);
                if (origin.normalization.span.start.byteOffset < origin.span.start.byteOffset ||
                    origin.normalization.span.stop.byteOffset > origin.span.stop.byteOffset ||
                    !outputMembers.some(m => m.role === 'normalizedWorker' && coreName(m.name) === worker))
                  refuse('OWNERSHIP_NORMALIZATION');
              }
              return { ...origin, id: sourceOwnerId, sourceId: snapshot.sourceId,
                namePieceIds: tokens.map(p => p.id), members: outputMembers };
            });
            return { ...module, sourceId: snapshot.sourceId, sourceSha256: snapshot.sourceSha256,
              profile: snapshot.profile, grammar: snapshot.grammar, origins };
          });
          if (members !== wire.sourceCoreDeclarations) refuse('OWNERSHIP_COVERAGE');
          const admissions = decoder.decode(regularFile(admissionsFile, losslessLimits.responseBytes));
          const ir = regularFile(irFile, losslessLimits.responseBytes);
          pinnedTool(checkerExecutable, checkerSha256);
          const checker = runIndependentChecker(checkerExecutable, admissions);
          pinnedTool(checkerExecutable, checkerSha256);
          const admissionsSha256 = hash(admissions), originalIrSha256 = hash(ir);
          const id = hash(JSON.stringify([protocol, sha256, sourceClosureDigest,
            admissionsSha256, originalIrSha256, rows.map(r => r.snapshot.sourceId)]));
          const index = deepFreeze({ protocol, id, sourceClosureDigest, entry, grammar, assurance,
            modules, sourceCoreDeclarations: members, logicalCoreDeclarations: wire.logicalCoreDeclarations,
            partialNames: wire.partialNames, admissionsSha256, originalIrSha256,
            checker: { ...checker, executableSha256: checkerSha256, accepted: true },
            metrics: { elapsedMs: metrics.elapsedMs, maxRssKiB: metrics.maxRssKiB,
              peakTreeRssKiB: metrics.peakTreeRssKiB, timeoutMs: metrics.timeoutMs },
            authority: { readOnlyOwnership: true, referenceResolution: false,
              semanticEquivalence: 'not-claimed', publication: false } });
          indexes.set(index, rows.map(r => r.snapshot.sourceId));
          return index;

      });
    },
    assertCurrent(index, snapshots) {
      const identities = indexes.get(index);
      if (!identities) refuse('OWNERSHIP_INDEX');
      const current = select(snapshots).map(r => r.snapshot.sourceId);
      if (JSON.stringify(current) !== JSON.stringify(identities)) refuse('OWNERSHIP_STALE');
      return true;
    },
  });
  ownershipTools.set(tool, { lexicalTool, executable, sha256 });
  return tool;
}


/** Checked candidate conversion, with exact before/after graph correspondence.
 * It never writes source files. Read candidate bytes explicitly for review.
 */
export function createCheckedSourceConverter({ ownershipTool }) {
  const configuration = ownershipTools.get(ownershipTool);
  if (!configuration) refuse('CONVERSION_OWNERSHIP_TOOL');
  const { lexicalTool, executable, sha256 } = configuration;
  const conversions = new WeakMap();
  const protocol = 'psc1-source-conversion/1';
  const commentPieces = snapshot => snapshot.pieces.filter(p =>
    p.kind === 'lineComment' || p.kind === 'blockComment');
  const semanticOwners = index => index.modules.map(module => ({
    module: module.module, imports: module.imports,
    origins: module.origins.map(origin => ({
      sourceIndex: origin.sourceIndex, sourceName: origin.sourceName,
      members: origin.members.map(member => ({
        index: member.index, name: member.name, role: member.role,
      })),
      normalization: origin.normalization?.workerName ?? null,
    })),
  }));

  function requireCorrespondence(before, after) {
    if (after.admissionsSha256 !== before.admissionsSha256 ||
        after.originalIrSha256 !== before.originalIrSha256 ||
        JSON.stringify(after.partialNames) !== JSON.stringify(before.partialNames) ||
        JSON.stringify(semanticOwners(after)) !== JSON.stringify(semanticOwners(before)))
      refuse('CONVERSION_CORRESPONDENCE');
  }

  function retainComments(original, target, before, after, policy) {
    const comments = commentPieces(original);
    if (!comments.length) return lexicalTool.reconstruct(target);
    const sourceOrigins = before.origins, targetOrigins = after.origins;
    const chunks = new Map();
    const put = (offset, comment) => chunks.set(offset, (chunks.get(offset) ?? '') + comment.raw + '\n');
    for (const comment of comments) {
      const inside = sourceOrigins.find(origin =>
        origin.span.start.byteOffset <= comment.span.start.byteOffset &&
        comment.span.stop.byteOffset <= origin.span.stop.byteOffset);
      if (inside) {
        if (policy !== 'owner-notes') refuse('CONVERSION_INNER_COMMENT');
        const next = targetOrigins[inside.sourceIndex];
        if (!next) refuse('CONVERSION_COMMENT_OWNER');
        put(next.span.start.byteOffset, comment);
      } else if (!sourceOrigins.length || comment.span.stop.byteOffset <=
          original.pieces.find(p => p.kind === 'token').span.start.byteOffset) {
        put(0, comment);
      } else {
        const following = sourceOrigins.find(origin =>
          origin.span.start.byteOffset >= comment.span.stop.byteOffset);
        const next = following ? targetOrigins[following.sourceIndex] : null;
        put(next ? next.span.start.byteOffset : target.byteLength, comment);
      }
    }
    const bytes = lexicalTool.reconstruct(target), output = [];
    let cursor = 0;
    for (const [offset, raw] of [...chunks].sort((a, b) => a[0] - b[0])) {
      output.push(bytes.subarray(cursor, offset));
      // Newlines around comments prevent token concatenation or line swallowing.
      if (offset > 0 && bytes[offset - 1] !== 10) output.push(Buffer.from('\n'));
      output.push(Buffer.from(raw));
      cursor = offset;
    }
    output.push(bytes.subarray(cursor));
    return Buffer.concat(output);
  }

  return Object.freeze({
    convert({ index, snapshots, targetGrammar, commentPolicy = 'preserve' }) {
      const started = Date.now();
      ownershipTool.assertCurrent(index, snapshots);
      if (!['lean', 'ps'].includes(targetGrammar) || !['preserve', 'owner-notes'].includes(commentPolicy))
        refuse('CONVERSION_REQUEST');
      const sources = snapshots.map(snapshot => ({
        module: snapshot.module, kind: snapshot.grammar,
        text: decoder.decode(lexicalTool.reconstruct(snapshot)),
      }));
      const sourceClosureDigest = compilerSourceClosureDigest(sources);
      const requestId = hash(JSON.stringify([protocol, sourceClosureDigest,
        index.entry, index.assurance, targetGrammar, commentPolicy]));
      const encoded = JSON.stringify(['psc1-compiler-service/1', requestId,
        sourceClosureDigest, index.grammar, index.assurance, index.entry,
        sources.map(row => [row.module, row.text])]);
      if (Buffer.byteLength(encoded) > losslessLimits.responseBytes) refuse('CONVERSION_REQUEST_LIMIT');
      const candidate = runSourceHelper({ executable, sha256 }, 'to-' + targetGrammar, encoded, ({ wire }) => {
        if (wire?.status === 'refused') {
          exactKeys(wire, ['protocol', 'status', 'requestId', 'sourceClosureDigest', 'error']);
          if (wire.protocol !== protocol || wire.requestId !== requestId ||
              wire.sourceClosureDigest !== sourceClosureDigest) refuse('CONVERSION_IDENTITY');
          throw new Error('PSC1_LOSSLESS_CONVERSION_REFUSED', { cause: wire.error });
        }
        exactKeys(wire, ['protocol', 'status', 'requestId', 'sourceClosureDigest',
          'sourceGrammar', 'targetGrammar', 'modules']);
        if (wire.protocol !== protocol || wire.status !== 'candidate' || wire.requestId !== requestId ||
            wire.sourceClosureDigest !== sourceClosureDigest || wire.sourceGrammar !== index.grammar ||
            wire.targetGrammar !== targetGrammar || !Array.isArray(wire.modules) ||
            wire.modules.length !== snapshots.length) refuse('CONVERSION_RESPONSE');
        return wire.modules.map((module, i) => {
          exactKeys(module, ['module', 'text']);
          if (module.module !== snapshots[i].module || typeof module.text !== 'string' ||
              !module.text.isWellFormed()) refuse('CONVERSION_MODULE');
          return lexicalTool.capture({ module: module.module, grammar: targetGrammar,
            bytes: Buffer.from(module.text) });
        });
      });
      const provisional = ownershipTool.analyze({
        snapshots: candidate, entry: index.entry, assurance: index.assurance,
      });
      requireCorrespondence(index, provisional);
      const retained = candidate.map((snapshot, i) => {
        const bytes = retainComments(snapshots[i], snapshot,
          index.modules[i], provisional.modules[i], commentPolicy);
        if (bytes.equals(lexicalTool.reconstruct(snapshot))) return snapshot;
        return lexicalTool.capture({ module: snapshot.module, grammar: targetGrammar, bytes });
      });
      const changed = retained.some((snapshot, i) => snapshot.sourceId !== candidate[i].sourceId);
      const checked = changed ? ownershipTool.analyze({
        snapshots: retained, entry: index.entry, assurance: index.assurance,
      }) : provisional;
      requireCorrespondence(index, checked);
      for (let i = 0; i < snapshots.length; i++) {
        const original = commentPieces(snapshots[i]).map(piece => [piece.kind, piece.raw]);
        const converted = commentPieces(retained[i]).map(piece => [piece.kind, piece.raw]);
        if (JSON.stringify(original) !== JSON.stringify(converted)) refuse('CONVERSION_COMMENTS');
      }
      const report = deepFreeze({
        protocol, id: hash(JSON.stringify([protocol, index.id, checked.id, commentPolicy])),
        sourceIndexId: index.id, candidateIndexId: checked.id, sourceGrammar: index.grammar,
        targetGrammar, entry: index.entry, assurance: index.assurance, commentPolicy,
        admissionsSha256: checked.admissionsSha256, originalIrSha256: checked.originalIrSha256,
        elapsedMs: Date.now() - started,
        originMap: index.modules.map((module, i) => ({
          module: module.module, from: module.sourceId, to: checked.modules[i].sourceId,
          declarations: module.origins.map((origin, j) => ({
            sourceIndex: origin.sourceIndex, before: origin.span,
            after: checked.modules[i].origins[j].span,
            nameBefore: origin.nameSpan, nameAfter: checked.modules[i].origins[j].nameSpan,
            members: origin.members.map(m => ({ name: m.name, role: m.role })),
          })),
        })),
        authority: { candidateOnly: true, sourceFilesWritten: false, publication: false,
          relation: 'equal canonical admission and original strict IR; identical member ownership',
          formalSourcePreservation: false, rename: false },
      });
      conversions.set(report, { original: index, snapshots: retained, checked });
      return report;
    },
    readCandidate(report, module) {
      const record = conversions.get(report);
      if (!record) refuse('CONVERSION_REPORT');
      const source = record.snapshots.find(snapshot => snapshot.module === module);
      if (!source) refuse('CONVERSION_MODULE');
      return lexicalTool.reconstruct(source);
    },
    candidateIndex(report) {
      const record = conversions.get(report);
      if (!record) refuse('CONVERSION_REPORT');
      return record.checked;
    },
    candidateSnapshots(report) {
      const record = conversions.get(report);
      if (!record) refuse('CONVERSION_REPORT');
      return Object.freeze([...record.snapshots]);
    },
    assertCurrent(report, snapshots) {
      const record = conversions.get(report);
      if (!record) refuse('CONVERSION_REPORT');
      return ownershipTool.assertCurrent(record.original, snapshots);
    },
  });
}
