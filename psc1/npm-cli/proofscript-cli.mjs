#!/usr/bin/env node
// Developer-facing adapter. The unchanged universal-cli owns checked execution.
// Import it only in a child, so help/init/project inspection need no kernel or SDK.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {watchProject} from './cli-watch.mjs';
import {runtimeArguments} from '../host-tools/runtime-policy.mjs';
import {captureProject, describeProject, initializeProject, parseCompilation,
  refuse} from './cli-project.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const usage = `ProofScript — independently checked .ps and .lean compilation

Usage:
  psc init [--kind ps|lean]       Create Main.ps and proofscript.json without overwriting
  psc check [Main.ps | -p path]  Check sources through the existing checked target pipeline
  psc compile [Main.ps | -p path]  Return checked source and receipt as JSON
  psc build [Main.ps | -p path] --out directory  Publish a checked immutable generation
  psc --showConfig [-p path]     Inspect captured inputs; does not check or publish
  psc --version                 Print the installed package version
  psc --identity                Return verified installation metadata as JSON
  psc kernel --identity|check admissions.json [--provider wasm|native|both]

Project workflow:
  With no source argument, check/compile/build read ./proofscript.json.
  -p accepts a project JSON file or a directory. It never searches parent directories.
  Existing inline source projects remain supported. File projects capture only
  declared relative .ps/.lean files, in declared order; no npm plugin code executes.

Options:
  --engine js|ts|rust|wasm-core   Compiler engine (default js)
  --target js|ts|rust|wasm-core|wasm-component|python|php  Output target (default js)
  --kernel wasm|native|both      Independent checker (default genuine Lean Wasm)
  --assurance checked|ordinary-checked
  --output-abi scalar|io-dispatcher
  --publication-protocol legacy-symlink|portable-file
  --rust-toolchain-root path     Explicit host-owned Rust output SDK
  -p, --project path             Source data only; cannot choose tools or output
  -o, --out directory            Required for build; forbidden for check/compile
  --diagnostics text|json        Errors on stderr (default text)
  -w, --watch, -watch           Recheck declared inputs after edits (500 ms polling)
  --showConfig                  Inspect only; logicalAdmission remains not-run
  -h, --help                    Show this help

Examples:
  npm exec -- psc init
  npm exec -- psc check
  npm exec -- psc build --out dist/app --publication-protocol portable-file
  psc compile Main.lean --engine ts
  psc build Main.ps --target ts --out dist/ts --watch
  psc build -p . --target rust --out dist/rust -w

check retains target emission/consumer checks; it is not a new frontend-only mode.
Success receipts remain JSON on stdout; errors use stderr and a nonzero exit.
Rust/Wasm engines, non-JS output SDKs and Python/PHP providers may require explicit
pinned optional packages. No install/compile command downloads a missing SDK.
Current checked publication is Linux-qualified; compile does not publish.
`;
const hints = [
  [/OPTIONAL_PACKAGE_MISSING/, 'Install the exact optional package named in the diagnostic; no fallback is used.'],
  [/RUNTIME_VERSION|NODE_PIN/, 'Use Node >=22.23.3 or Bun >=1.4.0. Exact CI versions are reproduction records, not installation pins.'],
  [/WATCH_SUPERSEDED/, 'The watch supervisor will retry the latest inputs; the previous checked generation is preserved.'],
  [/ENOENT/, 'Check declared source paths. Watch mode resumes when missing files are restored.'],
  [/OUTPUT_DIRECTORY/, 'Pass --out directory to psc build.'],
  [/PUBLICATION_PLATFORM_UNQUALIFIED/, 'Use psc compile on this platform; publication needs platform qualification.'],
  [/COMMITTED_DURABILITY_UNCERTAIN/, 'Publication may already be committed. Inspect the store; do not assume rollback.'],
  [/PROJECT_FIELDS/, 'Project JSON selects sources only; pass host options explicitly on the command line.'],
];
function diagnostic(error, mode, fallbackCode = 'PSC1_CLI_EXECUTION_FAILED') {
  const message = String(error?.message || error).trim();
  const code = error?.cliCode || message.match(/\bPSC1_[A-Z0-9_]+/)?.[0] || fallbackCode;
  const hint = error?.cliHint || hints.find(([pattern]) => pattern.test(message))?.[1];
  if (mode === 'json')
    console.error(JSON.stringify({schema: 'proofscript-cli-diagnostic/1',
      code, message, ...(hint ? {hint} : {})}));
  else {
    console.error(message.includes(code) ? message : code + ': ' + message);
    if (hint) console.error('Hint: ' + hint);
  }
}
function presentation(args) {
  const rest = [];
  let mode = 'text', seen = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--') { rest.push(...args.slice(i)); break; }
    if (args[i] === '--diagnostics' || args[i].startsWith('--diagnostics=')) {
      if (seen) refuse('ARGUMENT', 'Duplicate --diagnostics.');
      seen = true;
      mode = args[i] === '--diagnostics' ? args[++i] : args[i].slice('--diagnostics='.length);
      if (!['text', 'json'].includes(mode))
        refuse('ARGUMENT', '--diagnostics must be text or json.');
    } else rest.push(args[i]);
  }
  return {args: rest, mode};
}
// Individual compiler/tool/checker limits remain inside the unchanged host.
// Stream stdout without changing JSON receipts; cap diagnostic buffering at32MiB.
// Signals are forwarded and retain130/143. No shell, downloader or fallback.
async function execute(args, mode, worker = 'universal-cli.mjs') {
  if (!['universal-cli.mjs', 'cli-watch-worker.mjs'].includes(worker)) refuse('WORKER', 'Unknown CLI worker.');
  const child = spawn(process.execPath, runtimeArguments([path.join(here, worker), ...args]),
    {stdio: ['inherit', 'pipe', 'pipe'], detached: process.platform !== 'win32', windowsHide: true});
  let requestedSignal, escalation;
  const kill = signal => {
    try {
      if (process.platform !== 'win32' && child.pid) process.kill(-child.pid, signal);
      else child.kill(signal);
    } catch (error) { if (error.code !== 'ESRCH') throw error; }
  };
  child.stdout.pipe(process.stdout);
  const parts = [];
  let bytes = 0, overflow = false, launchError;
  child.stderr.on('data', chunk => {
    bytes += chunk.length;
    if (bytes > 32 * 1024 * 1024) { overflow = true; kill('SIGKILL'); }
    else parts.push(chunk);
  });
  const signals = new Map(['SIGINT', 'SIGTERM'].map(signal => {
    const handler = () => {
      requestedSignal = signal; kill(signal);
      escalation ??= setTimeout(() => kill('SIGKILL'), 2000);
      escalation.unref();
    };
    process.on(signal, handler);
    return [signal, handler];
  }));
  child.on('error', error => { launchError = error; });
  const outcome = await new Promise(resolve =>
    child.on('close', (code, signal) => resolve({code, signal})));
  clearTimeout(escalation);
  for (const [signal, handler] of signals) process.off(signal, handler);
  const stderr = Buffer.concat(parts).toString('utf8');
  if (launchError) diagnostic(launchError, mode, 'PSC1_CLI_LAUNCH_FAILED');
  else if (overflow) diagnostic('PSC1_CLI_DIAGNOSTIC_LIMIT: child stderr exceeded32MiB.', mode);
  else if (stderr && outcome.code !== 0) diagnostic(stderr, mode);
  else if (stderr) process.stderr.write(stderr);
  if (requestedSignal) return requestedSignal === 'SIGINT' ? 130 : 143;
  return launchError || overflow ? 1 :
    outcome.code ?? (outcome.signal === 'SIGINT' ? 130 : outcome.signal === 'SIGTERM' ? 143 : 1);
}

let temporary, mode = process.argv.slice(2).some(a =>
  a === '--diagnostics=json') ? 'json' : 'text';
try {
  let args;
  ({args, mode} = presentation(process.argv.slice(2)));
  if (args[0] === 'generated') args = args.slice(1);
  if (!args.length || args[0] === 'help' || args.includes('--help') || args.includes('-h')) {
    console.log(usage);
  } else if (args.length === 1 && args[0] === '--version') {
    const meta = JSON.parse(fs.readFileSync(path.join(here, '../package.json'), 'utf8'));
    console.log(meta.name + ' ' + meta.version);
  } else if (['init', '--init'].includes(args[0])) {
    const result = initializeProject(args.slice(1));
    console.log('Created ' + result.created.join(' and ') + '.\nNext:\n  ' + result.next.join('\n  '));
  } else if (args[0] === '--identity' || args[0] === 'kernel') {
    process.exitCode = await execute(args, mode);
  } else {
    const command = ['check', 'compile', 'build'].includes(args[0]) ? args.shift() :
      args[0]?.startsWith('-') ? 'check' : undefined;
    if (!command) refuse('COMMAND', 'Unknown command: ' + args[0]);
    const parsed = parseCompilation(args);
    if (command !== 'build' && parsed.options.has('--out'))
      refuse('OUT_REQUIRES_BUILD', '--out requires psc build.');
    if (command === 'build' && !parsed.showConfig && !parsed.options.has('--out'))
      refuse('OUTPUT_DIRECTORY', 'psc build requires an output directory.',
        'Run psc build --out dist/app.');
    const captured = captureProject(parsed);
    if (parsed.showConfig) console.log(JSON.stringify(describeProject(parsed, captured), null, 2));
    else if (parsed.watch) {
      process.exitCode = await watchProject({command, parsed, execute, diagnostic, mode});
    } else {
      temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-cli-project-'));
      const project = path.join(temporary, 'sources.json');
      fs.writeFileSync(project, JSON.stringify(captured.project), {flag: 'wx', mode: 0o600});
      const forwarded = [command, '--project', project];
      for (const [key, value] of parsed.options)
        if (key !== '--project') forwarded.push(key, value);
      process.exitCode = await execute(forwarded, mode);
    }
  }
} catch (error) {
  diagnostic(error, mode);
  process.exitCode = 1;
} finally {
  if (temporary) fs.rmSync(temporary, {recursive: true, force: true});
}
