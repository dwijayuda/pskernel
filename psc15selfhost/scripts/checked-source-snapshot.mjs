import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { packageBySection, parseImports } from './workspace-layout.mjs';
import { findSourceWorkspaceRoot, readGeneratedSourceClosure } from './selfhost-source-workspace.mjs';

const stripImports = source => source.split(/\r?\n/u)
  .filter(line => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line)).join('\n').trim();
function inside(root, file) {
  const relative = path.relative(root, file);
  if (relative === '..' || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    throw new Error(`PSC2_CHECKED_SOURCE_ESCAPE: ${file}`);
  }
}
export async function readCheckedSourceSnapshot(entryPath) {
  const entry = path.resolve(entryPath);
  const extension = path.extname(entry);
  if (!['.lean', '.ps'].includes(extension)) throw new Error('PSC2_CHECKED_SOURCE_KIND');
  let root;
  try { root = findSourceWorkspaceRoot(entry); }
  catch (error) {
    if (!String(error.message).startsWith('PSC2_SELFHOST_WORKSPACE_NOT_FOUND:')) throw error;
    root = path.dirname(entry); // A standalone project cannot fall back to a parent source tree.
  }
  const generated = await readGeneratedSourceClosure(entry, root);
  let ordered;
  if (generated) ordered = generated.ordered;
  else {
    const realRoot = await realpath(root); ordered = [];
    const active = new Set(); const visited = new Set();
    async function visit(file) {
      inside(root, file);
      const actual = await realpath(file); inside(realRoot, actual);
      if (active.has(file)) throw new Error(`PSC2_CHECKED_IMPORT_CYCLE: ${file}`);
      if (visited.has(file)) return;
      const source = await readFile(actual, 'utf8'); active.add(file);
      for (const moduleName of parseImports(source)) {
        if (!/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$/u.test(moduleName)) {
          throw new Error('PSC2_CHECKED_IMPORT_NAME');
        }
        const parts = moduleName.split('.'); let base;
        if (parts[0] === 'ProofScript') base = path.join(root, 'stdlib', ...parts);
        else if (parts[0] === 'Ps') {
          const folder = packageBySection.get(parts[1]);
          if (!folder) throw new Error(`PSC2_CHECKED_UNKNOWN_PACKAGE: ${moduleName}`);
          base = path.join(root, 'packages', folder, 'src', ...parts);
        } else base = path.join(root, ...parts);
        // Checked projects are homogeneous. Never silently prefer a Lean sibling
        // or translate a different generation. Missing sources are fatal.
        await visit(base + extension);
      }
      active.delete(file); visited.add(file);
      ordered.push(Object.freeze({ path: file, source }));
    }
    await visit(entry); ordered = Object.freeze(ordered);
  }
  const files = ordered.map(item => ({
    path: path.relative(root, item.path).split(path.sep).join('/'), source: item.source,
  })).sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  const closureSha256 = generated?.closureSha256 ?? createHash('sha256')
    .update(JSON.stringify({ entry: path.relative(root, entry).split(path.sep).join('/'), files }))
    .digest('hex');
  const sources = Object.freeze(ordered.map(item => stripImports(item.source)).filter(Boolean));
  return Object.freeze({ root, entry, kind: extension === '.ps' ? 'ps' : 'lean',
    ordered, closureSha256, sources, source: sources.join('\n\n') + '\n' });
}
