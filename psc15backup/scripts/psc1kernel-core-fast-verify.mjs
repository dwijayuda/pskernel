import { createHash } from "node:crypto";
import { mkdir, readFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { resolveTypeScriptCli, pinnedTypeScriptVersion, pinnedTypeScriptVersionText } from "./typescript-cli.mjs";
import { assertBootstrapWorkspaceManifest } from "./bootstrap-manifest.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

if (process.argv.length < 6) {
  throw new Error(
    "usage: node scripts/psc1kernel-core-fast-verify.mjs " +
      "<bootstrap-workspace> <selfhost-workspace> <generated.ts> <native.ts>",
  );
}

const bootstrapWorkspace = path.resolve(root, process.argv[2]);
const selfhostWorkspace = path.resolve(root, process.argv[3]);
const generatedTs = path.resolve(root, process.argv[4]);
const nativeTs = path.resolve(root, process.argv[5]);

function runNode(args) {
  const result = spawnSync(process.execPath, args, {
    cwd: root,
    encoding: "utf8",
    stdio: "pipe",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC1KERNEL_FAST_VERIFY_COMMAND_FAILED",
        "command=node " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

runNode([
  "scripts/compare-source-workspaces.mjs",
  path.relative(root, bootstrapWorkspace),
  path.relative(root, selfhostWorkspace),
]);

const bootstrapManifest = JSON.parse(
  await readFile(
    path.join(bootstrapWorkspace, ".proofscript-bootstrap.json"),
    "utf8",
  ),
);
const closureSha256 = await assertBootstrapWorkspaceManifest(
  bootstrapWorkspace,
  bootstrapManifest,
  "bootstrap",
);

const [generated, native] = await Promise.all([
  readFile(generatedTs, "utf8"),
  readFile(nativeTs, "utf8"),
]);
const generatedSha256 = sha256(generated);
const nativeSha256 = sha256(native);

if (generated !== native) {
  throw new Error(
    [
      "PSC1KERNEL_CROSS_HOST_TYPESCRIPT_MISMATCH",
      `generated.sha256=${generatedSha256}`,
      `native.sha256=${nativeSha256}`,
    ].join("\n"),
  );
}

const tsc = resolveTypeScriptCli();
const version = spawnSync(process.execPath, [tsc, "--version"], {
  cwd: root,
  encoding: "utf8",
});
if (
  version.error ||
  version.status !== 0 ||
  version.stdout.trim() !== pinnedTypeScriptVersionText
) {
  throw new Error("PSC1KERNEL_FAST_VERIFY_TYPESCRIPT_PIN: require TypeScript " + pinnedTypeScriptVersion);
}

const smokeDir = path.join(path.dirname(generatedTs), "smoke-js");
await rm(smokeDir, { recursive: true, force: true });
await mkdir(smokeDir, { recursive: true });

const emitted = spawnSync(
  process.execPath,
  [
    tsc,
    "--ignoreConfig",
    generatedTs,
    "--target",
    "ES2022",
    "--module",
    "ES2022",
    "--moduleResolution",
    "bundler",
    "--skipLibCheck",
    "--noCheck",
    "--declaration",
    "false",
    "--sourceMap",
    "false",
    "--outDir",
    smokeDir,
  ],
  { cwd: root, encoding: "utf8", stdio: "pipe" },
);
if (emitted.error || emitted.status !== 0) {
  throw new Error(
    [
      "PSC1KERNEL_FAST_VERIFY_TRANSPILE_FAILED",
      emitted.stdout,
      emitted.stderr,
    ].filter(Boolean).join("\n"),
  );
}

const smokeJs = path.join(smokeDir, path.basename(generatedTs, ".ts") + ".js");
runNode([
  "scripts/psc1kernel-generated-smoke.mjs",
  path.relative(root, smokeJs),
]);

process.stdout.write(
  [
    "PSC1KERNEL_SELFHOST_FAST_VERIFY: PASS",
    `sources=${bootstrapManifest.sourceCount}`,
    `closure.sha256=${closureSha256}`,
    `typescript.sha256=${generatedSha256}`,
    "proof=source-fixed-point+cross-host-ts-equality+generated-runtime-smoke",
  ].join("\n") + "\n",
);
