import { readFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

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
        "PSC1KERNEL_SELFHOST_COMMAND_FAILED",
        "command=node " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
}

const compilerArg =
  process.argv[2] ?? "dist/bootstrap/packages/compiler/index.js";
const compiler = path.resolve(root, compilerArg);
const outRoot = path.resolve(
  root,
  process.argv[3] ?? "dist/kernel-core",
);
const bootstrapWorkspace = path.join(outRoot, "bootstrap", "workspace");
const selfhostWorkspace = path.join(outRoot, "selfhost", "workspace");
const bootstrapTs = path.join(outRoot, "bootstrap", "kernel", "index.ts");
const selfhostTs = path.join(outRoot, "selfhost", "kernel", "index.ts");
const entry =
  "packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean";

await rm(outRoot, { recursive: true, force: true });

run([
  "scripts/bootstrap-project.mjs",
  entry,
  path.relative(root, bootstrapWorkspace),
]);

const bootstrapManifest = JSON.parse(
  await readFile(
    path.join(bootstrapWorkspace, ".proofscript-bootstrap.json"),
    "utf8",
  ),
);
const bootstrapEntry = path.join(
  bootstrapWorkspace,
  bootstrapManifest.entry,
);

run([
  "scripts/compile-with-generated.mjs",
  path.relative(root, compiler),
  path.relative(root, bootstrapEntry),
  path.relative(root, bootstrapTs),
]);

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

const selfhostManifest = JSON.parse(
  await readFile(
    path.join(selfhostWorkspace, ".proofscript-selfhost.json"),
    "utf8",
  ),
);
const selfhostEntry = path.join(
  selfhostWorkspace,
  selfhostManifest.entry,
);

run([
  "scripts/compile-with-generated.mjs",
  path.relative(root, compiler),
  path.relative(root, selfhostEntry),
  path.relative(root, selfhostTs),
]);

run([
  "scripts/compare-selfhost.mjs",
  path.relative(root, bootstrapTs),
  path.relative(root, selfhostTs),
]);

process.stdout.write(
  [
    "PSC1KERNEL_SELFHOST_GENERATION_FIXED_POINT: PASS",
    "entry=" + entry,
    "sources=" + bootstrapManifest.sourceCount,
    "closure.sha256=" + bootstrapManifest.closureSha256,
  ].join("\n") + "\n",
);
