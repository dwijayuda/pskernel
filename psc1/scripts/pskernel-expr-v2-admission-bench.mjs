import { pathToFileURL, fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { performance } from "node:perf_hooks";
import { readFileSync } from "node:fs";
import path from "node:path";

const [filename, mode, variant, shape, countArg, callsArg] = process.argv.slice(2);
if (!filename) throw Error("PSC1_ADMISSION_BENCH_REQUIRES_GENERATED_KERNEL");
const absolute = path.resolve(filename);
const CASES = [
  ["chain", 8, 3], ["chain", 32, 2],
  ["metadata", 8, 3], ["metadata", 32, 2],
  ["binder", 8, 2], ["binder", 32, 1]
];
if (mode !== "worker") {
  const observations = [];
  for (const [shape, count, calls] of CASES) {
    for (const variant of ["legacy", "dag", "dag", "legacy"]) {
      const result = spawnSync(process.execPath, [
        "--expose-gc", fileURLToPath(import.meta.url), absolute, "worker",
        variant, shape, String(count), String(calls)
      ], { encoding: "utf8", timeout: 180000, maxBuffer: 4 * 1024 * 1024,
        env: { ...process.env, PATH: "" } });
      if (result.status !== 0) throw Error("PSC1_ADMISSION_WORKER_FAILED " +
        [variant, shape, count, result.error?.message || "", result.stderr, result.stdout].join(" "));
      const lines = result.stdout.split("\n").filter(line => line.startsWith("PSC1_ADMISSION_SAMPLE "));
      if (lines.length !== 1) throw Error("PSC1_ADMISSION_SAMPLE_COUNT");
      const sample = JSON.parse(lines[0].slice("PSC1_ADMISSION_SAMPLE ".length));
      if (sample.variant !== variant || sample.shape !== shape ||
          sample.declarations_per_batch !== count || sample.calls !== calls ||
          sample.checksum !== calls * count || sample.all_correct !== true ||
          sample.negative_type_mismatch !== true || sample.fuel !== 4096)
        throw Error("PSC1_ADMISSION_SAMPLE_INVALID");
      observations.push(sample);
      console.log(lines[0]);
    }
  }
  console.log("PSC1_ADMISSION_ABBA " + JSON.stringify({
    node: process.version, toolchain: readFileSync("lean-toolchain", "utf8").trim(),
    scope: "Complete safe definition admission. One fresh session per batch; legacy admits ordered requests individually, DAG admits the same requests in one checked graph batch.",
    timing: "admission_ms includes session creation and real public admission; independent exact-result assertions are reported separately.",
    limitations: "Finite fixtures; no general speedup, inductive-admission, or exact allocation-count claim.",
    observations
  }));
  console.log("PSC1_DAG_ADMISSION_BENCH: PASS");
} else {
  if (typeof global.gc !== "function") throw Error("PSC1_ADMISSION_REQUIRES_GC");
  if (!["legacy", "dag"].includes(variant) || !["chain", "metadata", "binder"].includes(shape))
    throw Error("PSC1_ADMISSION_INVALID_WORKLOAD");
  const count = Number(countArg), calls = Number(callsArg);
  if (![8, 32].includes(count) || !Number.isSafeInteger(calls) || calls < 1 || calls > 4)
    throw Error("PSC1_ADMISSION_INVALID_SIZE");
  const k = await import(pathToFileURL(absolute).href);
  const N = k.PsKernelName, L = k.PsKernelLevel, E = k.PsKernelExpr;
  const B = k.PsKernelBinderInfo, S = k.PsKernelDefinitionSafety;
  const H = k.PsKernelReducibilityHints, R = k.PsKernelDeclarationRequest;
  const D = k.PsKernelDagDeclarationRequest, C = k.PsKernelDagCommand;
  const CI = k.PsKernelConstantInfo, Reply = k.PsKernelDagReply;
  const treeMakers = { Sort: E.sort, Const: E.const, BVar: E.bvar,
    App: E.app, Lam: E.lam, Forall: E.forallE, MData: E.mdata };
  const nil = typeof k.List.nil === "function" ? k.List.nil() : k.List.nil;
  const list = items => items.reduceRight((tail, head) => k.List.cons(head, tail), nil);
  const must = (condition, label) => {
    if (condition !== true) throw Error("PSC1_ADMISSION_ASSERTION " + label);
  };
  // Exact generated values, including Symbol constructor tags; not a hash comparison.
  const same = (a, b) => {
    if (a === b) return true;
    if (a === null || b === null || typeof a !== "object" || typeof b !== "object") return false;
    const keys = Reflect.ownKeys(a), other = Reflect.ownKeys(b);
    return keys.length === other.length && keys.every(key =>
      Object.hasOwn(b, key) && same(a[key], b[key]));
  };
  const accepted = (result, label) => {
    if (result && typeof result === "object" && Object.hasOwn(result, "value")) return result.value;
    throw Error("PSC1_ADMISSION_REJECTED " + label);
  };
  const array = items => {
    const out = [];
    while (!same(items, nil)) {
      must(items !== null && typeof items === "object" &&
        Object.hasOwn(items, "head") && Object.hasOwn(items, "tail"), "invalid-list");
      out.push(items.head); items = items.tail;
    }
    return out;
  };
  const exact = (a, b) => k.psKernelExprEqual(a)(b) === true;
  const nameEq = (a, b) => k.psKernelNameEq(a)(b) === true;
  const name = value => N.str(N.anonymous, value);
  const policy = k.psKernelResourcePolicyDefault;
  const target = k.psKernelProviderDefault.target;
  must(policy.fuel === 4096n && policy.maxRecDepth === 0n &&
    policy.maxNatSize === 134217728n && policy.cancelled === false &&
    policy.maxDeclarations === 0n, "fixed-default-resource-policy");
  must(target.contract === "KernelContract-v1" && target.leanVersion === "4.35.0" &&
    target.leanCommit === "eb6cafb7290e8bd5f2937522d8d804f58f02bafc", "pinned-target");
  const fresh = () => accepted(k.psKernelKernelSessionEmpty(policy, k.psKernelProviderDefault), "session");
  const sort0 = E.sort(L.zero), sort1 = E.sort(L.succ(L.zero));
  must(exact(sort0, sort0) && !exact(sort0, sort1), "exact-expression-sentinel");
  must(!same(S.safe, S.unsafeDef) && !same(H.abbrevHint, H.opaqueHint),
    "symbol-constructor-sentinel");

  function fixture(representation, number, workload = shape, size = count, invalid = false) {
    let arena = k.psKernelExprV2PagedEmpty;
    const mk = (kind, ...args) => {
      if (representation === "legacy") return treeMakers[kind](...args);
      const made = accepted(k["psKernelExprV2PagedMk" + kind](arena, ...args), "construct-" + kind);
      arena = made.fst;
      return made.snd;
    };
    const s0 = mk("Sort", L.zero), s1 = mk("Sort", L.succ(L.zero));
    const a = name("A"), x = name("x");
    let b0, b1, declarationType = s1;
    if (workload === "binder") {
      b0 = mk("BVar", 0n); b1 = mk("BVar", 1n);
      declarationType = mk("Forall", a, s1,
        mk("Forall", x, b0, b1, B.default), B.default);
    }
    const specs = [], requests = [];
    for (let i = 0; i < size; i++) {
      const declarationName = name("AdmissionBench-" + workload + "-" + number + "-" + i);
      let value;
      if (workload === "binder") {
        const body = i === 0 ? b0 :
          mk("App", mk("App", mk("Const", specs[i - 1].base.name, nil), b1), b0);
        value = mk("Lam", a, s1, mk("Lam", x, b0, body, B.default), B.default);
      } else {
        value = i === 0 ? s0 : mk("Const", specs[i - 1].base.name, nil);
        if (workload === "metadata") for (let mark = 0; mark < 16; mark++)
          value = mk("MData", BigInt(number * 65536 + i * 16 + mark), value);
      }
      const definition = {
        base: { name: declarationName, levelParams: nil, type: declarationType },
        value: invalid ? s1 : value, hints: H.abbrevHint, safety: S.safe
      };
      specs.push(definition);
      requests.push(representation === "legacy" ?
        R.definitionDecl(definition) : D.definitionDecl(definition));
    }
    return { arena, specs, requests, commands: representation === "dag" ?
      list(requests.map(request => C.admit(request))) : null };
  }

  const negativeSession = fresh();
  const negative = fixture(variant, 900, "chain", 1, true);
  const bad = variant === "legacy" ?
    k.psKernelV1AdmitDeclaration(negativeSession, negative.requests[0]) :
    k.psKernelV1RunDag(negativeSession, nil, S.safe, negative.arena, negative.commands);
  must(bad && typeof bad === "object" && Object.hasOwn(bad, "error") &&
    same(k.psKernelErrorOutcome(bad.error), k.PsKernelOutcome.rejectedInvalid) &&
    bad.error.message === "definition type mismatch", "negative-type-mismatch");
  must(k.psKernelEnvironmentSize(negativeSession.environment) === 0n, "negative-no-mutation");

  // The expected tree fixtures are common validation data for both worker variants.
  // Timed DAG input construction uses smart constructors directly, never legacy import.
  const expected = Array.from({ length: 5 }, (_, i) => fixture("legacy", i));
  global.gc();
  const constructionBefore = process.memoryUsage();
  const constructionStart = performance.now();
  const inputs = Array.from({ length: 5 }, (_, i) => fixture(variant, i));
  const constructionMs = performance.now() - constructionStart;
  global.gc();
  const constructionAfter = process.memoryUsage();

  const receipt = (value, index) => {
    must(value.declarationsBefore === BigInt(index) &&
      value.declarationsAfter === BigInt(index + 1) &&
      same(value.target, target), "exact-receipt-" + index);
  };
  function execute(input) {
    const initial = fresh();
    if (variant === "dag") {
      const result = accepted(k.psKernelV1RunDag(initial, nil, S.safe, input.arena, input.commands), "dag-batch");
      return { initial, session: result.session, replies: result.replies, receipts: null };
    }
    let session = initial;
    const receipts = [];
    for (const request of input.requests) {
      const result = accepted(k.psKernelV1AdmitDeclaration(session, request), "legacy-declaration");
      session = result.session;
      receipts.push(result.declaration.receipt);
    }
    return { initial, session, replies: null, receipts };
  }
  function validate(result, wanted) {
    const { session, initial } = result;
    must(k.psKernelEnvironmentSize(initial.environment) === 0n, "initial-session-unchanged");
    must(session.resources.fuel === 4096n && session.resources.maxRecDepth === 0n &&
      session.resources.maxNatSize === 134217728n && session.resources.cancelled === false &&
      session.resources.maxDeclarations === 0n, "final-fixed-resource-policy");
    must(same(session.resources, policy) && same(session.provider, k.psKernelProviderDefault),
      "session-resources-and-provider-preserved");
    must(session.environment.quotInitialized === false &&
      k.psKernelEnvironmentSize(session.environment) === BigInt(count), "exact-environment-size");
    if (variant === "dag") {
      const replies = array(result.replies);
      must(replies.length === count, "all-admission-replies");
      replies.forEach((reply, i) => {
        must(Object.hasOwn(reply, "receipt") && same(reply, Reply.admitted(reply.receipt)),
          "admission-reply-tag");
        receipt(reply.receipt, i);
      });
    } else {
      must(result.receipts.length === count, "all-legacy-receipts");
      result.receipts.forEach(receipt);
    }
    const constants = array(session.environment.constants);
    must(constants.length === count, "exact-constant-list-size");
    for (let i = 0; i < count; i++) {
      const spec = wanted.specs[i], info = constants[count - i - 1];
      must(info && Object.hasOwn(info, "value") && same(info, CI.defnInfo(info.value)),
        "definition-constructor");
      const value = info.value;
      must(nameEq(value.base.name, spec.base.name) &&
        same(value.base.levelParams, nil) &&
        exact(value.base.type, spec.base.type) && exact(value.value, spec.value) &&
        same(value.hints, spec.hints) && same(value.safety, spec.safety), "exact-definition-" + i);
      const found = accepted(k.psKernelEnvironmentFind(session.environment, spec.base.name), "indexed-lookup");
      must(same(found, info), "list-index-correspondence-" + i);
    }
    must(k.psKernelEnvironmentContains(session.environment, name("AdmissionBench-absent")) === false,
      "absent-name-remains-absent");
  }
  function perform(i) {
    const slot = i % inputs.length;
    const start = performance.now();
    const result = execute(inputs[slot]);
    const admissionMs = performance.now() - start;
    const assertionStart = performance.now();
    validate(result, expected[slot]);
    return { admissionMs, assertionMs: performance.now() - assertionStart, checksum: count };
  }
  const cold = perform(0);
  for (let i = 0; i < inputs.length; i++) perform(i);
  global.gc();
  const before = process.memoryUsage();
  const start = performance.now();
  let admissionMs = 0, assertionMs = 0, checksum = 0;
  for (let i = 0; i < calls; i++) {
    const measured = perform(i);
    admissionMs += measured.admissionMs;
    assertionMs += measured.assertionMs;
    checksum += measured.checksum;
  }
  const checkedWallMs = performance.now() - start;
  global.gc();
  const after = process.memoryUsage();
  must(checksum === calls * count, "all-batches-checked");
  console.log("PSC1_ADMISSION_SAMPLE " + JSON.stringify({
    variant, shape, declarations_per_batch: count, calls, checksum,
    checked_declarations: calls * count, all_correct: true,
    negative_type_mismatch: true, fuel: 4096, input_pool: inputs.length,
    admission_ms: admissionMs, independent_assertion_ms: assertionMs,
    checked_wall_ms: checkedWallMs, cold_admission_ms: cold.admissionMs,
    cold_assertion_ms: cold.assertionMs,
    cold_scope: "first valid fixture batch after the independent negative sentinel; fresh semantic state",
    input_construction_ms: constructionMs,
    input_construction_heap_delta_bytes: constructionAfter.heapUsed - constructionBefore.heapUsed,
    input_construction_rss_delta_bytes: constructionAfter.rss - constructionBefore.rss,
    heap_before_bytes: before.heapUsed, heap_after_gc_bytes: after.heapUsed,
    retained_heap_delta_bytes: after.heapUsed - before.heapUsed,
    peak_rss_kib: process.resourceUsage().maxRSS,
    semantic_cache: "fresh session and checker state for every admitted batch",
    lifetime: "input pools retained; admitted environments discarded after exact assertions",
    direct_dag_admission_path_measured: false
  }));
}
