/**
 * PSCV native-Lean frontend M0 lexical preflight.
 *
 * This is a SOURCE-ONLY guard. It does not inspect imports, core declarations,
 * proof dependencies, ghost erasure, or approved specifications. It can never
 * establish PSCV-CERT-v1 and is deliberately conservative.
 */
export const forbiddenWords = new Set([
  'unsafe', 'partial', 'axiom', 'sorry', 'sorryAx', 'admit',
  'noncomputable', 'extern', 'native_decide', 'run_tac',
  'macro', 'macro_rules', 'syntax', 'elab', 'set_option',
]);

const asciiStart = ch => /[A-Za-z_]/.test(ch);
const asciiContinue = ch => /[A-Za-z0-9_']/.test(ch);

/**
 * Ignore source comments and double-quoted string literals, respecting
 * escaped quotes and arbitrarily nested Lean-style /- -/ comments.
 * Returns names and source positions, never a verification certificate.
 */
export function forbiddenSurfaceTokens(source) {
  const found = [];
  let i = 0;
  let line = 1;
  let column = 1;
  const take = () => {
    const ch = source[i++];
    if (ch === '\n') {
      line++;
      column = 1;
    } else {
      column++;
    }
    return ch;
  };
  while (i < source.length) {
    if (source.startsWith('--', i)) {
      while (i < source.length && source[i] !== '\n') take();
      continue;
    }
    if (source.startsWith('/-', i)) {
      const firstLine = line;
      let depth = 0;
      while (i < source.length) {
        if (source.startsWith('/-', i)) {
          depth++;
          take();
          take();
        } else if (source.startsWith('-/', i)) {
          depth--;
          take();
          take();
          if (depth === 0) break;
        } else {
          take();
        }
      }
      if (depth !== 0) {
        throw new Error('PSCV_LEAN_SOURCE: unterminated block comment at line ' + firstLine);
      }
      continue;
    }
    if (source[i] === '"') {
      const firstLine = line;
      take();
      let closed = false;
      while (i < source.length) {
        const ch = take();
        if (ch === '\\') {
          if (i >= source.length) break;
          take();
        } else if (ch === '"') {
          closed = true;
          break;
        } else if (ch === '\n') {
          throw new Error('PSCV_LEAN_SOURCE: newline in string at line ' + firstLine);
        }
      }
      if (!closed) throw new Error('PSCV_LEAN_SOURCE: unterminated string at line ' + firstLine);
      continue;
    }
    if (asciiStart(source[i])) {
      const tokenLine = line;
      const tokenColumn = column;
      let word = '';
      while (i < source.length && asciiContinue(source[i])) word += take();
      if (forbiddenWords.has(word)) {
        found.push({ word, line: tokenLine, column: tokenColumn });
      }
    } else {
      take();
    }
  }
  return found;
}

export function requireM0SourcePolicy(source) {
  const violations = forbiddenSurfaceTokens(source);
  if (violations.length !== 0) {
    throw new Error('PSCV_LEAN_SOURCE_REJECT: ' +
      violations.map(v => v.word + ' at ' + v.line + ':' + v.column).join(', '));
  }
}
