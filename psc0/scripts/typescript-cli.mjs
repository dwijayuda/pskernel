import { existsSync, realpathSync } from 'node:fs';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

// One active TS -> JS toolchain. Do not fall back to an older tsc.
// Native TypeScript 7 requires --ignoreConfig for explicit file builds.
export const pinnedTypeScriptVersion = '7.0.2';
export const pinnedTypeScriptVersionText = 'Version 7.0.2';
export const checkedTypeScriptToolchain = Object.freeze({
  package: 'typescript',
  version: pinnedTypeScriptVersion,
  cli: 'typescript/bin/tsc',
  profile: 'strict-es2022-esm-ignoreconfig/1',
});
export const strictTypeScriptArgs = Object.freeze([
  '--ignoreConfig', '--target', 'ES2022', '--module', 'ES2022',
  '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap',
  '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
]);

const require = createRequire(import.meta.url);
function findInstalledCompiler() {
  // TS7's package exports restrict 'typescript/bin/tsc' as a package import.
  // Resolve its public package.json entry, then address its CLI by exact path.
  try {
    const pkg = require.resolve('typescript/package.json');
    const candidate = path.join(path.dirname(pkg), 'bin', 'tsc');
    if (existsSync(candidate)) return candidate;
  } catch { /* check PATH for an explicitly installed compiler */ }
  return undefined;
}

// Invoke the installed native TypeScript 7 command via its Node launcher,
// including Windows where child_process cannot invoke .cmd without a shell.
export function resolveTypeScriptCli() {
  const installed = findInstalledCompiler();
  if (installed) return installed;
  for (const directory of (process.env.PATH ?? '').split(path.delimiter)) {
    if (!directory) continue;
    const candidates = [
      path.join(directory, 'tsc'),
      path.join(directory, 'node_modules/typescript/bin/tsc'),
      ...(path.basename(directory) === '.bin'
        ? [path.join(directory, '../typescript/bin/tsc')] : []),
    ];
    for (const candidate of candidates) {
      if (!existsSync(candidate)) continue;
      const resolved = realpathSync(candidate);
      if (resolved.replaceAll('\\', '/').endsWith('/typescript/bin/tsc')) return resolved;
    }
  }
  throw new Error('PSC2_TYPESCRIPT_CLI_MISSING: install TypeScript 7.0.2 locally or on PATH');
}

export function assertPinnedTypeScriptCli(cli = resolveTypeScriptCli()) {
  const result = spawnSync(process.execPath, [cli, '--version'], {
    encoding: 'utf8', timeout: 10000, windowsHide: true,
  });
  if (result.error || result.status !== 0 ||
      result.stdout.trim() !== pinnedTypeScriptVersionText) {
    throw new Error('PSC2_TYPESCRIPT_PIN: require exactly ' +
      pinnedTypeScriptVersionText + ' (got ' +
      (result.stdout?.trim() ?? result.error?.code ?? result.status) + ')');
  }
  return cli;
}
