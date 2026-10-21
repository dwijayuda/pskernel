#!/usr/bin/env node
// Diagnostic input export only. Capture the original transport before RunDag;
// native DecodeChecked and V1 admission remain the only diagnostic decisions.
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const SOURCE = '369bee5801bd5e4476837684fad3f7e1ca8c422c';
const BODY = '85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47';
const ADAPTED = '443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1';
const sha = value => createHash('sha256').update(value).digest('hex');
const require = (condition, message) => { if (!condition) throw Error(message); };
const options = Object.create(null);
const allowed = new Set(['--kernel', '--input', '--replay', '--out', '--receipt', '--source-sha']);
for (let index = 2; index < process.argv.length; index += 2) {
  const key = process.argv[index], value = process.argv[index + 1];
  require(allowed.has(key) && typeof value === 'string' && !Object.hasOwn(options, key),
    'invalid or duplicate native input exporter argument');
  options[key] = value;
}
require(Object.keys(options).length === allowed.size, 'missing native input exporter argument');
require(options['--source-sha'] === SOURCE, 'native input source identity differs');
const input = readFileSync(options['--input']);
const newline = input.indexOf(10);
require(newline >= 0 && sha(input) === ADAPTED && sha(input.subarray(newline + 1)) === BODY,
  'authenticated Church input or body differs');
const decode = bytes => new TextDecoder('utf-8', { fatal: true }).decode(bytes);
const inputText = decode(input);
const replayBytes = readFileSync(options['--replay']);
const replay = decode(replayBytes);
const kernelBytes = readFileSync(options['--kernel']);
const anchor = '    const commands=order.map(group=>C.admit(group.request));\n';
require(replay.split(anchor).length === 2 && !replay.includes('__psc1NativeCaptureToken'),
  'original pre-RunDag capture anchor differs');
const hook = [
  '    throw {',
  '      nativeCaptureToken: __psc1NativeCaptureToken, arena, commands,',
  '      requests: order.map(group=>group.request),',
  '      records, exportedDeclarations: metadata.length, coreInvoked',
  '    };',
  ''
].join('\n');
const captureSource =
  'const __psc1NativeCaptureToken = Object.freeze({});\n' +
  'export function nativeCaptureToken(){return __psc1NativeCaptureToken;}\n' +
  replay.replace(anchor, anchor + hook);
const detached = mkdtempSync(path.join(tmpdir(), 'psc1-native-input-export-'));
let kernel, capturedModule, captured;
try {
  writeFileSync(path.join(detached, 'kernel.mjs'), kernelBytes);
  writeFileSync(path.join(detached, 'capture.mjs'), captureSource);
  kernel = await import(pathToFileURL(path.join(detached, 'kernel.mjs')).href);
  capturedModule = await import(pathToFileURL(path.join(detached, 'capture.mjs')).href);
  try {
    capturedModule.replayText(kernel, inputText);
    throw Error('native input capture unexpectedly returned a semantic result');
  } catch (error) {
    if (!error || error.nativeCaptureToken !== capturedModule.nativeCaptureToken()) throw error;
    captured = error;
  }
} finally {
  rmSync(detached, { recursive: true, force: true });
}
require(captured.coreInvoked === false && captured.records === 227 &&
  captured.exportedDeclarations === 6 && captured.requests.length === 4 &&
  captured.commands.length === 4 && captured.arena.size === 197n,
  'authenticated Church transport shape differs');
const get = name => {
  require(Object.hasOwn(kernel, name), 'missing generated export ' + name);
  return kernel[name];
};
const N = get('PsKernelName'), L = get('PsKernelLevel'), B = get('PsKernelBinderInfo');
const Literal = get('PsKernelLiteral'), E = get('PsKernelExprV2Node');
const S = get('PsKernelDefinitionSafety'), H = get('PsKernelReducibilityHints');
const D = get('PsKernelDagDeclarationRequest'), C = get('PsKernelDagCommand');
const List = get('List');
const make = (constructor, args = []) =>
  typeof constructor === 'function' ? constructor(...args) : constructor;
const variant = (value, constructor, args = []) =>
  capturedModule.generatedVariantEqual(value, make(constructor, args));
const natural = value => {
  require(typeof value === 'bigint' && value >= 0n, 'non-natural generated scalar');
  return value.toString();
};
const boolean = value => {
  require(typeof value === 'boolean', 'non-Boolean generated scalar');
  return value ? 'true' : 'false';
};
const leanString = value => {
  require(typeof value === 'string' && value.isWellFormed(), 'invalid generated string');
  return '(String.ofList [' + Array.from(value,
    char => '(Char.ofNat ' + char.codePointAt(0) + ')').join(', ') + '])';
};
const listValues = value => {
  const items = [], seen = new Set();
  for (;;) {
    if (variant(value, List.nil)) return items;
    require(!seen.has(value) && variant(value, List.cons, [value.head, value.tail]),
      'invalid or cyclic generated List');
    seen.add(value);
    items.push(value.head);
    value = value.tail;
  }
};
const leanList = (value, emit) => '[' + listValues(value).map(emit).join(', ') + ']';
const leanArray = (value, emit) => {
  require(Array.isArray(value), 'invalid generated Array');
  return '#[' + value.map(emit).join(',\n  ') + ']';
};
const name = value => {
  if (variant(value, N.anonymous)) return 'PsKernelName.anonymous';
  if (variant(value, N.str, [value.parent, value.value]))
    return '(PsKernelName.str ' + name(value.parent) + ' ' + leanString(value.value) + ')';
  if (variant(value, N.num, [value.parent, value.value]))
    return '(PsKernelName.num ' + name(value.parent) + ' ' + natural(value.value) + ')';
  throw Error('unknown generated Name constructor');
};
const level = value => {
  if (variant(value, L.zero)) return 'PsKernelLevel.zero';
  if (variant(value, L.succ, [value.of]))
    return '(PsKernelLevel.succ ' + level(value.of) + ')';
  for (const tag of ['max', 'imax']) {
    if (variant(value, L[tag], [value.left, value.right]))
      return '(PsKernelLevel.' + tag + ' ' + level(value.left) + ' ' + level(value.right) + ')';
  }
  for (const tag of ['param', 'mvar']) {
    if (variant(value, L[tag], [value.name]))
      return '(PsKernelLevel.' + tag + ' ' + name(value.name) + ')';
  }
  throw Error('unknown generated Level constructor');
};
const binder = value => {
  for (const tag of ['default', 'implicit', 'strictImplicit', 'instImplicit'])
    if (variant(value, B[tag])) return 'PsKernelBinderInfo.' + tag;
  throw Error('unknown generated BinderInfo constructor');
};
const literal = value => {
  if (variant(value, Literal.nat, [value.value]))
    return '(PsKernelLiteral.nat ' + natural(value.value) + ')';
  if (variant(value, Literal.str, [value.value]))
    return '(PsKernelLiteral.str ' + leanString(value.value) + ')';
  throw Error('unknown generated Literal constructor');
};
const node = value => {
  if (variant(value, E.bvar, [value.index]))
    return '(PsKernelExprV2Node.bvar ' + natural(value.index) + ')';
  for (const tag of ['fvar', 'mvar'])
    if (variant(value, E[tag], [value.name]))
      return '(PsKernelExprV2Node.' + tag + ' ' + name(value.name) + ')';
  if (variant(value, E.sort, [value.level]))
    return '(PsKernelExprV2Node.sort ' + level(value.level) + ')';
  if (variant(value, E.const, [value.name, value.levels]))
    return '(PsKernelExprV2Node.const ' + name(value.name) + ' ' + leanList(value.levels, level) + ')';
  if (variant(value, E.app, [value.fn, value.arg]))
    return '(PsKernelExprV2Node.app ' + natural(value.fn) + ' ' + natural(value.arg) + ')';
  for (const tag of ['lam', 'forallE'])
    if (variant(value, E[tag], [value.name, value.type, value.body, value.binderInfo]))
      return '(PsKernelExprV2Node.' + tag + ' ' + name(value.name) + ' ' +
        natural(value.type) + ' ' + natural(value.body) + ' ' + binder(value.binderInfo) + ')';
  if (variant(value, E.letE, [value.name, value.type, value.value, value.body, value.nondep]))
    return '(PsKernelExprV2Node.letE ' + name(value.name) + ' ' + natural(value.type) + ' ' +
      natural(value.value) + ' ' + natural(value.body) + ' ' + boolean(value.nondep) + ')';
  if (variant(value, E.lit, [value.value]))
    return '(PsKernelExprV2Node.lit ' + literal(value.value) + ')';
  if (variant(value, E.mdata, [value.metadata, value.body]))
    return '(PsKernelExprV2Node.mdata ' + natural(value.metadata) + ' ' + natural(value.body) + ')';
  if (variant(value, E.proj, [value.typeName, value.index, value.body]))
    return '(PsKernelExprV2Node.proj ' + name(value.typeName) + ' ' +
      natural(value.index) + ' ' + natural(value.body) + ')';
  throw Error('unknown generated DAG node constructor');
};
const entry = value => '(PsKernelExprV2Entry.mk ' + node(value.node) + ' ' +
  natural(value.hash) + ' ' + natural(value.looseRange) + ' ' +
  boolean(value.hasFVar) + ' ' + boolean(value.hasExprMVar) + ' ' + natural(value.depth) + ')';
const safety = value => {
  for (const tag of ['unsafeDef', 'safe', 'partialDef'])
    if (variant(value, S[tag])) return 'PsKernelDefinitionSafety.' + tag;
  throw Error('unknown generated definition safety');
};
const hints = value => {
  for (const tag of ['opaqueHint', 'abbrevHint'])
    if (variant(value, H[tag])) return 'PsKernelReducibilityHints.' + tag;
  if (variant(value, H.regular, [value.height]))
    return '(PsKernelReducibilityHints.regular ' + natural(value.height) + ')';
  throw Error('unknown generated reducibility hint');
};
const base = value => '(PsKernelDagConstantBase.mk ' + name(value.name) + ' ' +
  leanList(value.levelParams, name) + ' ' + natural(value.type) + ')';
const definition = value => '(PsKernelDagDefinition.mk ' + base(value.base) + ' ' +
  natural(value.value) + ' ' + hints(value.hints) + ' ' + safety(value.safety) + ')';
const constructor = value => '(PsKernelDagConstructor.mk ' + name(value.name) + ' ' +
  natural(value.type) + ')';
const inductive = value => '(PsKernelDagInductive.mk ' + name(value.name) + ' ' +
  natural(value.type) + ' ' + leanList(value.ctors, constructor) + ')';
const group = value => '(PsKernelDagInductiveGroup.mk ' + leanList(value.levelParams, name) +
  ' ' + natural(value.numParams) + ' ' + leanList(value.types, inductive) + ' ' +
  boolean(value.isUnsafe) + ')';
const requestKinds = [];
const request = value => {
  let tag, fields;
  if (variant(value, D.axiomDecl, [value.base, value.isUnsafe])) {
    tag = 'axiomDecl'; fields = [base(value.base), boolean(value.isUnsafe)];
  } else if (variant(value, D.definitionDecl, [value.value])) {
    tag = 'definitionDecl'; fields = [definition(value.value)];
  } else if (variant(value, D.theoremDecl, [value.base, value.value])) {
    tag = 'theoremDecl'; fields = [base(value.base), natural(value.value)];
  } else if (variant(value, D.opaqueDecl, [value.base, value.value, value.isUnsafe])) {
    tag = 'opaqueDecl'; fields = [base(value.base), natural(value.value), boolean(value.isUnsafe)];
  } else if (variant(value, D.mutualDefinitions, [value.values])) {
    tag = 'mutualDefinitions'; fields = [leanList(value.values, definition)];
  } else if (variant(value, D.quot)) {
    tag = 'quot'; fields = [];
  } else if (variant(value, D.ordinaryInductive,
      [value.levelParams, value.numParams, value.value, value.isUnsafe])) {
    tag = 'ordinaryInductive'; fields = [leanList(value.levelParams, name),
      natural(value.numParams), inductive(value.value), boolean(value.isUnsafe)];
  } else if (variant(value, D.mutualInductive, [value.value])) {
    tag = 'mutualInductive'; fields = [group(value.value)];
  } else if (variant(value, D.nestedInductive, [value.value])) {
    tag = 'nestedInductive'; fields = [group(value.value)];
  } else if (variant(value, D.unsupported, [value.feature])) {
    tag = 'unsupported'; fields = [leanString(value.feature)];
  } else throw Error('unknown generated declaration request');
  requestKinds.push(tag);
  return '(PsKernelDagDeclarationRequest.' + tag + (fields.length ? ' ' + fields.join(' ') : '') + ')';
};
for (let index = 0; index < captured.requests.length; index++)
  require(variant(captured.commands[index], C.admit, [captured.requests[index]]),
    'captured admission command/request identity differs');
const arena = captured.arena;
let entryCount = 0;
const emittedEntry = value => { entryCount++; return entry(value); };
const arenaSource = '{\n  pages := ' + leanArray(arena.pages,
  page => leanArray(page, emittedEntry)) + '\n  active := ' + leanArray(arena.active, emittedEntry) +
  '\n  size := ' + natural(arena.size) + '\n  pageLimit := ' + natural(arena.pageLimit) + '\n}';
require(BigInt(entryCount) === arena.size, 'raw captured arena entry count differs');
const requestSource = '[' + captured.requests.map(request).join(',\n  ') + ']';
const fixture = [
  'import Ps.KernelCore.API.DagTypes',
  'import Ps.KernelCore.Core.ExprV2.Paged',
  '',
  '/- Exact host export of the authenticated original transport input.',
  '   Cached metadata is untrusted and must pass native DecodeChecked.',
  '   No exported recursor body or environment metadata is installed. -/',
  'def nativeChurchSourceSha : String := ' + leanString(SOURCE),
  'def nativeChurchBodySha256 : String := ' + leanString(BODY),
  'def nativeChurchAdaptedSha256 : String := ' + leanString(ADAPTED),
  '',
  'def nativeChurchArena : PsKernelExprV2PagedArena := ' + arenaSource,
  '',
  'def nativeChurchRequests : List PsKernelDagDeclarationRequest := ' + requestSource,
  ''
].join('\n');
writeFileSync(options['--out'], fixture);
const receipt = {
  format: 'psc1-authentic-native-v1-input-export-v1',
  source_sha: SOURCE, body_sha256: BODY, adapted_input_sha256: ADAPTED,
  input_bytes: input.length, kernel_sha256: sha(kernelBytes),
  original_replay_sha256: sha(replayBytes), capture_replay_sha256: sha(captureSource),
  fixture_sha256: sha(fixture), generator_sha256: sha(readFileSync(new URL(import.meta.url))),
  records: captured.records, exported_declarations: captured.exportedDeclarations,
  arena_nodes: arena.size.toString(), emitted_arena_nodes: entryCount,
  admission_requests: captured.requests.length, request_kinds: requestKinds,
  generated_admission_invoked: false, imported_recursor_metadata: false,
  requires_native_decode_checked: true, kernel_qualified: false
};
writeFileSync(options['--receipt'], JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_ARENA_NATIVE_INPUT_EXPORT ' + JSON.stringify(receipt));
