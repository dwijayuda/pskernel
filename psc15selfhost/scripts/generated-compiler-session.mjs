import { createHash } from "node:crypto";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { inspect } from "node:util";
import {
  findSourceWorkspaceRoot,
  readGeneratedSourceClosure,
} from "./selfhost-source-workspace.mjs";
import { sha256Bytes, sha256File } from "./cache-utils.mjs";

function exceptTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (tag === "ok" || tag === "error") return tag;
  }
  return undefined;
}

function unwrapExcept(value, stage) {
  const tag = exceptTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC2_RESIDENT_${stage.toUpperCase()}_FAILED: ${inspect(value.error, { depth: 8 })}`,
    );
  }
  throw new Error(`PSC2_RESIDENT_${stage.toUpperCase()}_RESULT_SHAPE`);
}

function stripImports(source) {
  return source
    .split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join("\n")
    .trim();
}

function prefixFingerprint(previous, sourceHash) {
  const hash = createHash("sha256");
  hash.update("psc2-resident-prefix-v1\0", "utf8");
  hash.update(previous, "utf8");
  hash.update("\0", "utf8");
  hash.update(sourceHash, "utf8");
  return hash.digest("hex");
}

function requireCompilerApi(compiler) {
  for (const name of [
    "PsCompilerSourceKind",
    "psCompilerParseSource",
    "psElabModule",
    "psListReverse",
    "psListAppend",
    "psCompilerElaborateSourcesWorker",
    "psCompilerPrepareElaborated",
    "psCompilerTypeScriptFromPrepared",
    "psSelfHostProdPreludeEnvironment",
    "List",
  ]) {
    if (!(name in compiler)) {
      throw new Error(`PSC2_RESIDENT_COMPILER_EXPORT_MISSING: ${name}`);
    }
  }
}

export async function createGeneratedCompilerSession(projectRoot, compilerPath) {
  const absoluteCompiler = path.resolve(projectRoot, compilerPath);
  const compilerSha256 = await sha256File(absoluteCompiler);
  const compiler = await import(
    pathToFileURL(absoluteCompiler).href + `?sha256=${compilerSha256}`
  );
  requireCompilerApi(compiler);

  const parseCache = new Map();
  const snapshotCache = new Map();
  const preparedCache = new Map();
  const backendCache = new Map();

  async function loadProject(entryPath) {
    const absoluteEntry = path.resolve(projectRoot, entryPath);
    if (!absoluteEntry.endsWith(".ps")) {
      throw new Error(`PSC2_RESIDENT_SOURCE_KIND: expected .ps, got ${absoluteEntry}`);
    }
    const workspaceRoot = findSourceWorkspaceRoot(absoluteEntry);
    const generated = await readGeneratedSourceClosure(
      absoluteEntry,
      workspaceRoot,
      { allowProjectManifest: true },
    );
    if (!generated) {
      throw new Error(
        `PSC2_RESIDENT_GENERATED_WORKSPACE_REQUIRED: ${absoluteEntry}`,
      );
    }
    const modules = [];
    for (const item of generated.ordered) {
      const source = stripImports(item.source);
      if (source.length === 0) continue;
      modules.push(
        Object.freeze({
          path: item.path,
          source,
          sourceHash: sha256Bytes(Buffer.from(source, "utf8")),
        }),
      );
    }
    return {
      entryPath: absoluteEntry,
      workspaceRoot,
      closureSha256: generated.closureSha256,
      modules,
    };
  }

  async function compile(entryPath, options = {}) {
    const cold = options.cold === true;
    const progress = options.progress === true;
    const project = await loadProject(entryPath);
    const sourceKind = compiler.PsCompilerSourceKind.proofScript;
    const stats = {
      modules: project.modules.length,
      parseHits: 0,
      parseMisses: 0,
      snapshotHits: 0,
      snapshotMisses: 0,
      preparedHit: false,
      backendHit: false,
    };

    let environment = compiler.psSelfHostProdPreludeEnvironment;
    let declarationsRev = compiler.List.nil();
    let prefix = sha256Bytes(
      Buffer.from(
        `psc2-resident-root-v1\0${compilerSha256}\0proofScript`,
        "utf8",
      ),
    );

    for (let index = 0; index < project.modules.length; index += 1) {
      const module = project.modules[index];
      const nextPrefix = prefixFingerprint(prefix, module.sourceHash);
      const started = performance.now();

      if (!cold && snapshotCache.has(nextPrefix)) {
        const snapshot = snapshotCache.get(nextPrefix);
        environment = snapshot.environment;
        declarationsRev = snapshot.declarationsRev;
        stats.snapshotHits += 1;
        prefix = nextPrefix;
        if (progress) {
          process.stdout.write(
            `PSC2_RESIDENT_MODULE: ${index + 1}/${project.modules.length} snapshot=hit parse=skip ms=${Math.round(performance.now() - started)}\n`,
          );
        }
        continue;
      }

      stats.snapshotMisses += 1;
      let parsed;
      let parseMode;
      if (!cold && parseCache.has(module.sourceHash)) {
        parsed = parseCache.get(module.sourceHash);
        parseMode = "hit";
        stats.parseHits += 1;
      } else {
        parsed = unwrapExcept(
          compiler.psCompilerParseSource(sourceKind, module.source),
          `parse-module-${index + 1}`,
        );
        parseMode = "miss";
        stats.parseMisses += 1;
        if (!cold) parseCache.set(module.sourceHash, parsed);
      }

      const elaborated = unwrapExcept(
        compiler.psElabModule(environment, parsed),
        `elaborate-module-${index + 1}`,
      );
      environment = elaborated.environment;
      declarationsRev = compiler.psListAppend(
        compiler.psListReverse(elaborated.declarations),
        declarationsRev,
      );
      if (!cold) {
        snapshotCache.set(
          nextPrefix,
          Object.freeze({ environment, declarationsRev }),
        );
      }
      prefix = nextPrefix;

      if (progress) {
        process.stdout.write(
          `PSC2_RESIDENT_MODULE: ${index + 1}/${project.modules.length} snapshot=miss parse=${parseMode} ms=${Math.round(performance.now() - started)}\n`,
        );
      }
    }

    let prepared;
    if (!cold && preparedCache.has(prefix)) {
      prepared = preparedCache.get(prefix);
      stats.preparedHit = true;
    } else {
      const elaborated = unwrapExcept(
        compiler.psCompilerElaborateSourcesWorker(
          sourceKind,
          compiler.List.nil(),
          environment,
          declarationsRev,
        ),
        "finalize",
      );
      prepared = unwrapExcept(
        compiler.psCompilerPrepareElaborated(elaborated),
        "prepare",
      );
      if (!cold) preparedCache.set(prefix, prepared);
    }

    let typeScript;
    if (!cold && backendCache.has(prefix)) {
      typeScript = backendCache.get(prefix);
      stats.backendHit = true;
    } else {
      typeScript = unwrapExcept(
        compiler.psCompilerTypeScriptFromPrepared(prepared),
        "backend",
      );
      if (!cold) backendCache.set(prefix, typeScript);
    }

    return {
      compilerSha256,
      fingerprint: prefix,
      project,
      prepared,
      typeScript,
      stats,
    };
  }

  function clear() {
    parseCache.clear();
    snapshotCache.clear();
    preparedCache.clear();
    backendCache.clear();
  }

  function cacheSizes() {
    return {
      parse: parseCache.size,
      snapshots: snapshotCache.size,
      prepared: preparedCache.size,
      backend: backendCache.size,
    };
  }

  return Object.freeze({
    compilerSha256,
    compile,
    clear,
    cacheSizes,
  });
}
