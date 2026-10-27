// User compatibility policy. Qualification receipts still record exact executable identities.
export const minimumNodeVersion = '22.23.3';
export const minimumBunVersion = '1.4.4';
function atLeast(actual, minimum) {
  const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(actual || '');
  if (!match) return false; // Do not silently qualify prerelease/custom version syntax.
  const current = match.slice(1).map(Number), required = minimum.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if (current[i] !== required[i]) return current[i] > required[i];
  }
  return true;
}
export function requireSupportedRuntime(versions = process.versions) {
  const name = versions.bun ? 'bun' : 'node';
  const version = versions[name], minimum = name === 'bun' ? minimumBunVersion : minimumNodeVersion;
  if (!atLeast(version, minimum))
    throw Error('PSC1_RUNTIME_VERSION: requires ' + name + ' >= ' + minimum + '; received ' + version);
  return Object.freeze({name, version, minimum, label: name + version});
}
export function syntaxArguments(file) {
  if (requireSupportedRuntime().name === 'node') return ['--check', file];
  // Bun --check means type-check-and-run, unlike Node's parse-only flag.
  // Parse JS without executing it; the separate mandatory API consumer still imports it.
  return ['-e', "const fs=require('node:fs');new Bun.Transpiler({loader:'js'}).scan(fs.readFileSync(process.argv[1],'utf8'));", file];
}

export function runtimeArguments(args) {
  return requireSupportedRuntime().name === 'bun'
    ? ['--no-install', '--no-macros', '--no-env-file', ...args] : args;
}
