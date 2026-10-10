// The release packer and fast installed-host gate stage the same host files.
import { cp, mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
export async function stageNpmHost(root, target) {
  await mkdir(path.join(target, 'bin'), { recursive: true });
  for (const entry of await readdir(path.join(root, 'npm-cli'), { withFileTypes: true })) {
    if (entry.isFile() && (entry.name === 'psc.js' || entry.name.endsWith('.mjs'))) await cp(path.join(root, 'npm-cli', entry.name), path.join(target, 'bin', entry.name));
  }
}
export function normalizeFacadeEntry(metadata, name) {
  if (['compiler', 'pskernel-core', 'pskernel-lean', 'pskernel-lean-wasm'].includes(name)) return metadata;
  // Source-owning facades are .mjs files, not independent generated .js outputs.
  metadata.main = './dist/index.mjs';
  metadata.exports = { ...metadata.exports, '.': './dist/index.mjs', './package.json': './package.json' };
  delete metadata.types;
  return metadata;
}
