import { existsSync, realpathSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

// Invoke the installed JavaScript CLI directly on every host, including Windows
// where child_process cannot execute a .cmd shim without a shell.
export function resolveTypeScriptCli() {
  try { return createRequire(import.meta.url).resolve('typescript/bin/tsc'); } catch {}
  for (const directory of (process.env.PATH ?? '').split(path.delimiter)) {
    const candidates = [path.join(directory, 'tsc'), path.join(directory, 'node_modules/typescript/bin/tsc'),
      ...(path.basename(directory) === '.bin' ? [path.join(directory, '../typescript/bin/tsc')] : [])];
    for (const candidate of candidates) {
      if (existsSync(candidate)) {
        const resolved = realpathSync(candidate);
        if (resolved.replaceAll('\\', '/').endsWith('/typescript/bin/tsc')) return resolved;
      }
    }
  }
  throw new Error('PSC2_TYPESCRIPT_CLI_MISSING: install TypeScript 5.8.3 locally or on PATH');
}
