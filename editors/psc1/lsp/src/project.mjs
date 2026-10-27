// Source data capture for the editor. Project files never select executables,
// npm plugins, kernel providers, compiler implementations or output locations.
// Preserve the existing proofscript-project/1 contract and declared source order;
// the real compiler remains responsible for import and semantic validation.
import fs from 'node:fs/promises';
import {constants, lstatSync} from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';

// The editor deliberately bounds its own memory below the compiler's unchanged
// 128 MiB / 4096-file CLI boundary. Larger projects remain usable with psc.
export const MAX_INPUT_BYTES = 8 * 1024 * 1024;
const MAX_FILES = 512;
const MODULE_NAME = /^[A-Za-z_][A-Za-z_0-9]*(\.[A-Za-z_][A-Za-z_0-9]*)*$/;
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const fileUri = file => pathToFileURL(file).href;
const inside = (root, file) => {
  const relative = path.relative(root, file);
  return !relative || (!relative.startsWith('..' + path.sep) && relative !== '..' && !path.isAbsolute(relative));
};

function refuse(code, message, uri, module) {
  const error = new Error(message);
  error.code = 'PSC1_LSP_' + code;
  error.uri = uri;
  if (module) error.module = module;
  throw error;
}

function sourceText(document) {
  return typeof document?.getText === 'function' ? document.getText() : document?.text;
}

// A file URI is a transport identifier, not a filesystem identity. In particular
// VS Code encodes Windows drive colons while Node's pathToFileURL does not.
// Decode before comparing, then retain the client's exact URI in every reply.
export function fileIdentity(uri) {
  try {
    const file = path.resolve(fileURLToPath(uri));
    return process.platform === 'win32' ? file.replace(/^[A-Z]:/, drive => drive.toLowerCase()) : file;
  } catch { return null; }
}

function sameIdentity(left, right) {
  if (left === right) return Boolean(left);
  if (!left || !right || process.platform !== 'win32' || left.toLowerCase() !== right.toLowerCase()) return false;
  // Windows also supports case-sensitive directories. Confirm an existing-file
  // case alias rather than merging paths merely because their spelling folds.
  try {
    const a = lstatSync(left, {bigint: true}), b = lstatSync(right, {bigint: true});
    return a.isFile() && b.isFile() && !a.isSymbolicLink() && !b.isSymbolicLink() &&
      a.ino !== 0n && a.dev === b.dev && a.ino === b.ino;
  } catch { return false; }
}

export function openDocument(documents, uri) {
  const direct = documents?.get?.(uri);
  if (direct) return direct;
  const selected = fileIdentity(uri);
  if (!selected) return undefined;
  const values = typeof documents?.all === 'function' ? documents.all() : documents?.values?.() || [];
  for (const document of values) if (sameIdentity(fileIdentity(document.uri), selected)) return document;
  return undefined;
}

const overlay = openDocument;

async function readRegular(file, limit = MAX_INPUT_BYTES) {
  const uri = fileUri(file);
  if (!Number.isSafeInteger(limit) || limit < 0)
    refuse('INPUT_KIND_SIZE', 'The captured project exceeds the editor 8 MiB limit.', uri);
  const before = await fs.lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > limit)
    refuse('INPUT_KIND_SIZE', 'Input must be a bounded regular file: ' + file, uri);
  const handle = await fs.open(file, constants.O_RDONLY | (constants.O_NOFOLLOW || 0));
  try {
    const opened = await handle.stat();
    if (!opened.isFile() || opened.dev !== before.dev || opened.ino !== before.ino)
      refuse('INPUT_CHANGED', 'Input changed while opening: ' + file, uri);
    const parts = [];
    let total = 0;
    for (;;) {
      const buffer = Buffer.allocUnsafe(Math.min(1024 * 1024, limit + 1 - total));
      const {bytesRead} = await handle.read(buffer, 0, buffer.length, null);
      if (!bytesRead) break;
      total += bytesRead;
      if (total > limit) refuse('INPUT_KIND_SIZE', 'Input exceeds the byte limit: ' + file, uri);
      parts.push(buffer.subarray(0, bytesRead));
    }
    const after = await handle.stat(), named = await fs.lstat(file);
    if (after.size !== opened.size || after.mtimeMs !== opened.mtimeMs || after.ctimeMs !== opened.ctimeMs ||
        named.isSymbolicLink() || named.dev !== opened.dev || named.ino !== opened.ino)
      refuse('INPUT_CHANGED', 'Input changed while capturing: ' + file, uri);
    return new TextDecoder('utf-8', {fatal: true, ignoreBOM: true}).decode(Buffer.concat(parts, total));
  } finally { await handle.close(); }
}

async function boundedText(file, documents, limit = MAX_INPUT_BYTES) {
  const uri = fileUri(file), document = overlay(documents, uri);
  if (!Number.isSafeInteger(limit) || limit < 0)
    refuse('INPUT_KIND_SIZE', 'The captured project exceeds the editor 8 MiB limit.', uri);
  if (document) {
    const text = sourceText(document);
    if (typeof text !== 'string' || Buffer.byteLength(text) > limit)
      refuse('INPUT_KIND_SIZE', 'The open document exceeds the byte limit.', uri);
    return {text, version: document.version ?? null, uri: document.uri};
  }
  return {text: await readRegular(file, limit), version: null, uri};
}

async function findConfig(file, documents, workspaceFolders) {
  const folders = (workspaceFolders || []).map(folder => {
    try {
      const value = typeof folder === 'string' ? folder : folder.uri;
      return fileURLToPath(value);
    } catch { return null; }
  }).filter(root => root && inside(root, file)).sort((left, right) => right.length - left.length);
  const boundary = folders[0] || path.parse(file).root;
  for (let directory = path.dirname(file), depth = 0; inside(boundary, directory) && depth < 128; depth++) {
    const config = path.join(directory, 'proofscript.json');
    if (overlay(documents, fileUri(config))) return config;
    try {
      const stat = await fs.lstat(config);
      if (stat.isSymbolicLink() || !stat.isFile())
        refuse('PROJECT_PATH', 'proofscript.json must be a regular file.', fileUri(config));
      return config;
    } catch (error) { if (error.code !== 'ENOENT') throw error; }
    if (directory === boundary || directory === path.dirname(directory)) break;
    directory = path.dirname(directory);
  }
  return null;
}

async function containedSource(root, relative, documents, configUri) {
  if (typeof relative !== 'string' || !relative || /[\\:\0]/.test(relative) ||
      path.posix.isAbsolute(relative) || relative.split('/').some(part => !part || part === '.' || part === '..'))
    refuse('PROJECT_SOURCE_PATH', 'Source paths must be relative paths inside the project directory.', configUri);
  const selected = path.resolve(root, relative);
  if (selected === root || !inside(root, selected))
    refuse('PROJECT_SOURCE_PATH', 'Source path leaves the project directory.', configUri);
  for (let cursor = selected; cursor !== root; cursor = path.dirname(cursor)) {
    try {
      if ((await fs.lstat(cursor)).isSymbolicLink())
        refuse('PROJECT_SOURCE_PATH', 'A declared source path contains a symlink: ' + relative, configUri);
    } catch (error) {
      // A newly created, unsaved editor file can be captured as source data even
      // before its first save. Existing ancestors are still checked for symlinks.
      if (error.code !== 'ENOENT' || !overlay(documents, fileUri(selected))) throw error;
    }
  }
  return selected;
}

function parseConfig(text, uri) {
  let data;
  try { data = JSON.parse(text); }
  catch { refuse('PROJECT_JSON', 'Invalid JSON in proofscript.json.', uri); }
  if (!data || typeof data !== 'object' || Array.isArray(data))
    refuse('PROJECT_FIELDS', 'The project must be a JSON object.', uri);
  if (data.assurance !== undefined && !['checked', 'ordinary-checked'].includes(data.assurance))
    refuse('PROJECT_FIELDS', 'Project assurance must be checked or ordinary-checked.', uri);
  if (typeof data.entryModule !== 'string' || !MODULE_NAME.test(data.entryModule))
    refuse('PROJECT_ENTRY', 'The project needs a valid entryModule.', uri);
  if (Object.hasOwn(data, 'schema')) {
    if (data.schema !== 'proofscript-project/1' ||
        Object.keys(data).some(key => !['schema', 'entryModule', 'files', 'assurance'].includes(key)) ||
        !Array.isArray(data.files) || !data.files.length || data.files.length > MAX_FILES)
      refuse('PROJECT_FIELDS', 'Expected proofscript-project/1 with entryModule, files and optional assurance only.', uri);
  } else if (Object.keys(data).some(key => !['entryModule', 'sources', 'assurance'].includes(key)) ||
      !Array.isArray(data.sources) || !data.sources.length || data.sources.length > MAX_FILES) {
    refuse('PROJECT_FIELDS', 'Legacy inline projects may contain entryModule, sources and optional assurance only.', uri);
  }
  return data;
}

export async function loadProject(uri, documents, workspaceFolders = []) {
  let selected;
  try { selected = fileURLToPath(uri); }
  catch { refuse('DOCUMENT_URI', 'Save the source as a .ps file to enable compiler checking.', uri); }
  const kind = path.extname(selected).slice(1);
  if (!['ps', 'lean'].includes(kind)) refuse('SOURCE', 'Select a .ps or PSC1 .lean source file.', uri);
  const config = await findConfig(selected, documents, workspaceFolders);
  if (!config) {
    if (kind === 'lean')
      refuse('LEAN_PROJECT_REQUIRED', 'PSC1 checks .lean files only inside a proofscript.json project.', uri);
    const entryModule = path.basename(selected, '.ps');
    if (!/^[A-Za-z_][A-Za-z_0-9]*$/.test(entryModule))
      refuse('SOURCE_MODULE', 'A standalone source filename must be a valid PSC1 module name.', uri);
    // The selected path may be newly created, but a saved symlink is never read.
    try { if ((await fs.lstat(selected)).isSymbolicLink()) refuse('SOURCE_PATH', 'Source symlinks are unsupported.', uri); }
    catch (error) { if (error.code !== 'ENOENT' || !overlay(documents, uri)) throw error; }
    const captured = await boundedText(selected, documents);
    return {key: uri, root: path.dirname(selected), entryModule, assurance: 'checked',
      sources: [{module: entryModule, kind, text: captured.text}],
      files: [{uri, module: entryModule, kind, text: captured.text, version: captured.version, sha256: hash(captured.text)}],
      configUri: null};
  }
  const configUri = fileUri(config), root = path.dirname(config);
  const capturedConfig = await boundedText(config, documents);
  const data = parseConfig(capturedConfig.text, configUri);
  const sources = [], files = [], names = new Set(), paths = new Set();
  let total = Buffer.byteLength(capturedConfig.text);
  if (total > MAX_INPUT_BYTES)
    refuse('INPUT_KIND_SIZE', 'The captured project exceeds the editor 8 MiB limit.', configUri);
  if (data.schema === 'proofscript-project/1') {
    for (const row of data.files) {
      if (!row || typeof row !== 'object' || Array.isArray(row) ||
          Object.keys(row).sort().join(',') !== 'module,path' ||
          typeof row.module !== 'string' || !MODULE_NAME.test(row.module) || names.has(row.module))
        refuse('PROJECT_FILES', 'Each project file needs a unique module and a relative path.', configUri);
      const file = await containedSource(root, row.path, documents, configUri);
      const sourceKind = path.extname(file).slice(1);
      const identity = fileIdentity(fileUri(file));
      if (!['ps', 'lean'].includes(sourceKind) || [...paths].some(previous => sameIdentity(previous, identity)))
        refuse('PROJECT_FILES', 'Project files must be distinct .ps or .lean sources.', configUri);
      const captured = await boundedText(file, documents, MAX_INPUT_BYTES - total);
      total += Buffer.byteLength(captured.text);
      names.add(row.module); paths.add(identity);
      sources.push({module: row.module, kind: sourceKind, text: captured.text});
      files.push({uri: captured.uri, module: row.module, kind: sourceKind, text: captured.text,
        version: captured.version, sha256: hash(captured.text)});
    }
    if (![...paths].some(file => sameIdentity(file, fileIdentity(uri))))
      refuse('SOURCE_NOT_DECLARED', 'This file is not listed in the nearest proofscript.json project.', uri);
  } else {
    // Inline project text has no file provenance. Never pretend a similarly
    // named open disk file is the source which the compiler checked.
    refuse('INLINE_PROJECT_UNMAPPED', 'Inline-source projects have no editor file mapping. Use proofscript-project/1 files to check open buffers.', configUri);
  }
  if (!names.has(data.entryModule))
    refuse('PROJECT_ENTRY', 'The entryModule must occur in the project files.', configUri);
  const assurance = data.assurance || 'checked';
  if (Buffer.byteLength(JSON.stringify({sources, entryModule: data.entryModule, assurance})) > MAX_INPUT_BYTES)
    refuse('INPUT_KIND_SIZE', 'The captured project exceeds the editor 8 MiB limit.', configUri);
  return {key: configUri, root, entryModule: data.entryModule, assurance, sources, files, configUri,
    configVersion: capturedConfig.version, configSha256: hash(capturedConfig.text)};
}
