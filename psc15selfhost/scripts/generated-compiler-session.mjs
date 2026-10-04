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

function hashAtom(hash, tag, value) {
  const text = String(value);
  hash.update(tag, "utf8");
  hash.update(":", "utf8");
  hash.update(String(Buffer.byteLength(text, "utf8")), "utf8");
  hash.update(":", "utf8");
  hash.update(text, "utf8");
  hash.update(";", "utf8");
}

function hashRuntimeValue(hash, value, active) {
  if (value === null) {
    hashAtom(hash, "null", "");
    return;
  }

  const type = typeof value;
  if (type === "undefined") {
    hashAtom(hash, "undefined", "");
    return;
  }
  if (type === "string") {
    hashAtom(hash, "string", value);
    return;
  }
  if (type === "boolean") {
    hashAtom(hash, "boolean", value ? "1" : "0");
    return;
  }
  if (type === "bigint") {
    hashAtom(hash, "bigint", value.toString(10));
    return;
  }
  if (type === "number") {
    const normalized =
      Number.isNaN(value)
        ? "NaN"
        : value === Infinity
          ? "Infinity"
          : value === -Infinity
            ? "-Infinity"
            : Object.is(value, -0)
              ? "-0"
              : String(value);
    hashAtom(hash, "number", normalized);
    return;
  }
  if (type === "symbol") {
    hashAtom(hash, "symbol-value", String(value));
    return;
  }
  if (type !== "object") {
    throw new Error(`PSC2_RESIDENT_SEMANTIC_FINGERPRINT_KIND: ${type}`);
  }
  if (active.has(value)) {
    throw new Error("PSC2_RESIDENT_SEMANTIC_FINGERPRINT_CYCLE");
  }

  active.add(value);
  hashAtom(hash, Array.isArray(value) ? "array-open" : "object-open", "");

  const names = Object.getOwnPropertyNames(value).sort();
  for (const name of names) {
    hashAtom(hash, "property", name);
    hashRuntimeValue(hash, value[name], active);
  }

  const symbols = Object.getOwnPropertySymbols(value)
    .map((symbol) => ({ symbol, label: String(symbol) }))
    .sort((left, right) => left.label.localeCompare(right.label));
  for (const item of symbols) {
    hashAtom(hash, "symbol-property", item.label);
    hashRuntimeValue(hash, value[item.symbol], active);
  }

  hashAtom(hash, Array.isArray(value) ? "array-close" : "object-close", "");
  active.delete(value);
}

function semanticValueFingerprint(value) {
  const hash = createHash("sha256");
  hashAtom(hash, "contract", "psc2-resident-runtime-value-v1");
  hashRuntimeValue(hash, value, new Set());
  return hash.digest("hex");
}

function transitionFingerprint(previousSemantic, relativePath, sourceHash) {
  const hash = createHash("sha256");
  hashAtom(hash, "contract", "psc2-resident-transition-v2");
  hashAtom(hash, "previous-semantic", previousSemantic);
  hashAtom(hash, "module", relativePath);
  hashAtom(hash, "source", sourceHash);
  return hash.digest("hex");
}

function semanticPrefixFingerprint(previousSemantic, relativePath, declarationsHash) {
  const hash = createHash("sha256");
  hashAtom(hash, "contract", "psc2-resident-semantic-prefix-v2");
  hashAtom(hash, "previous-semantic", previousSemantic);
  hashAtom(hash, "module", relativePath);
  hashAtom(hash, "declarations", declarationsHash);
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
  const semanticStateCache = new Map();
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
          relativePath: path
            .relative(workspaceRoot, item.path)
            .replaceAll(path.sep, "/"),
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
      semanticGreen: 0,
      preparedHit: false,
      backendHit: false,
    };

    let environment = compiler.psSelfHostProdPreludeEnvironment;
    let declarationsRev = compiler.List.nil();
    let semanticPrefix = sha256Bytes(
      Buffer.from(
        `psc2-resident-semantic-root-v2\0${compilerSha256}\0proofScript`,
        "utf8",
      ),
    );

    if (!cold && !semanticStateCache.has(semanticPrefix)) {
      semanticStateCache.set(
        semanticPrefix,
        Object.freeze({ environment, declarationsRev }),
      );
    }

    for (let index = 0; index < project.modules.length; index += 1) {
      const module = project.modules[index];
      const transition = transitionFingerprint(
        semanticPrefix,
        module.relativePath,
        module.sourceHash,
      );
      const started = performance.now();

      if (!cold && snapshotCache.has(transition)) {
        const snapshot = snapshotCache.get(transition);
        environment = snapshot.environment;
        declarationsRev = snapshot.declarationsRev;
        semanticPrefix = snapshot.semanticPrefix;
        stats.snapshotHits += 1;
        if (progress) {
          process.stdout.write(
            `PSC2_RESIDENT_MODULE: ${index + 1}/${project.modules.length} snapshot=hit parse=skip green=skip ms=${Math.round(performance.now() - started)}\n`,
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
      const declarationsHash = semanticValueFingerprint(
        elaborated.declarations,
      );
      const nextSemanticPrefix = semanticPrefixFingerprint(
        semanticPrefix,
        module.relativePath,
        declarationsHash,
      );

      environment = elaborated.environment;
      declarationsRev = compiler.psListAppend(
        compiler.psListReverse(elaborated.declarations),
        declarationsRev,
      );

      let green = false;
      if (!cold && semanticStateCache.has(nextSemanticPrefix)) {
        const stableState = semanticStateCache.get(nextSemanticPrefix);
        environment = stableState.environment;
        declarationsRev = stableState.declarationsRev;
        stats.semanticGreen += 1;
        green = true;
      } else if (!cold) {
        semanticStateCache.set(
          nextSemanticPrefix,
          Object.freeze({ environment, declarationsRev }),
        );
      }

      if (!cold) {
        snapshotCache.set(
          transition,
          Object.freeze({
            environment,
            declarationsRev,
            semanticPrefix: nextSemanticPrefix,
            declarationsHash,
          }),
        );
      }
      semanticPrefix = nextSemanticPrefix;

      if (progress) {
        process.stdout.write(
          `PSC2_RESIDENT_MODULE: ${index + 1}/${project.modules.length} snapshot=miss parse=${parseMode} green=${green ? "yes" : "no"} ms=${Math.round(performance.now() - started)}\n`,
        );
      }
    }

    let prepared;
    if (!cold && preparedCache.has(semanticPrefix)) {
      prepared = preparedCache.get(semanticPrefix);
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
      if (!cold) preparedCache.set(semanticPrefix, prepared);
    }

    let typeScript;
    if (!cold && backendCache.has(semanticPrefix)) {
      typeScript = backendCache.get(semanticPrefix);
      stats.backendHit = true;
    } else {
      typeScript = unwrapExcept(
        compiler.psCompilerTypeScriptFromPrepared(prepared),
        "backend",
      );
      if (!cold) backendCache.set(semanticPrefix, typeScript);
    }

    return {
      compilerSha256,
      fingerprint: semanticPrefix,
      project,
      prepared,
      typeScript,
      stats,
    };
  }

  function clear() {
    parseCache.clear();
    snapshotCache.clear();
    semanticStateCache.clear();
    preparedCache.clear();
    backendCache.clear();
  }

  function cacheSizes() {
    return {
      parse: parseCache.size,
      snapshots: snapshotCache.size,
      semanticStates: semanticStateCache.size,
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
