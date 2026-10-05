import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { assertBootstrapWorkspaceManifest } from "./bootstrap-manifest.mjs";
import { resolveTypeScriptCli, pinnedTypeScriptVersion, pinnedTypeScriptVersionText } from "./typescript-cli.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

function run(args) {
  const result = spawnSync(process.execPath, args, {
    cwd: root,
    encoding: "utf8",
    stdio: "pipe",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC1KERNEL_SELFHOST_RESUME_COMMAND_FAILED",
        "command=node " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
}

async function sha256File(file) {
  const bytes = await readFile(file);
  return createHash("sha256").update(bytes).digest("hex");
}

async function readJson(file) {
  return JSON.parse(await readFile(file, "utf8"));
}

const compilerArg =
  process.argv[2] ?? "dist/bootstrap/packages/compiler/index.js";
const compiler = path.resolve(root, compilerArg);
const outRoot = path.resolve(
  root,
  process.argv[3] ?? "dist/kernel-core",
);
const entry =
  "packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean";

if (!existsSync(compiler)) {
  throw new Error(`PSC1KERNEL_SELFHOST_COMPILER_MISSING: ${compiler}`);
}

const tsc = resolveTypeScriptCli();
const tscVersion = spawnSync(process.execPath, [tsc, "--version"], {
  cwd: root,
  encoding: "utf8",
});
if (
  tscVersion.error ||
  tscVersion.status !== 0 ||
  tscVersion.stdout.trim() !== pinnedTypeScriptVersionText
) {
  throw new Error("PSC1KERNEL_SELFHOST_TYPESCRIPT_PIN: require TypeScript " + pinnedTypeScriptVersion);
}

const bootstrapWorkspace = path.join(outRoot, "bootstrap", "workspace");
const selfhostWorkspace = path.join(outRoot, "selfhost", "workspace");
const bootstrapTs = path.join(outRoot, "bootstrap", "kernel", "index.ts");
const bootstrapJs = path.join(outRoot, "bootstrap", "kernel", "index.js");
const selfhostTs = path.join(outRoot, "selfhost", "kernel", "index.ts");
const selfhostJs = path.join(outRoot, "selfhost", "kernel", "index.js");
const receiptPath = path.join(outRoot, "selfhost-receipt.json");

await mkdir(outRoot, { recursive: true });

/*
Always regenerate the inexpensive canonical source closure. This makes the
closure hash the cache key and prevents a stale artifact from being reused
after source edits.
*/
await rm(bootstrapWorkspace, { recursive: true, force: true });
run([
  "scripts/bootstrap-project.mjs",
  entry,
  path.relative(root, bootstrapWorkspace),
]);

const bootstrapManifestPath =
  path.join(bootstrapWorkspace, ".proofscript-bootstrap.json");
const bootstrapManifest = await readJson(bootstrapManifestPath);
const closureSha256 = await assertBootstrapWorkspaceManifest(
  bootstrapWorkspace,
  bootstrapManifest,
  "bootstrap",
);
const compilerSha256 = await sha256File(compiler);
const key = `${compilerSha256}:${closureSha256}`;

let receipt;
if (existsSync(receiptPath)) {
  try {
    receipt = await readJson(receiptPath);
  } catch {
    receipt = undefined;
  }
}
if (receipt?.key !== key) receipt = undefined;

const bootstrapEntry = path.join(
  bootstrapWorkspace,
  bootstrapManifest.entry,
);

if (
  receipt?.bootstrapArtifact === true &&
  existsSync(bootstrapTs) &&
  existsSync(bootstrapJs)
) {
  process.stdout.write("PSC1KERNEL_SELFHOST_RESUME: reuse bootstrap artifact\n");
} else {
  await rm(path.dirname(bootstrapTs), { recursive: true, force: true });
  run([
    "scripts/compile-with-generated.mjs",
    path.relative(root, compiler),
    path.relative(root, bootstrapEntry),
    path.relative(root, bootstrapTs),
  ]);
  receipt = {
    schemaVersion: 1,
    key,
    compilerSha256,
    closureSha256,
    bootstrapArtifact: true,
    sourceFixedPoint: false,
    selfhostArtifact: false,
  };
  await writeFile(
    receiptPath,
    JSON.stringify(receipt, null, 2) + "\n",
    "utf8",
  );
}

if (
  receipt?.sourceFixedPoint === true &&
  existsSync(path.join(selfhostWorkspace, ".proofscript-selfhost.json"))
) {
  run([
    "scripts/compare-source-workspaces.mjs",
    path.relative(root, bootstrapWorkspace),
    path.relative(root, selfhostWorkspace),
  ]);
  process.stdout.write("PSC1KERNEL_SELFHOST_RESUME: reuse source fixed point\n");
} else {
  await rm(selfhostWorkspace, { recursive: true, force: true });
  run([
    "scripts/reemit-project-with-generated.mjs",
    path.relative(root, compiler),
    path.relative(root, bootstrapWorkspace),
    path.relative(root, selfhostWorkspace),
  ]);
  run([
    "scripts/compare-source-workspaces.mjs",
    path.relative(root, bootstrapWorkspace),
    path.relative(root, selfhostWorkspace),
  ]);
  receipt.sourceFixedPoint = true;
  await writeFile(
    receiptPath,
    JSON.stringify(receipt, null, 2) + "\n",
    "utf8",
  );
}

const selfhostManifest = await readJson(
  path.join(selfhostWorkspace, ".proofscript-selfhost.json"),
);
const selfhostEntry = path.join(
  selfhostWorkspace,
  selfhostManifest.entry,
);

if (
  receipt?.selfhostArtifact === true &&
  existsSync(selfhostTs) &&
  existsSync(selfhostJs)
) {
  process.stdout.write("PSC1KERNEL_SELFHOST_RESUME: reuse selfhost artifact\n");
} else {
  await rm(path.dirname(selfhostTs), { recursive: true, force: true });
  run([
    "scripts/compile-with-generated.mjs",
    path.relative(root, compiler),
    path.relative(root, selfhostEntry),
    path.relative(root, selfhostTs),
  ]);
  receipt.selfhostArtifact = true;
  await writeFile(
    receiptPath,
    JSON.stringify(receipt, null, 2) + "\n",
    "utf8",
  );
}

run([
  "scripts/compare-selfhost.mjs",
  path.relative(root, bootstrapTs),
  path.relative(root, selfhostTs),
]);

run([
  "scripts/psc1kernel-generated-smoke.mjs",
  path.relative(root, bootstrapJs),
]);

const bootstrapTsSha256 = await sha256File(bootstrapTs);
const bootstrapJsSha256 = await sha256File(bootstrapJs);
receipt.fixedPoint = true;
receipt.bootstrapTsSha256 = bootstrapTsSha256;
receipt.bootstrapJsSha256 = bootstrapJsSha256;
await writeFile(
  receiptPath,
  JSON.stringify(receipt, null, 2) + "\n",
  "utf8",
);

process.stdout.write(
  [
    "PSC1KERNEL_SELFHOST_RESUMABLE_FIXED_POINT: PASS",
    `sources=${bootstrapManifest.sourceCount}`,
    `compiler.sha256=${compilerSha256}`,
    `closure.sha256=${closureSha256}`,
    `typescript.sha256=${bootstrapTsSha256}`,
    `javascript.sha256=${bootstrapJsSha256}`,
  ].join("\n") + "\n",
);
