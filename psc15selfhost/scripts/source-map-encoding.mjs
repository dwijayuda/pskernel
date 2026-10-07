const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const fail = code => { throw new Error('PSC_SOURCE_MAP_' + code); };
const coordinate = n => {
  if (!Number.isInteger(n) || n < 0 || n > 2147483647 || Object.is(n, -0)) fail('COORDINATE');
};

/** ECMA-426 signed 32-bit VLQ, including its specified -2^31 sentinel.
 * Arithmetic avoids JavaScript's signed bitwise truncation at the limits.
 */
export function encodeSourceMapVlq(value) {
  if (!Number.isInteger(value) || value < -2147483648 || value > 2147483647 || Object.is(value, -0)) fail('VLQ_RANGE');
  let remaining = value === -2147483648 ? 1 : 2 * Math.abs(value) + (value < 0 ? 1 : 0);
  let output = '';
  do {
    const digit = remaining % 32; remaining = Math.floor(remaining / 32);
    output += alphabet[digit + (remaining ? 32 : 0)];
  } while (remaining);
  return output;
}

/** Ordered absolute positions: [generatedLine, generatedColumn] for unmapped,
 * or [generatedLine, generatedColumn, sourceIndex, sourceLine, sourceColumn].
 * Only the generated column resets at a line break. No symbol-name attribution
 * is guessed from these coarse declaration anchors.
 */
export function encodeSourceMapMappings(entries, { maxBytes = 128 * 1024 * 1024, maxSegments = 1000000 } = {}) {
  if (![maxBytes, maxSegments].every(n => Number.isSafeInteger(n) && n > 0) ||
      !Array.isArray(entries) || entries.length > maxSegments) fail('RESOURCE');
  const output = []; let length = 0, line = 0, column = 0, source = 0, sourceLine = 0, sourceColumn = 0;
  let previousLine = -1, previousColumn = -1, firstOnLine = true;
  function append(text) {
    if ((length += text.length) > maxBytes) fail('RESOURCE');
    output.push(text);
  }
  for (const entry of entries) {
    if (!Array.isArray(entry) || ![2, 5].includes(entry.length)) fail('SEGMENT');
    entry.forEach(coordinate);
    const [nextLine, nextColumn] = entry;
    if (nextLine < previousLine || (nextLine === previousLine && nextColumn <= previousColumn)) fail('ORDER');
    if (nextLine > line) {
      if (nextLine - line > maxBytes - length) fail('RESOURCE');
      append(';'.repeat(nextLine - line)); line = nextLine; column = 0; firstOnLine = true;
    }
    if (!firstOnLine) append(',');
    append(encodeSourceMapVlq(nextColumn - column)); column = nextColumn;
    if (entry.length === 5) {
      append(encodeSourceMapVlq(entry[2] - source));
      append(encodeSourceMapVlq(entry[3] - sourceLine));
      append(encodeSourceMapVlq(entry[4] - sourceColumn));
      [source, sourceLine, sourceColumn] = entry.slice(2);
    }
    firstOnLine = false; previousLine = nextLine; previousColumn = nextColumn;
  }
  // Terminate the last mapping line explicitly. ECMA-426 permits the final
  // empty line; this also makes terminal unmapped segments unambiguous to
  // consumers that recognize separators before recognizing end-of-input.
  if (entries.length) append(';');
  return output.join('');
}
