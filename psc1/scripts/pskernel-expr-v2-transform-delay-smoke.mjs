import { pathToFileURL } from "node:url";
import path from "node:path";

const file = process.argv[2];
if (!file) throw Error("PSC1_TRANSFORM_DELAY_KERNEL_REQUIRED");
const lib = await import(pathToFileURL(path.resolve(file)).href);
const get = name => {
  if (!(name in lib)) throw Error("PSC1_TRANSFORM_DELAY_MISSING_EXPORT " + name);
  return lib[name];
};
let assertions = 0;
const demand = (ok, label) => {
  if (!ok) throw Error("PSC1_TRANSFORM_DELAY_FAILED " + label);
  assertions++;
  console.log("PSC1_TRANSFORM_DELAY_ASSERT " + label);
};
const ok = result => {
  if (!result || typeof result !== "object" || !("value" in result))
    throw Error("PSC1_TRANSFORM_DELAY_EXPECTED_OK " + String(result?.error));
  return result.value;
};
const errorIs = (result, expected) =>
  result && typeof result === "object" && result.error === expected;
const staged = (name, values) => {
  let result = get(name);
  for (const value of values) {
    if (typeof result !== "function")
      throw Error("PSC1_TRANSFORM_DELAY_CURRIED_ABI " + name);
    result = result(value);
  }
  if (typeof result === "function")
    throw Error("PSC1_TRANSFORM_DELAY_UNAPPLIED_RESULT " + name);
  return result;
};
const unit = value => typeof value === "function" ? value() : value;
const List = get("List");
const nil = unit(List.nil);
const list = xs => xs.reduceRight((tail, head) => List.cons(head, tail), nil);
const Level = get("PsKernelLevel");
const T = get("PsKernelExprV2Transform");
const TS = {mk: (arena, memo) => ({arena, memo})};
const TM = {mk: (source, offset, budget, result) => ({source, offset, budget, result})};
const LS = {mk: (arena, memo) => ({arena, memo})};
const LM = {mk: (source, cutoff, amount, result) => ({source, cutoff, amount, result})};
const CM = {mk: (source, count) => ({source, count})};
const bvar = ok(get("psKernelExprV2PagedMkBVar")(
  get("psKernelExprV2PagedEmptyWithLimit")(3n), 0n));
const sort = ok(get("psKernelExprV2PagedMkSort")(bvar.fst, unit(Level.zero)));
const app = ok(get("psKernelExprV2PagedMkApp")(sort.fst, bvar.snd, bvar.snd));
const arena = app.fst, bad = arena.size;
const ts = TS.mk(arena, nil), ls = LS.mk(arena, nil);
const operation = T.instantiate(0n, list([sort.snd]));
const transformName = "psKernelExprV2TransformWithFuel";
const countName = "psKernelExprV2TransformCountWithFuel";
const liftName = "psKernelExprV2PagedLiftWithFuel";
const transform = (fuel, state, root, offset = 0n) =>
  staged(transformName, [fuel, operation, state, root, offset]);
const count = (fuel, memo, root) => staged(countName, [fuel, arena, memo, root]);
const lift = (fuel, state, root, cutoff, amount) =>
  staged(liftName, [fuel, state, root, cutoff, amount]);
const entry = (owner, id) => ok(get("psKernelExprV2PagedRequire")(owner, id));
const listArray = xs => {
  const result = [];
  for (let cursor = xs; cursor && typeof cursor === "object" && "head" in cursor;
       cursor = cursor.tail) result.push(cursor.head);
  return result;
};
demand(entry(arena, bvar.snd).node.index === 0n &&
  entry(arena, app.snd).node.fn === bvar.snd &&
  entry(arena, app.snd).node.arg === bvar.snd && bad === 3n,
  "harness-real-canonical-shared-app");

// Each assertion checks every declared returned-function stage explicitly.
let partial = get(transformName)(1n);
if (typeof partial !== "function") throw Error("TRANSFORM_FUEL_STAGE");
partial = partial(operation);
if (typeof partial !== "function") throw Error("TRANSFORM_OPERATION_STAGE");
partial = partial(ts);
if (typeof partial !== "function") throw Error("TRANSFORM_STATE_STAGE");
partial = partial(bvar.snd);
if (typeof partial !== "function") throw Error("TRANSFORM_ROOT_STAGE");
let value = ok(partial(0n));
demand(value.snd === sort.snd && value.fst.arena === arena,
  "staged-transform-all-four-arrows");
partial = get(countName)(1n);
if (typeof partial !== "function") throw Error("COUNT_FUEL_STAGE");
partial = partial(arena);
if (typeof partial !== "function") throw Error("COUNT_ARENA_STAGE");
partial = partial(nil);
if (typeof partial !== "function") throw Error("COUNT_MEMO_STAGE");
value = ok(partial(bvar.snd));
demand(value.snd === 1n && value.fst.head.source === bvar.snd,
  "staged-count-all-three-arrows");
partial = get(liftName)(1n);
if (typeof partial !== "function") throw Error("LIFT_FUEL_STAGE");
partial = partial(ls);
if (typeof partial !== "function") throw Error("LIFT_STATE_STAGE");
partial = partial(bvar.snd);
if (typeof partial !== "function") throw Error("LIFT_ROOT_STAGE");
partial = partial(0n);
if (typeof partial !== "function") throw Error("LIFT_CUTOFF_STAGE");
value = ok(partial(0n));
demand(value.fst === ls && value.snd === bvar.snd,
  "staged-lift-all-four-arrows");

// Raw-worker equations, including deliberately invalid internal inputs.
// These are not guarantees for untrusted input; Checked wrappers still validate.
value = ok(transform(0n, ts, app.snd));
demand(value.fst === ts && value.snd === app.snd,
  "raw-transform-zero-preserves-owner-and-id");
demand(errorIs(transform(0n, ts, bad), "PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
  "raw-transform-zero-still-requires-root");
const badTM = TS.mk(arena, list([TM.mk(bad, 0n, 1n, sort.snd)]));
demand(errorIs(transform(1n, badTM, bad), "PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
  "raw-transform-successor-root-before-memo");
const hitTM = TS.mk(arena, list([TM.mk(bvar.snd, 0n, 1n, sort.snd)]));
value = ok(transform(1n, hitTM, bvar.snd));
demand(value.fst === hitTM && value.snd === sort.snd,
  "raw-transform-successor-memo-preserves-full-owner");
value = ok(transform(1n, ts, app.snd));
demand(value.fst.arena === arena && value.snd === app.snd &&
  value.fst.memo.head.source === app.snd && value.fst.memo.head.budget === 1n,
  "raw-transform-one-retains-zero-budget-children");
value = ok(transform(2n, ts, app.snd));
const transformed = entry(value.fst.arena, value.snd);
const transformMemo = listArray(value.fst.memo);
demand(transformed.node.fn === sort.snd && transformed.node.arg === sort.snd &&
  value.fst.arena.size === arena.size + 1n && transformMemo.length === 2 &&
  transformMemo[0].source === app.snd && transformMemo[0].budget === 2n &&
  transformMemo[1].source === bvar.snd && transformMemo[1].budget === 1n &&
  ts.arena === arena && ts.memo === nil,
  "raw-transform-two-threads-shared-child-memo-and-ids");

const countHit = list([CM.mk(bvar.snd, 71n)]);
demand(errorIs(count(0n, countHit, bvar.snd), "PSKERNEL_V2_TRANSFORM_COUNT_FUEL"),
  "raw-count-zero-before-memo");
demand(errorIs(count(0n, nil, bad), "PSKERNEL_V2_TRANSFORM_COUNT_FUEL"),
  "raw-count-zero-before-root-validation");
value = ok(count(1n, nil, bvar.snd));
demand(value.snd === 1n && value.fst.head.source === bvar.snd &&
  value.fst.head.count === 1n, "raw-count-one-leaf");
demand(errorIs(count(1n, nil, app.snd), "PSKERNEL_V2_TRANSFORM_COUNT_FUEL"),
  "raw-count-one-child-exhaustion");
demand(errorIs(count(1n, nil, bad), "PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
  "raw-count-one-invalid-root");
const badCountHit = list([CM.mk(bad, 73n)]);
value = ok(count(1n, badCountHit, bad));
demand(value.fst === badCountHit && value.snd === 73n,
  "raw-count-successor-internal-memo-before-root");

demand(errorIs(lift(0n, ls, bad, 0n, 0n), "PSKERNEL_V2_PORTABLE_LIFT_FUEL"),
  "raw-lift-zero-before-zero-amount");
value = ok(lift(1n, ls, bad, 0n, 0n));
demand(value.fst === ls && value.snd === bad,
  "raw-lift-successor-zero-amount-before-root");
const badLM = LS.mk(arena, list([LM.mk(bad, 0n, 1n, sort.snd)]));
demand(errorIs(lift(1n, badLM, bad, 0n, 1n),
  "PSKERNEL_V2_PORTABLE_LIFT_INVALID_NODE"),
  "raw-lift-successor-root-before-memo");
const prunedLM = LS.mk(arena, list([LM.mk(bvar.snd, 1n, 1n, sort.snd)]));
value = ok(lift(1n, prunedLM, bvar.snd, 1n, 1n));
demand(value.fst === prunedLM && value.snd === bvar.snd,
  "raw-lift-loose-range-prune-before-memo");
const hitLM = LS.mk(arena, list([LM.mk(bvar.snd, 0n, 1n, sort.snd)]));
value = ok(lift(1n, hitLM, bvar.snd, 0n, 1n));
demand(value.fst === hitLM && value.snd === sort.snd,
  "raw-lift-valid-memo-preserves-full-owner");
demand(errorIs(lift(1n, ls, app.snd, 0n, 2n), "PSKERNEL_V2_PORTABLE_LIFT_FUEL"),
  "raw-lift-one-child-exhaustion");
value = ok(lift(2n, ls, app.snd, 0n, 2n));
const lifted = entry(value.fst.arena, value.snd);
const liftMemo = listArray(value.fst.memo);
demand(lifted.node.fn === lifted.node.arg &&
  entry(value.fst.arena, lifted.node.fn).node.index === 2n &&
  value.fst.arena.size === arena.size + 2n && liftMemo.length === 2 &&
  liftMemo[0].source === app.snd && liftMemo[1].source === bvar.snd &&
  ls.arena === arena && ls.memo === nil,
  "raw-lift-two-threads-shared-child-memo-and-ids");

if (assertions !== 23) throw Error("PSC1_TRANSFORM_DELAY_ASSERTION_INVENTORY");
console.log("PSC1_TRANSFORM_DELAY_RAW_JS: PASS assertions=23 exports=3 stagedArrows=11");
