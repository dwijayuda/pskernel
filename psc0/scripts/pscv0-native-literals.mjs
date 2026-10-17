// Harness-only source literals shared by PSCV0 wrappers and Rust assertions.
// Both source languages accept these ASCII hex escapes and Unicode scalars.
export function quotedSourceString(value) {
  let result = '"';
  for (const character of value) {
    const code = character.codePointAt(0);
    if (code >= 0xd800 && code <= 0xdfff) throw new Error('non-scalar harness string');
    if (character === '"') result += '\\"';
    else if (character === '\\') result += '\\\\';
    else if (character === '\n') result += '\\n';
    else if (character === '\t') result += '\\t';
    else if (code < 32 || code === 127) result += '\\x' + code.toString(16).padStart(2, '0');
    else result += character;
  }
  return result + '"';
}
