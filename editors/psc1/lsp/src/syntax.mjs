// Lexical conveniences only. This module neither elaborates nor verifies ProofScript.
const declarations = /^(\s*)(?:(?:public|private|protected|noncomputable|partial|unsafe)\s+)*(const|function|def|theorem|lemma|opaque|axiom|inductive|structure|class|abbrev)\s+([\p{L}_][\p{L}\p{N}_'.]*)/gmu;
const identifier = /[\p{L}_][\p{L}\p{N}_'.]*/gu;
export const keywords = ['const', 'function', 'theorem', 'def', 'inductive', 'structure', 'namespace', 'end', 'import', 'public', 'if', 'then', 'else', 'match', 'with', 'let', 'return', 'by'];

export function maskedSource(text) {
  const out = text.split('');
  let block = 0, string = false, escaped = false, line = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i], pair = text.slice(i, i + 2);
    if (line) { if (c === '\n') line = false; else out[i] = ' '; continue; }
    if (block) {
      if (pair === '/-') { block++; out[i] = out[++i] = ' '; }
      else if (pair === '-/') { block--; out[i] = out[++i] = ' '; }
      else if (c !== '\n' && c !== '\r') out[i] = ' ';
      continue;
    }
    if (string) {
      if (c !== '\n' && c !== '\r') out[i] = ' ';
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') string = false;
      continue;
    }
    if (pair === '--' || pair === '//') { line = true; out[i] = out[++i] = ' '; }
    else if (pair === '/-') { block = 1; out[i] = out[++i] = ' '; }
    else if (c === '"') { string = true; out[i] = ' '; }
  }
  return out.join('');
}

export function wordAt(document, position) {
  const text = maskedSource(document.getText()), offset = document.offsetAt(position);
  for (const match of text.matchAll(identifier)) {
    if (match.index <= offset && offset <= match.index + match[0].length)
      return { name: match[0], range: { start: document.positionAt(match.index), end: document.positionAt(match.index + match[0].length) } };
    if (match.index > offset) break;
  }
  return null;
}

export function outline(document) {
  const text = maskedSource(document.getText()), matches = [...text.matchAll(declarations)];
  return matches.map((m, index) => {
    const offset = m.index + m[0].lastIndexOf(m[3]);
    return { name: m[3], kind: m[2], verified: false, syntaxOnly: true,
      range: { start: document.positionAt(m.index + m[1].length), end: document.positionAt(matches[index + 1]?.index ?? text.length) },
      selectionRange: { start: document.positionAt(offset), end: document.positionAt(offset + m[3].length) } };
  });
}

export function lexicalHighlights(document, position) {
  const word = wordAt(document, position);
  if (!word) return [];
  const result = [];
  for (const match of maskedSource(document.getText()).matchAll(identifier)) {
    if (match[0] === word.name) result.push({ range: { start: document.positionAt(match.index), end: document.positionAt(match.index + match[0].length) }, kind: 1 });
    if (result.length >= 1000) break;
  }
  return result;
}

// The compiler emits one-based Unicode scalar columns; LSP uses zero-based UTF-16.
export function compilerPosition(text, line, column) {
  const rows = text.split('\n'), row = Math.max(0, Math.min(rows.length - 1, (Number(line) || 1) - 1));
  return { line: row, character: Array.from(rows[row]).slice(0, Math.max(0, (Number(column) || 1) - 1)).join('').length };
}

export function originDeclarations(document, declarationsForModule) {
  const text = document.getText(), lexical = outline(document);
  return declarationsForModule.map((d, index) => {
    const start = compilerPosition(text, d.line, d.column);
    const shortName = d.name.split('.').at(-1);
    const source = lexical.find(s => s.range.start.line === start.line && (s.name === d.name || s.name === shortName));
    const next = declarationsForModule[index + 1];
    const end = next ? compilerPosition(text, next.line, next.column) : document.positionAt(text.length);
    return { ...d, uri: document.uri, range: { start, end },
      selectionRange: source?.selectionRange ?? { start, end: start },
      kind: d.kind || source?.kind || 'def', syntaxOnly: false, verified: d.verified === true };
  });
}

export function contains(range, position) {
  const before = (a, b) => a.line < b.line || (a.line === b.line && a.character <= b.character);
  return before(range.start, position) && before(position, range.end);
}

export function importAt(document, position) {
  const line = maskedSource(document.getText()).split('\n')[position.line] || '';
  const match = /^\s*(?:public\s+)?import\s+([\p{L}_][\p{L}\p{N}_.]*)\s*;?\s*$/u.exec(line);
  if (!match) return null;
  const start = line.indexOf(match[1]);
  return position.character >= start && position.character <= start + match[1].length ? match[1] : null;
}
