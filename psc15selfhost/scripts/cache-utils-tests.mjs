import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import {
  cachedTextTransform,
  fileSetCacheKey,
  restoreFileSetCache,
  storeFileSetCache,
} from "./cache-utils.mjs";

function assert(condition, message) {
  if (!condition) throw new Error(`PSC2_CACHE_TEST: ${message}`);
}

const scratch = await mkdtemp(path.join(tmpdir(), "psc2-cache-test-"));
const oldCacheDir = process.env.PSC_CACHE_DIR;
const oldNoCache = process.env.PSC_NO_CACHE;
process.env.PSC_CACHE_DIR = path.join(scratch, "cache");
delete process.env.PSC_NO_CACHE;

try {
  let computes = 0;
  const compute = async () => {
    computes += 1;
    return "canonical-output\n";
  };

  const first = await cachedTextTransform({
    projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
    namespace: "text-test",
    contract: { operation: "test", version: 1 },
    input: "source",
    compute,
  });
  assert(first.cache === "miss", "first text transform must miss");
  assert(computes === 1, "first text transform must compute once");

  const second = await cachedTextTransform({
    projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
    namespace: "text-test",
    contract: { operation: "test", version: 1 },
    input: "source",
    compute,
  });
  assert(second.cache === "hit", "second text transform must hit");
  assert(second.value === first.value, "text cache must preserve exact bytes");
  assert(computes === 1, "text cache hit must not recompute");

  const untrusted = await cachedTextTransform({ projectRoot: scratch, namespace: "text-test",
    contract: { operation: "test", version: 1 }, input: "source", compute: async () => "fresh-untrusted-output" });
  assert(untrusted.cache === "untrusted-bypass", "untrusted metadata must not authorize cache reuse");
  assert(untrusted.value === "fresh-untrusted-output", "untrusted calls must compute independently");

  await writeFile(
    path.join(process.env.PSC_CACHE_DIR, "text-test", first.key, "output.txt"),
    "corrupt\n",
    "utf8",
  );
  const repaired = await cachedTextTransform({
    projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
    namespace: "text-test",
    contract: { operation: "test", version: 1 },
    input: "source",
    compute,
  });
  assert(repaired.cache === "miss", "corrupt text cache must become a miss");
  assert(repaired.value === "canonical-output\n", "corrupt text cache must recompute exact output");
  assert(computes === 2, "corrupt text cache must recompute once");

  const outputA = path.join(scratch, "out", "index.js");
  const outputB = path.join(scratch, "out", "index.d.ts");
  await mkdir(path.dirname(outputA), { recursive: true });
  await writeFile(outputA, "js-a\n", "utf8");
  await writeFile(outputB, "types-a\n", "utf8");
  const fileKey = fileSetCacheKey(
    { operation: "files", version: 1 },
    Buffer.from("primary"),
  );
  const fileOutputs = [
    { cacheName: "index.js", path: outputA },
    { cacheName: "index.d.ts", path: outputB },
  ];
  await storeFileSetCache({
    projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
    namespace: "files-test",
    key: fileKey,
    outputs: fileOutputs,
  });
  await writeFile(outputA, "changed\n", "utf8");
  await writeFile(outputB, "changed\n", "utf8");
  assert(
    await restoreFileSetCache({
      projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
      namespace: "files-test",
      key: fileKey,
      outputs: fileOutputs,
    }),
    "file-set cache must restore",
  );
  assert(
    (await readFile(outputA, "utf8")) === "js-a\n",
    "file-set cache must restore exact JS",
  );
  assert(
    (await readFile(outputB, "utf8")) === "types-a\n",
    "file-set cache must restore exact declarations",
  );

  assert(!(await restoreFileSetCache({ projectRoot: scratch, namespace: "files-test", key: fileKey,
    outputs: fileOutputs })), "default untrusted file-set restore must fail closed without evidence");

  await writeFile(
    path.join(process.env.PSC_CACHE_DIR, "files-test", fileKey, "index.js"),
    "corrupt-cache\n",
    "utf8",
  );
  await writeFile(outputA, "consumer-js\n", "utf8");
  await writeFile(outputB, "consumer-types\n", "utf8");
  assert(
    !(await restoreFileSetCache({
      projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
      namespace: "files-test",
      key: fileKey,
      outputs: fileOutputs,
    })),
    "corrupt file-set cache must reject the entire restore",
  );
  assert(
    (await readFile(outputA, "utf8")) === "consumer-js\n",
    "rejected file-set cache must not partially overwrite JS",
  );
  assert(
    (await readFile(outputB, "utf8")) === "consumer-types\n",
    "rejected file-set cache must not partially overwrite declarations",
  );

  process.env.PSC_NO_CACHE = "1";
  const cold = await cachedTextTransform({
    projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
    namespace: "text-test",
    contract: { operation: "test", version: 1 },
    input: "source",
    compute,
  });
  assert(cold.cache === "disabled", "cold mode must bypass text cache");
  assert(computes === 3, "cold mode must recompute");
  assert(
    !(await restoreFileSetCache({
      projectRoot: scratch,
    cacheTrust: 'bootstrap-local',
      namespace: "files-test",
      key: fileKey,
      outputs: fileOutputs,
    })),
    "cold mode must bypass file-set cache",
  );

  process.stdout.write("PSC2_CONTENT_CACHE: PASS\n");
} finally {
  if (oldCacheDir === undefined) delete process.env.PSC_CACHE_DIR;
  else process.env.PSC_CACHE_DIR = oldCacheDir;
  if (oldNoCache === undefined) delete process.env.PSC_NO_CACHE;
  else process.env.PSC_NO_CACHE = oldNoCache;
  await rm(scratch, { recursive: true, force: true });
}
