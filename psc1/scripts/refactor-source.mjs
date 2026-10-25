#!/usr/bin/env node
// Developer candidate transport. This command never edits project source files.
import fs from 'node:fs';
import path from 'node:path';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';

function fail(code) { throw new Error('PSC1_REFACTOR_' + code); }
function keys(value, names) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...names].sort().join(',')) fail('FIELDS');
}
function file(name, limit) {
  const stat = fs.lstatSync(name);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > limit) fail('FILE');
  return fs.readFileSync(name);
}
function argumentsOf(args) {
  const result = { sources: [], assurance: 'checked', comments: 'preserve' };
  const seen = new Set();
  for (let i = 0; i < args.length; i += 2) {
    const flag = args[i], value = args[i + 1];
    if (!value || !['--manifest', '--entry', '--grammar', '--to', '--source',
      '--assurance', '--comments'].includes(flag)) fail('ARGUMENTS');
    if (flag === '--source') {
      const split = value.indexOf('=');
      if (split < 1 || split === value.length - 1) fail('SOURCE');
      result.sources.push({ module: value.slice(0, split), path: path.resolve(value.slice(split + 1)) });
    } else {
      const key = flag.slice(2);
      if (seen.has(key)) fail('ARGUMENTS');
      seen.add(key);
      result[key] = value;
    }
  }
  if (!result.manifest || !result.entry || !['lean', 'ps'].includes(result.grammar) ||
      !['lean', 'ps'].includes(result.to) || !result.sources.length ||
      !['checked', 'ordinary-checked'].includes(result.assurance) ||
      !['preserve', 'owner-notes'].includes(result.comments)) fail('ARGUMENTS');
  return result;
}

try {
  const args = process.argv.slice(2);
  if (args.length === 1 && args[0] === '--help') {
    process.stdout.write('usage: node refactor-source.mjs --manifest TOOLS.json --entry MODULE --grammar lean|ps --to lean|ps --source MODULE=FILE [--source MODULE=FILE ...] [--assurance checked|ordinary-checked] [--comments preserve|owner-notes]\n');
  } else {
  const options = argumentsOf(args);
  const manifest = JSON.parse(file(path.resolve(options.manifest), 16384).toString('utf8'));
  keys(manifest, ['schema', 'lexical', 'ownership', 'checker']);
  if (manifest.schema !== 'psc1-source-tools/1') fail('MANIFEST');
  for (const tool of [manifest.lexical, manifest.ownership, manifest.checker]) {
    keys(tool, ['path', 'sha256']);
    if (!path.isAbsolute(tool.path) || !/^[0-9a-f]{64}$/.test(tool.sha256)) fail('MANIFEST');
  }
  const lexical = createLosslessSourceTool({
    executable: manifest.lexical.path, sha256: manifest.lexical.sha256,
  });
  const ownership = createSourceOwnershipTool({
    lexicalTool: lexical, executable: manifest.ownership.path, sha256: manifest.ownership.sha256,
    checkerExecutable: manifest.checker.path, checkerSha256: manifest.checker.sha256,
  });
  const converter = createCheckedSourceConverter({ ownershipTool: ownership });
  const snapshots = options.sources.map(source => lexical.capture({
    module: source.module, grammar: options.grammar, uri: source.path, bytes: file(source.path, 1048576),
  }));
  const index = ownership.analyze({ snapshots, entry: options.entry, assurance: options.assurance });
  const report = converter.convert({
    index, snapshots, targetGrammar: options.to, commentPolicy: options.comments,
  });
  const output = JSON.stringify({
    schema: 'psc1-source-conversion-candidate/1', report,
    modules: snapshots.map(source => ({
      module: source.module, grammar: options.to,
      text: converter.readCandidate(report, source.module).toString('utf8'),
    })),
  });
  if (Buffer.byteLength(output) > 33554432) fail('RESPONSE_LIMIT');
  process.stdout.write(output + '\n');
  }
} catch (error) {
  process.stderr.write(JSON.stringify({
    schema: 'psc1-source-conversion-error/1', message: error.message, detail: error.cause ?? null,
  }) + '\n');
  process.exitCode = 1;
}
