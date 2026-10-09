import { spawnSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { inspect, TextDecoder } from 'node:util';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';

const verifiedGrammarCompilers = new WeakSet();

// A current PS host command must not silently select an older generated parser
// or label an older printer's output as the new grammar. Module namespaces are
// immutable; checking their three exported identity constants once is enough.
export function assertProofScriptGrammar(compiler) {
  if (compiler !== null && (typeof compiler === 'object' || typeof compiler === 'function')) {
    if (verifiedGrammarCompilers.has(compiler)) return;
    if (compiler.psProofScriptGrammarEdition === sh1GrammarProfile.edition &&
        compiler.psProofScriptGrammarMode === sh1GrammarProfile.mode &&
        compiler.psProofScriptGrammarReferenceSha256 === sh1GrammarProfile.referenceSha256) {
      verifiedGrammarCompilers.add(compiler);
      return;
    }
  }
  throw new Error('PSC2_SOURCE_GRAMMAR_COMPILER_MISMATCH: requires ' +
    sh1GrammarProfile.edition + '/' + sh1GrammarProfile.mode + '/' + sh1GrammarProfile.referenceSha256);
}

// Preserve a leading BOM for the lexer and reject malformed UTF-8 instead of
// replacing invalid bytes before grammar validation.
export async function readProofScriptSource(sourcePath) {
  const bytes = await readFile(sourcePath);
  try { return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes); }
  catch (error) {
    throw new Error(`PSC2_SOURCE_UTF8_INVALID: ${sourcePath}`, { cause: error });
  }
}

function constructorTag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const key of Object.getOwnPropertySymbols(value)) {
    if (typeof value[key] === 'string') return value[key];
  }
  return undefined;
}

function unwrap(result, sourcePath, stage) {
  const tags = result !== null && typeof result === 'object'
    ? Object.getOwnPropertySymbols(result).map(key => result[key]) : [];
  if (tags.includes('ok')) return result.value;
  if (tags.includes('error')) {
    throw new Error(`PSC2_SOURCE_${stage}_FAILED: ${sourcePath}: ${inspect(result.error, { depth: 5 })}`);
  }
  throw new Error(`PSC2_SOURCE_${stage}_RESULT_SHAPE: ${sourcePath}`);
}

// Current PS imports come from the real parser's AST. Reading the whole source
// before resolving dependencies also rejects invalid bytes in import-only files;
// stripping or trimming source text must never bypass the selected grammar.
export function readProofScriptImports(compiler, source, sourcePath = '<source>') {
  assertProofScriptGrammar(compiler);
  if (typeof compiler.psParseProofScriptSource !== 'function' ||
      typeof compiler.psPrintSyntaxName !== 'function') {
    throw new Error('PSC2_SOURCE_PARSER_API_MISSING');
  }
  const module = unwrap(compiler.psParseProofScriptSource(source), sourcePath, 'PARSE');
  const names = [];
  let imports = module?.imports;
  while (constructorTag(imports) === 'cons') {
    if (!('head' in imports) || !('tail' in imports) || !imports.head?.moduleName) {
      throw new Error(`PSC2_SOURCE_IMPORTS_RESULT_SHAPE: ${sourcePath}`);
    }
    const name = unwrap(compiler.psPrintSyntaxName(imports.head.moduleName), sourcePath, 'IMPORT_NAME');
    if (typeof name !== 'string') throw new Error(`PSC2_SOURCE_IMPORT_NAME_RESULT_SHAPE: ${sourcePath}`);
    names.push(name);
    imports = imports.tail;
  }
  if (constructorTag(imports) !== 'nil' || 'head' in imports || 'tail' in imports) {
    throw new Error(`PSC2_SOURCE_IMPORTS_RESULT_SHAPE: ${sourcePath}`);
  }
  return names;
}

// The native checked seed exposes the same parser without requiring a generated
// compiler to exist before bootstrap. This command only returns AST import names;
// the existing prepared-session protocol still owns checking and emission.
export function readProofScriptImportsWithSeed(binaryPath, source, sourcePath = '<source>') {
  const result = spawnSync(binaryPath, ['--source-imports-ps'], {
    input: source, encoding: 'utf8', timeout: 30000,
    maxBuffer: 16 * 1024 * 1024, windowsHide: true,
  });
  if (result.error || result.status !== 0) {
    throw new Error(`PSC2_SOURCE_PARSE_FAILED: ${sourcePath}: ${result.stderr || result.error?.message || result.status}`,
      result.error ? { cause: result.error } : undefined);
  }
  let names;
  try { names = JSON.parse(result.stdout); }
  catch (error) {
    throw new Error(`PSC2_SOURCE_IMPORTS_RESULT_SHAPE: ${sourcePath}`, { cause: error });
  }
  if (!Array.isArray(names) || names.some(name => typeof name !== 'string')) {
    throw new Error(`PSC2_SOURCE_IMPORTS_RESULT_SHAPE: ${sourcePath}`);
  }
  return names;
}
