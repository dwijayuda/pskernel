// Component container packaging only. The qualified GC backend owns every core instruction.
import fs from 'node:fs';
import path from 'node:path';
import { isDeepStrictEqual } from 'node:util';
const fail = (code) => {
  throw Error('PSC1_COMPONENT_' + code);
};
const keywords = new Set([
  'use',
  'type',
  'func',
  'u8',
  'u16',
  'u32',
  'u64',
  's8',
  's16',
  's32',
  's64',
  'f32',
  'f64',
  'char',
  'resource',
  'own',
  'borrow',
  'record',
  'flags',
  'variant',
  'enum',
  'bool',
  'string',
  'option',
  'result',
  'future',
  'stream',
  'error-context',
  'list',
  'map',
  '_',
  'as',
  'from',
  'static',
  'interface',
  'tuple',
  'world',
  'import',
  'export',
  'package',
  'constructor',
  'include',
  'with',
  'async',
]);
const ident = (name) =>
  typeof name === 'string' &&
  !keywords.has(name) &&
  /^[a-z][a-z0-9]*(?:-[a-z][a-z0-9]*)*$/.test(name);
const leb = (n) => {
  if (!Number.isSafeInteger(n) || n < 0 || n > 0xffffffff) fail('LENGTH');
  const out = [];
  do {
    let b = n % 128;
    n = Math.floor(n / 128);
    out.push(b + (n ? 128 : 0));
  } while (n);
  return Buffer.from(out);
};
const cat = (parts) => Buffer.concat(parts.map((p) => Buffer.from(p)));
const name = (s) => {
  const b = Buffer.from(s);
  return cat([leb(b.length), b]);
};
const vector = (items) => cat([leb(items.length), ...items]);
const section = (id, bytes) => cat([[id], leb(bytes.length), bytes]);
export function componentSchema(candidate) {
  if (candidate.outputAbi || !candidate.publicNames.length) fail('ABI_UNSUPPORTED');
  return candidate.publicNames.map((publicName) => {
    if (!ident(publicName)) fail('WIT_EXPORT_NAME_UNSUPPORTED');
    const rows = candidate.specializedIr[4].filter((row) => row[0] === publicName);
    if (rows.length !== 1 || rows[0].length !== 5 || rows[0][1].length) fail('ABI_UNSUPPORTED');
    const row = rows[0],
      bool = (t) => isDeepStrictEqual(t, ['primitive', 'bool']);
    if (
      !bool(row[3]) ||
      row[2].length > 16 ||
      row[2].some((p) => !Array.isArray(p) || p.length !== 2 || !ident(p[0]) || !bool(p[1]))
    )
      fail('ABI_UNSUPPORTED');
    const parameters = row[2].map((p) => p[0]);
    if (new Set(parameters).size !== parameters.length) fail('ARGUMENT_DUPLICATE');
    return { name: publicName, parameters };
  });
}
// Same canonical type/alias/lift/export section layout as Ps.BackendWasm.Component.
// Extra core transport exports remain private to the instantiated core.
export function encodeBoolComponent(core, schema) {
  const module = new WebAssembly.Module(core);
  if (WebAssembly.Module.imports(module).length) fail('CORE_IMPORT');
  const exports = WebAssembly.Module.exports(module);
  for (const e of schema)
    if (exports.filter((x) => x.name === e.name && x.kind === 'function').length !== 1)
      fail('CORE_EXPORT');
  const types = schema.map((e) =>
    cat([[0x40], vector(e.parameters.map((p) => cat([name(p), [0x7f]]))), [0x00, 0x7f]]),
  );
  const aliases = schema.map((e) => cat([[0x00, 0x00, 0x01, 0x00], name(e.name)]));
  const lifts = schema.map((_, i) => cat([[0x00, 0x00], leb(i), [0x00], leb(i)]));
  const exportsSection = schema.map((e, i) => cat([[0x00], name(e.name), [0x01], leb(i), [0x00]]));
  return cat([
    [0, 97, 115, 109, 13, 0, 1, 0],
    section(1, core),
    section(2, [1, 0, 0, 0]),
    section(7, vector(types)),
    section(6, vector(aliases)),
    section(8, vector(lifts)),
    section(11, vector(exportsSection)),
  ]);
}
export function expectedBoolWit(schema) {
  return (
    'package proofscript:psc1;\n\nworld app {\n' +
    schema
      .map(
        (e) =>
          '  export ' +
          e.name +
          ': func(' +
          e.parameters.map((p) => p + ': bool').join(', ') +
          ') -> bool;\n',
      )
      .join('') +
    '}\n'
  );
}
// wasm-tools prints its root package name; package identity is not the public ABI.
// This closed parser rejects aliases, imports, other types and trailing declarations.
export function observedBoolWit(text) {
  const tokens =
    text
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/\/\/[^\n]*/g, '')
      .match(/->|[%a-zA-Z0-9_-]+|[^\s]/g) || [];
  let i = 0;
  const take = () => tokens[i++],
    expect = (s) => {
      const observed = take();
      if (observed !== s)
        fail('WIT_SIGNATURE:expected=' + s + ':observed=' + JSON.stringify(observed));
    };
  if (tokens[i] === 'package') {
    while (i < tokens.length && take() !== ';') {}
  }
  expect('world');
  if (!ident(take())) fail('WIT_WORLD');
  expect('{');
  const exports = [];
  while (tokens[i] !== '}' && i < tokens.length) {
    expect('export');
    const n = take();
    if (!ident(n)) fail('WIT_NAME');
    expect(':');
    expect('func');
    expect('(');
    const parameters = [];
    if (tokens[i] !== ')')
      do {
        const p = take();
        if (!ident(p)) fail('WIT_NAME');
        expect(':');
        expect('bool');
        parameters.push(p);
        if (tokens[i] !== ',') break;
        take();
      } while (true);
    expect(')');
    expect('->');
    expect('bool');
    expect(';');
    exports.push({ name: n, parameters });
  }
  expect('}');
  if (i !== tokens.length || !exports.length) fail('WIT_TRAILING');
  return exports;
}
export function prepareComponent(stage, candidate, coreArtifact, tools, run) {
  if (!tools) fail('TOOLS_UNAVAILABLE');
  const schema = componentSchema(candidate),
    core = fs.readFileSync(path.join(stage, 'target.wasm'));
  const bytes = encodeBoolComponent(core, schema),
    file = path.join(stage, 'target.component.wasm');
  fs.writeFileSync(file, bytes);
  fs.writeFileSync(
    path.join(stage, 'target.component.wasm.hex'),
    'psc1-wasm-component-hex/1:' + bytes.toString('hex'),
  );
  fs.writeFileSync(path.join(stage, 'target.wit'), expectedBoolWit(schema));
  run('component-core-validate', ['validate', path.join(stage, 'target.wasm')], tools.executable);
  run('component-validate', ['validate', file], tools.executable);
  const observed = run('component-wit', ['component', 'wit', file], tools.executable);
  fs.writeFileSync(path.join(stage, 'observed.wit'), observed);
  if (!isDeepStrictEqual(observedBoolWit(observed), schema)) fail('WIT_SIGNATURE_MISMATCH');
  return {
    targetFile: 'target.component.wasm',
    runtimeFile: 'target.component.wasm',
    sourceFile: 'target.component.wasm.hex',
    files: [
      ...coreArtifact.files,
      'target.component.wasm',
      'target.component.wasm.hex',
      'target.wit',
      'observed.wit',
    ],
    consumer: 'wasm-tools1.254.0-direct-GC-component-Bool',
    compilerTarget: 'wasm-core',
    schema,
  };
}
