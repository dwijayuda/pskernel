/** Decode only export names for diagnostics from an already engine-validated
 * module. This metadata never validates code, changes acceptance or selects code.
 */
export function wasmFunctionExports(bytes) {
  if (!(bytes instanceof Uint8Array)) throw new Error('PSC_WASM_DIAGNOSTIC_BYTES');
  let position = 8, limit = bytes.length;
  const byte = () => {
    if (position >= limit) throw new Error('PSC_WASM_DIAGNOSTIC_TRUNCATED');
    return bytes[position++];
  };
  const u32 = () => {
    let value = 0, factor = 1;
    for (let count = 0; count < 5; count++) {
      const part = byte();
      if (count === 4 && part > 15) throw new Error('PSC_WASM_DIAGNOSTIC_U32');
      value += (part & 127) * factor;
      if (part < 128) return value;
      factor *= 128;
    }
    throw new Error('PSC_WASM_DIAGNOSTIC_U32');
  };
  const names = new Map();
  while (position < bytes.length) {
    limit = bytes.length;
    const section = byte(), size = u32(), end = position + size;
    if (end > bytes.length) throw new Error('PSC_WASM_DIAGNOSTIC_SECTION');
    if (section === 7) {
      limit = end;
      const count = u32();
      for (let item = 0; item < count; item++) {
        const length = u32(), nameEnd = position + length;
        if (nameEnd > limit) throw new Error('PSC_WASM_DIAGNOSTIC_NAME');
        const name = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes.subarray(position, nameEnd));
        position = nameEnd;
        const kind = byte(), index = u32();
        if (kind === 0) names.set(index, [...(names.get(index) ?? []), name]);
      }
      if (position !== end) throw new Error('PSC_WASM_DIAGNOSTIC_EXPORT_END');
    }
    position = end;
  }
  return names;
}

export function describeWasmFailure(error, names) {
  const indices = [...new Set([...String(error?.stack ?? '').matchAll(/wasm-function\[(\d+)\]/gu)]
    .map(match => Number(match[1])))];
  return indices.map(index => ({ index, exports: names.get(index) ?? [] }));
}
