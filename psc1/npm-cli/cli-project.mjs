// Source configuration only. Host/compiler/checker/publication authority stays on argv.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { defaultPublicationProtocol } from '../host-tools/runtime-policy.mjs';

export const MAX_INPUT_BYTES = 128 * 1024 * 1024;
const maxProjectFiles = 4096;
const moduleName = /^[A-Za-z_][A-Za-z_0-9]*(\.[A-Za-z_][A-Za-z_0-9]*)*$/;
const digest = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');
export function refuse(code, message, hint = 'Run psc --help for supported commands.') {
  const error = new Error(message);
  error.cliCode = 'PSC1_CLI_' + code;
  error.cliHint = hint;
  throw error;
}

// Bound the actual read, not just a pre-read pathname size. Preserve BOM bytes.
// This is a workspace snapshot reader, not an OS sandbox against a hostile owner.
export function readInput(file, limit = MAX_INPUT_BYTES) {
  const before = fs.lstatSync(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > limit)
    refuse('INPUT_KIND_SIZE', 'Input must be a bounded regular file: ' + file);
  const fd = fs.openSync(file, fs.constants.O_RDONLY | (fs.constants.O_NOFOLLOW || 0));
  try {
    const opened = fs.fstatSync(fd);
    if (!opened.isFile() || opened.dev !== before.dev || opened.ino !== before.ino)
      refuse('INPUT_CHANGED', 'Input changed while opening: ' + file);
    const parts = [];
    let total = 0;
    for (;;) {
      const buffer = Buffer.allocUnsafe(Math.min(1024 * 1024, limit + 1 - total));
      const count = fs.readSync(fd, buffer, 0, buffer.length, null);
      if (!count) break;
      total += count;
      if (total > limit) refuse('INPUT_KIND_SIZE', 'Input exceeds the byte limit: ' + file);
      parts.push(buffer.subarray(0, count));
    }
    const after = fs.fstatSync(fd),
      named = fs.lstatSync(file);
    if (
      after.size !== opened.size ||
      after.mtimeMs !== opened.mtimeMs ||
      after.ctimeMs !== opened.ctimeMs ||
      named.isSymbolicLink() ||
      named.dev !== opened.dev ||
      named.ino !== opened.ino
    )
      refuse('INPUT_CHANGED', 'Input changed while capturing: ' + file);
    const bytes = Buffer.concat(parts, total);
    return {
      text: new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes),
      bytes: total,
      sha256: digest(bytes),
    };
  } finally {
    fs.closeSync(fd);
  }
}

const values = new Map([
  ['--engine', ['js', 'ts', 'rust', 'wasm-core']],
  ['--kernel', ['wasm', 'native', 'both']],
  ['--provider', ['wasm', 'native', 'both']],
  ['--target', ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php']],
  ['--assurance', ['checked', 'ordinary-checked']],
  ['--output-abi', ['scalar', 'io-dispatcher']],
  ['--publication-protocol', ['portable-file', 'legacy-symlink', 'portable-atomic']],
  ['--evidence', ['minimal', 'full']],
  ['--out', null],
  ['--project', null],
  ['--rust-toolchain-root', null],
]);
const aliases = new Map([
  ['-p', '--project'],
  ['-o', '--out'],
]);
export function parseCompilation(args) {
  const options = new Map();
  let file,
    showConfig = false,
    watch = false,
    positionalOnly = false;
  for (let i = 0; i < args.length; i++) {
    let argument = args[i];
    if (argument === '--' && !positionalOnly) {
      positionalOnly = true;
      continue;
    }
    if (!positionalOnly && ['--watch', '-w', '-watch'].includes(argument)) {
      if (watch) refuse('ARGUMENT', 'Duplicate --watch.');
      watch = true;
      continue;
    }
    if (!positionalOnly && argument === '--showConfig') {
      if (showConfig) refuse('ARGUMENT', 'Duplicate --showConfig.');
      showConfig = true;
      continue;
    }
    if (!positionalOnly && argument.startsWith('-')) {
      const equal = argument.indexOf('=');
      const embedded = equal >= 0 ? argument.slice(equal + 1) : undefined;
      if (equal >= 0) argument = argument.slice(0, equal);
      const option = aliases.get(argument) || argument;
      if (!values.has(option)) refuse('ARGUMENT', 'Unknown option: ' + argument);
      if (options.has(option)) refuse('ARGUMENT', 'Duplicate option: ' + option);
      const value = embedded ?? args[++i];
      if (!value || (embedded === undefined && value.startsWith('-')))
        refuse('ARGUMENT', 'Missing value for ' + option + '.');
      const allowed = values.get(option);
      if (allowed && !allowed.includes(value))
        refuse(
          'ARGUMENT',
          'Unsupported ' + option + ': ' + value,
          'Choose ' + allowed.join(', ') + '.',
        );
      options.set(option, value);
    } else {
      if (file) refuse('ARGUMENT', 'Only one entry file may be selected.');
      file = argument;
    }
  }
  if (file && options.has('--project'))
    refuse('SOURCE_OR_PROJECT_REQUIRED', 'Choose a source file or --project, not both.');
  if (options.has('--provider') && options.has('--kernel'))
    refuse('ARGUMENT', '--provider and --kernel select the same option; choose one.');
  if (watch && showConfig) refuse('ARGUMENT', '--watch cannot be combined with --showConfig.');
  return { options, file, showConfig, watch };
}

function configFile(selected, cwd) {
  let file = path.resolve(cwd, selected || 'proofscript.json');
  const stat = fs.lstatSync(file);
  if (stat.isSymbolicLink()) refuse('PROJECT_PATH', 'Project paths cannot be symlinks.');
  if (stat.isDirectory()) file = path.join(file, 'proofscript.json');
  return file;
}

function sourceFile(root, relative, allowMissing = false) {
  if (
    typeof relative !== 'string' ||
    !relative ||
    relative.includes('\\') ||
    relative.includes(':') ||
    relative.includes('\0') ||
    path.posix.isAbsolute(relative) ||
    relative.split('/').some((part) => !part || part === '.' || part === '..')
  )
    refuse('PROJECT_SOURCE_PATH', 'Source paths must stay relative to the project directory.');
  const absolute = path.resolve(root, relative);
  const inside = path.relative(root, absolute);
  if (!inside || inside.startsWith('..' + path.sep) || path.isAbsolute(inside))
    refuse('PROJECT_SOURCE_PATH', 'Source path leaves the project directory.');
  for (let cursor = absolute; cursor !== root; cursor = path.dirname(cursor)) {
    try {
      if (fs.lstatSync(cursor).isSymbolicLink())
        refuse('PROJECT_SOURCE_PATH', 'Source path contains a symlink: ' + relative);
    } catch (error) {
      if (!allowMissing || error.code !== 'ENOENT') throw error;
    }
  }
  return absolute;
}

export function captureProject(parsed, cwd = process.cwd()) {
  const { options, file } = parsed;
  if (file) {
    const kind = path.extname(file).slice(1),
      entryModule = path.basename(file, '.' + kind);
    if (!['lean', 'ps'].includes(kind) || !/^[A-Za-z_][A-Za-z_0-9]*$/.test(entryModule))
      refuse('SOURCE', 'Select a .lean or .ps file with a valid module name.');
    const selected = path.resolve(cwd, file),
      captured = readInput(selected);
    return {
      project: { entryModule, sources: [{ module: entryModule, kind, text: captured.text }] },
      config: null,
      files: [
        {
          module: entryModule,
          kind,
          path: selected,
          bytes: captured.bytes,
          sha256: captured.sha256,
        },
      ],
    };
  }
  let config;
  try {
    config = configFile(options.get('--project'), cwd);
  } catch (error) {
    if (error.code === 'ENOENT')
      refuse(
        'PROJECT_MISSING',
        'No project was found.',
        'Run psc init, pass Main.ps, or select a project with -p path/to/proofscript.json.',
      );
    throw error;
  }
  let data;
  try {
    data = JSON.parse(readInput(config).text);
  } catch (error) {
    if (error instanceof SyntaxError) refuse('PROJECT_JSON', 'Invalid project JSON: ' + config);
    throw error;
  }
  if (!data || typeof data !== 'object' || Array.isArray(data))
    refuse('PROJECT_FIELDS', 'Project must be a JSON object.');
  if (!Object.hasOwn(data, 'schema')) {
    if (Object.keys(data).some((key) => !['entryModule', 'sources', 'assurance'].includes(key)))
      refuse(
        'PROJECT_FIELDS',
        'Legacy projects may contain only entryModule, sources and assurance.',
      );
    return { project: data, config, files: null };
  }
  if (
    data.schema !== 'proofscript-project/1' ||
    Object.keys(data).some(
      (key) => !['schema', 'entryModule', 'files', 'assurance'].includes(key),
    ) ||
    typeof data.entryModule !== 'string' ||
    !moduleName.test(data.entryModule) ||
    (data.assurance !== undefined && !['checked', 'ordinary-checked'].includes(data.assurance)) ||
    !Array.isArray(data.files) ||
    !data.files.length ||
    data.files.length > maxProjectFiles
  )
    refuse(
      'PROJECT_FIELDS',
      'Invalid proofscript-project/1 fields.',
      'Projects select entryModule, files and optional assurance only; host options belong on argv.',
    );
  const root = path.dirname(config),
    names = new Set(),
    paths = new Set(),
    sources = [],
    files = [];
  let total = 0;
  for (const item of data.files) {
    if (
      !item ||
      typeof item !== 'object' ||
      Array.isArray(item) ||
      Object.keys(item).sort().join(',') !== 'module,path' ||
      typeof item.module !== 'string' ||
      !moduleName.test(item.module) ||
      names.has(item.module)
    )
      refuse('PROJECT_FILES', 'Each source needs a unique module and relative path.');
    const selected = sourceFile(root, item.path),
      kind = path.extname(selected).slice(1);
    if (!['lean', 'ps'].includes(kind) || paths.has(selected))
      refuse('PROJECT_FILES', 'Source files must be distinct .lean or .ps files.');
    const captured = readInput(selected, MAX_INPUT_BYTES - total);
    total += captured.bytes;
    names.add(item.module);
    paths.add(selected);
    sources.push({ module: item.module, kind, text: captured.text });
    files.push({
      module: item.module,
      kind,
      path: selected,
      bytes: captured.bytes,
      sha256: captured.sha256,
    });
  }
  if (!names.has(data.entryModule)) refuse('PROJECT_ENTRY', 'entryModule must occur in files.');
  const project = {
    entryModule: data.entryModule,
    sources,
    ...(data.assurance === undefined ? {} : { assurance: data.assurance }),
  };
  if (Buffer.byteLength(JSON.stringify(project)) > MAX_INPUT_BYTES)
    refuse('INPUT_KIND_SIZE', 'Captured project JSON exceeds 128 MiB.');
  return { project, config, files };
}

export function describeProject(parsed, captured) {
  return {
    schema: 'proofscript-effective-project/1',
    project: captured.config,
    entryModule: captured.project.entryModule,
    files: captured.files,
    sourceMode: captured.files === null ? 'legacy-inline' : 'captured-files',
    selectedOptions: Object.fromEntries(parsed.options),
    selection: {
      engine: parsed.options.get('--engine') || 'js',
      kernel: parsed.options.get('--kernel') || parsed.options.get('--provider') || 'wasm',
      target: parsed.options.get('--target') || 'js',
      assurance: parsed.options.get('--assurance') || captured.project.assurance || 'checked',
      outputAbi: parsed.options.get('--output-abi') || 'scalar',
      publicationProtocol:
        parsed.options.get('--publication-protocol') || defaultPublicationProtocol,
      ...(parsed.options.has('--out') ? { out: path.resolve(parsed.options.get('--out')) } : {}),
    },
    defaults: {
      engine: 'js',
      kernel: 'wasm',
      target: 'js',
      outputAbi: 'scalar',
      publicationProtocol: defaultPublicationProtocol,
    },
    logicalAdmission: 'not-run',
    publication: 'not-requested',
  };
}

export function initializeProject(args, cwd = process.cwd()) {
  let kind = 'ps';
  if (args.length) {
    if (args.length !== 2 || args[0] !== '--kind' || !['lean', 'ps'].includes(args[1]))
      refuse('INIT_USAGE', 'Usage: psc init [--kind ps|lean]');
    kind = args[1];
  }
  const source = 'Main.' + kind,
    config = 'proofscript.json';
  for (const name of [config, source]) {
    try {
      fs.lstatSync(path.join(cwd, name));
      refuse(
        'INIT_EXISTS',
        'Initialization would overwrite ' + name + '.',
        'Keep existing files; create a project file manually or use an empty directory.',
      );
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }
  // Exclusive creation never overwrites. A late config failure may leave the
  // newly created source; preserve it and report the error instead of deleting data.
  fs.writeFileSync(path.join(cwd, source), 'def answer : Nat := 42\n', { flag: 'wx' });
  fs.writeFileSync(
    path.join(cwd, config),
    JSON.stringify(
      {
        schema: 'proofscript-project/1',
        entryModule: 'Main',
        files: [{ module: 'Main', path: source }],
      },
      null,
      2,
    ) + '\n',
    { flag: 'wx' },
  );
  return { created: [source, config], next: ['psc check', 'psc build --out dist/app'] };
}

// Observe declared paths, including temporarily missing files after editor renames.
// This grants no source/tool authority; every attempt still uses captureProject().
export function declaredWatchPaths(parsed, cwd = process.cwd()) {
  if (parsed.file) return [path.resolve(cwd, parsed.file)];
  const config = configFile(parsed.options.get('--project'), cwd);
  const data = JSON.parse(readInput(config).text);
  const files = data?.schema === 'proofscript-project/1' ? data.files : [];
  if (!Array.isArray(files) || files.length > maxProjectFiles)
    refuse('PROJECT_FILES', 'Invalid watch source inventory.');
  return [config, ...files.map((item) => sourceFile(path.dirname(config), item?.path, true))];
}
export function checkedOptions(parsed, captured) {
  const o = parsed.options;
  return {
    ...captured.project,
    engine: o.get('--engine') || 'js',
    kernel: o.get('--kernel') || o.get('--provider') || 'wasm',
    assurance: o.get('--assurance') || captured.project.assurance || 'checked',
    ...(o.has('--evidence') ? { evidence: o.get('--evidence') } : {}),
    ...(o.has('--target') ? { target: o.get('--target') } : {}),
    ...(o.has('--output-abi') ? { outputAbi: o.get('--output-abi') } : {}),
    ...(o.has('--out') ? { out: o.get('--out') } : {}),
    ...(o.has('--publication-protocol')
      ? { publicationProtocol: o.get('--publication-protocol') }
      : {}),
    ...(o.has('--rust-toolchain-root')
      ? { rustToolchainRoot: path.resolve(o.get('--rust-toolchain-root')) }
      : {}),
  };
}
export const captureIdentity = (captured) => digest(JSON.stringify(captured));
