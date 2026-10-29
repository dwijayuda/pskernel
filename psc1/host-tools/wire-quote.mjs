// Fixed host-owned wire serialization. Compiler/source data cannot select callbacks.
import { Buffer } from 'node:buffer';
const stringify = JSON.stringify.bind(JSON);
const parse = JSON.parse.bind(JSON);
const nativeNode = process.release?.name === 'node' && !process.versions.bun;
export function createNativeWireQuoter(generatedQuote) {
  if (typeof generatedQuote !== 'function') throw Error('PSC1_WIRE_QUOTE_FALLBACK');
  const counts = { nativeCalls: 0, nativeInputBytes: 0, fallbackCalls: 0 };
  const fallback = (value) => {
    counts.fallbackCalls++;
    return generatedQuote(value);
  };
  const quoteString = (value) => {
    if (!nativeNode || typeof value !== 'string') return fallback(value);
    let encoded,
      bytes,
      valid = false;
    try {
      bytes = Buffer.from(value, 'utf8');
      // Preserve the generated runtime's behavior for non-scalar UTF-16 input.
      if (bytes.toString('utf8') === value) {
        encoded = stringify(value);
        valid = typeof encoded === 'string' && parse(encoded) === value;
      }
    } catch {
      /* Use the normative generated serializer below. */
    }
    if (!valid) return fallback(value);
    counts.nativeCalls++;
    counts.nativeInputBytes += bytes.length;
    return encoded;
  };
  return Object.freeze({ quoteString, metrics: () => ({ ...counts }) });
}
