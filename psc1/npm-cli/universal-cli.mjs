#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { getCompilerMetadata, compile, build, checkCanonicalAdmissions } from './universal.mjs';
import { kernelHandle } from '../host-tools/installed-engine-resolver.mjs';
const fail = (message) => {
  throw Error('PSC1_CLI_' + message);
};
// Preserve exact source bytes through fatal UTF-8 decoding, including a BOM.
// The frontend may refuse those bytes; the CLI must not silently rewrite them.
function text(file) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > 128 * 1024 * 1024)
    fail('INPUT_KIND_SIZE');
  return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(fs.readFileSync(file));
}
// Command-line options choose host behavior. Project JSON carries source data only.
// Return explicit fields so project metadata cannot acquire output/tool authority.
function project(args) {
  const options = {};
  let file;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a.startsWith('--')) {
      if (
        ![
          '--engine',
          '--kernel',
          '--provider',
          '--out',
          '--assurance',
          '--target',
          '--output-abi',
          '--publication-protocol',
          '--rust-toolchain-root',
          '--project',
        ].includes(a) ||
        Object.hasOwn(options, a) ||
        !args[i + 1] ||
        args[i + 1].startsWith('--')
      )
        fail('ARGUMENT');
      options[a] = args[++i];
    } else if (file) fail('ARGUMENT');
    else file = a;
  }
  if (Boolean(file) === Boolean(options['--project'])) fail('SOURCE_OR_PROJECT_REQUIRED');
  let source;
  if (options['--project']) {
    source = JSON.parse(text(path.resolve(options['--project'])));
    if (
      !source ||
      typeof source !== 'object' ||
      Array.isArray(source) ||
      Object.keys(source).some((k) => !['entryModule', 'sources', 'assurance'].includes(k))
    )
      fail('PROJECT_FIELDS');
  } else {
    const kind = path.extname(file).slice(1),
      entryModule = path.basename(file, path.extname(file));
    if (!['lean', 'ps'].includes(kind) || !/^[A-Za-z_][A-Za-z_0-9]*$/.test(entryModule))
      fail('SOURCE');
    source = {
      entryModule,
      sources: [{ module: entryModule, kind, text: text(path.resolve(file)) }],
    };
  }
  return {
    entryModule: source.entryModule,
    sources: source.sources,
    engine: options['--engine'] || 'js',
    kernel: options['--kernel'] || options['--provider'] || 'wasm',
    assurance: options['--assurance'] || source.assurance || 'checked',
    ...(options['--output-abi'] ? { outputAbi: options['--output-abi'] } : {}),
    ...(options['--target'] ? { target: options['--target'] } : {}),
    ...(options['--out'] ? { out: options['--out'] } : {}),
    ...(options['--rust-toolchain-root'] ? {rustToolchainRoot:path.resolve(options['--rust-toolchain-root'])} : {}),
    ...(options['--publication-protocol'] ? {publicationProtocol:options['--publication-protocol']} : {}),
  };
}
try {
  let args = process.argv.slice(2);
  if (args[0] === 'generated') args = args.slice(1);
  if (args.length === 1 && ['--identity', '--version'].includes(args[0]))
    console.log(JSON.stringify(getCompilerMetadata()));
  else if (args[0] === 'kernel') {
    const command = args[1];
    let provider = 'wasm',
      file;
    for (let i = 2; i < args.length; i++) {
      if (args[i] === '--provider') {
        provider = args[++i];
        if (!['wasm', 'native', 'both'].includes(provider)) fail('KERNEL_PROVIDER');
      } else if (!file && !args[i].startsWith('--')) file = args[i];
      else fail('KERNEL_USAGE');
    }
    if (command === '--identity') {
      if (file) fail('KERNEL_USAGE');
      const selected = provider === 'both' ? ['wasm', 'native'] : [provider],
        identities = {};
      for (const key of selected) {
        const { handle, verify } = await kernelHandle(key);
        verify();
        identities[key] = handle.metadata;
      }
      console.log(
        JSON.stringify({ provider, leanVersion: '4.35.0', wasmMemoryModel: 'linear', identities }),
      );
    } else if (command === 'check' && file) {
      const result = await checkCanonicalAdmissions(text(path.resolve(file)), { provider });
      console.log(JSON.stringify(result));
      if (!result.accepted || !result.agreement) process.exitCode = 1;
    } else if (command === 'check-source' && file) {
      const result = compile(project([file, '--kernel', provider]));
      console.log(JSON.stringify({ ...result, source: undefined }));
    } else fail('KERNEL_USAGE');
  } else if (['check', 'compile', 'build'].includes(args[0])) {
    const options = project(args.slice(1));
    if (args[0] !== 'build' && options.out) fail('OUT_REQUIRES_BUILD');
    const result = args[0] === 'build' ? build(options) : compile(options);
    console.log(JSON.stringify(args[0] === 'check' ? { ...result, source: undefined } : result));
  } else
    fail(
      'USAGE: psc check|compile|build Main.lean|ps [--engine js|ts|rust|wasm-core] [--kernel wasm|native|both] [--output-abi scalar|io-dispatcher] [--out directory]; psc kernel --identity|check admissions.json',
    );
} catch (error) {
  console.error(String(error?.message || error));
  process.exitCode = 1;
}
