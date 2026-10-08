import { canonicalArtifact } from './artifact-evidence.mjs';
import { selectUniformJavaScriptRegistry, decodeBackendRegistry } from './backend-contract.mjs';
import { readFile, readdir } from 'node:fs/promises';
import { auditCompilerOwnership } from './compiler-ownership.mjs';
const root = new URL('../', import.meta.url);
const json = async path => JSON.parse(await readFile(new URL(path, root), 'utf8'));
const policy = await json('contracts/compiler/COMPILER_OWNERSHIP_V1.json');
const backendRegistry = await json('contracts/backends/BACKEND_REGISTRY_V1.json');
const selfHost = await json('selfhost-profile.json');
const declared = new Set(policy.packages.map(item => item.folder));
for (const entry of await readdir(new URL('packages/', root), { withFileTypes: true })) {
  if (entry.isDirectory() && !entry.name.startsWith('pskernel') && !declared.has(entry.name))
    throw new Error('PSC_OWNERSHIP_UNREGISTERED_DIRECTORY: ' + entry.name);
}
async function sources(path, output) {
  for (const entry of await readdir(new URL(path, root), { withFileTypes: true })) {
    const child = path + entry.name;
    if (entry.isDirectory()) await sources(child + '/', output);
    else if (entry.isFile() && child.endsWith('.lean')) output.push({ path: child, source: await readFile(new URL(child, root), 'utf8') });
  }
}
const packages = [];
for (const entry of policy.packages) {
  const manifest = await json('packages/' + entry.folder + '/package.json'), modules = [];
  await sources('packages/' + entry.folder + '/src/', modules);
  packages.push({ folder: entry.folder, manifest, modules });
}
const result = auditCompilerOwnership({ policy, packages, backendRegistry, primaryBootstrapEntry: selfHost.entry });
const uniform = selectUniformJavaScriptRegistry(canonicalArtifact(backendRegistry, 'backend-registry', 'psc-backend-registry/1'));
auditCompilerOwnership({ policy, packages, backendRegistry: decodeBackendRegistry(uniform.registry), primaryBootstrapEntry: selfHost.entry });
process.stdout.write('PSCV_COMPILER_OWNERSHIP: PASS (' + result.packages + ' packages; ' +
  result.modules + ' modules; ' + result.dependencyEdges + ' declared edges; base and uniform backend emitters; static ownership only)\n');
