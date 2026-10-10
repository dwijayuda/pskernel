import { createHash } from 'node:crypto';
import { TextDecoder } from 'node:util';
import { loadGeneratedCompiler } from './sh1-source-snapshot.mjs';
import { assertProofScriptGrammar } from './proofscript-source.mjs';
import { buildChecked } from './checked-build.mjs';

export const queryProtocol = 'psc-source-query/1';
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');
const point = Object.freeze({ line: 0, character: 0 });
const fallbackRange = Object.freeze({ start: point, end: point });
const variant = term => {
  if (!term || typeof term !== 'object') return undefined;
  return Object.getOwnPropertySymbols(term)
    .map(key => term[key]).find(value => typeof value === 'string');
};
const diagnosticCode = message => {
  const found = /^PSC(?:0|1|2)?_[A-Z0-9_]+/u.exec(message);
  return found ? found[0] : 'PSC_QUERY_UNAVAILABLE';
};
function utf16AtUtf8Offset(source, offset) {
  const full = Buffer.from(source, 'utf8');
  if (typeof offset === 'bigint' && offset > BigInt(Number.MAX_SAFE_INTEGER)) return null;
  const number = Number(offset);
  if (!Number.isSafeInteger(number) || number < 0 || number > full.length) return null;
  const prefix = full.subarray(0, number).toString('utf8');
  if (Buffer.byteLength(prefix, 'utf8') !== number) return null;
  let line = 0, character = 0, afterCR = false;
  for (const char of prefix) {
    if (char === '\r') {
      line++; character = 0; afterCR = true;
    } else if (char === '\n') {
      if (!afterCR) line++;
      character = 0; afterCR = false;
    } else {
      character += char.length; afterCR = false;
    }
  }
  return { line, character };
}

export function syntaxErrorRange(source, error) {
  const span = error?.span;
  if (!span || !span.start || !span.stop) return null;
  const start = utf16AtUtf8Offset(source, span.start.byteOffset);
  const end = utf16AtUtf8Offset(source, span.stop.byteOffset);
  if (!start || !end || end.line < start.line ||
      end.line === start.line && end.character < start.character) return null;
  return { start, end };
}

async function preciseSyntaxDiagnostic(sourceText, compilerPath, compilerSha256) {
  try {
    const { compiler } = await loadGeneratedCompiler(compilerPath, {
      expectedSha256: compilerSha256,
    });
    assertProofScriptGrammar(compiler);
    const parsed = compiler.psParseProofScriptSource(sourceText);
    if (variant(parsed) !== 'error') return null;
    const frontend = parsed.error;
    if (!['lex', 'parse'].includes(variant(frontend))) return null;
    const issue = frontend.error;
    const kind = variant(issue);
    if (typeof kind !== 'string') return null;
    let message = kind;
    if (kind === 'expectedText' && typeof issue.expected === 'string' &&
        typeof issue.actual === 'string') {
      message = 'Expected ' + JSON.stringify(issue.expected.slice(0, 80)) +
        ', encountered ' + JSON.stringify(issue.actual.slice(0, 80));
    } else if (kind === 'unexpectedEnd' && typeof issue.expected === 'string') {
      message = 'Unexpected end of input; expected ' + issue.expected.slice(0, 80);
    } else if (kind === 'unterminatedString') message = 'Unterminated string';
    else if (kind === 'unterminatedBlockComment') message = 'Unterminated block comment';
    else if (kind === 'newlineInString') message = 'Newline inside string literal';
    else if (kind === 'unterminatedCharacter') message = 'Unterminated character literal';
    else if (kind === 'invalidSource' && typeof issue.reason === 'string') {
      message = 'Invalid source: ' + issue.reason.slice(0, 80);
    }
    const range = syntaxErrorRange(sourceText, issue);
    return {
      source: 'ProofScript', code: 'PSC_SYNTAX_' +
        kind.replace(/([a-z])([A-Z])/gu, '$1_$2').toUpperCase(), severity: 1,
      message: message.slice(0, 300),
      range: range ?? fallbackRange,
      location: range ? 'syntax-span' : 'source-unlocated',
    };
  } catch {
    // Compiler identity or parser problems never create a successful result.
    // They are reported by the original protected query below.
    return null;
  }
}

/**
 * Editor-only query contract: declaration admission of an in-memory .ps
 * document plus its saved import closure. It never performs erasure,
 * emits files, accepts extension operations, or publishes a build receipt.
 */
export async function queryCheckedSource({
  entryPath, sourceText, compilerPath, compilerSha256, kernel, nativeBinaryPath, signal,
}) {
  if (typeof entryPath !== 'string' || !entryPath.endsWith('.ps') ||
      typeof sourceText !== 'string' || Buffer.byteLength(sourceText, 'utf8') > 1024 * 1024 ||
      new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(Buffer.from(sourceText)) !== sourceText) {
    throw new Error('PSC_QUERY_INPUT_PROFILE');
  }
  const sourceSha256 = hash(sourceText);
  const result = { schemaVersion: 1, kind: queryProtocol,
    entryPath, sourceSha256, scope: 'document-with-saved-import-closure',
    stage: 'kernel-admission-only', irChecked: false, abiChecked: false,
    targetChecked: false, semanticPreservationProved: false, pscvVerified: false,
    diagnostics: [] };
  try {
    const receipt = await buildChecked({
      entryPath, sourceOverlay: sourceText, compilerPath, compilerSha256,
      kernel, nativeBinaryPath, profile: 'checked', checkOnly: true, signal,
    });
    if (!receipt.kernelAdmissionAccepted ||
        receipt.editorBuffer?.sourceSha256 !== sourceSha256 ||
        receipt.editorBuffer?.notPublished !== true) throw new Error('PSC_QUERY_RECEIPT_BINDING');
    return { ...result, status: 'accepted', kernelAdmissionAccepted: true,
      sourceClosureSha256: receipt.sourceClosureSha256,
      kernel: receipt.kernel, compiler: receipt.compiler };
  } catch (error) {
    signal?.throwIfAborted();
    const message = String(error?.message ?? error).slice(0, 1024);
    const expectedSourceError = /^PSC(?:0|1|2)?_(?:.*(?:PARSE|PREPARE|ELAB|KERNEL_REJECTED|SOURCE_(?:UTF8|IMPORT|CYCLE)|IMPORT|PROJECT_SOURCE))/u.test(message);
    const precise = expectedSourceError
      ? await preciseSyntaxDiagnostic(sourceText, compilerPath, compilerSha256) : null;
    const diagnostic = precise ?? {
      source: 'ProofScript', severity: expectedSourceError ? 1 : 2,
      code: diagnosticCode(message),
      message: (expectedSourceError
        ? 'ProofScript declaration check rejected (exact source location unavailable): '
        : 'ProofScript checker unavailable (no source-validity conclusion): ') +
        message.slice(0, 512),
      range: fallbackRange, location: 'source-unlocated',
    };
    return { ...result, status: expectedSourceError ? 'rejected' : 'unavailable',
      kernelAdmissionAccepted: false, diagnostics: [diagnostic] };
  }
}
