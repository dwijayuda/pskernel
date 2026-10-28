// Trusted host integration. The graph and adapter are resources, not admission
// tokens. The existing session must execute, independently check and publish its
// own result. No parser, elaborator, IR transform or target printer is copied.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {createGeneratedJsCompilerSession} from '../generated-compiler-session.mjs';
import {verify} from './verify.mjs';

const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const refuse = code => { throw Error('PSC1_EXECUTABLE_' + code); };
const ownFile = relative => fileURLToPath(new URL(relative, import.meta.url));
const helperFiles = [
  ownFile('./loader.mjs'), ownFile('./verify.mjs'), ownFile('./tools.mjs'),
  ownFile('../runtime-policy.mjs'),
];
const runnerFile = ownFile('../execution/unified-candidate-runner.mjs');

export function createExecutableCompilerSession({
  graphRoot, manifestFile, manifestSha256, variant, adapterFile,
  ...options
}) {
  if (!['js', 'ts'].includes(variant) ||
      ![graphRoot, manifestFile, adapterFile].every(value => path.isAbsolute(value || '')) ||
      !/^[a-f0-9]{64}$/.test(manifestSha256 || '')) refuse('SESSION_ARGUMENTS');
  for (const name of [
    'serviceFile', 'serviceSha256', 'runnerFile', 'runnerSha256',
    'serviceKind', 'serviceDependencies',
  ]) if (Object.hasOwn(options, name)) refuse('SESSION_TOOL_OVERRIDE');
  if (fs.realpathSync(graphRoot) !== graphRoot ||
      fs.realpathSync(manifestFile) !== manifestFile ||
      fs.realpathSync(path.dirname(adapterFile)) !== path.dirname(adapterFile))
    refuse('SESSION_SYMLINK');
  const relative = path.relative(graphRoot, adapterFile);
  if (relative === '' || (!relative.startsWith('..' + path.sep) && !path.isAbsolute(relative)))
    refuse('ADAPTER_INSIDE_GRAPH');
  const manifest = verify(graphRoot, fs.readFileSync(manifestFile), manifestSha256);
  const config = {root: graphRoot, manifestFile, manifestSha256, variant};
  const adapter = 'import {loadExecutableCompiler} from ' +
    JSON.stringify(pathToFileURL(helperFiles[0]).href) + ';\n' +
    'const engine=await loadExecutableCompiler(' + JSON.stringify(config) + ');\n' +
    'export function psCompilerServiceCandidate(input){return engine.candidate(input);}\n';
  fs.writeFileSync(adapterFile, adapter, {flag: 'wx', mode: 0o600});
  const dependencyFiles = [
    manifestFile,
    ...manifest.files.map(row => path.join(graphRoot, row.path)),
    ...helperFiles,
  ];
  const serviceDependencies = dependencyFiles.map(file => {
    if (!fs.lstatSync(file).isFile() || fs.realpathSync(file) !== file)
      refuse('SESSION_RESOURCE_KIND');
    return {path: file, sha256: hash(fs.readFileSync(file))};
  });
  return createGeneratedJsCompilerSession({
    ...options,
    serviceKind: 'unified-embedded',
    serviceFile: adapterFile,
    serviceSha256: hash(adapter),
    runnerFile,
    runnerSha256: hash(fs.readFileSync(runnerFile)),
    serviceDependencies,
  });
}
