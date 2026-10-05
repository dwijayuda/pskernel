import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createGeneratedCompilerSession } from "./generated-compiler-session.mjs";
import {
  findSourceWorkspaceRoot,
  readGeneratedSourceClosure,
} from "./selfhost-source-workspace.mjs";

function assert(condition, message) {
  if (!condition) throw new Error(`PSC2_RESIDENT_CACHE_TEST: ${message}`);
}

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const compiler = path.join(
  "dist",
  "bootstrap",
  "packages",
  "compiler",
  "index.js",
);
const scratch = await mkdtemp(path.join(tmpdir(), "psc2-resident-cache-"));
const demo = path.join(scratch, "Demo");
const aPath = path.join(demo, "A.ps");
const bPath = path.join(demo, "B.ps");
const cPath = path.join(demo, "C.ps");

async function writeProject({
  aValue = "1",
  cValue = "b",
  aComment = "",
} = {}) {
  await mkdir(demo, { recursive: true });
  await writeFile(
    aPath,
    `${aComment}const a: Nat := { ${aValue} }\n`,
    "utf8",
  );
  await writeFile(
    bPath,
    "import Demo.A\nconst b: Nat := { a }\n",
    "utf8",
  );
  await writeFile(
    cPath,
    `import Demo.B\nconst c: Nat := { ${cValue} }\n`,
    "utf8",
  );
  await writeFile(
    path.join(scratch, ".proofscript-project.json"),
    JSON.stringify(
      {
        schemaVersion: 1,
        sourceKind: "ps",
        targetKind: "ps",
        entry: "Demo/C.ps",
        sourceCount: 3,
        generated: ["Demo/A.ps", "Demo/B.ps", "Demo/C.ps"],
      },
      null,
      2,
    ) + "\n",
    "utf8",
  );
}

try {
  await writeProject();
  const projectRoot = findSourceWorkspaceRoot(cPath);
  assert(
    (await readGeneratedSourceClosure(cPath, projectRoot)) === undefined,
    "ordinary project loading must remain recursive by default",
  );
  const declaredProject = await readGeneratedSourceClosure(
    cPath,
    projectRoot,
    { allowProjectManifest: true },
  );
  assert(
    declaredProject?.ordered.length === 3,
    "resident mode must opt into the exact declared project closure",
  );

  const session = await createGeneratedCompilerSession(root, compiler);

  const first = await session.compile(cPath);
  assert(first.stats.snapshotHits === 0, "cold first pass must have no snapshot hits");
  assert(first.stats.snapshotMisses === 3, "cold first pass must elaborate all modules");
  assert(first.stats.parseMisses === 3, "cold first pass must parse all modules");

  const warm = await session.compile(cPath);
  assert(warm.typeScript === first.typeScript, "warm output must equal cold output");
  assert(warm.stats.snapshotHits === 3, "unchanged warm pass must reuse all snapshots");
  assert(warm.stats.snapshotMisses === 0, "unchanged warm pass must elaborate no modules");
  assert(warm.stats.parseMisses === 0, "unchanged warm pass must parse no modules");
  assert(warm.stats.preparedHit, "unchanged warm pass must reuse prepared module");
  assert(warm.stats.backendHit, "unchanged warm pass must reuse backend output");

  await writeProject({ cValue: "Nat.succ(b)" });
  const changedSuffix = await session.compile(cPath);
  assert(changedSuffix.stats.snapshotHits === 2, "changed suffix must reuse two-module prefix");
  assert(changedSuffix.stats.snapshotMisses === 1, "changed suffix must re-elaborate only suffix");
  assert(changedSuffix.stats.parseHits === 0, "changed suffix needs no unchanged parsed module after prefix");
  assert(changedSuffix.stats.parseMisses === 1, "changed suffix text must be reparsed");

  await writeProject();
  const reverted = await session.compile(cPath);
  assert(reverted.typeScript === first.typeScript, "reverted output must equal original output");
  assert(reverted.stats.snapshotHits === 3, "reverted known source must reuse prior snapshots");
  assert(reverted.stats.snapshotMisses === 0, "reverted known source must not re-elaborate");
  assert(reverted.stats.preparedHit, "reverted known source must reuse prepared module");
  assert(reverted.stats.backendHit, "reverted known source must reuse backend output");

  await writeProject({ aComment: "/* semantic no-op */\n" });
  const greenPrefix = await session.compile(cPath);
  assert(
    greenPrefix.typeScript === first.typeScript,
    "semantic no-op source change must preserve exact TypeScript",
  );
  assert(
    greenPrefix.stats.snapshotHits === 2,
    "semantic no-op first-module edit must reuse downstream semantic transitions",
  );
  assert(
    greenPrefix.stats.snapshotMisses === 1,
    "semantic no-op first-module edit must re-elaborate only the changed module",
  );
  assert(
    greenPrefix.stats.parseMisses === 1,
    "semantic no-op changed text must be parsed once",
  );
  assert(
    greenPrefix.stats.semanticGreen === 1,
    "semantic no-op must be recognized as a red/green semantic match",
  );
  assert(
    greenPrefix.stats.preparedHit && greenPrefix.stats.backendHit,
    "semantic no-op must reuse final prepared/backend results",
  );

  await writeProject();
  const afterGreenRestore = await session.compile(cPath);
  assert(
    afterGreenRestore.stats.snapshotHits === 3,
    "restoring after a semantic no-op must recover the original transitions",
  );

  await writeProject({ aValue: "2" });
  const changedPrefix = await session.compile(cPath);
  assert(changedPrefix.stats.snapshotHits === 0, "changed first module must invalidate semantic prefix");
  assert(changedPrefix.stats.snapshotMisses === 3, "changed first module must re-elaborate all modules");
  assert(changedPrefix.stats.parseMisses === 1, "changed first module must reparse only changed text");
  assert(
    changedPrefix.stats.parseHits === 2,
    "unchanged downstream modules must reuse their parsed ASTs",
  );

  await writeProject();
  const restoredAgain = await session.compile(cPath);
  assert(
    restoredAgain.typeScript === first.typeScript,
    "restored prefix must recover exact original TypeScript",
  );
  assert(
    restoredAgain.stats.snapshotHits === 3,
    "restored known prefix must recover all original snapshots",
  );

  const coldOracle = await session.compile(cPath, { cold: true });
  assert(coldOracle.typeScript === first.typeScript, "cold oracle must equal cached output");
  assert(coldOracle.stats.snapshotHits === 0, "cold oracle must bypass snapshots");
  assert(coldOracle.stats.snapshotMisses === 3, "cold oracle must elaborate all modules");
  assert(coldOracle.stats.parseHits === 0, "cold oracle must bypass parsed AST cache");
  assert(coldOracle.stats.parseMisses === 3, "cold oracle must parse all modules");
  assert(!coldOracle.stats.preparedHit, "cold oracle must bypass prepared cache");
  assert(!coldOracle.stats.backendHit, "cold oracle must bypass backend cache");

  process.stdout.write(
    [
      "PSC2_RESIDENT_CACHE: PASS",
      `unchanged.snapshotHits=${warm.stats.snapshotHits}`,
      `suffix.snapshotHits=${changedSuffix.stats.snapshotHits}`,
      `green.semanticMatches=${greenPrefix.stats.semanticGreen}`,
      `green.snapshotHits=${greenPrefix.stats.snapshotHits}`,
      `prefix.parseHits=${changedPrefix.stats.parseHits}`,
      `prefix.parseMisses=${changedPrefix.stats.parseMisses}`,
    ].join("\n") + "\n",
  );
} finally {
  await rm(scratch, { recursive: true, force: true });
}
