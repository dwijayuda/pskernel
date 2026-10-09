import { accessSync, constants, existsSync, readFileSync, realpathSync, statSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

function checkedVersion(version) {
  if (version !== '7.0.2' && version !== '5.8.3') {
    throw new Error('PSC0_TYPESCRIPT_VERSION: expected 7.0.2 or historical 5.8.3, received ' + JSON.stringify(version));
  }
  return version;
}

export function expectedTypeScriptVersion() {
  return checkedVersion(process.env.PSC0_TYPESCRIPT_VERSION ?? '7.0.2');
}

// Positional source files must ignore unrelated project configuration in TS7.
// Historical recovery keeps the exact TS5 argument list and artifact recipe.
export function typeScriptProfileArgs(args, version = expectedTypeScriptVersion()) {
  return checkedVersion(version) === '7.0.2' ? ['--ignoreConfig', ...args] : [...args];
}

function installedPackageCli(packageJson) {
  const realPackageJson = realpathSync(packageJson);
  const directory = path.dirname(realPackageJson);
  const metadata = JSON.parse(readFileSync(realPackageJson, 'utf8'));
  const bin = metadata.bin?.tsc;
  if (metadata.name !== 'typescript' || typeof bin !== 'string' || bin.length === 0 || path.isAbsolute(bin)) {
    throw new Error('package.json must declare the typescript package and relative bin.tsc');
  }
  const launcher = realpathSync(path.resolve(directory, bin));
  const relative = path.relative(directory, launcher);
  if (relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative) ||
      !statSync(launcher).isFile()) {
    throw new Error('bin.tsc must be a regular file inside the installed typescript package');
  }
  accessSync(launcher, constants.R_OK);
  return launcher;
}

function installedLauncher(candidate) {
  const launcher = realpathSync(candidate);
  if (!statSync(launcher).isFile()) throw new Error('TypeScript launcher must be a regular file');
  let directory = path.dirname(launcher);
  for (;;) {
    const packageJson = path.join(directory, 'package.json');
    if (existsSync(packageJson)) {
      const declared = installedPackageCli(packageJson);
      if (declared !== launcher) throw new Error('launcher is not the installed package bin.tsc');
      return launcher;
    }
    const parent = path.dirname(directory);
    if (parent === directory) throw new Error('launcher has no owning typescript package');
    directory = parent;
  }
}

// Both pinned releases provide a JavaScript bin.tsc launcher. Invoke that file
// through Node on every host; never invoke a shell shim or the native binary.
export function resolveTypeScriptCli() {
  const expected = expectedTypeScriptVersion();
  if (Object.hasOwn(process.env, 'PSC0_TSC')) {
    const override = process.env.PSC0_TSC;
    if (!path.isAbsolute(override)) {
      throw new Error('PSC0_TYPESCRIPT_CLI_OVERRIDE: PSC0_TSC must be an absolute installed JavaScript launcher');
    }
    try { return installedLauncher(override); }
    catch (error) {
      throw new Error('PSC0_TYPESCRIPT_CLI_OVERRIDE: ' + override + ': ' + error.message, { cause: error });
    }
  }

  let packageJson;
  try { packageJson = createRequire(import.meta.url).resolve('typescript/package.json'); } catch {}
  if (packageJson) return installedPackageCli(packageJson);

  for (const directory of (process.env.PATH ?? '').split(path.delimiter)) {
    const candidates = [path.join(directory, 'tsc'), path.join(directory, 'node_modules/typescript/bin/tsc'),
      ...(path.basename(directory) === '.bin' ? [path.join(directory, '../typescript/bin/tsc')] : [])];
    for (const candidate of candidates) {
      if (existsSync(candidate)) {
        try { return installedLauncher(candidate); } catch {}
      }
    }
  }
  throw new Error('PSC2_TYPESCRIPT_CLI_MISSING: install TypeScript ' + expected +
    ' locally or on PATH, or set PSC0_TSC to its absolute installed JavaScript launcher');
}
