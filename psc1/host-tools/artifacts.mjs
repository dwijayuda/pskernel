// Host-side layout and filesystem operations only. Logical admission and typed
// IR decisions belong to the native Lean compiler, never to this helper.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { isDeepStrictEqual } from 'node:util';
import { parse } from '@babel/parser';
import * as prettier from 'prettier';

const require = createRequire(import.meta.url);
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const slash = value => value.split(path.sep).join('/');
const fail = (code, detail = '') => { throw new Error(`${code}${detail ? ': ' + detail : ''}`); };
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const json = value => JSON.stringify(value, null, 2) + '\n';
const sourceInfoName = 'psc1-input.json';
const nativePin = readJson(fileURLToPath(new URL('../NATIVE_SOURCE_PIN.json', import.meta.url)));

export function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 120_000, ...options
  });
  if (result.error || result.status !== 0) {
    fail('PSC1_HOST_TOOL_FAILED', `${command} ${args.join(' ')}\n${result.error?.message ?? result.stderr ?? result.signal}`);
  }
  return result.stdout;
}

function requireVersions() {
  for (const [name, expected] of [['prettier', '3.6.2'], ['@babel/parser', '7.28.0']]) {
    const actual = require(`${name}/package.json`).version;
    if (actual !== expected) fail('PSC1_FORMATTER_VERSION_MISMATCH', `${name}: ${actual}, expected ${expected}`);
  }
}

function parseProgram(source, kind) {
  return parse(source, {
    sourceType: 'module', plugins: kind === 'ts' ? ['typescript'] : [],
    errorRecovery: false, attachComment: false
  }).program;
}

// Strip only parser metadata. All syntax, literal values, operator identities,
// declaration order and control-flow nodes remain in the comparison.
const triviaKeys = new Set(['start', 'end', 'loc', 'extra', 'comments',
  'leadingComments', 'innerComments', 'trailingComments', 'tokens', 'errors']);
export function semanticTree(value) {
  if (Array.isArray(value)) return value.map(semanticTree);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).filter(key => !triviaKeys.has(key)).sort()
      .map(key => [key, semanticTree(value[key])]));
  }
  return value;
}

export async function formatEcma(source, kind) {
  requireVersions();
  const before = parseProgram(source, kind);
  const text = await prettier.format(source, {
    parser: kind === 'ts' ? 'typescript' : 'babel', printWidth: 100,
    tabWidth: 2, useTabs: false, semi: true, singleQuote: false,
    trailingComma: 'none', endOfLine: 'lf', quoteProps: 'preserve'
  });
  const after = parseProgram(text, kind);
  if (!isDeepStrictEqual(semanticTree(before), semanticTree(after))) {
    fail('PSC1_FORMATTING_CHANGED_SYNTAX_TREE');
  }
  return { text, program: after };
}

function declaredNames(statement) {
  const declaration = statement.type === 'ExportNamedDeclaration' ? statement.declaration : statement;
  if (!declaration) return [];
  if (declaration.type === 'VariableDeclaration') {
    return declaration.declarations.map(item => item.id?.name).filter(Boolean);
  }
  return declaration.id?.name ? [declaration.id.name] : [];
}

export function exportedNames(program) {
  const names = [];
  for (const statement of program.body) {
    if (statement.type === 'ExportDefaultDeclaration' || statement.type === 'ExportAllDeclaration') {
      fail('PSC1_UNPLANNED_EXPORT_KIND', statement.type);
    }
    if (statement.type === 'ExportNamedDeclaration') {
      names.push(...declaredNames(statement));
      for (const specifier of statement.specifiers ?? []) names.push(specifier.exported.name ?? specifier.exported.value);
    }
  }
  return names.sort();
}

const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
export function vlq(value) {
  if (!Number.isSafeInteger(value) || value < -2147483648 || value > 2147483647) {
    fail('PSC1_SOURCE_MAP_DELTA_RANGE', String(value));
  }
  let unsigned = value === -2147483648 ? 1 : Math.abs(value) * 2 + (value < 0 ? 1 : 0);
  let result = '';
  do {
    let digit = unsigned % 32;
    unsigned = Math.floor(unsigned / 32);
    if (unsigned) digit += 32;
    result += alphabet[digit];
  } while (unsigned);
  return result;
}

export function sourceMap(program, info, outputName) {
  const root = path.dirname(info.entryPath);
  const origins = new Map();
  info.sources.forEach((source, sourceIndex) => {
    for (const origin of source.origins) {
      if (origins.has(origin.name)) fail('PSC1_SOURCE_ORIGIN_AMBIGUOUS', origin.name);
      origins.set(origin.name, { ...origin, sourceIndex });
    }
  });
  const entries = [];
  for (const statement of program.body) {
    const names = declaredNames(statement);
    const origin = names.length === 1 ? origins.get(names[0]) : undefined;
    entries.push({ line: statement.loc.start.line - 1, column: statement.loc.start.column, origin });
    // Explicitly stop attributing a declaration at the end of its actual final
    // formatted span. Runtime prelude and generated-only statements are unmapped.
    entries.push({ line: statement.loc.end.line - 1, column: statement.loc.end.column });
  }
  entries.sort((a, b) => a.line - b.line || a.column - b.column);
  let line = 0, column = 0, source = 0, sourceLine = 0, sourceColumn = 0;
  let mappings = '', onLine = false;
  for (const entry of entries) {
    while (line < entry.line) { mappings += ';'; line++; column = 0; onLine = false; }
    if (onLine) mappings += ',';
    mappings += vlq(entry.column - column);
    column = entry.column;
    if (entry.origin) {
      const origin = entry.origin;
      mappings += vlq(origin.sourceIndex - source) + vlq(origin.line - sourceLine) + vlq(origin.column - sourceColumn);
      source = origin.sourceIndex; sourceLine = origin.line; sourceColumn = origin.column;
    }
    onLine = true;
  }
  return {
    version: 3, file: outputName,
    sources: info.sources.map(source => slash(path.relative(root, source.path))),
    sourcesContent: info.sources.map(source => source.text), names: [], mappings,
    x_psc1_mappingGranularity: 'declaration', x_psc1_sourceSnapshot: 'captured-before-admission'
  };
}

export async function formatTarget(stage, kind, fileName) {
  const info = readJson(path.join(stage, sourceInfoName));
  const file = path.join(stage, fileName);
  const result = await formatEcma(fs.readFileSync(file, 'utf8'), kind);
  const expected = [...info.publicNames].sort();
  if (!isDeepStrictEqual(exportedNames(result.program), expected)) {
    fail('PSC1_TARGET_PUBLIC_API_MISMATCH', fileName);
  }
  const declarationFile = path.join(stage, fileName.replace(/\.(?:js|ts)$/, '.d.ts'));
  const declaration = await formatEcma(fs.readFileSync(declarationFile, 'utf8'), 'ts');
  if (!isDeepStrictEqual(exportedNames(declaration.program), expected)) {
    fail('PSC1_DECLARATION_PUBLIC_API_MISMATCH', fileName);
  }
  fs.writeFileSync(declarationFile, declaration.text);
  fs.writeFileSync(file, result.text + `//# sourceMappingURL=${encodeURIComponent(fileName + '.map')}\n`);
  fs.writeFileSync(file + '.map', json(sourceMap(result.program, info, fileName)));
}

// This is an intentionally small structural WIT parser for the advertised scalar
// world. It rejects extra imports, exports, interfaces, duplicate names and any
// unrecognized syntax instead of accepting a substring of the requested name.
export function scalarWitApi(text) {
  const tokens = [];
  const lexer = /\s+|\/\/[^\n]*|\/\*[\s\S]*?\*\/|->|%?[a-z][a-z0-9]*(?:-[a-z][a-z0-9]*)*|[0-9]+|[{}():;,@.]/gy;
  let offset = 0;
  while (offset < text.length) {
    lexer.lastIndex = offset;
    const match = lexer.exec(text);
    if (!match) fail('PSC1_WIT_UNRECOGNIZED_TOKEN', String(offset));
    offset = lexer.lastIndex;
    if (!/^\s|^\/\//.test(match[0]) && !match[0].startsWith('/*')) tokens.push(match[0]);
  }
  let index = 0;
  const take = () => tokens[index++];
  const expect = wanted => { if (take() !== wanted) fail('PSC1_WIT_SYNTAX', `expected ${wanted}`); };
  const identifier = () => {
    const value = take();
    if (!/^%?[a-z][a-z0-9]*(?:-[a-z][a-z0-9]*)*$/.test(value ?? '')) fail('PSC1_WIT_IDENTIFIER');
    return value.replace(/^%/, '');
  };
  if (tokens[index] === 'package') {
    take(); identifier(); expect(':'); identifier();
    if (tokens[index] === '@') {
      take();
      for (let n = 0; n < 3; n++) {
        if (!/^[0-9]+$/.test(take() ?? '')) fail('PSC1_WIT_VERSION');
        if (n < 2) expect('.');
      }
    }
    expect(';');
  }
  expect('world'); identifier(); expect('{');
  const scalars = new Set(['bool', 'u8', 'u16', 'u32', 'u64', 's8', 's16', 's32', 's64', 'f32', 'f64']);
  const scalar = () => { const value = take(); if (!scalars.has(value)) fail('PSC1_WIT_SCALAR', String(value)); return value; };
  const exports = [];
  while (tokens[index] !== '}') {
    expect('export'); const name = identifier(); expect(':'); expect('func'); expect('(');
    const parameters = [];
    while (tokens[index] !== ')') {
      const parameter = identifier(); expect(':'); const type = scalar();
      if (parameters.some(p => p.name === parameter)) fail('PSC1_WIT_DUPLICATE_PARAMETER', parameter);
      parameters.push({ name: parameter, type });
      if (tokens[index] !== ')') expect(',');
    }
    expect(')'); expect('->'); const result = scalar(); expect(';');
    if (exports.some(e => e.name === name)) fail('PSC1_WIT_DUPLICATE_EXPORT', name);
    exports.push({ name, parameters, result });
  }
  expect('}');
  if (index !== tokens.length) fail('PSC1_WIT_TRAILING_SYNTAX');
  return exports.sort((a, b) => a.name.localeCompare(b.name, 'en'));
}

export function checkWit(expectedPath, observedPath) {
  const expected = scalarWitApi(fs.readFileSync(expectedPath, 'utf8'));
  const observed = scalarWitApi(fs.readFileSync(observedPath, 'utf8'));
  if (!isDeepStrictEqual(expected, observed)) fail('PSC1_COMPONENT_WIT_SIGNATURE_MISMATCH');
}

export function prepareRust(stage, fileName) {
  const source = fs.readFileSync(path.join(stage, fileName), 'utf8');
  const formatted = run('rustfmt', ['--edition', '2021', '--emit', 'stdout'], { input: source });
  if (!formatted.trim()) fail('PSC1_RUST_FORMAT_EMPTY');
  fs.writeFileSync(path.join(stage, fileName), formatted);
  const crate = path.join(stage, fileName.slice(0, -3) + '.cargo');
  fs.mkdirSync(path.join(crate, 'src'), { recursive: true });
  fs.writeFileSync(path.join(crate, 'src', 'lib.rs'), formatted);
  const plan = readTargetPlans(stage)?.plans.find(item => item.target === 'rust');
  const requirements = plan?.runtimeRequirements ?? ['num-bigint@0.4.6', 'num-traits@0.2.19'];
  fs.writeFileSync(path.join(crate, 'Cargo.toml'),
    '[package]\nname = "psc1_generated"\nversion = "0.0.0"\nedition = "2021"\npublish = false\n\n' +
    '[lib]\npath = "src/lib.rs"\n\n[dependencies]\n' +
    (requirements.includes('num-bigint@0.4.6') ? 'num-bigint = "=0.4.6"\n' : '') +
    (requirements.includes('num-traits@0.2.19') ? 'num-traits = "=0.2.19"\n' : ''));
  run('cargo', ['generate-lockfile', '--manifest-path', path.join(crate, 'Cargo.toml')]);
  run('cargo', ['check', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')], {
    env: { ...process.env, CARGO_TARGET_DIR: path.join(os.tmpdir(), 'psc1-scoped-cargo-target') }
  });
}

const targetInfoName = 'psc1-target.json';

function readTargetPlans(stage) {
  const file = path.join(stage, targetInfoName);
  if (!fs.existsSync(file)) return undefined;
  const descriptor = readJson(file);
  if (descriptor.schema !== 'psc1-direct-target-plan/1' ||
      descriptor.runtimeContract !== 'psc1-runtime-semantics/1' ||
      !Array.isArray(descriptor.plans) || descriptor.plans.length === 0) {
    fail('PSC1_TARGET_PLAN_INVALID');
  }
  for (const plan of descriptor.plans) {
    if (typeof plan.target !== 'string' || typeof plan.file !== 'string' ||
        path.basename(plan.file) !== plan.file ||
        typeof plan.runtimeVersion !== 'string' || typeof plan.runtimeSource !== 'string' ||
        !Array.isArray(plan.runtimeRequirements) ||
        !plan.runtimeRequirements.every(item => typeof item === 'string' && item.length > 0) ||
        new Set(plan.runtimeRequirements).size !== plan.runtimeRequirements.length ||
        !Array.isArray(plan.declarationLines)) fail('PSC1_TARGET_PLAN_INVALID');
  }
  return descriptor;
}

function scriptOrigins(stage, fileName, plan, info) {
  const sources = new Map();
  for (const source of info.sources) {
    for (const origin of source.origins) {
      if (sources.has(origin.name)) fail('PSC1_SOURCE_ORIGIN_AMBIGUOUS', origin.name);
      sources.set(origin.name, { path: slash(path.relative(path.dirname(info.entryPath), source.path)),
        line: origin.line + 1, column: origin.column, sourceName: origin.sourceName });
    }
  }
  const lineCount = fs.readFileSync(path.join(stage, fileName), 'utf8').split('\n').length;
  const seen = new Set();
  const declarations = plan.declarationLines.map(item => {
    if (typeof item.name !== 'string' || seen.has(item.name) ||
        !Number.isSafeInteger(item.line) || item.line < 1 || item.line > lineCount) {
      fail('PSC1_GENERATED_DECLARATION_ORIGIN_INVALID');
    }
    seen.add(item.name);
    return { name: item.name, generatedLine: item.line, original: sources.get(item.name) ?? null };
  });
  for (const name of info.publicNames) {
    if (!seen.has(name) || !sources.has(name)) fail('PSC1_PUBLIC_SOURCE_ORIGIN_MISSING', name);
  }
  fs.writeFileSync(path.join(stage, fileName + '.origins.json'), json({
    schema: 'psc1-source-origins/1', generatedFile: fileName,
    coverage: 'declaration-starts-only', generatedLineBase: 1, originalLineBase: 1,
    originalColumnBase: 0, originalColumnUnit: 'utf16-code-units',
    generatedHelperOrigins: 'unmapped', declarations
  }));
}

export function prepareScript(stage, kind, fileName) {
  const descriptor = readTargetPlans(stage);
  const plan = descriptor?.plans.find(item => item.target === kind && item.file === fileName);
  if (!plan || descriptor.plans.length !== 1) fail('PSC1_SCRIPT_TARGET_PLAN_MISSING');
  const info = readJson(path.join(stage, sourceInfoName));
  const file = path.join(stage, fileName);
  const source = fs.readFileSync(file, 'utf8');
  let validation;
  let companion;
  if (kind === 'python') {
    companion = path.join(stage, fileName.replace(/\.py$/, '.pyi'));
    const checker = [
      'import ast,json,pathlib,sys',
      'if sys.version_info < (3,14): raise SystemExit("PSC1_PYTHON_VERSION_REQUIRED: Python >=3.14")',
      'source=pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")',
      'stub=pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")',
      'compile(source,sys.argv[1],"exec")',
      'compile(stub,sys.argv[2],"exec")',
      'tree=ast.parse(source)',
      'exports=None',
      'for node in tree.body:',
      ' if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="__all__" for t in node.targets): exports=ast.literal_eval(node.value)',
      'stub_tree=ast.parse(stub)',
      'names=[node.name for node in stub_tree.body if isinstance(node,(ast.FunctionDef,ast.AsyncFunctionDef))]',
      'names += [node.target.id for node in stub_tree.body if isinstance(node,ast.AnnAssign) and isinstance(node.target,ast.Name) ]',
      'print(json.dumps({"runtime":sys.version.split()[0],"parser":"python-compile","exports":exports,"stubNames":names}))'
    ].join('\n');
    validation = JSON.parse(run(process.env.PSC1_PYTHON || 'python3',
      ['-I', '-c', checker, file, companion]));
    if (!Array.isArray(validation.exports) ||
        !isDeepStrictEqual([...validation.exports].sort(), [...info.publicNames].sort()) ||
        !isDeepStrictEqual(validation.stubNames.filter(name => info.publicNames.includes(name) || !name.startsWith('_')).sort(),
          [...info.publicNames].sort())) {
      fail('PSC1_PYTHON_PUBLIC_API_MISMATCH');
    }
  } else if (kind === 'php') {
    companion = path.join(stage, fileName.replace(/\.php$/, '.composer.json'));
    const composer = readJson(companion);
    const needsGmp = Object.hasOwn(composer.require ?? {}, 'ext-gmp');
    if (composer.require?.php !== '>=8.5') fail('PSC1_PHP_COMPOSER_VERSION_CONTRACT');
    const checker = [
      'if (PHP_VERSION_ID < 80500) { fwrite(STDERR, "PSC1_PHP_VERSION_REQUIRED: PHP >=8.5"); exit(1); }',
      needsGmp ? 'if (!extension_loaded("gmp")) { fwrite(STDERR, "PSC1_PHP_GMP_REQUIRED: install ext-gmp for this target"); exit(1); }' : '',
      'echo json_encode(["runtime" => PHP_VERSION, "parser" => "php-lint", "gmp" => extension_loaded("gmp")]);'
    ].join('\n');
    const php = process.env.PSC1_PHP || 'php';
    validation = JSON.parse(run(php, ['-r', checker]));
    run(php, ['-l', file]);
  } else fail('PSC1_SCRIPT_TARGET_INVALID', kind);
  plan.validation = { ...validation, sourceSha256: sha256(source),
    companionSha256: sha256(fs.readFileSync(companion)) };
  fs.writeFileSync(path.join(stage, targetInfoName), json(descriptor));
  scriptOrigins(stage, fileName, plan, info);
}

function sealTargetPlans(stage, kind) {
  const descriptor = readTargetPlans(stage);
  if (!descriptor) {
    if (kind === 'python' || kind === 'php') fail('PSC1_SCRIPT_TARGET_PLAN_MISSING');
    return undefined;
  }
  const expected = kind === 'ecma' ? ['js', 'ts'] : [kind];
  if (!isDeepStrictEqual(descriptor.plans.map(item => item.target).sort(), expected.sort())) {
    fail('PSC1_TARGET_PLAN_SET_MISMATCH');
  }
  const plans = descriptor.plans.map(plan => {
    const bytes = fs.readFileSync(path.join(stage, plan.file));
    if (plan.runtimeSource && !bytes.toString('utf8').includes(plan.runtimeSource) &&
        !['js', 'ts', 'rust', 'wasm-core', 'wasm-component'].includes(plan.target)) {
      fail('PSC1_RUNTIME_IMPLEMENTATION_NOT_BUNDLED', plan.file);
    }
    if (plan.target === 'python' || plan.target === 'php') {
      const companion = plan.file.replace(plan.target === 'python' ? /\.py$/ : /\.php$/,
        plan.target === 'python' ? '.pyi' : '.composer.json');
      if (!plan.validation || plan.validation.sourceSha256 !== sha256(bytes) ||
          plan.validation.companionSha256 !== sha256(fs.readFileSync(path.join(stage, companion)))) {
        fail('PSC1_SCRIPT_VALIDATION_IDENTITY_MISMATCH', plan.file);
      }
    }
    const { runtimeSource, ...metadata } = plan;
    return { ...metadata, runtimeSha256: sha256(runtimeSource),
      runtimeBytes: Buffer.byteLength(runtimeSource),
      runtimeFree: runtimeSource.length === 0 && plan.runtimeRequirements.length === 0 };
  });
  const sealed = { ...descriptor, plans };
  fs.writeFileSync(path.join(stage, targetInfoName), json(sealed));
  return sealed;
}

function outputLayout(output) {
  if (process.platform !== 'linux') fail('PSC1_ATOMIC_PUBLICATION_REQUIRES_LINUX');
  const absolute = path.resolve(output);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  const parent = fs.realpathSync(path.dirname(absolute));
  const name = path.basename(absolute);
  if (!name || name === '.' || name === '..' || /[\r\n\0]/.test(name)) fail('PSC1_OUTPUT_NAME');
  const storeName = `.${name}.psc1`;
  return { parent, name, storeName, store: path.join(parent, storeName) };
}

export function createStage(output) {
  const layout = outputLayout(output);
  const generations = path.join(layout.store, 'generations');
  fs.mkdirSync(generations, { recursive: true });
  return fs.mkdtempSync(path.join(generations, '.stage-'));
}

function inspect(file) {
  try { return fs.lstatSync(file); } catch (error) { if (error.code === 'ENOENT') return undefined; throw error; }
}

function syncDirectory(directory) {
  const fd = fs.openSync(directory, 'r');
  try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}

function fileInventory(directory, relative = '') {
  const entries = [];
  for (const name of fs.readdirSync(path.join(directory, relative)).sort()) {
    const rel = path.join(relative, name);
    const full = path.join(directory, rel);
    const stat = fs.lstatSync(full);
    if (stat.isSymbolicLink()) fail('PSC1_BUNDLE_SYMLINK_REJECTED', rel);
    if (stat.isDirectory()) entries.push(...fileInventory(directory, rel));
    else if (stat.isFile()) {
      const bytes = fs.readFileSync(full);
      entries.push({ path: slash(rel), bytes: bytes.length, sha256: sha256(bytes) });
      const fd = fs.openSync(full, 'r');
      try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
    } else fail('PSC1_BUNDLE_NONREGULAR_FILE', rel);
  }
  syncDirectory(path.join(directory, relative));
  return entries;
}

function publicationFault(phase) {
  // A negative-only test hook. It cannot skip checking or produce an acceptance.
  if (process.env.PSC1_TEST_PUBLICATION_FAIL_AT === phase) fail('PSC1_INJECTED_PUBLICATION_FAILURE', phase);
}

export function publish(stage, output, kind) {
  const layout = outputLayout(output);
  const generations = path.join(layout.store, 'generations');
  if (path.dirname(path.resolve(stage)) !== generations || !path.basename(stage).startsWith('.stage-')) {
    fail('PSC1_STAGE_OUTSIDE_OUTPUT_STORE');
  }
  const infoPath = path.join(stage, sourceInfoName);
  const info = readJson(infoPath);
  if (info.profile !== 'psc1-checked-direct/1' || !Array.isArray(info.publicNames) || !Array.isArray(info.sources)) {
    fail('PSC1_BUNDLE_PROFILE_INVALID');
  }
  if (info.leanVersion !== nativePin.version || info.leanCommit !== nativePin.commit) {
    fail('PSC1_BUNDLE_NATIVE_PIN_MISMATCH');
  }
  const assurance = info.assurance ?? 'checked-logical';
  const partialDeclarations = info.partialDeclarations ?? [];
  if (!['checked-logical', 'ordinary-checked'].includes(assurance) ||
      (info.behaviorallyVerified !== undefined && info.behaviorallyVerified !== false) ||
      !Array.isArray(partialDeclarations) ||
      !partialDeclarations.every(name => typeof name === 'string' && name.length > 0) ||
      new Set(partialDeclarations).size !== partialDeclarations.length ||
      (assurance === 'checked-logical' && partialDeclarations.length !== 0)) {
    fail('PSC1_BUNDLE_ASSURANCE_INVALID');
  }

  const admissions = fs.readFileSync(path.join(stage, 'admissions.json'));
  if (!admissions.length) fail('PSC1_BUNDLE_ADMISSIONS_MISSING');
  const root = path.dirname(info.entryPath);
  const sourceRecords = info.sources.map(source => ({
    path: slash(path.relative(root, source.path)), sha256: sha256(source.text),
    bytes: Buffer.byteLength(source.text), text: source.text, origins: source.origins
  }));
  // Persist a relocatable snapshot; no later source-file reads enter this bundle.
  fs.writeFileSync(infoPath, json({ ...info, entryPath: path.basename(info.entryPath), sources: sourceRecords }));
  const publicPaths = fs.readdirSync(stage).filter(name => name !== sourceInfoName && name !== 'admissions.json' && name !== targetInfoName).sort();
  const mustHave = kind === 'js' || kind === 'ts'
    ? [layout.name, layout.name + '.map', layout.name.replace(/\.(?:js|ts)$/, '.d.ts')]
    : kind === 'ecma' ? ['.js', '.ts', '.d.ts', '.js.map', '.ts.map'].map(extension => layout.name.slice(0, -5) + extension)
    : kind === 'python' ? [layout.name, layout.name.slice(0, -3) + '.pyi', layout.name + '.origins.json']
    : kind === 'php' ? [layout.name, layout.name.slice(0, -4) + '.composer.json', layout.name + '.origins.json']
    : kind === 'rust' ? [layout.name, layout.name.slice(0, -3) + '.cargo']
    : kind === 'wasm-component' ? [layout.name, layout.name.slice(0, -5) + '.wat', layout.name.slice(0, -5) + '.wit', layout.name.slice(0, -5) + '.core.wasm', layout.name.slice(0, -5) + '.core.wat']
    : kind === 'wasm-core' ? [layout.name, layout.name.slice(0, -5) + '.wat'] : fail('PSC1_BUNDLE_TARGET_INVALID', kind);
  if (!isDeepStrictEqual(publicPaths, [...mustHave].sort())) fail('PSC1_BUNDLE_INVENTORY_MISMATCH', kind);
  const aliases = [...publicPaths, layout.name + '.bundle.json'].map(name => ({
    file: path.join(layout.parent, name),
    target: slash(path.join(layout.storeName, 'current', name === layout.name + '.bundle.json' ? 'manifest.json' : name))
  }));
  // Preflight all names. Never overwrite a user's ordinary file or somebody
  // else's symlink to make a multi-file update appear atomic.
  for (const alias of aliases) {
    const stat = inspect(alias.file);
    if (stat && (!stat.isSymbolicLink() || fs.readlinkSync(alias.file) !== alias.target)) {
      fail('PSC1_OUTPUT_NOT_MANAGED', alias.file);
    }
  }
  const current = path.join(layout.store, 'current');
  const currentStat = inspect(current);
  if (currentStat && !currentStat.isSymbolicLink()) fail('PSC1_CURRENT_POINTER_NOT_SYMLINK');
  publicationFault('before-seal');
  const targetPlan = sealTargetPlans(stage, kind);
  const files = fileInventory(stage);
  const manifest = {
    schema: 'psc1-artifact-bundle/1', target: kind,
    ...(kind === 'ecma' ? { targets: ['ts', 'js'], sharedCheckedInput: true } : {}),
    profile: info.profile, logicalChecker: 'lean4:' + info.leanVersion,
    logicalCheckerCommit: info.leanCommit,
    assurance, behaviorallyVerified: false, partialDeclarations,
    kernelAdmissionSha256: sha256(admissions),
    sourceClosureSha256: sha256(json(sourceRecords.map(({ path, sha256, bytes }) => ({ path, sha256, bytes })))),
    compiler: info.compiler ?? 'PSC1 native', publicNames: info.publicNames,
    formatter: ['js', 'ts', 'ecma'].includes(kind) ? { prettier: '3.6.2', babelParser: '7.28.0' } : null,
    ...(targetPlan ? { runtimeContract: targetPlan.runtimeContract, targetPlans: targetPlan.plans } : {}),
    claim: 'source admission and bounded IR validation; not a backend-preservation proof',
    files
  };
  const manifestText = json(manifest);
  const generation = sha256(manifestText);
  fs.writeFileSync(path.join(stage, 'manifest.json'), manifestText);
  const manifestFd = fs.openSync(path.join(stage, 'manifest.json'), 'r');
  try { fs.fsyncSync(manifestFd); } finally { fs.closeSync(manifestFd); }
  syncDirectory(stage);
  const sealed = path.join(generations, generation);
  if (inspect(sealed)) {
    if (fs.readFileSync(path.join(sealed, 'manifest.json'), 'utf8') !== manifestText) fail('PSC1_GENERATION_COLLISION');
    for (const file of files) {
      if (sha256(fs.readFileSync(path.join(sealed, file.path))) !== file.sha256) fail('PSC1_EXISTING_GENERATION_CORRUPT', file.path);
    }
    fs.rmSync(stage, { recursive: true });
  } else {
    try { fs.renameSync(stage, sealed); }
    catch (error) {
      if (!inspect(sealed)) throw error;
      if (fs.readFileSync(path.join(sealed, 'manifest.json'), 'utf8') !== manifestText) throw error;
      for (const file of files) {
        if (sha256(fs.readFileSync(path.join(sealed, file.path))) !== file.sha256) throw error;
      }
      fs.rmSync(stage, { recursive: true });
    }
  }
  syncDirectory(generations);
  publicationFault('after-seal');
  for (const alias of aliases) {
    if (!inspect(alias.file)) {
      try { fs.symlinkSync(alias.target, alias.file); }
      catch (error) {
        if (error.code !== 'EEXIST' || !inspect(alias.file)?.isSymbolicLink() || fs.readlinkSync(alias.file) !== alias.target) throw error;
      }
    }
  }
  syncDirectory(layout.parent);
  publicationFault('after-aliases');
  const pointer = path.join(layout.store, `.current-${crypto.randomUUID()}`);
  fs.symlinkSync(slash(path.join('generations', generation)), pointer);
  try {
    publicationFault('before-commit');
    // The only publication commit point. Every aliased artifact changes through
    // this one pointer; previous immutable generations remain available to readers.
    fs.renameSync(pointer, current);
  } finally {
    if (inspect(pointer)) fs.unlinkSync(pointer);
  }
  syncDirectory(layout.store);
  return { generation, bundle: sealed, manifest: path.join(sealed, 'manifest.json') };
}

async function main(args) {
  const [command, ...rest] = args;
  if (command === 'stage' && rest.length === 1) console.log(createStage(rest[0]));
  else if (command === 'format' && rest.length === 3) await formatTarget(rest[0], rest[1], rest[2]);
  else if (command === 'rust' && rest.length === 2) prepareRust(rest[0], rest[1]);
  else if (command === 'script' && rest.length === 3) prepareScript(rest[0], rest[1], rest[2]);
  else if (command === 'wit-check' && rest.length === 2) checkWit(rest[0], rest[1]);
  else if (command === 'publish' && rest.length === 3) console.log(json(publish(rest[0], rest[1], rest[2])).trim());
  else fail('PSC1_HOST_TOOL_USAGE');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(error => { console.error(error.message); process.exitCode = 1; });
}
