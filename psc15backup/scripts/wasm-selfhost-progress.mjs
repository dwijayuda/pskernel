import { wasmFunctionExports, describeWasmFailure } from './wasm-function-diagnostics.mjs';

function required(exports, name) {
  if (typeof exports[name] !== 'function') throw new Error('PSC_WASM_PROGRESS_EXPORT_MISSING: ' + name);
  return exports[name];
}

export async function loadWasmSelfhostCompiler(bytes) {
  const module = await WebAssembly.compile(bytes), instance = await WebAssembly.instantiate(module, {});
  const names = wasmFunctionExports(bytes);
  const api = { describeFailure: error => describeWasmFailure(error, names) };
  for (const name of ['Initial', 'Failed', 'Parse', 'Elaborate', 'Prepare', 'Finish', 'Validate', 'Specialize', 'Lower', 'Encode', 'Output'])
    api[name] = required(instance.exports, 'psCompilerWasmProgress' + name);
  for (const [key, name] of Object.entries({ stringNew: '__ps_selfhost_string_new', stringSet: '__ps_selfhost_string_set',
    stringFinish: '__ps_selfhost_string_finish',
    bytesIsNil: '__ps_selfhost_bytes_is_nil', bytesHead: '__ps_selfhost_bytes_head', bytesTail: '__ps_selfhost_bytes_tail',
    sourceListEmpty: 'psCompilerSelfHostSourceListEmpty', sourceListCons: 'psCompilerSelfHostSourceListCons',
    compileWhole: 'psCompilerWasm32ProofScriptSourcesBytesOrEmpty' })) api[key] = required(instance.exports, name);
  return Object.freeze(api);
}

function wasmString(api, text) {
  const chars = Array.from(text), value = api.stringNew(chars.length);
  for (let index = 0; index < chars.length; index++) api.stringSet(value, index, chars[index].codePointAt(0));
  return api.stringFinish(value);
}

function byteList(api, value) {
  const bytes = [];
  for (let cursor = value; api.bytesIsNil(cursor) === 0; cursor = api.bytesTail(cursor)) {
    if (bytes.length >= 512 * 1024 * 1024) throw new Error('PSC2_DIRECT_WASM_SELFHOST_OUTPUT_LIMIT');
    const byte = api.bytesHead(cursor);
    if (!Number.isInteger(byte) || byte < 0 || byte > 255) throw new Error('PSC2_DIRECT_WASM_SELFHOST_BYTE_RANGE');
    bytes.push(byte);
  }
  if (!bytes.length) throw new Error('PSC2_DIRECT_WASM_SELFHOST_COMPILE_FAILED_OR_EMPTY');
  return Uint8Array.from(bytes);
}

/** Uses the same preparation/IR/specialization/lowering/encoding functions as
 * the monolithic entry, with observable boundaries between calls. No fallback.
 */
export function compileWasmSelfhostProgress(api, sourceItems, phase = () => {}) {
  let state = api.Initial();
  const accept = (next, stage) => {
    const failed = api.Failed(next);
    if (failed !== 0) throw new Error('PSC_WASM_PROGRESS_FAILED: ' + stage);
    state = next;
  };
  for (let index = 0; index < sourceItems.length; index++) {
    const item = sourceItems[index];
    const position = String(index + 1) + '/' + String(sourceItems.length) + ':' + item.path;
    phase('parse:' + position);
    accept(api.Parse(state, wasmString(api, item.source)), 'parse:' + item.path);
    phase('elaborate:' + position);
    accept(api.Elaborate(state), 'elaborate:' + item.path);
  }
  for (const [name, method] of [['prepare:finish', 'Finish'], ['validated-ir', 'Validate'],
    ['specialize', 'Specialize'], ['lower', 'Lower'], ['encode', 'Encode']]) {
    phase(name);
    try { accept(api[method](state), name); }
    catch (error) {
      phase('failure-functions:' + JSON.stringify(api.describeFailure(error)));
      throw error;
    }
  }
  phase('read-output');
  const bytes = byteList(api, api.Output(state));
  phase('output-bytes:' + String(bytes.length));
  return bytes;
}

/** Retained for focused differential checking of the new orchestration. */
export function compileWasmSelfhostMonolithic(api, sources) {
  let list = api.sourceListEmpty();
  for (let index = sources.length - 1; index >= 0; index--) list = api.sourceListCons(wasmString(api, sources[index]), list);
  return byteList(api, api.compileWhole(list));
}
