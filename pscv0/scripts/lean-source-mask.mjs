// Shared lexical masking for source-structural audits, not a Lean parser.
// Offsets (UTF-16 code units) and line breaks are preserved. Profile rules and
// the compiler remain responsible for rejecting unsupported/malformed syntax.
// Character grammar: https://lean-lang.org/doc/reference/latest/Basic-Types/Characters/
// Raw strings: https://lean-lang.org/doc/reference/latest/Basic-Types/Strings/
const character = /'(?:\\(?:[rnt\\"']|x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4})|[^'\\])'/uy;
const identifierTail = /[\p{L}\p{N}\p{M}_'!?]/u;
const blank = text => text.replace(/[^\r\n]/g, ' ');

export function maskLeanSource(source, { preserveStrings = false, strict = false } = {}) {
  if (typeof source !== 'string') throw new Error('PSC_LEAN_LEXICAL_SOURCE');
  const parts = [];
  let index = 0;
  const emit = (start, end, preserve = false) =>
    parts.push(preserve ? source.slice(start, end) : blank(source.slice(start, end)));
  const unfinished = kind => {
    if (strict) throw new Error('PSC_LEAN_LEXICAL_UNTERMINATED: ' + kind);
  };
  while (index < source.length) {
    const start = index, char = source[index], next = source[index + 1];
    if (char === '-' && next === '-') {
      index = source.indexOf('\n', index + 2);
      if (index < 0) index = source.length;
      emit(start, index);
    } else if (char === '/' && next === '-') {
      let depth = 1;
      index += 2;
      while (index < source.length && depth > 0) {
        if (source.startsWith('/-', index)) { depth++; index += 2; }
        else if (source.startsWith('-/', index)) { depth--; index += 2; }
        else index++;
      }
      if (depth) unfinished('comment');
      emit(start, index);
    } else if (char === "'" && !identifierTail.test(source[index - 1] ?? '')) {
      character.lastIndex = index;
      const match = character.exec(source);
      if (match) { index += match[0].length; emit(start, index); }
      else { parts.push(char); index++; }
    } else {
      // A suffix apostrophe belongs to an identifier, never to a character.
      // Raw literals end with the exact opening number of hashes.
      let rawHashes = -1;
      if (char === 'r' && !identifierTail.test(source[index - 1] ?? '')) {
        let end = index + 1;
        while (source[end] === '#') end++;
        if (source[end] === '"') rawHashes = end - index - 1;
      }
      if (rawHashes >= 0) {
        const openingEnd = index + rawHashes + 2;
        const terminator = '"' + '#'.repeat(rawHashes);
        const end = source.indexOf(terminator, openingEnd);
        if (end < 0) { unfinished('raw string'); index = source.length; }
        else index = end + terminator.length;
        emit(start, index, preserveStrings);
      } else if (char === '"') {
        index++;
        let closed = false;
        while (index < source.length) {
          const current = source[index++];
          if (current === '\\' && index < source.length) index++;
          else if (current === '"') { closed = true; break; }
        }
        if (!closed) unfinished('string');
        emit(start, index, preserveStrings);
      } else {
        parts.push(char);
        index++;
      }
    }
  }
  return parts.join('');
}
