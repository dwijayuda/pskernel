// One parent-owned checked build: compiler worker, selected kernel, exact
// target installation, frozen inputs and one immutable-generation commit.
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { readFile, readdir, mkdir, mkdtemp, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkCanonicalAdmissions } from '@proofscript/pskernel-core/check';
import { createCompilerProcess } from './frontend-session.mjs';
import { captureSourceGraph } from './source-graph.mjs';
import { publishGeneration } from './publication.mjs';
import { createTypeScriptTarget } from './target-toolchain.mjs';
const require = createRequire(import.meta.url);
const hash = b => createHash('sha256').update(b).digest('hex');
const host = path.dirname(fileURLToPath(import.meta.url));
const compilerPath = require.resolve('@proofscript/compiler');
const compilerIdentity = hash(readFileSync(compilerPath));
const coreRoot = path.dirname(require.resolve('@proofscript/pskernel-core/package.json'));
const coreManifest = JSON.parse(readFileSync(path.join(coreRoot, 'dist/kernel-manifest.json'), 'utf8'));
const expectedKernel = Object.freeze({ protocol: 'pskernel-core-js/1', provider: 'psc0-generated-js-core', leanVersion: '4.34.0', profile: 'lean4.34-core', kernelSha256: coreManifest.kernelSha256, kernelSourceRevision: coreManifest.baseMainCommit });

export async function runCheckedBuild({ entry, output, checkOnly = false, version = 'development', frontendLimits, signal }) {
  const destination = path.resolve(output || entry.replace(/\.(ps|lean)$/u, '.js'));
  if (!checkOnly && !/\.(js|ts)$/u.test(destination)) throw new Error('PSC_OUTPUT_EXTENSION');
  signal?.throwIfAborted();
  // A logical check neither resolves nor runs the target compiler.
  const target = checkOnly ? null : await createTypeScriptTarget({ signal });
  const trustedFiles = [['compiler', compilerPath], ['compiler-package', require.resolve('@proofscript/compiler/package.json')], ['kernel-package', require.resolve('@proofscript/pskernel-core/package.json')]];
  for (const name of ['index.js', 'kernel-manifest.json', 'prelude.json', 'core-checker.mjs', 'core-cli.mjs', 'generated-core-provider.mjs']) trustedFiles.push(['kernel/' + name, path.join(coreRoot, 'dist', name)]);
  for (const name of (await readdir(host)).filter(n => n.endsWith('.mjs') || n === 'psc.js').sort()) trustedFiles.push(['host/' + name, path.join(host, name)]);
  const frontend = await createCompilerProcess({ compilerSha256: compilerIdentity, kernelIdentity: expectedKernel, checkAdmissions: text => checkCanonicalAdmissions(text, { timeoutMs: 120000 }), limits: frontendLimits, signal });
  let stage;
  try {
    const graph = await captureSourceGraph(frontend, entry, { trustedFiles });
    if (hash(await readFile(compilerPath)) !== compilerIdentity) throw new Error('PSC_COMPILER_IDENTITY_CHANGED');
    const binding = { sourceClosureSha256: graph.snapshot.sourceClosureSha256, compilerSha256: compilerIdentity, grammar: 'ps-0.9-r3/new-only', kernel: expectedKernel, profile: 'bounded-compiler', frontendLimits: frontend.stats().limits, targetPlanSha256: target?.planSha256 ?? null };
    const handle = await frontend.checkSources(graph.kind, graph.sources, binding);
    await graph.snapshot.revalidate();
    const audit = { schemaVersion: 3, kind: checkOnly ? 'psc0-npm-checked' : 'psc0-npm-checked-build', version, entry: path.resolve(entry), sourceCount: graph.sourceCount, sourceClosureSha256: graph.snapshot.sourceClosureSha256, canonicalAdmissionsSha256: handle.canonicalAdmissionsSha256, compilerSha256: compilerIdentity, kernel: expectedKernel, inputs: graph.snapshot.binding, checkedBinding: binding, claims: { kernelAdmitted: true, fullPscvVerified: false, compilerSemanticsProven: false, newSelfhostFixedPoint: false }, receiptIsAuthority: false };
    if (checkOnly) {
      await frontend.assertCurrent(handle);
      const evidence = frontend.stats();
      await frontend.close();
      signal?.throwIfAborted();
      return Object.freeze({ ...audit, frontend: evidence });
    }
    const typeScriptSource = await frontend.emit(handle);
    await mkdir(path.dirname(destination), { recursive: true });
    stage = await mkdtemp(path.join(path.dirname(destination), '.psc-stage-'));
    const stem = path.basename(destination).replace(/\.(js|ts)$/u, '');
    if (!/^[A-Za-z_][A-Za-z_0-9.-]*$/u.test(stem)) throw new Error('PSC_OUTPUT_NAME');
    const input = path.join(stage, stem + '.ts');
    await writeFile(input, typeScriptSource, { flag: 'wx', mode: 0o600 });
    const generated = await target.compile(input);
    if (generated.evidence.inputTypeScriptSha256 !== hash(typeScriptSource)) throw new Error('PSC_TARGET_CHECKED_INPUT_CHANGED');
    await frontend.assertCurrent(handle);
    const evidence = frontend.stats();
    await frontend.close();
    // Publication revalidates both source and target, not merely the JS launcher.
    const snapshot = Object.freeze({
      protectedPaths: graph.snapshot.protectedPaths,
      async revalidate() { await graph.snapshot.revalidate(); await target.revalidate(); signal?.throwIfAborted(); },
    });
    return await publishGeneration({ output: destination, products: generated.products, snapshot, receipt: { ...audit, frontend: evidence, typescript: '7.0.2', target: generated.evidence, outputSha256: hash(generated.products['.js']) } });
  } finally {
    await frontend.close();
    if (stage) await rm(stage, { recursive: true, force: true }).catch(error => console.warn('PSC_STAGING_CLEANUP: ' + error.message));
  }
}
